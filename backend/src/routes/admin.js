const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const adminAuth = require('../middleware/adminAuth');

// ============================================
// AUTH (Public)
// ============================================
router.post('/login', adminController.login);

// ============================================
// PROTECTED ROUTES (Require Admin Auth)
// ============================================

// Auth
router.get('/me', adminAuth, adminController.getMe);

// Dashboard
router.get('/dashboard', adminAuth, adminController.getDashboardStats);

// Customers
router.get('/customers', adminAuth, adminController.getCustomers);
router.get('/customers/:id', adminAuth, adminController.getCustomer);
router.post('/customers/:id/credits', adminAuth, adminController.addCredits);

// Photos
router.get('/photos', adminAuth, adminController.getPhotos);

// Transactions
router.get('/transactions', adminAuth, adminController.getTransactions);

// Reports
router.get('/reports', adminAuth, adminController.getReports);

module.exports = router;
