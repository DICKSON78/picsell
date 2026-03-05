const axios = require('axios');
const crypto = require('crypto');

module.exports = async (req, res) => {
  try {
    const { packageId, phoneNumber, paymentMethod } = req.body;
    
    console.log('📱 SIMPLE PAYMENT TEST');
    console.log('   Package:', packageId);
    console.log('   Phone:', phoneNumber);
    console.log('   Method:', paymentMethod);

    // Format phone number
    let formattedPhone = phoneNumber;
    if (phoneNumber.startsWith('07')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    } else if (phoneNumber.startsWith('0')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    }

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

    console.log('💰 Price:', selectedPackage.price);
    console.log('📱 Formatted Phone:', formattedPhone);

    // Generate token using working endpoint
    console.log('🔑 Generating token...');
    const tokenResponse = await axios.post(
      'https://api.clickpesa.com/v1/auth/token',
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

    console.log('✅ Token Response:', tokenResponse.data);

    // Generate checksum
    const orderReference = `DUKASELL_${Date.now()}`;
    const payload = {
      amount: selectedPackage.price.toString(),
      currency: 'TZS',
      orderReference,
      phoneNumber: formattedPhone
    };

    const checksum = crypto.createHmac('sha256', process.env.CLICKPESA_CLIENT_ID)
      .update(JSON.stringify(payload))
      .digest('hex');

    console.log('🔐 Checksum:', checksum.substring(0, 10) + '...');

    // Initiate USSD push
    console.log('📤 Initiating USSD push...');
    const ussdResponse = await axios.post(
      'https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request',
      {
        ...payload,
        checksum
      },
      {
        headers: {
          'Authorization': tokenResponse.data.token || `Bearer ${tokenResponse.data.token}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );

    console.log('✅ USSD Response:', ussdResponse.data);

    res.status(200).json({
      success: true,
      message: 'Payment initiated successfully!',
      package: selectedPackage,
      phone: formattedPhone,
      orderReference,
      payment: ussdResponse.data,
      note: 'CHECK YOUR PHONE NOW - USSD should appear!'
    });

  } catch (error) {
    console.error('❌ Payment Error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data'
    });
  }
};
