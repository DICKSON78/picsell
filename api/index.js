// Vercel Serverless Function - Main API Handler
require('dotenv').config();

const cors = require('cors');
const admin = require('firebase-admin');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const crypto = require('crypto');

// Initialize Firebase Admin
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
      authProviderX509CertUrl: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL,
      clientX509CertUrl: process.env.FIREBASE_CLIENT_X509_CERT_URL,
    }),
  });
}

const db = admin.firestore();

// Parse JSON body
async function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (err) {
        resolve({});
      }
    });
    req.on('error', reject);
  });
}

// Verify JWT token
function verifyToken(req) {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) return null;
    return jwt.verify(token, process.env.JWT_SECRET);
  } catch (err) {
    return null;
  }
}

// Main handler
module.exports = async (req, res) => {
  // CORS
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token,X-Requested-With,Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Api-Version,Authorization'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  try {
    // Route to appropriate handler
    if (req.url.startsWith('/api/credits/')) {
      return handleCredits(req, res);
    }

    if (req.url.startsWith('/api/auth/')) {
      return handleAuth(req, res);
    }

    if (req.url === '/api/health') {
      return res.status(200).json({ status: 'ok', message: 'DukaSell API is running' });
    }

    // Webhook routes (no auth)
    if (req.method === 'POST' && req.url === '/api/webhook/clickpesa') {
      return handleClickPesaWebhook(req, res);
    }

    res.status(404).json({ error: 'Endpoint not found' });
  } catch (error) {
    console.error('API Error:', error);
    res.status(500).json({ error: error.message || 'Internal server error' });
  }
};

// Credits handler
async function handleCredits(req, res) {
  // Check auth for all endpoints except webhook
  const decoded = verifyToken(req);
  if (!decoded) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const url = req.url.split('?')[0];

  // GET /api/credits/balance
  if (req.method === 'GET' && url === '/api/credits/balance') {
    try {
      const userDoc = await db.collection('users').doc(decoded.userId).get();
      const user = userDoc.data();
      res.status(200).json({
        credits: user?.credits || 0,
        email: user?.email,
      });
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
    return;
  }

  // POST /api/credits/create-payment
  if (req.method === 'POST' && url === '/api/credits/create-payment') {
    const body = await parseBody(req);
    return handleCreatePayment(req, res, decoded, body);
  }

  res.status(404).json({ error: 'Endpoint not found' });
}

// Create payment handler
async function handleCreatePayment(req, res, decoded, body) {
  try {
    const { packageId, phoneNumber, paymentMethod } = body;

    const packages = {
      pack_10: { credits: 10, price: 1000 },
      pack_25: { credits: 25, price: 2500 },
      pack_50: { credits: 50, price: 5000 },
      pack_100: { credits: 100, price: 10000 },
    };

    const selectedPackage = packages[packageId];
    if (!selectedPackage) {
      return res.status(400).json({ error: 'Invalid package' });
    }

    // Format phone number
    let formattedPhone = phoneNumber;
    if (phoneNumber.startsWith('0')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    }

    // Generate order reference
    const orderReference = `CRED${Date.now()}${decoded.userId.slice(-6)}`;

    // Get ClickPesa token
    let token;
    try {
      const tokenResponse = await axios.post(
        'https://api.clickpesa.com/auth/token',
        {
          client_id: process.env.CLICKPESA_CLIENT_ID,
          client_secret: process.env.CLICKPESA_API_KEY,
        }
      );
      token = tokenResponse.data.access_token;
    } catch (error) {
      console.error('Token error:', error.response?.data || error.message);
      return res.status(500).json({
        error: 'Failed to get ClickPesa token',
        details: error.response?.data,
      });
    }

    // Preview payment
    const previewData = {
      amount: String(selectedPackage.price),
      phone_number: formattedPhone,
      order_reference: orderReference,
    };

    const previewChecksum = generateChecksum(previewData);
    previewData.checksum = previewChecksum;

    let preview;
    try {
      preview = await axios.post(
        'https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request',
        previewData,
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );
    } catch (error) {
      console.error('Preview error:', error.response?.data || error.message);
      return res.status(400).json({
        error: 'Failed to preview payment',
        details: error.response?.data,
      });
    }

    // Save transaction to Firestore
    await db.collection('transactions').add({
      userId: decoded.userId,
      packageId,
      credits: selectedPackage.credits,
      amount: selectedPackage.price,
      phoneNumber: formattedPhone,
      orderReference,
      paymentMethod,
      status: 'initiated',
      createdAt: new Date(),
    });

    // Return success
    res.status(200).json({
      success: true,
      paymentInitiated: true,
      orderReference,
      message: 'USSD push sent to your phone. Please complete the payment.',
      methods: preview.data.available_methods || [],
    });
  } catch (error) {
    console.error('Create payment error:', error);
    res.status(500).json({ error: error.message });
  }
}

// ClickPesa Webhook handler
async function handleClickPesaWebhook(req, res) {
  try {
    const body = await parseBody(req);
    console.log('Webhook received:', body);

    const { order_reference, status, transaction_id } = body;

    if (status === 'completed') {
      // Find transaction and update
      const snapshot = await db
        .collection('transactions')
        .where('orderReference', '==', order_reference)
        .limit(1)
        .get();

      if (!snapshot.empty) {
        const transactionDoc = snapshot.docs[0];
        const transaction = transactionDoc.data();

        // Update transaction status
        await transactionDoc.ref.update({
          status: 'completed',
          transactionId: transaction_id,
          completedAt: new Date(),
        });

        // Add credits to user
        const userRef = db.collection('users').doc(transaction.userId);
        await userRef.update({
          credits: admin.firestore.FieldValue.increment(transaction.credits),
        });

        console.log(`Credits added: ${transaction.credits} to user ${transaction.userId}`);
      }
    }

    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: error.message });
  }
}

// Auth handler
async function handleAuth(req, res) {
  res.status(404).json({ error: 'Auth endpoint not available in serverless' });
}

// Checksum generation
function generateChecksum(data) {
  const canonicalized = JSON.stringify(canonicalize(data));
  const hmac = crypto.createHmac('sha256', process.env.CLICKPESA_CHECKSUM_SECRET);
  hmac.update(canonicalized);
  return hmac.digest('hex');
}

function canonicalize(obj) {
  if (Array.isArray(obj)) {
    return obj.map(item => canonicalize(item));
  } else if (obj !== null && typeof obj === 'object') {
    return Object.keys(obj)
      .sort()
      .reduce((result, key) => {
        result[key] = canonicalize(obj[key]);
        return result;
      }, {});
  }
  return obj;
}
