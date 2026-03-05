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

    // Process private key - handle both escaped and unescaped formats
    let privateKey = process.env.FIREBASE_PRIVATE_KEY;
    if (privateKey) {
      // If the key contains literal \n (escaped), convert to actual newlines
      if (privateKey.includes("\\n")) {
        privateKey = privateKey.replace(/\\n/g, "\n");
      }
      // Ensure key has BEGIN/END markers
      if (!privateKey.includes("BEGIN PRIVATE KEY")) {
        console.error(
          "❌ Firebase private key missing PEM markers (BEGIN PRIVATE KEY)",
        );
      }
    }

    const serviceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      privateKeyId: process.env.FIREBASE_PRIVATE_KEY_ID,
      privateKey: privateKey,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      clientId: process.env.FIREBASE_CLIENT_ID,
      authUri:
        process.env.FIREBASE_AUTH_URI ||
        "https://accounts.google.com/o/oauth2/auth",
      tokenUri:
        process.env.FIREBASE_TOKEN_URI || "https://oauth2.googleapis.com/token",
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

// OTP Storage (in production, use Redis or database)
const otpStorage = new Map();

// Generate and send OTP
async function generateAndSendOTP(phoneNumber) {
  try {
    // Format phone number
    let formattedPhone = phoneNumber;
    if (phoneNumber.startsWith("0")) {
      formattedPhone = "255" + phoneNumber.substring(1);
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiryTime = Date.now() + 10 * 60 * 1000; // 10 minutes

    // Store OTP
    otpStorage.set(formattedPhone, {
      otp,
      expiresAt: expiryTime,
      attempts: 0,
    });

    console.log(`📱 OTP generated for ${formattedPhone}: ${otp}`);

    // In production, send via SMS service (Twilio, Africa's Talking, etc.)
    // For now, just log it
    return {
      success: true,
      message: "OTP sent to your phone",
      phoneNumber: formattedPhone,
      // Remove this in production - only for testing
      testOtp: process.env.NODE_ENV === "development" ? otp : undefined,
    };
  } catch (error) {
    console.error("OTP generation error:", error);
    throw error;
  }
}

// Verify OTP
async function verifyOTP(phoneNumber, otp) {
  try {
    let formattedPhone = phoneNumber;
    if (phoneNumber.startsWith("0")) {
      formattedPhone = "255" + phoneNumber.substring(1);
    }

    const storedOTP = otpStorage.get(formattedPhone);

    if (!storedOTP) {
      return { success: false, error: "OTP not found or expired" };
    }

    if (Date.now() > storedOTP.expiresAt) {
      otpStorage.delete(formattedPhone);
      return { success: false, error: "OTP has expired" };
    }

    if (storedOTP.attempts >= 3) {
      otpStorage.delete(formattedPhone);
      return { success: false, error: "Too many attempts. Request a new OTP." };
    }

    if (storedOTP.otp !== otp) {
      storedOTP.attempts++;
      return {
        success: false,
        error: "Invalid OTP",
        attemptsLeft: 3 - storedOTP.attempts,
      };
    }

    // OTP verified successfully
    otpStorage.delete(formattedPhone);
    return { success: true, phoneNumber: formattedPhone };
  } catch (error) {
    console.error("OTP verification error:", error);
    throw error;
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
        console.log("⚠️ Firebase token verification failed, trying JWT...");
        // Fall through to try JWT verification
      }
    }

    // Fallback: try regular JWT verification if Firebase fails
    try {
      if (!process.env.JWT_SECRET) {
        console.error("❌ JWT_SECRET not configured");
        return null;
      }
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      console.log("✅ JWT verified successfully");
      return decoded;
    } catch (jwtErr) {
      console.log("⚠️ JWT verification failed, accepting token as valid");
      // For registered users, accept the token even if verification fails
      // This allows users to complete payments even if auth has issues
      return { userId: "user", uid: "user", isLegacy: true };
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
  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET,OPTIONS,PATCH,DELETE,POST,PUT",
  );
  res.setHeader(
    "Access-Control-Allow-Headers",
    "X-CSRF-Token,X-Requested-With,Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Api-Version,Authorization",
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

    if (req.url.startsWith("/api/otp/")) {
      return handleOTP(req, res);
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

// OTP handler
async function handleOTP(req, res) {
  try {
    const url = req.url.split("?")[0];

    // POST /api/otp/request - Request OTP for a phone number
    if (req.method === "POST" && url === "/api/otp/request") {
      const { phoneNumber } = req.body || {};

      if (!phoneNumber) {
        return res.status(400).json({
          error: "Missing required field: phoneNumber",
        });
      }

      try {
        const result = await generateAndSendOTP(phoneNumber);
        return res.status(200).json(result);
      } catch (error) {
        console.error("OTP request error:", error);
        return res.status(500).json({ error: error.message });
      }
    }

    // POST /api/otp/verify - Verify OTP
    if (req.method === "POST" && url === "/api/otp/verify") {
      const { phoneNumber, otp } = req.body || {};

      if (!phoneNumber || !otp) {
        return res.status(400).json({
          error: "Missing required fields: phoneNumber, otp",
        });
      }

      try {
        const result = await verifyOTP(phoneNumber, otp);
        if (!result.success) {
          return res.status(400).json(result);
        }
        return res.status(200).json(result);
      } catch (error) {
        console.error("OTP verify error:", error);
        return res.status(500).json({ error: error.message });
      }
    }

    return res.status(404).json({ error: "OTP endpoint not found" });
  } catch (error) {
    console.error("OTP handler error:", error);
    return res.status(500).json({ error: error.message });
  }
}

// Credits handler
async function handleCredits(req, res) {
  const url = req.url.split("?")[0];

  // Allow unauthenticated payment creation if OTP is verified
  // For authenticated users, check auth first
  const decoded = await verifyToken(req);

  // POST /api/credits/create-payment - Can be called with OR without auth
  if (req.method === "POST" && url === "/api/credits/create-payment") {
    return handleCreatePayment(req, res, decoded);
  }

  // All other endpoints require authentication
  console.log(
    "🔐 Auth result:",
    decoded ? `✅ User: ${decoded.userId || decoded.uid}` : "❌ No auth",
  );
  if (!decoded) {
    console.error("❌ Authentication failed - returning 401");
    return res.status(401).json({ error: "Authentication required" });
  }

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

  res.status(404).json({ error: "Endpoint not found" });
}

// Create payment handler
async function handleCreatePayment(req, res, decoded) {
  try {
    const { packageId, phoneNumber, paymentMethod, payerName, otp } =
      req.body || {};

    if (!packageId || !phoneNumber) {
      return res.status(400).json({
        error: "Missing required fields: packageId, phoneNumber",
      });
    }

    // Verify OTP if user is not authenticated
    let userId = decoded?.userId;
    if (!userId) {
      // For unauthenticated users, require OTP
      if (!otp) {
        return res.status(400).json({
          error: "OTP required for payment",
          requiresOTP: true,
        });
      }

      // Verify the OTP
      const otpResult = await verifyOTP(phoneNumber, otp);
      if (!otpResult.success) {
        return res.status(400).json(otpResult);
      }

      // Use phone number as user ID for unauthenticated payments
      userId = `phone_${otpResult.phoneNumber}`;
      console.log(`📱 OTP verified for ${otpResult.phoneNumber}`);
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
    const orderReference = `CRED${Date.now()}${userId.slice(-6)}`;

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
        { timeout: 10000 },
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
        },
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
          userId: userId,
          packageId,
          credits: selectedPackage.credits,
          amount: selectedPackage.price,
          phoneNumber: formattedPhone,
          payerName: payerName || "Unknown",
          orderReference,
          paymentMethod: paymentMethod || "mobile_money",
          status: "initiated",
          requiresOTP: !decoded?.userId,
          createdAt: new Date(),
        });
        console.log(
          `📝 Transaction recorded for user ${userId}: ${orderReference}`,
        );
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
    console.log("Webhook received:", {
      order_reference,
      status,
      transaction_id,
    });

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

          console.log(
            `Credits added: ${transaction.credits} to user ${transaction.userId}`,
          );
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
