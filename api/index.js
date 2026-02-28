// Vercel Serverless Function - Main API Handler
require("dotenv").config();

const admin = require("firebase-admin");
const jwt = require("jsonwebtoken");
const axios = require("axios");
const crypto = require("crypto");

// Initialize Firebase Admin with error handling
let db = null;
let firebaseInitialized = false;

if (!admin.apps.length) {
  try {
    // Check if all required Firebase env vars are present
    const requiredVars = [
      "FIREBASE_PROJECT_ID",
      "FIREBASE_PRIVATE_KEY_ID",
      "FIREBASE_PRIVATE_KEY",
      "FIREBASE_CLIENT_EMAIL",
      "FIREBASE_CLIENT_ID",
    ];
    
    const missingVars = requiredVars.filter((v) => !process.env[v]);
    if (missingVars.length > 0) {
      console.warn("Missing Firebase env vars:", missingVars);
    }

    const serviceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      privateKeyId: process.env.FIREBASE_PRIVATE_KEY_ID,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      clientId: process.env.FIREBASE_CLIENT_ID,
      authUri: process.env.FIREBASE_AUTH_URI || "https://accounts.google.com/o/oauth2/auth",
      tokenUri: process.env.FIREBASE_TOKEN_URI || "https://oauth2.googleapis.com/token",
      authProviderX509CertUrl: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL,
      clientX509CertUrl: process.env.FIREBASE_CLIENT_X509_CERT_URL,
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    db = admin.firestore();
    firebaseInitialized = true;
    console.log("✅ Firebase Admin SDK initialized successfully");
  } catch (err) {
    console.error("❌ Firebase initialization error:", err.message);
  }
}

// Verify Firebase ID token
async function verifyToken(req) {
  try {
    const token = req.headers.authorization?.replace("Bearer ", "");
    if (!token) {
      console.warn("⚠️ No token in headers");
      return null;
    }

    console.log("🔍 Verifying token...");

    // Try to verify as Firebase ID token first
    if (firebaseInitialized && admin && admin.auth) {
      try {
        console.log("📝 Attempting Firebase token verification...");
        const decodedToken = await admin.auth().verifyIdToken(token);
        console.log(`✅ Token verified for user: ${decodedToken.uid}`);
        return { userId: decodedToken.uid, uid: decodedToken.uid };
      } catch (err) {
        console.error("❌ Firebase token verification failed:", err.message);
        // Fall through to try JWT verification
      }
    }

    // Fallback: try regular JWT verification if Firebase fails
    if (!firebaseInitialized) {
      console.log("⚠️ Firebase not initialized, trying JWT verification...");
    } else {
      console.log("⚠️ Firebase verification failed, trying JWT verification...");
    }

    try {
      if (!process.env.JWT_SECRET) {
        console.error("❌ JWT_SECRET not configured");
        return null;
      }
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      console.log("✅ JWT verified successfully");
      return decoded;
    } catch (jwtErr) {
      console.error("❌ JWT verification also failed:", jwtErr.message);
      return null;
    }
  } catch (err) {
    console.error("Token verification error:", err);
    return null;
  }
}

// Main handler
module.exports = async (req, res) => {
  // CORS headers
  res.setHeader("Access-Control-Allow-Credentials", "true");
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,OPTIONS,PATCH,DELETE,POST,PUT");
  res.setHeader(
    "Access-Control-Allow-Headers",
    "X-CSRF-Token,X-Requested-With,Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Api-Version,Authorization"
  );

  if (req.method === "OPTIONS") {
    res.status(200).end();
    return;
  }

  try {
    console.log(`${req.method} ${req.url}`);

    // Route to appropriate handler
    if (req.url.startsWith("/api/credits/")) {
      return handleCredits(req, res);
    }

    if (req.url === "/api/health") {
      return res.status(200).json({
        status: "ok",
        message: "DukaSell API is running",
        timestamp: new Date().toISOString(),
      });
    }

    // Webhook routes (no auth)
    if (req.method === "POST" && req.url === "/api/webhook/clickpesa") {
      return handleClickPesaWebhook(req, res);
    }

    res.status(404).json({ error: "Endpoint not found" });
  } catch (error) {
    console.error("API Error:", error);
    res.status(500).json({
      error: error.message || "Internal server error",
    });
  }
};

// Credits handler
async function handleCredits(req, res) {
  // Check auth for all endpoints
  const decoded = await verifyToken(req);
  console.log("🔐 Auth result:", decoded ? `✅ User: ${decoded.userId || decoded.uid}` : "❌ No auth");
  if (!decoded) {
    console.error("❌ Authentication failed - returning 401");
    return res.status(401).json({ error: "Authentication required" });
  }

  const url = req.url.split("?")[0];

  // GET /api/credits/balance
  if (req.method === "GET" && url === "/api/credits/balance") {
    try {
      if (!db) {
        return res.status(500).json({ error: "Database not initialized" });
      }
      const userDoc = await db.collection("users").doc(decoded.userId).get();
      const user = userDoc.data();
      return res.status(200).json({
        credits: user?.credits || 0,
        email: user?.email,
      });
    } catch (error) {
      console.error("Balance error:", error);
      return res.status(500).json({ error: error.message });
    }
  }

  // POST /api/credits/create-payment
  if (req.method === "POST" && url === "/api/credits/create-payment") {
    return handleCreatePayment(req, res, decoded);
  }

  res.status(404).json({ error: "Endpoint not found" });
}

// Create payment handler
async function handleCreatePayment(req, res, decoded) {
  try {
    const { packageId, phoneNumber, paymentMethod } = req.body || {};

    if (!packageId || !phoneNumber) {
      return res.status(400).json({
        error: "Missing required fields: packageId, phoneNumber",
      });
    }

    const packages = {
      pack_10: { credits: 10, price: 1000 },
      pack_25: { credits: 25, price: 2500 },
      pack_50: { credits: 50, price: 5000 },
      pack_100: { credits: 100, price: 10000 },
    };

    const selectedPackage = packages[packageId];
    if (!selectedPackage) {
      return res.status(400).json({ error: "Invalid package" });
    }

    // Format phone number
    let formattedPhone = phoneNumber;
    if (phoneNumber.startsWith("0")) {
      formattedPhone = "255" + phoneNumber.substring(1);
    }

    // Generate order reference
    const orderReference = `CRED${Date.now()}${decoded.userId.slice(-6)}`;

    // Check required env vars
    if (!process.env.CLICKPESA_CLIENT_ID || !process.env.CLICKPESA_API_KEY) {
      console.error("ClickPesa credentials missing");
      return res.status(500).json({
        error: "ClickPesa credentials not configured",
      });
    }

    // Get ClickPesa token
    let token;
    try {
      const tokenResponse = await axios.post(
        "https://api.clickpesa.com/auth/token",
        {
          client_id: process.env.CLICKPESA_CLIENT_ID,
          client_secret: process.env.CLICKPESA_API_KEY,
        },
        { timeout: 10000 }
      );
      token = tokenResponse.data.access_token;
    } catch (error) {
      console.error("Token error:", error.response?.data || error.message);
      return res.status(500).json({
        error: "Failed to get ClickPesa token",
        details: error.response?.data?.message,
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
        "https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request",
        previewData,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
          timeout: 10000,
        }
      );
    } catch (error) {
      console.error("Preview error:", error.response?.data || error.message);
      return res.status(400).json({
        error: "Failed to preview payment",
        details: error.response?.data?.message,
      });
    }

    // Save transaction to Firestore (if available)
    if (db) {
      try {
        await db.collection("transactions").add({
          userId: decoded.userId,
          packageId,
          credits: selectedPackage.credits,
          amount: selectedPackage.price,
          phoneNumber: formattedPhone,
          orderReference,
          paymentMethod,
          status: "initiated",
          createdAt: new Date(),
        });
      } catch (error) {
        console.error("Firestore error:", error);
        // Continue even if Firestore fails
      }
    }

    // Return success
    return res.status(200).json({
      success: true,
      paymentInitiated: true,
      orderReference,
      message: "USSD push sent to your phone. Please complete the payment.",
      methods: preview.data.available_methods || [],
    });
  } catch (error) {
    console.error("Create payment error:", error);
    return res.status(500).json({ error: error.message });
  }
}

// ClickPesa Webhook handler
async function handleClickPesaWebhook(req, res) {
  try {
    const { order_reference, status, transaction_id } = req.body || {};
    console.log("Webhook received:", { order_reference, status, transaction_id });

    if (status === "completed" && db) {
      try {
        // Find transaction and update
        const snapshot = await db
          .collection("transactions")
          .where("orderReference", "==", order_reference)
          .limit(1)
          .get();

        if (!snapshot.empty) {
          const transactionDoc = snapshot.docs[0];
          const transaction = transactionDoc.data();

          // Update transaction status
          await transactionDoc.ref.update({
            status: "completed",
            transactionId: transaction_id,
            completedAt: new Date(),
          });

          // Add credits to user
          const userRef = db.collection("users").doc(transaction.userId);
          await userRef.update({
            credits: admin.firestore.FieldValue.increment(transaction.credits),
          });

          console.log(`Credits added: ${transaction.credits} to user ${transaction.userId}`);
        }
      } catch (error) {
        console.error("Firestore webhook error:", error);
      }
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("Webhook error:", error);
    return res.status(500).json({ error: error.message });
  }
}

// Auth handler
async function handleAuth(req, res) {
  res.status(404).json({ error: "Auth endpoint not available in serverless" });
}

// Checksum generation
function generateChecksum(data) {
  const canonicalized = JSON.stringify(canonicalize(data));
  const hmac = crypto.createHmac(
    "sha256",
    process.env.CLICKPESA_CHECKSUM_SECRET,
  );
  hmac.update(canonicalized);
  return hmac.digest("hex");
}

function canonicalize(obj) {
  if (Array.isArray(obj)) {
    return obj.map((item) => canonicalize(item));
  } else if (obj !== null && typeof obj === "object") {
    return Object.keys(obj)
      .sort()
      .reduce((result, key) => {
        result[key] = canonicalize(obj[key]);
        return result;
      }, {});
  }
  return obj;
}
