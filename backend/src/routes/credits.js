const express = require('express');
const router = express.Router();
const creditsController = require('../controllers/creditsController');
const auth = require('../middleware/auth');

// Get credit balance
router.get('/balance', auth, creditsController.getBalance);

// Deduct credit (for cached images)
router.post('/deduct', auth, creditsController.deductCredit);

// Get credit packages
router.get('/packages', auth, creditsController.getCreditPackages);

// Create payment intent
router.post('/create-payment', auth, creditsController.createPaymentIntent);

// Confirm payment
router.post('/confirm-payment', auth, creditsController.confirmPayment);

// Get transaction history
router.get('/transactions', auth, creditsController.getTransactionHistory);

module.exports = router;
