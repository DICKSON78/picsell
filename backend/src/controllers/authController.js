const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Transaction = require('../models/Transaction');

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const authController = {
  // Google Sign In
  async googleSignIn(req, res) {
    try {
      const { idToken } = req.body;

      if (!idToken) {
        return res.status(400).json({ error: 'ID token is required' });
      }

      // Verify the Google ID token
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      const { sub: googleId, email, name, picture } = payload;

      // Find or create user
      let user = await User.findOne({ googleId });

      if (!user) {
        // Create new user with welcome bonus credits
        user = await User.create({
          googleId,
          email,
          name,
          picture,
          credits: 5, // Welcome bonus
        });

        // Log the welcome bonus transaction
        await Transaction.create({
          userId: user._id,
          type: 'bonus',
          credits: 5,
          description: 'Welcome bonus',
        });
      } else {
        // Update last login
        user.lastLogin = Date.now();
        await user.save();
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user._id },
        process.env.JWT_SECRET,
        { expiresIn: '30d' }
      );

      res.json({
        success: true,
        token,
        user: {
          id: user._id,
          email: user.email,
          name: user.name,
          picture: user.picture,
          credits: user.credits,
        },
      });
    } catch (error) {
      console.error('Google Sign In Error:', error);
      res.status(400).json({ error: 'Failed to authenticate with Google' });
    }
  },

  // Get current user info
  async getCurrentUser(req, res) {
    try {
      const user = req.user;
      res.json({
        success: true,
        user: {
          id: user._id,
          email: user.email,
          name: user.name,
          picture: user.picture,
          credits: user.credits,
          totalSpent: user.totalSpent,
        },
      });
    } catch (error) {
      res.status(500).json({ error: 'Failed to get user info' });
    }
  },
};

module.exports = authController;
