require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });
const mongoose = require('mongoose');
const Admin = require('../models/Admin');

const seedAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Check if admin exists
    const existingAdmin = await Admin.findOne({ username: 'admin' });

    if (existingAdmin) {
      console.log('Admin user already exists');
      process.exit(0);
    }

    // Create default admin
    const admin = await Admin.create({
      username: 'admin',
      password: 'admin123',
      name: 'Super Admin',
      email: 'admin@dukasell.com',
      role: 'super_admin',
    });

    console.log('Default admin created successfully!');
    console.log('Username: admin');
    console.log('Password: admin123');
    console.log('Admin ID:', admin._id);

    process.exit(0);
  } catch (error) {
    console.error('Seed Error:', error);
    process.exit(1);
  }
};

seedAdmin();
