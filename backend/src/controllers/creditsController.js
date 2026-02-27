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

  // Create ClickPesa payment request
  async createPayment(req, res) {
    try {
      const { packageId, phoneNumber, paymentMethod } = req.body;
      const user = req.user;

      const packages = {
        pack_10: { credits: 10, price: 12000 }, // TZS 12,000
        pack_25: { credits: 25, price: 24000 }, // TZS 24,000
        pack_50: { credits: 50, price: 43000 }, // TZS 43,000
        pack_100: { credits: 100, price: 72000 }, // TZS 72,000
      };

      const selectedPackage = packages[packageId];

      if (!selectedPackage) {
        return res.status(400).json({ error: 'Invalid package' });
      }

      // Generate unique order reference
      const orderReference = `CRED_${Date.now()}_${user._id.toString().slice(-6)}`;

      // Create pending transaction
      const transaction = await Transaction.create({
        userId: user._id,
        type: 'purchase',
        credits: selectedPackage.credits,
        amount: selectedPackage.price,
        currency: paymentMethod === 'card' ? 'USD' : 'TZS',
        orderReference,
        status: 'pending',
        paymentMethod,
        description: `Purchasing ${selectedPackage.credits} credits`,
      });

      if (paymentMethod === 'card') {
        // Handle CRDB bank payment
        const bankDetails = await clickpesaService.getUserBankDetails(user._id);
        
        if (!bankDetails || bankDetails.bankName !== 'CRDB') {
          return res.status(400).json({ 
            error: 'No CRDB bank details found. Please save your bank details first.' 
          });
        }

        // Process CRDB payment
        const bankPayment = await clickpesaService.processCRDBPayment(
          user._id,
          selectedPackage.price,
          orderReference
        );

        if (!bankPayment.success) {
          transaction.status = 'failed';
          transaction.error = bankPayment.error || 'CRDB payment failed';
          await transaction.save();
          
          return res.status(400).json({ 
            error: bankPayment.error || 'Failed to process CRDB payment',
            details: bankPayment 
          });
        }

        // Add credits immediately since CRDB payment is completed
        user.credits += selectedPackage.credits;
        user.totalSpent += selectedPackage.price / 100; // Convert to TZS if needed
        await user.save();

        // Update transaction status
        transaction.status = 'completed';
        transaction.completedAt = new Date();
        transaction.finalAmount = selectedPackage.price;
        await transaction.save();

        res.json({
          success: true,
          orderReference,
          amount: selectedPackage.price,
          credits: selectedPackage.credits,
          currency: 'TZS',
          paymentMethod: 'crdb_bank',
          transactionId: bankPayment.transactionId,
          creditsRemaining: user.credits,
          message: 'Payment completed successfully',
        });
      } else if (paymentMethod === 'clickpesa_card') {
        // Handle ClickPesa card payment
        const usdAmount = await clickpesaService.convertTzsToUsd(selectedPackage.price);
        
        // Preview card payment
        const preview = await clickpesaService.previewCardPayment(
          usdAmount,
          orderReference
        );

        if (!preview.success) {
          transaction.status = 'failed';
          transaction.error = preview.error || 'Card payment preview failed';
          await transaction.save();
          
          return res.status(400).json({ 
            error: preview.error || 'Failed to preview card payment',
            details: preview 
          });
        }

        // Initiate card payment
        const cardPayment = await clickpesaService.initiateCardPayment(
          usdAmount,
          orderReference,
          user._id.toString()
        );

        if (!cardPayment.success) {
          transaction.status = 'failed';
          transaction.error = cardPayment.error || 'Card payment initiation failed';
          await transaction.save();
          
          return res.status(400).json({ 
            error: cardPayment.error || 'Failed to initiate card payment',
            details: cardPayment 
          });
        }

        res.json({
          success: true,
          orderReference,
          amount: selectedPackage.price,
          credits: selectedPackage.credits,
          currency: 'TZS',
          usdAmount,
          paymentMethod: 'clickpesa_card',
          cardPaymentLink: cardPayment.cardPaymentLink,
          clientId: cardPayment.clientId,
          transactionId: transaction._id,
        });
      } else {
        // Handle mobile money payment
        if (!phoneNumber) {
          return res.status(400).json({ error: 'Phone number is required for mobile money' });
        }

        // Preview payment with ClickPesa
        const preview = await clickpesaService.previewPayment(
          phoneNumber,
          selectedPackage.price,
          orderReference
        );

        if (!preview.success) {
          transaction.status = 'failed';
          transaction.error = preview.error || 'Mobile money payment preview failed';
          await transaction.save();
          
          return res.status(400).json({ 
            error: preview.error || 'Failed to preview payment',
            details: preview 
          });
        }

        res.json({
          success: true,
          orderReference,
          amount: selectedPackage.price,
          credits: selectedPackage.credits,
          currency: 'TZS',
          paymentMethod: 'mobile_money',
          preview: {
            availableMethods: preview.activeMethods || [],
            fee: preview.fee || 0,
            totalAmount: preview.amount || selectedPackage.price,
          },
          transactionId: transaction._id,
        });
      }
    } catch (error) {
      console.error('Create ClickPesa Payment Error:', error);
      res.status(500).json({ error: 'Failed to create payment' });
    }
  },

  // Save bank details
  async saveBankDetails(req, res) {
    try {
      const { accountNumber, accountName, bankName, isDefault } = req.body;
      const user = req.user;

      if (!accountNumber || !accountName || !bankName) {
        return res.status(400).json({ error: 'All bank details are required' });
      }

      // Validate CRDB account number (10 digits)
      if (bankName === 'CRDB' && !/^\d{10}$/.test(accountNumber)) {
        return res.status(400).json({ error: 'Invalid CRDB account number. Must be 10 digits.' });
      }

      const bankDetails = {
        accountNumber,
        accountName,
        bankName,
        isDefault: isDefault || false,
      };

      await clickpesaService.saveUserBankDetails(user._id, bankDetails);

      res.json({
        success: true,
        message: 'Bank details saved successfully',
        bankDetails: {
          ...bankDetails,
          accountNumber: accountNumber.slice(0, 4) + '****' + accountNumber.slice(-4), // Mask account number
        }
      });
    } catch (error) {
      console.error('Save Bank Details Error:', error);
      res.status(500).json({ error: 'Failed to save bank details' });
    }
  },

  // Get bank details
  async getBankDetails(req, res) {
    try {
      const user = req.user;
      const bankDetails = await clickpesaService.getUserBankDetails(user._id);

      if (!bankDetails) {
        return res.json({
          success: true,
          hasBankDetails: false,
          message: 'No bank details found'
        });
      }

      res.json({
        success: true,
        hasBankDetails: true,
        bankDetails: {
          accountNumber: bankDetails.accountNumber.slice(0, 4) + '****' + bankDetails.accountNumber.slice(-4),
          accountName: bankDetails.accountName,
          bankName: bankDetails.bankName,
          isDefault: bankDetails.isDefault,
          savedAt: bankDetails.savedAt
        }
      });
    } catch (error) {
      console.error('Get Bank Details Error:', error);
      res.status(500).json({ error: 'Failed to get bank details' });
    }
  },

  // Get exchange rate
  async getExchangeRate(req, res) {
    try {
      const exchangeRate = await clickpesaService.getExchangeRate();
      
      res.json({
        success: true,
        exchangeRate,
        lastUpdated: new Date(),
        currency: 'TZS to USD'
      });
    } catch (error) {
      console.error('Get Exchange Rate Error:', error);
      res.status(500).json({ error: 'Failed to get exchange rate' });
    }
  },

  // Confirm payment and add credits (webhook endpoint)
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
