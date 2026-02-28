#!/usr/bin/env node

/**
 * Brute force checksum testing - try ALL possible combinations
 */

require("dotenv").config();
const axios = require("axios");
const crypto = require("crypto");

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;

// Test data
const payload = {
  amount: "1000",
  currency: "TZS",
  orderReference: `BRUTE_${Date.now()}`,
  phoneNumber: "255678960706",
};

async function bruteForceChecksum() {
  console.log("🔨 Brute Force Checksum Testing\n");
  console.log("Trying different combinations...\n");

  try {
    const tokenResponse = await axios.post(
      "https://api.clickpesa.com/third-parties/generate-token",
      {},
      {
        headers: {
          "api-key": apiKey,
          "client-id": clientId,
          "Content-Type": "application/json",
        },
      },
    );

    const token = tokenResponse.data.token;

    // Different combinations to test
    const combinations = [
      // Format: [name, key, input_format]

      // Base64 approaches
      [
        "Base64(clientId)",
        clientId,
        (p, k) => {
          const b64 = Buffer.from(k).toString("base64");
          return crypto
            .createHmac("sha256", b64)
            .update(JSON.stringify(p))
            .digest("hex");
        },
      ],

      [
        "Base64(apiKey)",
        apiKey,
        (p, k) => {
          const b64 = Buffer.from(k).toString("base64");
          return crypto
            .createHmac("sha256", b64)
            .update(JSON.stringify(p))
            .digest("hex");
        },
      ],

      // With timestamps
      [
        "SHA256(clientId + timestamp)",
        clientId,
        (p, k) => {
          const ts = Math.floor(Date.now() / 1000);
          return crypto
            .createHmac("sha256", k)
            .update(JSON.stringify(p) + ts)
            .digest("hex");
        },
      ],

      // Different hash algorithms
      [
        "MD5 instead of SHA256",
        clientId,
        (p, k) => {
          return crypto
            .createHmac("md5", k)
            .update(JSON.stringify(p))
            .digest("hex");
        },
      ],

      [
        "SHA1 instead of SHA256",
        clientId,
        (p, k) => {
          return crypto
            .createHmac("sha1", k)
            .update(JSON.stringify(p))
            .digest("hex");
        },
      ],

      // Using just some fields
      [
        "Only amount+currency",
        clientId,
        (p, k) => {
          return crypto
            .createHmac("sha256", k)
            .update(p.amount + p.currency)
            .digest("hex");
        },
      ],

      [
        "All fields concatenated",
        clientId,
        (p, k) => {
          return crypto
            .createHmac("sha256", k)
            .update(p.amount + p.currency + p.orderReference + p.phoneNumber)
            .digest("hex");
        },
      ],

      // With different orders
      [
        "Reverse order fields",
        clientId,
        (p, k) => {
          const str = p.phoneNumber + p.orderReference + p.currency + p.amount;
          return crypto.createHmac("sha256", k).update(str).digest("hex");
        },
      ],

      // Try combination of both credentials
      [
        "HMAC(clientId + apiKey as key)",
        clientId + apiKey,
        (p, k) => {
          return crypto
            .createHmac("sha256", k)
            .update(JSON.stringify(p))
            .digest("hex");
        },
      ],

      // Different JSON formats
      [
        "Stringified without spaces",
        clientId,
        (p, k) => {
          return crypto
            .createHmac("sha256", k)
            .update(JSON.stringify(p, null, 0))
            .digest("hex");
        },
      ],

      [
        "Object with specific field order",
        clientId,
        (p, k) => {
          const ordered = {
            amount: p.amount,
            currency: p.currency,
            phoneNumber: p.phoneNumber,
            orderReference: p.orderReference,
          };
          return crypto
            .createHmac("sha256", k)
            .update(JSON.stringify(ordered))
            .digest("hex");
        },
      ],

      // Maybe it's a public key thing
      [
        "clientId.substring(0, 16)",
        clientId.substring(0, 16),
        (p, k) => {
          return crypto
            .createHmac("sha256", k)
            .update(JSON.stringify(p))
            .digest("hex");
        },
      ],

      [
        "SHA256 of payload itself",
        clientId,
        (p, k) => {
          const payloadHash = crypto
            .createHash("sha256")
            .update(JSON.stringify(p))
            .digest("hex");
          return crypto
            .createHmac("sha256", k)
            .update(payloadHash)
            .digest("hex");
        },
      ],
    ];

    let successCount = 0;

    for (const [name, key, fn] of combinations) {
      try {
        const checksum = fn(payload, key);

        const testPayload = {
          ...payload,
          orderReference: `${payload.orderReference}_${++successCount}`,
          checksum,
        };

        const response = await axios.post(
          "https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request",
          testPayload,
          {
            headers: {
              Authorization: token,
              "Content-Type": "application/json",
            },
            timeout: 3000,
          },
        );

        console.log(`✅ SUCCESS: ${name}`);
        console.log(`   Checksum: ${checksum.substring(0, 16)}...`);
        console.log(
          `   Response: ${JSON.stringify(response.data).substring(0, 80)}...`,
        );
        console.log("\n🎉 FOUND IT!");
        return name;
      } catch (error) {
        // Ignore - try next method
      }
    }

    console.log("❌ None of the combinations worked.");
    console.log("\n⚠️  The checksum algorithm might be:");
    console.log("  1. A completely custom algorithm");
    console.log("  2. Using a secret key not provided in credentials");
    console.log("  3. Based on account-specific settings");
    console.log("  4. Only available in ClickPesa merchant dashboard");
  } catch (error) {
    console.error("Token error:", error.message);
  }
}

bruteForceChecksum();
