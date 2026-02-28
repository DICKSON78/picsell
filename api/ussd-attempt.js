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

    console.log('📱 Attempting USSD push to:', formattedPhone);
    console.log('💰 Amount:', amount);

    // Try with basic auth format
    try {
      const response = await axios.post(
        'https://api.clickpesa.com/v1/payments',
        {
          phone_number: formattedPhone,
          amount: amount,
          currency: 'TZS',
          payment_type: 'ussd_push'
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Basic ${Buffer.from(`${process.env.CLICKPESA_CLIENT_ID}:${process.env.CLICKPESA_API_KEY}`).toString('base64')}`
          },
          timeout: 15000
        }
      );

      console.log('✅ USSD Push Response:', response.data);
      
      res.status(200).json({
        success: true,
        message: 'USSD push initiated!',
        phone: formattedPhone,
        response: response.data
      });

    } catch (error) {
      console.log('❌ Basic auth failed, trying token method...');
      
      // Try token method
      const tokenResponse = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        {},
        {
          headers: {
            'X-Client-Id': process.env.CLICKPESA_CLIENT_ID,
            'X-Api-Key': process.env.CLICKPESA_API_KEY
          }
        }
      );

      const token = tokenResponse.data.token;
      
      const ussdResponse = await axios.post(
        'https://api.clickpesa.com/third-parties/payments/ussd-push',
        {
          phone_number: formattedPhone,
          amount: amount,
          currency: 'TZS'
        },
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          timeout: 15000
        }
      );

      res.status(200).json({
        success: true,
        message: 'USSD push initiated via token!',
        phone: formattedPhone,
        response: ussdResponse.data
      });
    }

  } catch (error) {
    console.error('❌ All USSD attempts failed:', error.response?.data || error.message);
    
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data',
      phone: phoneNumber,
      note: 'Check ClickPesa credentials and account status'
    });
  }
};
