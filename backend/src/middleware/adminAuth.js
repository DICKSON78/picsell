const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');

const adminAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Check if it's an admin token
    if (!decoded.isAdmin) {
      return res.status(403).json({ error: 'Admin access required' });
    }

    const admin = await Admin.findById(decoded.id).select('-password');

    if (!admin) {
      return res.status(401).json({ error: 'Admin not found' });
    }

    if (!admin.isActive) {
      return res.status(401).json({ error: 'Admin account is deactivated' });
    }

    req.admin = admin;
    next();
  } catch (error) {
    console.error('Admin Auth Error:', error.message);
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

module.exports = adminAuth;
