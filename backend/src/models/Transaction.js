const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  type: {
    type: String,
    enum: ['purchase', 'payout'],
    default: 'purchase',
  },
  credits: {
    type: Number,
    required: true,
  },
  amount: {
    type: Number,
    required: true,
  },
  currency: {
    type: String,
    default: 'TZS',
  },
  status: {
    type: String,
    enum: ['pending', 'completed', 'failed', 'processing', 'refunded', 'reversed'],
    default: 'pending',
  },
  orderReference: {
    type: String,
    required: true,
    unique: true,
  },
  paymentIntentId: {
    type: String,
  },
  paymentMethod: {
    type: String,
    enum: ['mobile_money', 'card', 'bank', 'clickpesa_card', 'crdb_bank'],
  },
  description: {
    type: String,
  },
  finalAmount: {
    type: Number,
  },
  completedAt: {
    type: Date,
  },
  webhookData: {
    eventType: String,
    status: String,
    customer: Object,
    payout: Object,
    timestamp: Date,
  },
  payoutData: {
    amount: Number,
    method: String,
    recipient: String,
    reference: String,
  },
  error: {
    type: String,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Transaction', transactionSchema);
