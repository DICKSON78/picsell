#!/usr/bin/env node

/**
 * Direct USSD Push Test for ClickPesa
 * This simulates the exact payment flow from your Flutter app
 */

require('dotenv').config();
const clickpesaService = require('./backend/src/services/clickpesaService');

async function testUSSDPush() {
  console.log('🧪 Testing USSD Push to Your Phone\n');
  
  // Your phone number from the logs
  const originalPhone = '0678960706';
  const formattedPhone = '255678960706';
  
  console.log('📱 Phone Details:');
  console.log('   Original:', originalPhone);
  console.log('   Formatted:', formattedPhone);
  console.log('   This will send a REAL USSD push to your phone!\n');
  
  try {
    // Test 1: Preview payment
    console.log('1️⃣ Testing payment preview...');
    const testAmount = 1000; // TZS 1,000 (small test amount)
    const testOrderRef = `TEST_USSD_${Date.now()}`;
    
    console.log('   Amount:', testAmount, 'TZS');
    console.log('   Order Reference:', testOrderRef);
    
    const preview = await clickpesaService.previewPayment(
      formattedPhone,
      testAmount,
      testOrderRef
    );
    
    console.log('   ✅ Preview successful');
    console.log('   Preview response:', JSON.stringify(preview, null, 2));
    
    // Test 2: Initiate actual USSD push
    console.log('\n2️⃣ Initiating USSD Push...');
    console.log('   🚨 This will send a REAL USSD push to', formattedPhone);
    console.log('   📱 Check your phone now for the USSD message!\n');
    
    const payment = await clickpesaService.initiatePayment(
      formattedPhone,
      testAmount,
      testOrderRef
    );
    
    console.log('   ✅ USSD Push initiated successfully!');
    console.log('   Payment ID:', payment.paymentId);
    console.log('   Status:', payment.status);
    console.log('   Channel:', payment.channel);
    console.log('   Order Reference:', payment.orderReference);
    
    console.log('\n🎯 What to do next:');
    console.log('   1. Check your phone for USSD message from ClickPesa');
    console.log('   2. Follow the USSD menu to complete payment');
    console.log('   3. Enter your PIN/Mobile money password');
    console.log('   4. Wait for payment confirmation');
    
    console.log('\n📋 Test Summary:');
    console.log('   ✅ Phone formatting: 0678960706 → 255678960706');
    console.log('   ✅ API call: ClickPesa initiate-ussd-push-request');
    console.log('   ✅ Expected: USSD push on your phone');
    console.log('   ✅ Amount: TZS 1,000 (test amount)');
    
  } catch (error) {
    console.error('\n❌ USSD Push Test Failed:');
    console.error('   Error:', error.message);
    
    if (error.response) {
      console.error('   API Response:', JSON.stringify(error.response.data, null, 2));
    }
    
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Check ClickPesa credentials in .env file');
    console.log('   2. Verify phone number is active for mobile money');
    console.log('   3. Check if ClickPesa API is accessible');
    console.log('   4. Verify internet connection');
  }
}

// Run the test
testUSSDPush();
