#!/usr/bin/env node

/**
 * Direct API test with correct checksum
 */

require('dotenv').config();
const axios = require('axios');
const crypto = require('crypto');

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;

// Exact functions from ClickPesa docs
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

const createPayloadChecksum = (checksumKey, payload) => {
  const canonicalPayload = canonicalize(payload);
  const payloadString = JSON.stringify(canonicalPayload);
  const hmac = crypto.createHmac('sha256', checksumKey);
  hmac.update(payloadString);
  return hmac.digest('hex');
};

async function directAPITest() {
  console.log('🧪 Direct API Test with Correct Checksum\n');
  
  try {
    // Get token
    const tokenResponse = await axios.post('https://api.clickpesa.com/third-parties/generate-token', {}, {
      headers: {
        'api-key': apiKey,
        'client-id': clientId,
        'Content-Type': 'application/json'
      }
    });
    
    const token = tokenResponse.data.token;
    console.log('✅ Token obtained');
    
    // Prepare payload with correct checksum
    const payload = {
      amount: '1000',
      currency: 'TZS',
      orderReference: `DIRECT_TEST_${Date.now()}`,
      phoneNumber: '255678960706'
    };
    
    const checksum = createPayloadChecksum(apiKey, payload);
    payload.checksum = checksum;
    
    console.log('\n📋 Payload with checksum:');
    console.log(JSON.stringify(payload, null, 2));
    
    console.log('\n🔄 Calling Preview API...');
    const response = await axios.post('https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request', payload, {
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ SUCCESS! Preview API worked!');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    
    // If preview works, try actual payment
    if (response.data.success) {
      console.log('\n🚀 Trying actual payment initiation...');
      console.log('📱 This will send REAL USSD push to your phone!');
      
      const paymentResponse = await axios.post('https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request', payload, {
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ USSD Push initiated successfully!');
      console.log('Payment Response:', JSON.stringify(paymentResponse.data, null, 2));
      console.log('\n📱 Check your phone for USSD message!');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.response?.status);
    console.error('Response:', JSON.stringify(error.response?.data, null, 2));
  }
}

directAPITest();
