const axios = require('axios');

module.exports = async (req, res) => {
  try {
    console.log('🔑 Testing ClickPesa Credentials...');
    console.log('Client ID:', process.env.CLICKPESA_CLIENT_ID);
    console.log('API Key Length:', process.env.CLICKPESA_API_KEY?.length || 0);
    
    // Test 1: Original format from documentation
    try {
      console.log('🧪 Test 1: Documentation format...');
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
      console.log('✅ Test 1 Success:', response1.data);
      return res.json({ success: true, method: 'doc_format', token: response1.data.token });
    } catch (error1) {
      console.log('❌ Test 1 Failed:', error1.message);
    }

    // Test 2: X- prefix format
    try {
      console.log('🧪 Test 2: X- prefix format...');
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
      console.log('✅ Test 2 Success:', response2.data);
      return res.json({ success: true, method: 'x_prefix', token: response2.data.token });
    } catch (error2) {
      console.log('❌ Test 2 Failed:', error2.message);
    }

    // Test 3: Lowercase format
    try {
      console.log('🧪 Test 3: Lowercase format...');
      const response3 = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        {},
        {
          headers: {
            'Api-Key': process.env.CLICKPESA_API_KEY,
            'Client-Id': process.env.CLICKPESA_CLIENT_ID
          }
        }
      );
      console.log('✅ Test 3 Success:', response3.data);
      return res.json({ success: true, method: 'capitalized', token: response3.data.token });
    } catch (error3) {
      console.log('❌ Test 3 Failed:', error3.message);
    }

    // Test 4: Basic Auth format
    try {
      console.log('🧪 Test 4: Basic Auth format...');
      const auth = Buffer.from(`${process.env.CLICKPESA_CLIENT_ID}:${process.env.CLICKPESA_API_KEY}`).toString('base64');
      const response4 = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        {},
        {
          headers: {
            'Authorization': `Basic ${auth}`
          }
        }
      );
      console.log('✅ Test 4 Success:', response4.data);
      return res.json({ success: true, method: 'basic_auth', token: response4.data.token });
    } catch (error4) {
      console.log('❌ Test 4 Failed:', error4.message);
    }

    res.status(500).json({
      success: false,
      error: 'All authentication methods failed',
      credentials: {
        clientId: process.env.CLICKPESA_CLIENT_ID ? 'SET' : 'MISSING',
        apiKey: process.env.CLICKPESA_API_KEY ? 'SET' : 'MISSING'
      }
    });

  } catch (error) {
    console.error('❌ Credentials Test Error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
};
