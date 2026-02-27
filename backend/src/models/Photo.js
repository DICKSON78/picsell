const mongoose = require('mongoose');

const photoSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  originalUrl: {
    type: String,
    required: true,
  },
  processedUrl: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['processing', 'completed', 'failed'],
    default: 'processing',
  },
  downloaded: {
    type: Boolean,
    default: false,
  },
  creditsUsed: {
    type: Number,
    default: 1,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Photo', photoSchema);
