require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/database');
const fs = require('fs');
const path = require('path');

// Create express app
const app = express();

// Connect to database
connectDB();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Create upload directories if they don't exist
const uploadDirs = ['uploads/original', 'uploads/processed'];
uploadDirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// Serve static files
app.use('/uploads', express.static('uploads'));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/photos', require('./routes/photos'));
app.use('/api/credits', require('./routes/credits'));
app.use('/api/admin', require('./routes/admin'));

// ClickPesa Webhook (no auth required)
app.post('/webhook/clickpesa', require('./services/clickpesaService').handleWebhook);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'DukaSell API is running' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server Error:', err);
  res.status(500).json({
    error: err.message || 'Internal server error',
  });
});

// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Frontend should connect to: http://localhost:${PORT}`);
});
