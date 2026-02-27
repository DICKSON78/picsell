// Vercel Serverless Function for ClickPesa Webhook
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      privateKeyId: process.env.FIREBASE_PRIVATE_KEY_ID,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      clientId: process.env.FIREBASE_CLIENT_ID,
      authUri: process.env.FIREBASE_AUTH_URI,
      tokenUri: process.env.FIREBASE_TOKEN_URI,
    }),
  });
}

const db = admin.firestore();

module.exports = async (req, res) => {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { 
      eventType,           // ClickPesa event type
      orderReference, 
      status, 
      amount, 
      paymentMethod,
      customer,
      payout,
      timestamp 
    } = req.body;

    console.log('ClickPesa Webhook Received:', { eventType, orderReference, status, amount, paymentMethod, customer, payout, timestamp });

    // Handle different ClickPesa events
    switch (eventType) {
      case 'PAYMENT RECEIVED':
        await handlePaymentReceived(req.body);
        break;
        
      case 'PAYMENT FAILED':
        await handlePaymentFailed(req.body);
        break;
        
      case 'PAYOUT INITIATED':
        await handlePayoutInitiated(req.body);
        break;
        
      case 'PAYOUT REFUNDED':
        await handlePayoutRefunded(req.body);
        break;
        
      case 'PAYOUT REVERSED':
        await handlePayoutReversed(req.body);
        break;
        
      default:
        console.log('Unknown event type:', eventType);
        break;
    }

    // Send response to ClickPesa
    res.status(200).json({ 
      success: true, 
      message: 'Webhook received successfully' 
    });
  } catch (error) {
    console.error('Webhook Error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Webhook processing failed' 
    });
  }
};

// Handle payment received event
async function handlePaymentReceived(data) {
  const { orderReference, status, amount, paymentMethod, customer, timestamp } = data;
  
  // Find pending transaction
  const transactionRef = db.collection('transactions').where('orderReference', '==', orderReference).where('status', '==', 'pending');
  const transactionSnapshot = await transactionRef.get();
  
  if (!transactionSnapshot.empty) {
    const transactionDoc = transactionSnapshot.docs[0];
    const transaction = transactionDoc.data();
    
    // Update transaction status
    await transactionDoc.ref.update({
      status: 'completed',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      finalAmount: amount,
      webhookData: { status, customer, timestamp }
    });

    // Add credits to user
    const userRef = db.collection('users').doc(transaction.userId);
    const userDoc = await userRef.get();
    
    if (userDoc.exists) {
      await userRef.update({
        credits: admin.firestore.FieldValue.increment(transaction.credits),
        totalSpent: admin.firestore.FieldValue.increment(amount / 100)
      });
    }

    console.log('Payment received successfully:', orderReference);
  }
}

// Handle payment failed event
async function handlePaymentFailed(data) {
  const { orderReference, status, amount, paymentMethod, customer, timestamp } = data;
  
  // Update transaction status to failed
  const transactionRef = db.collection('transactions').where('orderReference', '==', orderReference).where('status', '==', 'pending');
  const transactionSnapshot = await transactionRef.get();
  
  if (!transactionSnapshot.empty) {
    const transactionDoc = transactionSnapshot.docs[0];
    
    await transactionDoc.ref.update({
      status: 'failed',
      error: 'Payment failed',
      webhookData: { status, customer, timestamp }
    });
  }
  
  console.log('Payment failed:', orderReference);
}

// Handle payout initiated event
async function handlePayoutInitiated(data) {
  const { orderReference, status, payout, timestamp } = data;
  
  // Find payout transaction
  const transactionRef = db.collection('transactions').where('orderReference', '==', orderReference).where('type', '==', 'payout').where('status', '==', 'pending');
  const transactionSnapshot = await transactionRef.get();
  
  if (!transactionSnapshot.empty) {
    const transactionDoc = transactionSnapshot.docs[0];
    
    await transactionDoc.ref.update({
      status: 'processing',
      payoutData: payout,
      webhookData: { status, payout, timestamp }
    });
  }

  console.log('Payout initiated:', orderReference);
}

// Handle payout refunded event
async function handlePayoutRefunded(data) {
  const { orderReference, status, payout, timestamp } = data;
  
  // Find payout transaction
  const transactionRef = db.collection('transactions').where('orderReference', '==', orderReference).where('type', '==', 'payout').where('status', '==', 'processing');
  const transactionSnapshot = await transactionRef.get();
  
  if (!transactionSnapshot.empty) {
    const transactionDoc = transactionSnapshot.docs[0];
    const transaction = transactionDoc.data();
    
    await transactionDoc.ref.update({
      status: 'refunded',
      payoutData: payout,
      webhookData: { status, payout, timestamp }
    });

    // Add credits back to user (refund)
    const userRef = db.collection('users').doc(transaction.userId);
    const userDoc = await userRef.get();
    
    if (userDoc.exists) {
      await userRef.update({
        credits: admin.firestore.FieldValue.increment(transaction.credits)
      });
    }
  }

  console.log('Payout refunded:', orderReference);
}

// Handle payout reversed event
async function handlePayoutReversed(data) {
  const { orderReference, status, payout, timestamp } = data;
  
  // Find payout transaction
  const transactionRef = db.collection('transactions').where('orderReference', '==', orderReference).where('type', '==', 'payout').where('status', '==', 'processing');
  const transactionSnapshot = await transactionRef.get();
  
  if (!transactionSnapshot.empty) {
    const transactionDoc = transactionSnapshot.docs[0];
    const transaction = transactionDoc.data();
    
    await transactionDoc.ref.update({
      status: 'reversed',
      payoutData: payout,
      webhookData: { status, payout, timestamp }
    });

    // Add credits back to user (reverse)
    const userRef = db.collection('users').doc(transaction.userId);
    const userDoc = await userRef.get();
    
    if (userDoc.exists) {
      await userRef.update({
        credits: admin.firestore.FieldValue.increment(transaction.credits)
      });
    }
  }

  console.log('Payout reversed:', orderReference);
}
