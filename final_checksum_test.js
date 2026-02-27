#!/usr/bin/env node

/**
 * Final attempt - Try to find the correct checksum approach
 */

require('dotenv').config();
const axios = require('axios');
const crypto = require('crypto');

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;

async function finalChecksumTest() {
  console.log('🎯 Final Checksum Test\n');
  
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
    console.log('✅ Token obtained\n');
    
    // Try the exact example from ClickPesa docs
    console.log('🔄 Testing with exact ClickPesa example format...');
    
    const payload = {
      amount: '1000',
      currency: 'TZS',
      orderReference: `FINAL_TEST_${Date.now()}`,
      phoneNumber: '255678960706'
    };
    
    // Try every possible checksum key
    const checksumKeys = [
      apiKey,
      clientId,
      'test-key',
      'checksum-key',
      '',
      'SKKae77OH1EcikhGyG6oIjaQRuubyNXPORZbUfbD5Q', // API key again
      'IDnqLPeiJAEGiHwKcXyzfWkqJqmkkSbN', // Client ID again
    ];
    
    for (let i = 0; i < checksumKeys.length; i++) {
      const key = checksumKeys[i];
      const keyName = `Key ${i + 1} (${key ? key.substring(0, 10) + '...' : 'EMPTY'})`;
      
      console.log(`\n🧪 Trying ${keyName}:`);
      
      try {
        const testPayload = { ...payload };
        
        if (key) {
          // Generate checksum with this key
          const canonicalPayload = JSON.stringify(payload, Object.keys(payload).sort());
          const hmac = crypto.createHmac('sha256', key);
          hmac.update(canonicalPayload);
          testPayload.checksum = hmac.digest('hex');
        }
        
        const response = await axios.post('https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request', testPayload, {
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json'
          },
          timeout: 10000
        });
        
        console.log('✅ SUCCESS! Found the correct key!');
        console.log('Response:', JSON.stringify(response.data, null, 2));
        
        // If successful, try actual payment
        if (response.data.success) {
          console.log('\n🚀 Attempting actual USSD push...');
          console.log('📱 This will send a REAL USSD push to 255678960706!');
          
          const paymentResponse = await axios.post('https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request', testPayload, {
            headers: {
              'Authorization': token,
              'Content-Type': 'application/json'
            },
            timeout: 10000
          });
          
          console.log('🎉 USSD PUSH SENT SUCCESSFULLY!');
          console.log('Payment Response:', JSON.stringify(paymentResponse.data, null, 2));
          console.log('\n📱 Check your phone now for the USSD message!');
        }
        
        return; // Stop on first success
        
      } catch (error) {
        console.log(`❌ Failed: ${error.response?.data?.message || error.message}`);
      }
    }
    
    console.log('\n❌ None of the checksum keys worked. May need to check ClickPesa dashboard for specific checksum key.');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

finalChecksumTest();
