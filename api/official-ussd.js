const axios = require('axios');
const crypto = require('crypto');

module.exports = async (req, res) => {
  try {
    const { phoneNumber, amount } = req.body;
    
    // Format phone number (255XXXXXXXXX format without +)
    let formattedPhone = phoneNumber;
    if (phoneNumber.startsWith('07')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    } else if (phoneNumber.startsWith('0')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    }

    console.log('📱 OFFICIAL CLICKPESA USSD TEST');
    console.log('   Original:', phoneNumber);
    console.log('   Formatted:', formattedPhone);
    console.log('   Amount:', amount);

    // Step 1: Generate Token (EXACT from documentation)
    console.log('🔑 Step 1: Generate Token');
    console.log('   API Key:', process.env.CLICKPESA_API_KEY?.substring(0, 10) + '...');
    console.log('   Client ID:', process.env.CLICKPESA_CLIENT_ID);
    
    // Try different header formats
    let token = null;
    let tokenError = null;
    
    // Method 1: Original format
    try {
      console.log('🔄 Trying original header format...');
      const response1 = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        {},
        {
          headers: {
            'api-key': process.env.CLICKPESA_API_KEY,
            'client-id': process.env.CLICKPESA_CLIENT_ID
          }
        }
      );
      if (response1.data.success && response1.data.token) {
        token = response1.data.token;
        console.log('✅ Original format SUCCESS');
      }
    } catch (error1) {
      tokenError = error1.response?.data || error1.message;
      console.log('❌ Original format FAILED:', tokenError);
    }
    
    // Method 2: Alternative header names
    if (!token) {
      try {
        console.log('🔄 Trying X- prefix headers...');
        const response2 = await axios.post(
          'https://api.clickpesa.com/third-parties/generate-token',
          {},
          {
            headers: {
              'X-API-Key': process.env.CLICKPESA_API_KEY,
              'X-Client-Id': process.env.CLICKPESA_CLIENT_ID
            }
          }
        );
        if (response2.data.success && response2.data.token) {
          token = response2.data.token;
          console.log('✅ X-prefix format SUCCESS');
        }
      } catch (error2) {
        tokenError = error2.response?.data || error2.message;
        console.log('❌ X-prefix format FAILED:', tokenError);
      }
    }
    
    // Method 3: JSON body auth
    if (!token) {
      try {
        console.log('🔄 Trying JSON body auth...');
        const response3 = await axios.post(
          'https://api.clickpesa.com/third-parties/generate-token',
          {
            client_id: process.env.CLICKPESA_CLIENT_ID,
            api_key: process.env.CLICKPESA_API_KEY
          },
          {
            headers: {
              'Content-Type': 'application/json'
            }
          }
        );
        if (response3.data.success && response3.data.token) {
          token = response3.data.token;
          console.log('✅ JSON body auth SUCCESS');
        }
      } catch (error3) {
        tokenError = error3.response?.data || error3.message;
        console.log('❌ JSON body auth FAILED:', tokenError);
      }
    }

    if (!token) {
      throw new Error('All token generation methods failed. Last error: ' + tokenError);
    }

    // Step 2: Preview USSD Push (from documentation)
    console.log('🔍 Step 2: Preview USSD Push');
    const orderReference = `DUKASELL_${Date.now()}`;
    const previewPayload = {
      amount: amount.toString(),
      currency: 'TZS',
      orderReference,
      phoneNumber: formattedPhone,
      fetchSenderDetails: false,
      checksum: generateChecksum({
        amount: amount.toString(),
        currency: 'TZS',
        orderReference,
        phoneNumber: formattedPhone,
        fetchSenderDetails: false
      })
    };

    const previewResponse = await axios.post(
      'https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request',
      previewPayload,
      {
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Preview Response:', previewResponse.data);

    // Step 3: Initiate USSD Push (from documentation)
    console.log('📤 Step 3: Initiate USSD Push');
    const initiatePayload = {
      amount: amount.toString(),
      currency: 'TZS',
      orderReference,
      phoneNumber: formattedPhone,
      checksum: generateChecksum({
        amount: amount.toString(),
        currency: 'TZS',
        orderReference,
        phoneNumber: formattedPhone
      })
    };

    const initiateResponse = await axios.post(
      'https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request',
      initiatePayload,
      {
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );

    console.log('✅ Initiate Response:', initiateResponse.data);

    res.status(200).json({
      success: true,
      message: 'Official ClickPesa USSD initiated successfully!',
      phone: formattedPhone,
      amount: amount,
      orderReference,
      preview: previewResponse.data,
      initiate: initiateResponse.data,
      note: 'CHECK YOUR PHONE NOW - USSD should appear!'
    });

  } catch (error) {
    console.error('❌ Official USSD Error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data',
      stack: error.stack
    });
  }
};

// Generate checksum function (from documentation)
function generateChecksum(data) {
  const checksumKey = process.env.CLICKPESA_CLIENT_ID;
  const canonicalPayload = canonicalize(data);
  const payloadString = JSON.stringify(canonicalPayload);
  
  const hmac = crypto.createHmac('sha256', checksumKey);
  hmac.update(payloadString);
  return hmac.digest('hex');
}

// Canonicalize object recursively (from documentation)
function canonicalize(obj) {
  if (obj === null || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) {
    return obj.map(item => canonicalize(item));
  }
  return Object.keys(obj)
    .sort()
    .reduce((acc, key) => {
      acc[key] = canonicalize(obj[key]);
      return acc;
    }, {});
}
