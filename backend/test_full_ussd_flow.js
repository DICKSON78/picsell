require('dotenv').config();
const clickpesaService = require('./src/services/clickpesaService');

async function testFullUSSDFlow() {
  console.log('🎯 FULL USSD PAYMENT FLOW TEST\n');

  try {
    // Test 1: Preview
    console.log('1️⃣ Testing USSD Preview...');
    const preview = await clickpesaService.previewPayment('255712345678', 24000, 'CRED17722829172130');
    console.log('✅ Preview Success:');
    console.log('   Available Methods:', preview.activeMethods.map(m => m.name + ' (Fee: ' + m.fee + ')').join(', '));

    // Test 2: Initiate Payment
    console.log('\n2️⃣ Testing Payment Initiation...');
    const payment = await clickpesaService.initiatePayment('255712345678', 1000, 'CRED17722829172131');
    console.log('✅ Payment Initiated:');
    console.log('   Payment ID:', payment.paymentId);
    console.log('   Status:', payment.status);
    console.log('   Amount:', payment.collectedAmount, payment.collectedCurrency);
    console.log('   Created:', payment.createdAt);

    console.log('\n🎉 USSD PAYMENT INTEGRATION IS WORKING!\n');
    console.log('✅ Summary:');
    console.log('   • Checksum generation: WORKING ✓');
    console.log('   • Token authentication: WORKING ✓');
    console.log('   • Payment preview: WORKING ✓');
    console.log('   • Payment initiation: WORKING ✓');
    console.log('\n📱 NEXT: Webhook will auto-complete when user pays via USSD!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

testFullUSSDFlow();
