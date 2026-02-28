require('dotenv').config();
const crypto = require('crypto');
const axios = require('axios');

async function testOrderRef() {
  const testPayload = {
    amount: '24000',
    currency: 'TZS',
    orderReference: 'CRED' + Date.now(),  // Alphanumeric: CRED + timestamp
    phoneNumber: '255712345678'
  };

  const checksumSecret = process.env.CLICKPESA_CHECKSUM_SECRET;

  function canonicalize(obj) {
    if (obj === null || typeof obj !== 'object') return obj;
    if (Array.isArray(obj)) return obj.map(canonicalize);
    return Object.keys(obj).sort().reduce((acc, key) => {
      acc[key] = canonicalize(obj[key]);
      return acc;
    }, {});
  }

  const canonicalPayload = canonicalize(testPayload);
  const payloadString = JSON.stringify(canonicalPayload);
  const hmac = crypto.createHmac('sha256', checksumSecret);
  hmac.update(payloadString);
  const checksum = hmac.digest('hex');

  const payloadWithChecksum = { ...testPayload, checksum };

  console.log('Test Payload:', payloadWithChecksum);

  try {
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

    console.log('✅ PREVIEW SUCCESS!');
    console.log(JSON.stringify(previewResponse.data, null, 2));
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
  }
}

testOrderRef();
