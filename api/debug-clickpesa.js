const axios = require('axios');

module.exports = async (req, res) => {
  try {
    console.log('🔍 DEBUGGING CLICKPESA API');
    
    // Check environment variables
    const clientId = process.env.CLICKPESA_CLIENT_ID;
    const apiKey = process.env.CLICKPESA_API_KEY;
    
    console.log('✅ Environment Variables:');
    console.log('   Client ID:', clientId ? 'SET' : 'MISSING');
    console.log('   Client ID Value:', clientId);
    console.log('   API Key:', apiKey ? 'SET' : 'MISSING');
    console.log('   API Key Length:', apiKey?.length || 0);
    console.log('   API Key Preview:', apiKey?.substring(0, 10) + '...');
    
    // Test 1: Direct API call with different formats
    console.log('\n🧪 Test 1: Original format');
    try {
      const response1 = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        {},
        {
          headers: {
            'api-key': apiKey,
            'client-id': clientId,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('✅ SUCCESS:', response1.data);
      return res.json({
        success: true,
        method: 'original',
        data: response1.data
      });
    } catch (error1) {
      console.log('❌ FAILED:', error1.response?.status, error1.response?.data || error1.message);
    }
    
    // Test 2: URL encoded
    console.log('\n🧪 Test 2: URL encoded');
    try {
      const encodedApiKey = encodeURIComponent(apiKey);
      const encodedClientId = encodeURIComponent(clientId);
      
      const response2 = await axios.post(
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
      console.log('✅ SUCCESS:', response2.data);
      return res.json({
        success: true,
        method: 'url_encoded',
        data: response2.data
      });
    } catch (error2) {
      console.log('❌ FAILED:', error2.response?.status, error2.response?.data || error2.message);
    }
    
    // Test 3: Different endpoint
    console.log('\n🧪 Test 3: Different endpoint');
    try {
      const response3 = await axios.post(
        'https://api.clickpesa.com/v1/auth/token',
        {
          client_id: clientId,
          api_key: apiKey
        },
        {
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('✅ SUCCESS:', response3.data);
      return res.json({
        success: true,
        method: 'different_endpoint',
        data: response3.data
      });
    } catch (error3) {
      console.log('❌ FAILED:', error3.response?.status, error3.response?.data || error3.message);
    }
    
    // Test 4: Basic auth
    console.log('\n🧪 Test 4: Basic auth');
    try {
      const auth = Buffer.from(`${clientId}:${apiKey}`).toString('base64');
      const response4 = await axios.post(
        'https://api.clickpesa.com/third-parties/generate-token',
        {},
        {
          headers: {
            'Authorization': `Basic ${auth}`,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('✅ SUCCESS:', response4.data);
      return res.json({
        success: true,
        method: 'basic_auth',
        data: response4.data
      });
    } catch (error4) {
      console.log('❌ FAILED:', error4.response?.status, error4.response?.data || error4.message);
    }
    
    // All tests failed
    res.status(500).json({
      success: false,
      error: 'All authentication methods failed',
      env_status: {
        client_id: clientId ? 'SET' : 'MISSING',
        api_key: apiKey ? 'SET' : 'MISSING',
        client_id_value: clientId,
        api_key_length: apiKey?.length || 0
      },
      note: 'Check ClickPesa account status and API permissions'
    });
    
  } catch (error) {
    console.error('❌ DEBUG ERROR:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
