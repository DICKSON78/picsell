#!/usr/bin/env node
require('dotenv').config();
const crypto = require('crypto');
const axios = require('axios');

async function debugChecksum() {
  console.log('🔍 ClickPesa Checksum Debug\n');
  
  // Test payload - exactly like previewPayment sends
  const testPayload = {
    amount: '24000',
    currency: 'TZS',
    orderReference: 'TEST_123456',
    phoneNumber: '255712345678'
  };

  const checksumSecret = process.env.CLICKPESA_CHECKSUM_SECRET;
  console.log('Checksum Secret:', checksumSecret);
  console.log('Test Payload:', testPayload, '\n');

  // Generate checksum EXACTLY as docs say
  const canonicalPayload = canonicalize(testPayload);
  const payloadString = JSON.stringify(canonicalPayload);
  const hmac = crypto.createHmac('sha256', checksumSecret);
  hmac.update(payloadString);
  const checksum = hmac.digest('hex');

  console.log('Canonical Payload:', payloadString);
  console.log('Generated Checksum:', checksum, '\n');

  // Now test with the actual API
  console.log('Testing with ClickPesa API...\n');

  const payloadWithChecksum = {
    ...testPayload,
    checksum: checksum
  };

  console.log('Sending to API:', JSON.stringify(payloadWithChecksum, null, 2), '\n');

  try {
    // First get token
    const tokenResponse = await axios.post(
      'https://api.clickpesa.com/third-parties/generate-token',
      {},
      {
        headers: {
          'api-key': process.env.CLICKPESA_API_KEY,
          'client-id': process.env.CLICKPESA_CLIENT_ID,
          'Content-Type': 'application/json',
        },
      }
    );

    const token = tokenResponse.data.token;
    console.log('✅ Token generated\n');

    // Test preview payment
    console.log('Testing preview payment...');
    const previewResponse = await axios.post(
      'https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request',
      payloadWithChecksum,
      {
        headers: {
          Authorization: token,
          'Content-Type': 'application/json',
        },
      }
    );

    console.log('✅ Preview successful!');
    console.log(JSON.stringify(previewResponse.data, null, 2));

  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    
    if (error.response?.data?.message?.includes('checksum')) {
      console.log('\n⚠️ CHECKSUM ISSUE DETECTED:');
      console.log('   1. Verify CLICKPESA_CHECKSUM_SECRET is correct');
      console.log('   2. Check if checksum is enabled in merchant dashboard');
      console.log('   3. Verify API tokens were regenerated after enabling checksum');
      console.log('   4. Try disabling checksum temporarily to test other parts');
    }
  }
}

function canonicalize(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) {
    return obj.map(canonicalize);
  }
  return Object.keys(obj)
    .sort()
    .reduce((acc, key) => {
      acc[key] = canonicalize(obj[key]);
      return acc;
    }, {});
}

debugChecksum();
