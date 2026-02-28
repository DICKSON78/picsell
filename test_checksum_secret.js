#!/usr/bin/env node

/**
 * Test checksum with the provided secret key variations
 */

require("dotenv").config();
const axios = require("axios");
const crypto = require("crypto");

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;
const checksumSecret = process.env.CLICKPESA_CHECKSUM_SECRET;

async function testChecksumVariations() {
  console.log("🔍 Testing Checksum with Different Variations\n");
  console.log("Secret provided:", checksumSecret);
  console.log("");

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
    console.log("✅ Token obtained\n");

    const payload = {
      amount: "1000",
      currency: "TZS",
      orderReference: `VARIATION_${Date.now()}`,
      phoneNumber: "255678960706",
    };

    // Different checksum variations
    const variations = [
      {
        name: "As-is (current)",
        key: checksumSecret,
      },
      {
        name: "SHA256(secret) as key",
        key: crypto.createHash("sha256").update(checksumSecret).digest("hex"),
      },
      {
        name: "MD5(secret) as key",
        key: crypto.createHash("md5").update(checksumSecret).digest("hex"),
      },
      {
        name: "Lowercase",
        key: checksumSecret.toLowerCase(),
      },
      {
        name: 'Remove "CHK" prefix',
        key: checksumSecret.replace(/^CHK/, ""),
      },
      {
        name: "Just use payload as string",
        key: checksumSecret,
        customChecksum: () =>
          crypto
            .createHash("sha256")
            .update(JSON.stringify(payload))
            .digest("hex"),
      },
      {
        name: "No canonicalization, just sorted keys",
        key: checksumSecret,
        customChecksum: () => {
          const sorted = {};
          Object.keys(payload)
            .sort()
            .forEach((k) => (sorted[k] = payload[k]));
          return crypto
            .createHmac("sha256", checksumSecret)
            .update(JSON.stringify(sorted))
            .digest("hex");
        },
      },
    ];

    for (const variation of variations) {
      console.log(`🧪 Testing: ${variation.name}`);

      try {
        let checksum;
        if (variation.customChecksum) {
          checksum = variation.customChecksum();
        } else {
          const canonical = JSON.stringify(payload);
          checksum = crypto
            .createHmac("sha256", variation.key)
            .update(canonical)
            .digest("hex");
        }

        const testPayload = {
          ...payload,
          orderReference: `${payload.orderReference}_${variation.name.substring(0, 5)}`,
          checksum,
        };

        console.log(`   Checksum: ${checksum.substring(0, 16)}...`);

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

        console.log(`   ✅ SUCCESS! This variation works!`);
        console.log(
          `   Response:`,
          JSON.stringify(response.data).substring(0, 100) + "...\n",
        );
        console.log("\n🎉 FOUND THE CORRECT FORMAT!");
        console.log(`Use: ${variation.name}`);
        return;
      } catch (error) {
        if (error.response?.status === 400) {
          console.log(`   ❌ Invalid checksum\n`);
        } else {
          console.log(`   ⚠️  ${error.message?.substring(0, 50)}\n`);
        }
      }
    }

    console.log("\n❌ None of the variations worked.");
    console.log("\n💡 Next steps:");
    console.log("1. Check ClickPesa docs if secret needs specific formatting");
    console.log(
      "2. Verify the secret is correct (copy-paste from dashboard again)",
    );
    console.log(
      "3. Contact ClickPesa support to confirm checksum secret format",
    );
  } catch (error) {
    console.error("Error:", error.message);
  }
}

testChecksumVariations();
