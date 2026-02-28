const axios = require('axios');

module.exports = async (req, res) => {
  try {
    const { phoneNumber, amount } = req.body;
    
    // Format phone number
    let formattedPhone = phoneNumber;
    if (phoneNumber.startsWith('07')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    } else if (phoneNumber.startsWith('0')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    }

    console.log('📱 LOWERCASE API KEY TEST');
    console.log('   Phone:', formattedPhone);
    console.log('   Amount:', amount);

    // Try with lowercase API key
    const originalKey = process.env.CLICKPESA_API_KEY;
    const lowercaseKey = originalKey.toLowerCase();
    
    console.log('   Original Key:', originalKey);
    console.log('   Lowercase Key:', lowercaseKey);

    const tokenResponse = await axios.post(
      'https://api.clickpesa.com/third-parties/generate-token',
      {},
      {
        headers: {
          'api-key': lowercaseKey,
          'client-id': process.env.CLICKPESA_CLIENT_ID.toLowerCase()
        }
      }
    );

    console.log('✅ Token Response:', tokenResponse.data);

    if (tokenResponse.data.success && tokenResponse.data.token) {
      const token = tokenResponse.data.token;
      
      // Try USSD push
      const orderReference = `LOWERCASE_${Date.now()}`;
      const ussdResponse = await axios.post(
        'https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request',
        {
          amount: amount.toString(),
          currency: 'TZS',
          orderReference,
          phoneNumber: formattedPhone
        },
        {
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json'
          }
        }
      );

      console.log('✅ USSD Response:', ussdResponse.data);

      res.status(200).json({
        success: true,
        message: 'Lowercase API key test completed',
        token: tokenResponse.data,
        ussd: ussdResponse.data,
        phone: formattedPhone,
        note: 'CHECK YOUR PHONE NOW - USSD should appear!'
      });
    } else {
      throw new Error('Token generation failed: ' + JSON.stringify(tokenResponse.data));
    }

  } catch (error) {
    console.error('❌ Lowercase Test Error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data'
    });
  }
};
