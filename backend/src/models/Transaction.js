const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  type: {
    type: String,
    enum: ['purchase', 'usage', 'bonus'],
    required: true,
  },
  credits: {
    type: Number,
    required: true,
  },
  amount: {
    type: Number, // Amount in USD for purchases
    default: 0,
  },
  paymentIntentId: {
    type: String, // Stripe payment intent ID
  },
  description: {
    type: String,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Transaction', transactionSchema);
