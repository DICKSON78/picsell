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

    console.log('📱 FINAL USSD ATTEMPT');
    console.log('   Phone:', formattedPhone);
    console.log('   Amount:', amount);
    console.log('   Client ID:', process.env.CLICKPESA_CLIENT_ID);
    console.log('   API Key Length:', process.env.CLICKPESA_API_KEY?.length || 0);

    // Try different header encodings
    const attempts = [];

    // Attempt 1: URL encoded headers
    try {
      console.log('🔄 Attempt 1: URL encoded headers...');
      const encodedApiKey = encodeURIComponent(process.env.CLICKPESA_API_KEY);
      const encodedClientId = encodeURIComponent(process.env.CLICKPESA_CLIENT_ID);
      
      const response1 = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        {},
        {
          headers: {
            'api-key': encodedApiKey,
            'client-id': encodedClientId,
            'Content-Type': 'application/json'
          }
        }
      );
      attempts.push({ method: 'URL encoded', success: true, response: response1.data });
      console.log('✅ Attempt 1 SUCCESS:', response1.data);
    } catch (error1) {
      attempts.push({ method: 'URL encoded', success: false, error: error1.response?.data || error1.message });
      console.log('❌ Attempt 1 FAILED:', error1.response?.data || error1.message);
    }

    // Attempt 2: Raw string without quotes
    try {
      console.log('🔄 Attempt 2: Raw headers...');
      const response2 = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        {},
        {
          headers: {
            'api-key': String(process.env.CLICKPESA_API_KEY),
            'client-id': String(process.env.CLICKPESA_CLIENT_ID),
            'Content-Type': 'application/json'
          }
        }
      );
      attempts.push({ method: 'Raw headers', success: true, response: response2.data });
      console.log('✅ Attempt 2 SUCCESS:', response2.data);
    } catch (error2) {
      attempts.push({ method: 'Raw headers', success: false, error: error2.response?.data || error2.message });
      console.log('❌ Attempt 2 FAILED:', error2.response?.data || error2.message);
    }

    // Attempt 3: JSON body with credentials
    try {
      console.log('🔄 Attempt 3: JSON body auth...');
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
      attempts.push({ method: 'JSON body auth', success: true, response: response3.data });
      console.log('✅ Attempt 3 SUCCESS:', response3.data);
    } catch (error3) {
      attempts.push({ method: 'JSON body auth', success: false, error: error3.response?.data || error3.message });
      console.log('❌ Attempt 3 FAILED:', error3.response?.data || error3.message);
    }

    // Attempt 4: Form data
    try {
      console.log('🔄 Attempt 4: Form data...');
      const FormData = require('form-data');
      const form = new FormData();
      form.append('client_id', process.env.CLICKPESA_CLIENT_ID);
      form.append('api_key', process.env.CLICKPESA_API_KEY);
      
      const response4 = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        form,
        {
          headers: {
            ...form.getHeaders()
          }
        }
      );
      attempts.push({ method: 'Form data', success: true, response: response4.data });
      console.log('✅ Attempt 4 SUCCESS:', response4.data);
    } catch (error4) {
      attempts.push({ method: 'Form data', success: false, error: error4.response?.data || error4.message });
      console.log('❌ Attempt 4 FAILED:', error4.response?.data || error4.message);
    }

    res.status(200).json({
      success: true,
      phone: formattedPhone,
      amount: amount,
      attempts,
      message: 'All USSD attempts completed',
      note: 'Check which attempt succeeded and try that method for actual USSD'
    });

  } catch (error) {
    console.error('❌ Final USSD Error:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
