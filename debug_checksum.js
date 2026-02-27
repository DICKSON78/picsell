#!/usr/bin/env node

/**
 * Debug checksum generation
 */

require('dotenv').config();
const crypto = require('crypto');

const apiKey = process.env.CLICKPESA_API_KEY;

// Copy the exact functions from ClickPesa docs
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
  // Canonicalize the payload recursively for consistent ordering
  const canonicalPayload = canonicalize(payload);
  
  // Serialize the canonical payload
  const payloadString = JSON.stringify(canonicalPayload);
  
  // Create HMAC with SHA256
  const hmac = crypto.createHmac('sha256', checksumKey);
  hmac.update(payloadString);
  return hmac.digest('hex');
};

// Test data
const payload = {
  amount: '1000',
  currency: 'TZS',
  orderReference: 'TEST_CHECKSUM_DEBUG',
  phoneNumber: '255678960706'
};

console.log('🔍 Debugging Checksum Generation\n');
console.log('📋 Original Payload:');
console.log(JSON.stringify(payload, null, 2));

console.log('\n📋 Canonicalized Payload:');
const canonicalPayload = canonicalize(payload);
console.log(JSON.stringify(canonicalPayload, null, 2));

console.log('\n📋 Serialized Payload:');
const payloadString = JSON.stringify(canonicalPayload);
console.log(payloadString);

console.log('\n🔑 API Key (first 10 chars):', apiKey.substring(0, 10));

console.log('\n🔐 Generated Checksum:');
const checksum = createPayloadChecksum(apiKey, payload);
console.log(checksum);
console.log('Length:', checksum.length);

// Test with different key
console.log('\n🧪 Testing with different key:');
const testKey = 'test-key';
const testChecksum = createPayloadChecksum(testKey, payload);
console.log('With test-key:', testChecksum);
