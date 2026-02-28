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

    console.log('📱 CLEAN USSD TEST');
    console.log('   Phone:', formattedPhone);
    console.log('   Amount:', amount);
    console.log('   Raw API Key:', process.env.CLICKPESA_API_KEY);
    console.log('   Raw Client ID:', process.env.CLICKPESA_CLIENT_ID);

    // Try with cleaned API key (remove potential special chars)
    const cleanApiKey = process.env.CLICKPESA_API_KEY?.replace(/[^a-zA-Z0-9]/g, '');
    const cleanClientId = process.env.CLICKPESA_CLIENT_ID?.replace(/[^a-zA-Z0-9]/g, '');

    console.log('   Clean API Key:', cleanApiKey);
    console.log('   Clean Client ID:', cleanClientId);

    // Test token generation with cleaned credentials
    const tokenResponse = await axios.post(
      'https://api.clickpesa.com/third-parties/generate-token',
      {},
      {
        headers: {
          'api-key': cleanApiKey,
          'client-id': cleanClientId
        }
      }
    );

    console.log('✅ Token Response:', tokenResponse.data);

    if (tokenResponse.data.success && tokenResponse.data.token) {
      const token = tokenResponse.data.token;
      
      // Now try USSD push
      const orderReference = `CLEAN_${Date.now()}`;
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
        message: 'Clean USSD test completed',
        token: tokenResponse.data,
        ussd: ussdResponse.data,
        phone: formattedPhone,
        note: 'Check your phone for USSD!'
      });
    } else {
      throw new Error('Token generation failed: ' + JSON.stringify(tokenResponse.data));
    }

  } catch (error) {
    console.error('❌ Clean USSD Error:', error.response?.data || error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data'
    });
  }
};
