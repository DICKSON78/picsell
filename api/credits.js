// Vercel Serverless Function for Credits API
const cors = require('cors');

// Firebase Admin
const admin = require('firebase-admin');

// Initialize Firebase
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      privateKeyId: process.env.FIREBASE_PRIVATE_KEY_ID,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      clientId: process.env.FIREBASE_CLIENT_ID,
      authUri: process.env.FIREBASE_AUTH_URI,
      tokenUri: process.env.FIREBASE_TOKEN_URI,
    }),
  });
}

const db = admin.firestore();

// CORS middleware
const corsHandler = cors({
  origin: ['http://localhost:3000', 'https://yourdomain.com', 'exp://192.168.1.100:8081'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
});

module.exports = async (req, res) => {
  // Apply CORS
  await new Promise((resolve, reject) => {
    corsHandler(req, res, (result) => {
      if (result instanceof Error) {
        return reject(result);
      }
      return resolve(result);
    });
  });

  // Only allow POST requests for payment
  if (req.method === 'POST' && req.url.includes('/create-payment')) {
    return handleCreatePayment(req, res);
  }

  // Only allow GET requests for balance
  if (req.method === 'GET' && req.url.includes('/balance')) {
    return handleGetBalance(req, res);
  }

  return res.status(404).json({ error: 'Endpoint not found' });
};

async function handleCreatePayment(req, res) {
  try {
    const { packageId, phoneNumber, paymentMethod } = req.body;
    
    // For now, we'll skip authentication and use a mock user
    // In production, you should verify JWT token here
    
    const packages = {
      pack_10: { credits: 10, price: 12000 },
      pack_25: { credits: 25, price: 24000 },
      pack_50: { credits: 50, price: 43000 },
      pack_100: { credits: 100, price: 72000 },
    };

    const selectedPackage = packages[packageId];
    if (!selectedPackage) {
      return res.status(400).json({ error: 'Invalid package' });
    }

    // Generate unique order reference
    const orderReference = `CRED_${Date.now()}_TEST`;

    // Create pending transaction (skip for now since we don't have user ID)
    
    if (paymentMethod === 'mobile_money') {
      // Preview payment with ClickPesa
      const preview = await clickpesaService.previewPayment(
        phoneNumber,
        selectedPackage.price,
        orderReference
      );

      if (!preview.success) {
        return res.status(400).json({ 
          error: preview.error || 'Failed to preview payment',
          details: preview 
        });
      }

      // Initiate actual USSD push payment
      const payment = await clickpesaService.initiatePayment(
        phoneNumber,
        selectedPackage.price,
        orderReference
      );

      if (!payment.success) {
        return res.status(400).json({ 
          error: payment.error || 'Failed to initiate payment',
          details: payment 
        });
      }

      return res.json({
        success: true,
        orderReference,
        amount: selectedPackage.price,
        credits: selectedPackage.credits,
        currency: 'TZS',
        paymentMethod: 'mobile_money',
        paymentInitiated: true,
        paymentId: payment.paymentId,
        message: 'USSD push sent to your phone. Please complete the payment.',
        transactionId: orderReference,
      });
    }

    res.status(400).json({ error: 'Unsupported payment method' });
  } catch (error) {
    console.error('Create Payment Error:', error);
    res.status(500).json({ error: 'Failed to create payment' });
  }
}

async function handleGetBalance(req, res) {
  try {
    // Mock response for now
    res.json({
      success: true,
      credits: 25,
    });
  } catch (error) {
    console.error('Get Balance Error:', error);
    res.status(500).json({ error: 'Failed to get credit balance' });
  }
}
