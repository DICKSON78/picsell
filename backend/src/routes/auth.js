const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');

// Google Sign In
router.post('/google-signin', authController.googleSignIn);

// Get current user (protected)
router.get('/me', auth, authController.getCurrentUser);

module.exports = router;
