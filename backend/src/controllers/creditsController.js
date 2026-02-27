const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const User = require('../models/User');
const Transaction = require('../models/Transaction');

const creditsController = {
  // Get user's credit balance
  async getBalance(req, res) {
    try {
      const user = req.user;
      res.json({
        success: true,
        credits: user.credits,
      });
    } catch (error) {
      console.error('Get Balance Error:', error);
      res.status(500).json({ error: 'Failed to get credit balance' });
    }
  },

  // Deduct credit (for cached images)
  async deductCredit(req, res) {
    try {
      const user = req.user;
      const { amount = 1 } = req.body;

      if (user.credits < amount) {
        return res.status(400).json({
          error: 'Insufficient credits',
          credits: user.credits,
        });
      }

      user.credits -= amount;
      await user.save();

      // Log transaction
      await Transaction.create({
        userId: user._id,
        type: 'usage',
        credits: -amount,
        description: 'Used cached photo',
      });

      res.json({
        success: true,
        creditsRemaining: user.credits,
        deducted: amount,
      });
    } catch (error) {
      console.error('Deduct Credit Error:', error);
      res.status(500).json({ error: 'Failed to deduct credit' });
    }
  },

  // Get credit packages
  async getCreditPackages(req, res) {
    try {
      const packages = [
        {
          id: 'pack_10',
          name: '10 Credits',
          credits: 10,
          price: 4.99,
          popular: false,
        },
        {
          id: 'pack_25',
          name: '25 Credits',
          credits: 25,
          price: 9.99,
          popular: true,
          discount: '20% off',
        },
        {
          id: 'pack_50',
          name: '50 Credits',
          credits: 50,
          price: 17.99,
          popular: false,
          discount: '28% off',
        },
        {
          id: 'pack_100',
          name: '100 Credits',
          credits: 100,
          price: 29.99,
          popular: false,
          discount: '40% off',
        },
      ];

      res.json({
        success: true,
        packages,
      });
    } catch (error) {
      res.status(500).json({ error: 'Failed to get credit packages' });
    }
  },

  // Create payment intent
  async createPaymentIntent(req, res) {
    try {
      const { packageId } = req.body;
      const user = req.user;

      const packages = {
        pack_10: { credits: 10, price: 4.99 },
        pack_25: { credits: 25, price: 9.99 },
        pack_50: { credits: 50, price: 17.99 },
        pack_100: { credits: 100, price: 29.99 },
      };

      const selectedPackage = packages[packageId];

      if (!selectedPackage) {
        return res.status(400).json({ error: 'Invalid package' });
      }

      // Create Stripe payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(selectedPackage.price * 100), // Convert to cents
        currency: 'usd',
        metadata: {
          userId: user._id.toString(),
          credits: selectedPackage.credits,
          packageId,
        },
      });

      res.json({
        success: true,
        clientSecret: paymentIntent.client_secret,
        amount: selectedPackage.price,
        credits: selectedPackage.credits,
      });
    } catch (error) {
      console.error('Create Payment Intent Error:', error);
      res.status(500).json({ error: 'Failed to create payment' });
    }
  },

  // Confirm payment and add credits
  async confirmPayment(req, res) {
    try {
      const { paymentIntentId } = req.body;
      const user = req.user;

      // Retrieve payment intent from Stripe
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

      if (paymentIntent.status !== 'succeeded') {
        return res.status(400).json({ error: 'Payment not completed' });
      }

      // Check if already processed
      const existingTransaction = await Transaction.findOne({ paymentIntentId });

      if (existingTransaction) {
        return res.status(400).json({ error: 'Payment already processed' });
      }

      const credits = parseInt(paymentIntent.metadata.credits);
      const amount = paymentIntent.amount / 100;

      // Add credits to user
      user.credits += credits;
      user.totalSpent += amount;
      await user.save();

      // Log transaction
      await Transaction.create({
        userId: user._id,
        type: 'purchase',
        credits,
        amount,
        paymentIntentId,
        description: `Purchased ${credits} credits`,
      });

      res.json({
        success: true,
        credits: user.credits,
        purchased: credits,
      });
    } catch (error) {
      console.error('Confirm Payment Error:', error);
      res.status(500).json({ error: 'Failed to confirm payment' });
    }
  },

  // Get transaction history
  async getTransactionHistory(req, res) {
    try {
      const user = req.user;
      const transactions = await Transaction.find({ userId: user._id })
        .sort({ createdAt: -1 })
        .limit(50);

      res.json({
        success: true,
        transactions: transactions.map(t => ({
          id: t._id,
          type: t.type,
          credits: t.credits,
          amount: t.amount,
          description: t.description,
          createdAt: t.createdAt,
        })),
      });
    } catch (error) {
      console.error('Get Transaction History Error:', error);
      res.status(500).json({ error: 'Failed to get transaction history' });
    }
  },
};

module.exports = creditsController;
