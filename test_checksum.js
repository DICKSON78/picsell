#!/usr/bin/env node

/**
 * Test ClickPesa Checksum Generation
 */

require('dotenv').config();
const crypto = require('crypto');

const clientId = process.env.CLICKPESA_CLIENT_ID;
const apiKey = process.env.CLICKPESA_API_KEY;

// Test data
const testData = {
  amount: '1000',
  currency: 'TZS',
  orderReference: 'TEST_CHECKSUM_123',
  phoneNumber: '255678960706'
};

console.log('🔍 Testing Checksum Generation\n');
console.log('📋 Test Data:');
console.log(JSON.stringify(testData, null, 2));
console.log('\nAPI Key:', apiKey.substring(0, 10) + '...');

// Method 1: Current implementation
function generateChecksum1(data) {
  const stringToHash = Object.keys(data)
    .sort()
    .map(key => `${key}${data[key]}`)
    .join('');
  
  return crypto.createHash('sha256')
    .update(stringToHash + apiKey)
    .digest('hex');
}

// Method 2: Without API key
function generateChecksum2(data) {
  const stringToHash = Object.keys(data)
    .sort()
    .map(key => `${key}${data[key]}`)
    .join('');
  
  return crypto.createHash('sha256')
    .update(stringToHash)
    .digest('hex');
}

// Method 3: With client ID
function generateChecksum3(data) {
  const stringToHash = Object.keys(data)
    .sort()
    .map(key => `${key}${data[key]}`)
    .join('');
  
  return crypto.createHash('sha256')
    .update(stringToHash + clientId)
    .digest('hex');
}

// Method 4: Different order
function generateChecksum4(data) {
  const stringToHash = `amount${data.amount}currency${data.currency}orderReference${data.orderReference}phoneNumber${data.phoneNumber}`;
  
  return crypto.createHash('sha256')
    .update(stringToHash + apiKey)
    .digest('hex');
}

console.log('\n🧪 Testing Different Checksum Methods:');
console.log('1. Current method (sorted + API key):', generateChecksum1(testData));
console.log('2. Sorted only (no key):', generateChecksum2(testData));
console.log('3. Sorted + Client ID:', generateChecksum3(testData));
console.log('4. Fixed order + API key:', generateChecksum4(testData));

// Test what the sorted string looks like
const sortedString = Object.keys(testData)
  .sort()
  .map(key => `${key}${data[key]}`)
  .join('');

console.log('\n📝 Sorted string for hashing:');
console.log(sortedString);
console.log('With API key:', sortedString + apiKey);
