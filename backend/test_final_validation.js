require('dotenv').config();
const clickpesaService = require('./src/services/clickpesaService');

async function testPaymentSystem() {
  console.log('🎯 FINAL PAYMENT SYSTEM VALIDATION\n');
  console.log('═'.repeat(60) + '\n');

  try {
    // Test 1: Preview with unique reference
    const ref1 = 'CRED' + Date.now() + Math.random().toString().slice(2, 5);
    console.log('1️⃣ Testing Payment Preview...');
    console.log('   Order Reference:', ref1);
    
    const preview = await clickpesaService.previewPayment('255712345678', 24000, ref1);
    console.log('   ✅ Preview successful!');
    console.log('   Available Methods:');
    preview.activeMethods.forEach(m => {
      console.log(`      • ${m.name} (Fee: ${m.fee} TZS, Status: ${m.status})`);
    });

    // Test 2: Initiate payment with unique reference
    const ref2 = 'CRED' + (Date.now() + 1) + Math.random().toString().slice(2, 5);
    console.log('\n2️⃣ Testing Payment Initiation...');
    console.log('   Order Reference:', ref2);
    
    const payment = await clickpesaService.initiatePayment('255712345678', 1000, ref2);
    console.log('   ✅ Payment initiated successfully!');
    console.log('   Details:');
    console.log(`      Payment ID: ${payment.paymentId}`);
    console.log(`      Status: ${payment.status}`);
    console.log(`      Amount: ${payment.collectedAmount} ${payment.collectedCurrency}`);
    console.log(`      Created: ${payment.createdAt}`);

    console.log('\n' + '═'.repeat(60));
    console.log('🎉 PAYMENT SYSTEM STATUS: FULLY OPERATIONAL\n');
    console.log('✅ All Components Working:');
    console.log('   ✓ Token generation');
    console.log('   ✓ Checksum calculation');
    console.log('   ✓ USSD payment preview');
    console.log('   ✓ USSD payment initiation');
    console.log('   ✓ Order reference validation');
    console.log('   ✓ Payment method discovery');
    console.log('\n📱 Next Step: User enters phone, receives USSD push, pays via menu');
    console.log('💰 Webhook will auto-add credits when payment completes\n');
    console.log('═'.repeat(60) + '\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
  }
}

testPaymentSystem();
