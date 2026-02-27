// Vercel Serverless Function for ClickPesa Webhook
const mongoose = require('mongoose');
const Transaction = require('../backend/src/models/Transaction');
const User = require('../backend/src/models/User');

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

module.exports = async (req, res) => {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { 
      eventType,           // ClickPesa event type
      orderReference, 
      status, 
      amount, 
      paymentMethod,
      customer,
      payout,
      timestamp 
    } = req.body;

    console.log('ClickPesa Webhook Received:', { eventType, orderReference, status, amount, paymentMethod, customer, payout, timestamp });

    // Handle different ClickPesa events
    switch (eventType) {
      case 'PAYMENT RECEIVED':
        await handlePaymentReceived(req.body);
        break;
        
      case 'PAYMENT FAILED':
        await handlePaymentFailed(req.body);
        break;
        
      case 'PAYOUT INITIATED':
        await handlePayoutInitiated(req.body);
        break;
        
      case 'PAYOUT REFUNDED':
        await handlePayoutRefunded(req.body);
        break;
        
      case 'PAYOUT REVERSED':
        await handlePayoutReversed(req.body);
        break;
        
      default:
        console.log('Unknown event type:', eventType);
        break;
    }

    // Send response to ClickPesa
    res.status(200).json({ 
      success: true, 
      message: 'Webhook received successfully' 
    });
  } catch (error) {
    console.error('Webhook Error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Webhook processing failed' 
    });
  }
};

// Handle payment received event
async function handlePaymentReceived(data) {
  const { orderReference, status, amount, paymentMethod, customer, timestamp } = data;
  
  // Find pending transaction
  const transaction = await Transaction.findOne({ orderReference, status: 'pending' });
  
  if (transaction) {
    // Update transaction status
    transaction.status = 'completed';
    transaction.completedAt = new Date();
    transaction.finalAmount = amount;
    transaction.webhookData = { status, customer, timestamp };
    await transaction.save();

    // Add credits to user
    const user = await User.findById(transaction.userId);
    if (user) {
      user.credits += transaction.credits;
      user.totalSpent += amount / 100; // Convert to TZS if needed
      await user.save();
    }

    console.log('Payment received successfully:', orderReference);
  }
}

// Handle payment failed event
async function handlePaymentFailed(data) {
  const { orderReference, status, amount, paymentMethod, customer, timestamp } = data;
  
  // Update transaction status to failed
  const transaction = await Transaction.findOne({ orderReference, status: 'pending' });
  
  if (transaction) {
    transaction.status = 'failed';
    transaction.error = 'Payment failed';
    transaction.webhookData = { status, customer, timestamp };
    await transaction.save();
  }
  
  console.log('Payment failed:', orderReference);
}

// Handle payout initiated event
async function handlePayoutInitiated(data) {
  const { orderReference, status, payout, timestamp } = data;
  
  // Find payout transaction
  const transaction = await Transaction.findOne({ orderReference, type: 'payout', status: 'pending' });
  
  if (transaction) {
    // Update transaction status
    transaction.status = 'processing';
    transaction.payoutData = payout;
    transaction.webhookData = { status, payout, timestamp };
    await transaction.save();
  }

  console.log('Payout initiated:', orderReference);
}

// Handle payout refunded event
async function handlePayoutRefunded(data) {
  const { orderReference, status, payout, timestamp } = data;
  
  // Find payout transaction
  const transaction = await Transaction.findOne({ orderReference, type: 'payout', status: 'processing' });
  
  if (transaction) {
    // Update transaction status
    transaction.status = 'refunded';
    transaction.payoutData = payout;
    transaction.webhookData = { status, payout, timestamp };
    await transaction.save();

    // Add credits back to user (refund)
    const user = await User.findById(transaction.userId);
    if (user) {
      user.credits += transaction.credits; // Refund credits
      await user.save();
    }
  }

  console.log('Payout refunded:', orderReference);
}

// Handle payout reversed event
async function handlePayoutReversed(data) {
  const { orderReference, status, payout, timestamp } = data;
  
  // Find payout transaction
  const transaction = await Transaction.findOne({ orderReference, type: 'payout', status: 'processing' });
  
  if (transaction) {
    // Update transaction status
    transaction.status = 'reversed';
    transaction.payoutData = payout;
    transaction.webhookData = { status, payout, timestamp };
    await transaction.save();

    // Add credits back to user (reverse)
    const user = await User.findById(transaction.userId);
    if (user) {
      user.credits += transaction.credits; // Reverse credits
      await user.save();
    }
  }

  console.log('Payout reversed:', orderReference);
}
