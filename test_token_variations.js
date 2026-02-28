#!/usr/bin/env node

/**
 * Test with correct header format and other variations
 */

require("dotenv").config();
const axios = require("axios");
const crypto = require("crypto");

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;

async function testWithCorrectHeaders() {
  console.log("🔄 Testing with different token generation headers\n");

  const headerVariations = [
    {
      name: "Current (lowercase api-key, client-id)",
      headers: {
        "api-key": apiKey,
        "client-id": clientId,
        "Content-Type": "application/json",
      },
    },
    {
      name: "Uppercase (X-API-Key, X-Client-Id)",
      headers: {
        "X-API-Key": apiKey,
        "X-Client-Id": clientId,
        "Content-Type": "application/json",
      },
    },
    {
      name: "Authorization header with API Key",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "X-Client-Id": clientId,
        "Content-Type": "application/json",
      },
    },
  ];

  for (const variant of headerVariations) {
    console.log(`\n🧪 Testing: ${variant.name}`);

    try {
      const tokenResponse = await axios.post(
        "https://api.clickpesa.com/third-parties/generate-token",
        {},
        {
          headers: variant.headers,
          timeout: 5000,
        },
      );

      console.log("✅ Token obtained with this variant!");

      const token = tokenResponse.data.token;

      // Now test payment with this token
      const payload = {
        amount: "1000",
        currency: "TZS",
        orderReference: `TEST_${Date.now()}_${variant.name.substring(0, 5)}`,
        phoneNumber: "255678960706",
      };

      // Try checksum with client ID
      const checksum1 = crypto
        .createHmac("sha256", clientId)
        .update(JSON.stringify(payload))
        .digest("hex");

      payload.checksum = checksum1;

      console.log("  Testing payment with this token...");
      const paymentResponse = await axios.post(
        "https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request",
        payload,
        {
          headers: {
            Authorization: token,
            "Content-Type": "application/json",
          },
          timeout: 5000,
        },
      );

      console.log("✅ PAYMENT SUCCESS!");
      console.log("Response:", JSON.stringify(paymentResponse.data, null, 2));
      console.log("\n🎉 FOUND THE CORRECT APPROACH!");
      console.log("Headers to use:", JSON.stringify(variant.headers, null, 2));
      return;
    } catch (error) {
      if (
        error.response?.status === 400 &&
        error.response?.data?.message?.includes("Invalid checksum")
      ) {
        console.log("❌ Checksum invalid (token format OK)");
      } else {
        console.log(
          `❌ Error: ${error.response?.data?.message || error.message}`,
        );
      }
    }
  }

  console.log(
    "\n🔍 Testing without checksum field (maybe not required after all)...",
  );

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

    const payload = {
      amount: "1000",
      currency: "TZS",
      orderReference: `NO_CHECKSUM_${Date.now()}`,
      phoneNumber: "255678960706",
    };
    // No checksum field

    const response = await axios.post(
      "https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request",
      payload,
      {
        headers: {
          Authorization: token,
          "Content-Type": "application/json",
        },
      },
    );

    console.log("✅ Works without checksum!");
    console.log("Response:", JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.log("❌ Checksum still required");
  }
}

testWithCorrectHeaders();
