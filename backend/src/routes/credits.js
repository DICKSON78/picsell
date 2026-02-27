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

// Create ClickPesa payment request
router.post('/create-payment', auth, creditsController.createPayment);

// Initiate ClickPesa payment
router.post('/initiate-payment', auth, creditsController.initiatePayment);

// Save bank details
router.post('/save-bank-details', auth, creditsController.saveBankDetails);

// Get bank details
router.get('/bank-details', auth, creditsController.getBankDetails);

// Get exchange rate
router.get('/exchange-rate', auth, creditsController.getExchangeRate);

// Confirm payment (webhook endpoint)
router.post('/confirm-payment', creditsController.confirmPayment);

// Get transaction history
router.get('/transactions', auth, creditsController.getTransactionHistory);

// ClickPesa webhook endpoint (no auth required)
router.post('/webhook/clickpesa', creditsController.confirmPayment);

module.exports = router;
