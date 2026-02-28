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

    console.log('📱 DIRECT USSD TEST');
    console.log('   Original:', phoneNumber);
    console.log('   Formatted:', formattedPhone);
    console.log('   Amount:', amount);

    // Try multiple ClickPesa approaches
    const attempts = [];

    // Attempt 1: Direct USSD push with basic auth
    try {
      console.log('🔄 Attempt 1: Basic Auth USSD...');
      const response1 = await axios.post(
        'https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request',
        {
          amount: amount.toString(),
          currency: 'TZS',
          orderReference: `DIRECT_${Date.now()}`,
          phoneNumber: formattedPhone
        },
        {
          headers: {
            'Authorization': `Basic ${Buffer.from(`${process.env.CLICKPESA_CLIENT_ID}:${process.env.CLICKPESA_API_KEY}`).toString('base64')}`,
            'Content-Type': 'application/json'
          },
          timeout: 30000
        }
      );
      attempts.push({ method: 'Basic Auth USSD', success: true, response: response1.data });
      console.log('✅ Attempt 1 SUCCESS:', response1.data);
    } catch (error1) {
      attempts.push({ method: 'Basic Auth USSD', success: false, error: error1.response?.data || error1.message });
      console.log('❌ Attempt 1 FAILED:', error1.response?.data || error1.message);
    }

    // Attempt 2: Token-based approach
    try {
      console.log('🔄 Attempt 2: Token-based USSD...');
      const tokenResponse = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        {},
        {
          headers: {
            'api-key': process.env.CLICKPESA_API_KEY,
            'client-id': process.env.CLICKPESA_CLIENT_ID
          }
        }
      );

      const token = tokenResponse.data.token;
      console.log('✅ Token obtained');

      const response2 = await axios.post(
        'https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request',
        {
          amount: amount.toString(),
          currency: 'TZS',
          orderReference: `TOKEN_${Date.now()}`,
          phoneNumber: formattedPhone
        },
        {
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json'
          },
          timeout: 30000
        }
      );
      attempts.push({ method: 'Token-based USSD', success: true, response: response2.data });
      console.log('✅ Attempt 2 SUCCESS:', response2.data);
    } catch (error2) {
      attempts.push({ method: 'Token-based USSD', success: false, error: error2.response?.data || error2.message });
      console.log('❌ Attempt 2 FAILED:', error2.response?.data || error2.message);
    }

    // Attempt 3: Alternative endpoint
    try {
      console.log('🔄 Attempt 3: Alternative endpoint...');
      const response3 = await axios.post(
        'https://api.clickpesa.com/v1/payments',
        {
          customer: { phone_number: formattedPhone },
          payment: {
            amount: amount,
            currency: 'TZS',
            payment_method: 'mobile_money',
            payment_type: 'ussd_push'
          },
          order_reference: `ALT_${Date.now()}`
        },
        {
          headers: {
            'Authorization': `Bearer ${process.env.CLICKPESA_API_KEY}`,
            'X-Client-Id': process.env.CLICKPESA_CLIENT_ID,
            'Content-Type': 'application/json'
          },
          timeout: 30000
        }
      );
      attempts.push({ method: 'Alternative endpoint', success: true, response: response3.data });
      console.log('✅ Attempt 3 SUCCESS:', response3.data);
    } catch (error3) {
      attempts.push({ method: 'Alternative endpoint', success: false, error: error3.response?.data || error3.message });
      console.log('❌ Attempt 3 FAILED:', error3.response?.data || error3.message);
    }

    res.status(200).json({
      success: true,
      phone: formattedPhone,
      amount: amount,
      attempts,
      message: 'USSD test completed - check your phone!',
      note: 'If you see USSD prompt, enter your PIN to complete payment'
    });

  } catch (error) {
    console.error('❌ Direct USSD Error:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
