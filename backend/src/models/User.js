const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  googleId: {
    type: String,
    required: true,
    unique: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  name: {
    type: String,
    required: true,
  },
  picture: {
    type: String,
  },
  credits: {
    type: Number,
    default: 5, // Give 5 free credits on signup
  },
  totalSpent: {
    type: Number,
    default: 0,
  },
  bankDetails: {
    accountNumber: {
      type: String,
      default: null,
    },
    accountName: {
      type: String,
      default: null,
    },
    bankName: {
      type: String,
      default: null,
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
    savedAt: {
      type: Date,
      default: null,
    },
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  lastLogin: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('User', userSchema);
