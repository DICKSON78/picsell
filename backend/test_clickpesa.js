#!/usr/bin/env node

/**
 * Test script to verify ClickPesa payment integration
 * Run this script to test if ClickPesa API is working correctly
 */

require("dotenv").config();
const clickpesaService = require("./src/services/clickpesaService");

async function testClickPesaIntegration() {
  console.log("🧪 Testing ClickPesa Integration...\n");

  try {
    // Test 1: Check environment variables
    console.log("1️⃣ Checking environment variables...");
    console.log(
      "   CLICKPESA_CLIENT_ID:",
      process.env.CLICKPESA_CLIENT_ID ? "✅ Set" : "❌ Missing",
    );
    console.log(
      "   CLICKPESA_API_KEY:",
      process.env.CLICKPESA_API_KEY ? "✅ Set" : "❌ Missing",
    );

    if (!process.env.CLICKPESA_CLIENT_ID || !process.env.CLICKPESA_API_KEY) {
      console.log(
        "\n❌ ClickPesa credentials not found. Please check your .env file.",
      );
      console.log("   Required: CLICKPESA_CLIENT_ID and CLICKPESA_API_KEY");
      return;
    }

    // Test 2: Generate token
    console.log("\n2️⃣ Testing token generation...");
    try {
      const token = await clickpesaService.generateToken();
      console.log("   ✅ Token generated successfully");
      console.log("   Token length:", token.length);
      console.log("   Token preview:", token.substring(0, 20) + "...");
    } catch (error) {
      console.log("   ❌ Token generation failed:", error.message);
      console.log(
        "   This usually means your ClickPesa credentials are invalid",
      );
      return;
    }

    // Test 3: Test exchange rate
    console.log("\n3️⃣ Testing exchange rate...");
    try {
      const rate = await clickpesaService.getExchangeRate();
      console.log("   ✅ Exchange rate retrieved:", rate);
    } catch (error) {
      console.log("   ❌ Exchange rate failed:", error.message);
    }

    // Test 4: Test payment preview (with test data)
    console.log("\n4️⃣ Testing payment preview...");
    try {
      const testPhone = "255712345678"; // Test phone number
      const testAmount = 24000; // TZS 24,000
      const testOrderRef = `TEST_${Date.now()}`;

      console.log("   Testing with:", { testPhone, testAmount, testOrderRef });

      const preview = await clickpesaService.previewPayment(
        testPhone,
        testAmount,
        testOrderRef,
      );
      console.log("   ✅ Payment preview successful");
      console.log("   Response:", JSON.stringify(preview, null, 2));
    } catch (error) {
      console.log("   ❌ Payment preview failed:", error.message);
      if (error.response) {
        console.log(
          "   Error details:",
          JSON.stringify(error.response.data, null, 2),
        );
      }
    }

    // Test 5: Test actual payment initiation (with test data)
    console.log("\n5️⃣ Testing payment initiation...");
    try {
      const testPhone = "255712345678"; // Test phone number
      const testAmount = 1000; // TZS 1,000 (small amount for testing)
      const testOrderRef = `TEST_INIT_${Date.now()}`;

      console.log("   Testing with:", { testPhone, testAmount, testOrderRef });

      // Validate phone number format
      if (!testPhone.startsWith("255") || testPhone.length !== 12) {
        console.log(
          "   ❌ Invalid phone format. Should be 255XXXXXXXXX (12 digits)",
        );
        return;
      }

      console.log("   ✅ Phone number format is correct");
      console.log("   ⚠️  This will send a real USSD push if successful!");

      const payment = await clickpesaService.initiatePayment(
        testPhone,
        testAmount,
        testOrderRef,
      );
      console.log("   ✅ Payment initiation successful");
      console.log("   Payment ID:", payment.paymentId);
      console.log("   Status:", payment.status);
      console.log("   Channel:", payment.channel);
      console.log("   🎉 USSD Push should appear on phone:", testPhone);
    } catch (error) {
      console.log("   ❌ Payment initiation failed:", error.message);
      if (error.response) {
        console.log(
          "   Error details:",
          JSON.stringify(error.response.data, null, 2),
        );
      }
    }

    console.log("\n🎉 ClickPesa integration test completed!");
    console.log("\n📋 Summary:");
    console.log("   - If test 2 fails: Check your ClickPesa credentials");
    console.log("   - If test 4 fails: Check API permissions and phone format");
    console.log("   - If test 5 succeeds: USSD push should work in production");
    console.log("   - Check your phone for the test USSD push message");
  } catch (error) {
    console.error("\n💥 Test failed:", error.message);
  }
}

// Load environment variables
require("dotenv").config();

// Run the test
testClickPesaIntegration();
