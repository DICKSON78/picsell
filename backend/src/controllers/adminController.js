const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');
const User = require('../models/User');
const Photo = require('../models/Photo');
const Transaction = require('../models/Transaction');

const adminController = {
  // ============================================
  // AUTH
  // ============================================

  // Admin Login
  async login(req, res) {
    try {
      const { username, password } = req.body;

      if (!username || !password) {
        return res.status(400).json({ error: 'Username and password required' });
      }

      // Find admin by username
      const admin = await Admin.findOne({ username });

      if (!admin) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Check if active
      if (!admin.isActive) {
        return res.status(401).json({ error: 'Account is deactivated' });
      }

      // Check password
      const isMatch = await admin.comparePassword(password);
      if (!isMatch) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Update last login
      admin.lastLogin = new Date();
      await admin.save();

      // Generate token
      const token = jwt.sign(
        { id: admin._id, role: admin.role, isAdmin: true },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      res.json({
        success: true,
        token,
        admin: {
          id: admin._id,
          username: admin.username,
          name: admin.name,
          email: admin.email,
          role: admin.role,
        },
      });
    } catch (error) {
      console.error('Admin Login Error:', error);
      res.status(500).json({ error: 'Login failed' });
    }
  },

  // Get current admin
  async getMe(req, res) {
    try {
      const admin = await Admin.findById(req.admin._id).select('-password');
      res.json({ success: true, admin });
    } catch (error) {
      res.status(500).json({ error: 'Failed to get admin info' });
    }
  },

  // ============================================
  // DASHBOARD
  // ============================================

  // Get dashboard stats
  async getDashboardStats(req, res) {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const thisMonth = new Date();
      thisMonth.setDate(1);
      thisMonth.setHours(0, 0, 0, 0);

      // Get counts
      const [
        totalUsers,
        newUsersToday,
        newUsersThisMonth,
        totalPhotos,
        photosToday,
        photosThisMonth,
        totalRevenue,
        revenueThisMonth,
      ] = await Promise.all([
        User.countDocuments(),
        User.countDocuments({ createdAt: { $gte: today } }),
        User.countDocuments({ createdAt: { $gte: thisMonth } }),
        Photo.countDocuments(),
        Photo.countDocuments({ createdAt: { $gte: today } }),
        Photo.countDocuments({ createdAt: { $gte: thisMonth } }),
        Transaction.aggregate([
          { $match: { type: 'purchase' } },
          { $group: { _id: null, total: { $sum: '$amount' } } },
        ]),
        Transaction.aggregate([
          { $match: { type: 'purchase', createdAt: { $gte: thisMonth } } },
          { $group: { _id: null, total: { $sum: '$amount' } } },
        ]),
      ]);

      // Get recent activity
      const recentPhotos = await Photo.find()
        .populate('userId', 'name email picture')
        .sort({ createdAt: -1 })
        .limit(5);

      const recentTransactions = await Transaction.find({ type: 'purchase' })
        .populate('userId', 'name email')
        .sort({ createdAt: -1 })
        .limit(5);

      res.json({
        success: true,
        stats: {
          users: {
            total: totalUsers,
            today: newUsersToday,
            thisMonth: newUsersThisMonth,
          },
          photos: {
            total: totalPhotos,
            today: photosToday,
            thisMonth: photosThisMonth,
          },
          revenue: {
            total: totalRevenue[0]?.total || 0,
            thisMonth: revenueThisMonth[0]?.total || 0,
          },
        },
        recentPhotos: recentPhotos.map(p => ({
          id: p._id,
          originalUrl: p.originalUrl,
          processedUrl: p.processedUrl,
          status: p.status,
          user: p.userId ? {
            name: p.userId.name,
            email: p.userId.email,
            picture: p.userId.picture,
          } : null,
          createdAt: p.createdAt,
        })),
        recentTransactions: recentTransactions.map(t => ({
          id: t._id,
          type: t.type,
          credits: t.credits,
          amount: t.amount,
          user: t.userId ? {
            name: t.userId.name,
            email: t.userId.email,
          } : null,
          createdAt: t.createdAt,
        })),
      });
    } catch (error) {
      console.error('Dashboard Stats Error:', error);
      res.status(500).json({ error: 'Failed to get dashboard stats' });
    }
  },

  // ============================================
  // CUSTOMERS
  // ============================================

  // Get all customers
  async getCustomers(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const search = req.query.search || '';
      const skip = (page - 1) * limit;

      const query = search
        ? {
            $or: [
              { name: { $regex: search, $options: 'i' } },
              { email: { $regex: search, $options: 'i' } },
            ],
          }
        : {};

      const [customers, total] = await Promise.all([
        User.find(query)
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit),
        User.countDocuments(query),
      ]);

      // Get photo counts for each customer
      const customerIds = customers.map(c => c._id);
      const photoCounts = await Photo.aggregate([
        { $match: { userId: { $in: customerIds } } },
        { $group: { _id: '$userId', count: { $sum: 1 } } },
      ]);

      const photoCountMap = {};
      photoCounts.forEach(p => {
        photoCountMap[p._id.toString()] = p.count;
      });

      res.json({
        success: true,
        customers: customers.map(c => ({
          id: c._id,
          name: c.name,
          email: c.email,
          picture: c.picture,
          credits: c.credits,
          totalSpent: c.totalSpent,
          photoCount: photoCountMap[c._id.toString()] || 0,
          createdAt: c.createdAt,
          lastLogin: c.lastLogin,
        })),
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit),
        },
      });
    } catch (error) {
      console.error('Get Customers Error:', error);
      res.status(500).json({ error: 'Failed to get customers' });
    }
  },

  // Get single customer details
  async getCustomer(req, res) {
    try {
      const customer = await User.findById(req.params.id);

      if (!customer) {
        return res.status(404).json({ error: 'Customer not found' });
      }

      const [photos, transactions] = await Promise.all([
        Photo.find({ userId: customer._id }).sort({ createdAt: -1 }).limit(20),
        Transaction.find({ userId: customer._id }).sort({ createdAt: -1 }).limit(20),
      ]);

      res.json({
        success: true,
        customer: {
          id: customer._id,
          name: customer.name,
          email: customer.email,
          picture: customer.picture,
          credits: customer.credits,
          totalSpent: customer.totalSpent,
          createdAt: customer.createdAt,
          lastLogin: customer.lastLogin,
        },
        photos: photos.map(p => ({
          id: p._id,
          originalUrl: p.originalUrl,
          processedUrl: p.processedUrl,
          status: p.status,
          downloaded: p.downloaded,
          createdAt: p.createdAt,
        })),
        transactions: transactions.map(t => ({
          id: t._id,
          type: t.type,
          credits: t.credits,
          amount: t.amount,
          description: t.description,
          createdAt: t.createdAt,
        })),
      });
    } catch (error) {
      console.error('Get Customer Error:', error);
      res.status(500).json({ error: 'Failed to get customer' });
    }
  },

  // Add credits to customer
  async addCredits(req, res) {
    try {
      const { credits, reason } = req.body;
      const customer = await User.findById(req.params.id);

      if (!customer) {
        return res.status(404).json({ error: 'Customer not found' });
      }

      customer.credits += credits;
      await customer.save();

      // Log transaction
      await Transaction.create({
        userId: customer._id,
        type: 'bonus',
        credits,
        description: reason || 'Admin bonus',
      });

      res.json({
        success: true,
        message: `Added ${credits} credits to ${customer.name}`,
        newBalance: customer.credits,
      });
    } catch (error) {
      console.error('Add Credits Error:', error);
      res.status(500).json({ error: 'Failed to add credits' });
    }
  },

  // ============================================
  // PHOTOS
  // ============================================

  // Get all photos
  async getPhotos(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const status = req.query.status;
      const skip = (page - 1) * limit;

      const query = status ? { status } : {};

      const [photos, total] = await Promise.all([
        Photo.find(query)
          .populate('userId', 'name email picture')
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit),
        Photo.countDocuments(query),
      ]);

      res.json({
        success: true,
        photos: photos.map(p => ({
          id: p._id,
          originalUrl: p.originalUrl,
          processedUrl: p.processedUrl,
          status: p.status,
          downloaded: p.downloaded,
          creditsUsed: p.creditsUsed,
          user: p.userId ? {
            id: p.userId._id,
            name: p.userId.name,
            email: p.userId.email,
            picture: p.userId.picture,
          } : null,
          createdAt: p.createdAt,
        })),
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit),
        },
      });
    } catch (error) {
      console.error('Get Photos Error:', error);
      res.status(500).json({ error: 'Failed to get photos' });
    }
  },

  // ============================================
  // TRANSACTIONS
  // ============================================

  // Get all transactions
  async getTransactions(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const type = req.query.type;
      const skip = (page - 1) * limit;

      const query = type ? { type } : {};

      const [transactions, total, stats] = await Promise.all([
        Transaction.find(query)
          .populate('userId', 'name email')
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit),
        Transaction.countDocuments(query),
        Transaction.aggregate([
          { $match: { type: 'purchase' } },
          {
            $group: {
              _id: null,
              totalRevenue: { $sum: '$amount' },
              totalCredits: { $sum: '$credits' },
              count: { $sum: 1 },
            },
          },
        ]),
      ]);

      res.json({
        success: true,
        transactions: transactions.map(t => ({
          id: t._id,
          type: t.type,
          credits: t.credits,
          amount: t.amount,
          description: t.description,
          paymentIntentId: t.paymentIntentId,
          user: t.userId ? {
            id: t.userId._id,
            name: t.userId.name,
            email: t.userId.email,
          } : null,
          createdAt: t.createdAt,
        })),
        stats: stats[0] || { totalRevenue: 0, totalCredits: 0, count: 0 },
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit),
        },
      });
    } catch (error) {
      console.error('Get Transactions Error:', error);
      res.status(500).json({ error: 'Failed to get transactions' });
    }
  },

  // ============================================
  // REPORTS
  // ============================================

  // Get reports data
  async getReports(req, res) {
    try {
      const days = parseInt(req.query.days) || 30;
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      // Daily stats
      const dailyPhotos = await Photo.aggregate([
        { $match: { createdAt: { $gte: startDate } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]);

      const dailyRevenue = await Transaction.aggregate([
        { $match: { type: 'purchase', createdAt: { $gte: startDate } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            amount: { $sum: '$amount' },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]);

      const dailyUsers = await User.aggregate([
        { $match: { createdAt: { $gte: startDate } } },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]);

      // Top customers
      const topCustomers = await User.find()
        .sort({ totalSpent: -1 })
        .limit(10)
        .select('name email picture credits totalSpent');

      res.json({
        success: true,
        period: `${days} days`,
        charts: {
          photos: dailyPhotos,
          revenue: dailyRevenue,
          users: dailyUsers,
        },
        topCustomers: topCustomers.map(c => ({
          id: c._id,
          name: c.name,
          email: c.email,
          picture: c.picture,
          credits: c.credits,
          totalSpent: c.totalSpent,
        })),
      });
    } catch (error) {
      console.error('Get Reports Error:', error);
      res.status(500).json({ error: 'Failed to get reports' });
    }
  },
};

module.exports = adminController;
