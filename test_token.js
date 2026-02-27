#!/usr/bin/env node

/**
 * Test ClickPesa Token Generation with Real Credentials
 */

require('dotenv').config();
const axios = require('axios');

async function testTokenGeneration() {
  console.log('🔑 Testing ClickPesa Token Generation\n');
  
  const clientId = process.env.CLICKPESA_CLIENT_ID;
  const apiKey = process.env.CLICKPESA_API_KEY;
  
  console.log('📋 Credentials Check:');
  console.log('   Client ID:', clientId ? clientId.substring(0, 10) + '...' : 'NOT FOUND');
  console.log('   API Key:', apiKey ? apiKey.substring(0, 10) + '...' : 'NOT FOUND');
  console.log('   Base URL: https://api.clickpesa.com/third-parties\n');
  
  if (!clientId || !apiKey) {
    console.log('❌ Missing credentials in .env file');
    return;
  }
  
  try {
    console.log('🔄 Generating token...');
    
    const response = await axios.post('https://api.clickpesa.com/third-parties/generate-token', {}, {
      headers: {
        'api-key': apiKey,
        'client-id': clientId,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Token generated successfully!');
    console.log('   Response:', JSON.stringify(response.data, null, 2));
    
    if (response.data.success && response.data.token) {
      console.log('   Token length:', response.data.token.length);
      console.log('   Token preview:', response.data.token.substring(0, 50) + '...');
    }
    
  } catch (error) {
    console.error('❌ Token generation failed:');
    console.error('   Status:', error.response?.status);
    console.error('   Status Text:', error.response?.statusText);
    console.error('   Response:', JSON.stringify(error.response?.data, null, 2));
    
    console.log('\n🔧 Possible Issues:');
    console.log('   1. Client ID is incorrect');
    console.log('   2. API Key is incorrect');
    console.log('   3. Account is not active');
    console.log('   4. API permissions not enabled');
    console.log('   5. Network connectivity issues');
  }
}

testTokenGeneration();
