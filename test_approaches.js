#!/usr/bin/env node

/**
 * Test ClickPesa API with different approaches
 */

require('dotenv').config();
const axios = require('axios');

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;

async function testDifferentApproaches() {
  console.log('🧪 Testing Different ClickPesa API Approaches\n');
  
  try {
    // Generate token
    const tokenResponse = await axios.post('https://api.clickpesa.com/third-parties/generate-token', {}, {
      headers: {
        'api-key': apiKey,
        'client-id': clientId,
        'Content-Type': 'application/json'
      }
    });
    
    const token = tokenResponse.data.token;
    console.log('✅ Token obtained\n');
    
    // Try different checksum approaches
    const approaches = [
      {
        name: 'Empty checksum',
        checksum: ''
      },
      {
        name: 'Null checksum',
        checksum: null
      },
      {
        name: 'Simple checksum',
        checksum: 'test123'
      },
      {
        name: 'SHA256 of amount only',
        checksum: require('crypto').createHash('sha256').update('1000').digest('hex')
      }
    ];
    
    for (const approach of approaches) {
      console.log(`🔄 Testing: ${approach.name}`);
      
      const data = {
        amount: '1000',
        currency: 'TZS',
        orderReference: `TEST_${Date.now()}`,
        phoneNumber: '255678960706'
      };
      
      if (approach.checksum !== null) {
        data.checksum = approach.checksum;
      }
      
      try {
        const response = await axios.post('https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request', data, {
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json'
          }
        });
        
        console.log('✅ SUCCESS with', approach.name);
        console.log('Response:', JSON.stringify(response.data, null, 2));
        break;
        
      } catch (error) {
        console.log('❌ Failed:', error.response?.data?.message || error.message);
      }
      
      console.log('');
    }
    
  } catch (error) {
    console.error('❌ Token error:', error.message);
  }
}

testDifferentApproaches();
