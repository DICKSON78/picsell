#!/usr/bin/env node

/**
 * Test if checksum is required for preview vs initiate
 */

require('dotenv').config();
const axios = require('axios');
const crypto = require('crypto');

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;

async function testChecksumRequirement() {
  console.log('🧪 Testing Checksum Requirements\n');
  
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
    
    // Test 1: Preview without checksum
    console.log('1️⃣ Testing Preview WITHOUT checksum:');
    try {
      const payload1 = {
        amount: '1000',
        currency: 'TZS',
        orderReference: `NO_CHECKSUM_${Date.now()}`,
        phoneNumber: '255678960706'
      };
      
      const response1 = await axios.post('https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request', payload1, {
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Preview works without checksum!');
      console.log('Response:', JSON.stringify(response1.data, null, 2));
      
    } catch (error) {
      console.log('❌ Preview requires checksum:', error.response?.data?.message);
    }
    
    console.log('\n2️⃣ Testing Initiate WITHOUT checksum:');
    try {
      const payload2 = {
        amount: '1000',
        currency: 'TZS',
        orderReference: `NO_CHECKSUM_INIT_${Date.now()}`,
        phoneNumber: '255678960706'
      };
      
      const response2 = await axios.post('https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request', payload2, {
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Initiate works without checksum!');
      console.log('Response:', JSON.stringify(response2.data, null, 2));
      
    } catch (error) {
      console.log('❌ Initiate requires checksum:', error.response?.data?.message);
    }
    
  } catch (error) {
    console.error('❌ Token error:', error.message);
  }
}

testChecksumRequirement();
