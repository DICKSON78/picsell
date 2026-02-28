#!/usr/bin/env node

/**
 * Debug checksum generation for ClickPesa API
 * Tests various checksum algorithms to find the correct one
 */

require("dotenv").config();
const axios = require("axios");
const crypto = require("crypto");

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;

// Test payload
const payload = {
  amount: "1000",
  currency: "TZS",
  orderReference: `DEBUG_${Date.now()}`,
  phoneNumber: "255678960706",
};

console.log("🔍 Debugging Checksum Generation\n");
console.log("📋 Payload:");
console.log(JSON.stringify(payload, null, 2));
console.log("\nClient ID:", clientId.substring(0, 10) + "...");
console.log("API Key:", apiKey.substring(0, 10) + "...");

// Different checksum generation methods
const methods = {
  "Method 1: Canonical JSON + HMAC(clientId)": () => {
    const canonical = JSON.stringify(payload);
    return crypto
      .createHmac("sha256", clientId)
      .update(canonical)
      .digest("hex");
  },

  "Method 2: Canonical JSON + HMAC(apiKey)": () => {
    const canonical = JSON.stringify(payload);
    return crypto.createHmac("sha256", apiKey).update(canonical).digest("hex");
  },

  "Method 3: Sorted fields + HMAC(clientId)": () => {
    const fields = Object.keys(payload)
      .sort()
      .map((k) => `${k}${payload[k]}`)
      .join("");
    return crypto.createHmac("sha256", clientId).update(fields).digest("hex");
  },

  "Method 4: Sorted fields + HMAC(apiKey)": () => {
    const fields = Object.keys(payload)
      .sort()
      .map((k) => `${k}${payload[k]}`)
      .join("");
    return crypto.createHmac("sha256", apiKey).update(fields).digest("hex");
  },

  "Method 5: Field=value pairs + HMAC(clientId)": () => {
    const fields = Object.keys(payload)
      .sort()
      .map((k) => `${k}=${payload[k]}`)
      .join("&");
    return crypto.createHmac("sha256", clientId).update(fields).digest("hex");
  },

  "Method 6: Field=value pairs + HMAC(apiKey)": () => {
    const fields = Object.keys(payload)
      .sort()
      .map((k) => `${k}=${payload[k]}`)
      .join("&");
    return crypto.createHmac("sha256", apiKey).update(fields).digest("hex");
  },

  "Method 7: Sorted + pipe separator + HMAC(clientId)": () => {
    const fields = Object.keys(payload)
      .sort()
      .map((k) => payload[k])
      .join("|");
    return crypto.createHmac("sha256", clientId).update(fields).digest("hex");
  },

  "Method 8: Sorted + pipe separator + HMAC(apiKey)": () => {
    const fields = Object.keys(payload)
      .sort()
      .map((k) => payload[k])
      .join("|");
    return crypto.createHmac("sha256", apiKey).update(fields).digest("hex");
  },

  "Method 9: JSON + SHA256(clientId) hash + HMAC": () => {
    const canonical = JSON.stringify(payload);
    const key = crypto.createHash("sha256").update(clientId).digest("hex");
    return crypto.createHmac("sha256", key).update(canonical).digest("hex");
  },

  "Method 10: Amount+Currency+OrderRef+Phone + HMAC(apiKey)": () => {
    const str = `${payload.amount}${payload.currency}${payload.orderReference}${payload.phoneNumber}`;
    return crypto.createHmac("sha256", apiKey).update(str).digest("hex");
  },
};

console.log("\n🧪 Testing Different Checksum Methods:\n");
Object.entries(methods).forEach(([name, fn]) => {
  try {
    const checksum = fn();
    console.log(`${name}:`);
    console.log(`  ${checksum}\n`);
  } catch (error) {
    console.log(`${name}: ERROR - ${error.message}\n`);
  }
});

// Test each method with actual API
async function testWithAPI() {
  console.log("\n🔄 Testing Each Method With ClickPesa API...\n");

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

    for (const [name, fn] of Object.entries(methods)) {
      try {
        const checksum = fn();
        const testPayload = {
          ...payload,
          orderReference: `${payload.orderReference}_${name.substring(0, 10)}`,
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
            timeout: 5000,
          },
        );

        console.log(`✅ ${name}: SUCCESS!`);
        console.log(
          `   Response: ${JSON.stringify(response.data).substring(0, 100)}...\n`,
        );
        return; // Found the correct method
      } catch (error) {
        if (
          error.response?.status === 400 &&
          error.response?.data?.message?.includes("Invalid checksum")
        ) {
          console.log(`❌ ${name}: Invalid checksum`);
        } else {
          console.log(`⚠️  ${name}: ${error.message?.substring(0, 50)}`);
        }
      }
    }
  } catch (error) {
    console.error("Failed to get token:", error.message);
  }
}

testWithAPI();
