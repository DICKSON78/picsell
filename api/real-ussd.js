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

    console.log('📱 Real USSD Test - Phone:', formattedPhone);
    console.log('💰 Amount:', amount);

    // Try actual ClickPesa payment endpoint
    const response = await axios.post(
      'https://api.clickpesa.com/v1/payments',
      {
        customer: {
          phone_number: formattedPhone,
          email: 'test@example.com'
        },
        payment: {
          amount: amount,
          currency: 'TZS',
          payment_method: 'mobile_money',
          payment_type: 'ussd_push'
        },
        order_reference: `DUKASELL_${Date.now()}`
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${Buffer.from(`${process.env.CLICKPESA_CLIENT_ID}:${process.env.CLICKPESA_API_KEY}`).toString('base64')}`
        },
        timeout: 20000
      }
    );

    console.log('✅ Full Response:', JSON.stringify(response.data, null, 2));

    res.status(200).json({
      success: true,
      message: 'Real USSD push sent!',
      phone: formattedPhone,
      amount: amount,
      fullResponse: response.data,
      note: 'Check your phone for USSD prompt'
    });

  } catch (error) {
    console.error('❌ Real USSD Error:', error.response?.data || error.message);
    
    // Try alternative endpoint
    try {
      console.log('🔄 Trying alternative endpoint...');
      
      const altResponse = await axios.post(
        'https://api.clickpesa.com/third-parties/payments',
        {
          phone_number: formattedPhone,
          amount: amount,
          currency: 'TZS',
          payment_method: 'mobile_money',
          reference: `DUKASELL_${Date.now()}`
        },
        {
          headers: {
            'Content-Type': 'application/json',
            'X-Client-Id': process.env.CLICKPESA_CLIENT_ID,
            'X-Api-Key': process.env.CLICKPESA_API_KEY
          },
          timeout: 20000
        }
      );

      console.log('✅ Alt Response:', JSON.stringify(altResponse.data, null, 2));

      res.status(200).json({
        success: true,
        message: 'Alternative USSD push sent!',
        phone: formattedPhone,
        amount: amount,
        fullResponse: altResponse.data,
        note: 'Check your phone for USSD prompt'
      });

    } catch (altError) {
      res.status(500).json({
        success: false,
        error: 'All methods failed',
        primaryError: error.response?.data || error.message,
        altError: altError.response?.data || altError.message,
        phone: formattedPhone,
        note: 'ClickPesa credentials may need verification'
      });
    }
  }
};
