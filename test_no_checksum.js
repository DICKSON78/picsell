#!/usr/bin/env node

/**
 * Test ClickPesa API without checksum
 */

require('dotenv').config();
const axios = require('axios');

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;

async function testWithoutChecksum() {
  console.log('🧪 Testing ClickPesa API without checksum\n');
  
  try {
    // Generate token
    console.log('1️⃣ Getting token...');
    const tokenResponse = await axios.post('https://api.clickpesa.com/third-parties/generate-token', {}, {
      headers: {
        'api-key': apiKey,
        'client-id': clientId,
        'Content-Type': 'application/json'
      }
    });
    
    const token = tokenResponse.data.token;
    console.log('✅ Token obtained');
    
    // Test preview without checksum
    console.log('\n2️⃣ Testing preview without checksum...');
    
    const data = {
      amount: '1000',
      currency: 'TZS',
      orderReference: 'TEST_NO_CHECKSUM_123',
      phoneNumber: '255678960706'
      // No checksum field
    };
    
    console.log('Data being sent:', JSON.stringify(data, null, 2));
    
    const previewResponse = await axios.post('https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request', data, {
      headers: {
        'Authorization': token,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Preview successful without checksum!');
    console.log('Response:', JSON.stringify(previewResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.response?.status, error.response?.statusText);
    console.error('Response:', JSON.stringify(error.response?.data, null, 2));
    
    if (error.response?.data?.message?.includes('checksum')) {
      console.log('\n🔍 Checksum is required. Trying different approaches...');
    }
  }
}

testWithoutChecksum();
