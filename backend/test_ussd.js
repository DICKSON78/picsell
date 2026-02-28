#!/usr/bin/env node
require("dotenv").config();
const clickpesaService = require("./src/services/clickpesaService");

async function testUSSDPayment() {
  console.log("🧪 Testing USSD Payment...\n");

  try {
    // Test 1: Token
    console.log("1️⃣ Generating token...");
    const token = await clickpesaService.generateToken();
    console.log("✅ Token generated\n");

    // Test 2: Test preview payment
    console.log("2️⃣ Testing payment preview...");
    const testPhone = "255712345678";
    const testAmount = 24000;
    const orderRef = `TEST_${Date.now()}`;

    try {
      const preview = await clickpesaService.previewPayment(
        testPhone,
        testAmount,
        orderRef,
      );
      console.log("✅ Preview successful:");
      console.log(JSON.stringify(preview, null, 2));
    } catch (previewError) {
      console.log("❌ Preview failed:", previewError.message);
    }

    // Test 3: Test actual payment initiation
    console.log("\n3️⃣ Testing payment initiation...");
    const testAmount2 = 1000;
    const orderRef2 = `TEST_INIT_${Date.now()}`;

    try {
      const payment = await clickpesaService.initiatePayment(
        testPhone,
        testAmount2,
        orderRef2,
      );
      console.log("✅ Payment initiated successfully:");
      console.log(JSON.stringify(payment, null, 2));
      console.log("\n🎉 USSD PAYMENT INTEGRATION WORKING!");
    } catch (paymentError) {
      console.log("❌ Payment initiation failed:", paymentError.message);
    }
  } catch (error) {
    console.error("❌ Fatal error:", error.message);
  }
}

testUSSDPayment();
