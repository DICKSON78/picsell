#!/usr/bin/env node

/**
 * Test different API key formats
 */

require('dotenv').config();
const crypto = require('crypto');

const apiKey = process.env.CLICKPESA_API_KEY;

console.log('🔍 Analyzing API Key\n');
console.log('Raw API Key:', apiKey);
console.log('Length:', apiKey.length);
console.log('Type:', typeof apiKey);

// Check for any special characters
console.log('\n🔍 Character Analysis:');
for (let i = 0; i < apiKey.length; i++) {
  const char = apiKey[i];
  const code = char.charCodeAt(0);
  console.log(`  Position ${i}: "${char}" (code: ${code})`);
}

// Test different encodings
console.log('\n🧪 Testing Different Encodings:');

const testPayload = {
  amount: '1000',
  currency: 'TZS',
  orderReference: 'ENCODING_TEST',
  phoneNumber: '255678960706'
};

// Method 1: Raw key
const checksum1 = crypto.createHmac('sha256', apiKey)
  .update(JSON.stringify(testPayload))
  .digest('hex');
console.log('1. Raw key:', checksum1);

// Method 2: UTF-8 encoded key
const checksum2 = crypto.createHmac('sha256', Buffer.from(apiKey, 'utf8'))
  .update(JSON.stringify(testPayload))
  .digest('hex');
console.log('2. UTF-8 buffer:', checksum2);

// Method 3: Trim key (in case of whitespace)
const checksum3 = crypto.createHmac('sha256', apiKey.trim())
  .update(JSON.stringify(testPayload))
  .digest('hex');
console.log('3. Trimmed key:', checksum3);

// Method 4: Try with client ID instead
const clientId = process.env.CLICKPESA_CLIENT_ID;
const checksum4 = crypto.createHmac('sha256', clientId)
  .update(JSON.stringify(testPayload))
  .digest('hex');
console.log('4. Client ID:', checksum4);

console.log('\n📋 API Key Info:');
console.log('Contains spaces:', apiKey.includes(' '));
console.log('Contains special chars:', /[^a-zA-Z0-9]/.test(apiKey));
console.log('Client ID:', clientId);
console.log('Client ID length:', clientId.length);
