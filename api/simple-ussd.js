// Simple USSD Test without database dependencies
const cors = require('cors');
const axios = require('axios');

// CORS middleware
const corsHandler = cors({
  origin: ['http://localhost:3000', 'https://yourdomain.com', 'exp://192.168.1.100:8081'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
});

module.exports = async (req, res) => {
  // Apply CORS
  await new Promise((resolve, reject) => {
    corsHandler(req, res, (result) => {
      if (result instanceof Error) {
        return reject(result);
      }
      return resolve(result);
    });
  });

  if (req.method === 'POST' && req.url.includes('/create-payment')) {
    return handleCreatePayment(req, res);
  }

  return res.status(404).json({ error: 'Endpoint not found' });
};

async function handleCreatePayment(req, res) {
  try {
    const { packageId, phoneNumber, paymentMethod } = req.body;
    
    // Package pricing
    const packages = {
      pack_10: { credits: 10, price: 12000 },
      pack_25: { credits: 25, price: 24000 },
      pack_50: { credits: 50, price: 43000 },
      pack_100: { credits: 100, price: 72000 },
    };

    const selectedPackage = packages[packageId];
    if (!selectedPackage) {
      return res.status(400).json({ error: 'Invalid package' });
    }

    // Format phone number
    let formattedPhone = phoneNumber;
    if (phoneNumber.startsWith('07')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    } else if (phoneNumber.startsWith('0')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    }

    // Generate order reference
    const orderReference = `CRED_${Date.now()}`;

    console.log('📱 Phone verification:');
    console.log('   Original:', phoneNumber);
    console.log('   Formatted:', formattedPhone);
    console.log('🔑 API Key:', process.env.CLICKPESA_API_KEY ? 'Present' : 'Missing');
    console.log('🆔 Client ID:', process.env.CLICKPESA_CLIENT_ID ? 'Present' : 'Missing');

    // Test ClickPesa API call (using correct format)
    try {
      // First get token
      const tokenResponse = await axios.post('https://api.clickpesa.com/third-parties/generate-token', {}, {
        headers: {
          'api-key': process.env.CLICKPESA_API_KEY.trim(),
          'Content-Type': 'application/json'
        }
      });

      const token = tokenResponse.data.token;
      console.log('✅ Token obtained:', token ? 'Success' : 'Failed');

      // Generate checksum (simplified)
      const checksumData = {
        amount: selectedPackage.price.toString(),
        currency: 'TZS',
        orderReference,
        phoneNumber: formattedPhone
      };
      
      const crypto = require('crypto');
      const checksum = crypto.createHmac('sha256', process.env.CLICKPESA_CLIENT_ID)
        .update(JSON.stringify(checksumData))
        .digest('hex');

      const clickpesaResponse = await axios.post(
        'https://api.clickpesa.com/third-parties/payments/preview-ussd-push-request',
        {
          amount: selectedPackage.price.toString(),
          currency: 'TZS',
          orderReference,
          phoneNumber: formattedPhone,
          checksum: checksum
        },
        {
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json'
          }
        }
      );

      console.log('✅ ClickPesa Response:', clickpesaResponse.data);

      res.status(200).json({
        success: true,
        orderReference,
        paymentInitiated: true,
        package: selectedPackage,
        phoneNumber: formattedPhone,
        clickpesaResponse: clickpesaResponse.data,
        message: 'USSD push initiated successfully'
      });

    } catch (clickpesaError) {
      console.error('❌ ClickPesa Error:', clickpesaError.response?.data || clickpesaError.message);
      
      res.status(500).json({
        success: false,
        error: 'ClickPesa API Error',
        details: clickpesaError.response?.data || clickpesaError.message,
        package: selectedPackage,
        phoneNumber: formattedPhone,
        orderReference
      });
    }

  } catch (error) {
    console.error('❌ USSD Test Error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data'
    });
  }
}
