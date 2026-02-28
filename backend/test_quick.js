#!/usr/bin/env node
const axios = require("axios");
require("dotenv").config();

async function testClickPesa() {
  console.log("🧪 Quick ClickPesa Test\n");

  console.log("Environment Variables:");
  console.log("  CLIENT_ID:", process.env.CLICKPESA_CLIENT_ID);
  console.log(
    "  API_KEY:",
    process.env.CLICKPESA_API_KEY?.substring(0, 10) + "...",
  );
  console.log(
    "  CHECKSUM_SECRET:",
    process.env.CLICKPESA_CHECKSUM_SECRET?.substring(0, 10) + "...\n",
  );

  try {
    console.log("Making token request...");
    const response = await axios.post(
      "https://api.clickpesa.com/third-parties/generate-token",
      {},
      {
        headers: {
          "api-key": process.env.CLICKPESA_API_KEY,
          "client-id": process.env.CLICKPESA_CLIENT_ID,
          "Content-Type": "application/json",
        },
      },
    );

    console.log("✅ Response Status:", response.status);
    console.log("✅ Response Data:", response.data);

    if (response.data.success && response.data.token) {
      console.log("\n✅ TOKEN GENERATION SUCCESSFUL!");
      console.log("Token:", response.data.token.substring(0, 30) + "...");
    }
  } catch (error) {
    console.error("❌ Error:", error.response?.data || error.message);
    console.error("Status:", error.response?.status);
  }
}

testClickPesa();
