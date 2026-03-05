const axios = require('axios');

module.exports = async (req, res) => {
  try {
    console.log('🔍 CLICKPESA AUTH DEBUG');
    
    const clientId = process.env.CLICKPESA_CLIENT_ID;
    const apiKey = process.env.CLICKPESA_API_KEY;
    
    console.log('🔑 Credentials Check:');
    console.log('   Client ID:', clientId);
    console.log('   API Key:', apiKey?.substring(0, 10) + '...');
    console.log('   API Key Length:', apiKey?.length || 0);
    
    // Test 1: Check if credentials are valid format
    console.log('\n🧪 Test 1: Basic connection test');
    try {
      const response1 = await axios.get('https://api.clickpesa.com/v1/auth/status');
      console.log('✅ API reachable:', response1.data);
    } catch (error1) {
      console.log('❌ API not reachable:', error1.message);
    }
    
    // Test 2: Try different auth methods
    console.log('\n🧪 Test 2: Token generation (v1/auth/token)');
    try {
      const response2 = await axios.post(
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
      console.log('✅ v1/auth/token SUCCESS:', response2.data);
      
      // If successful, try USSD
      const token = response2.data.token;
      console.log('\n🧪 Test 3: USSD with valid token');
      try {
        const ussdResponse = await axios.post(
          'https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request',
          {
            amount: '1000',
            currency: 'TZS',
            orderReference: `DEBUG_${Date.now()}`,
            phoneNumber: '255678960706'
          },
          {
            headers: {
              'Authorization': token.startsWith('Bearer ') ? token : `Bearer ${token}`,
              'Content-Type': 'application/json'
            }
          }
        );
        console.log('✅ USSD SUCCESS:', ussdResponse.data);
        return res.json({
          success: true,
          message: 'ClickPesa working!',
          auth: response2.data,
          ussd: ussdResponse.data
        });
      } catch (ussdError) {
        console.log('❌ USSD failed:', ussdError.response?.data || ussdError.message);
      }
      
    } catch (error2) {
      console.log('❌ v1/auth/token FAILED:', error2.response?.status, error2.response?.data || error2.message);
    }
    
    // Test 3: Try original endpoint
    console.log('\n🧪 Test 4: Original endpoint (third-parties/generate-token)');
    try {
      const response3 = await axios.post(
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
      console.log('✅ Original endpoint SUCCESS:', response3.data);
    } catch (error3) {
      console.log('❌ Original endpoint FAILED:', error3.response?.status, error3.response?.data || error3.message);
    }
    
    // Test 4: Check account status
    console.log('\n🧪 Test 5: Account status check');
    try {
      const response4 = await axios.get(
        'https://api.clickpesa.com/v1/account/status',
        {
          headers: {
            'Authorization': `Basic ${Buffer.from(`${clientId}:${apiKey}`).toString('base64')}`
          }
        }
      );
      console.log('✅ Account status:', response4.data);
    } catch (error4) {
      console.log('❌ Account status failed:', error4.response?.status, error4.response?.data || error4.message);
    }
    
    res.status(500).json({
      success: false,
      error: 'All authentication methods failed',
      credentials: {
        client_id: clientId ? 'SET' : 'MISSING',
        api_key: apiKey ? 'SET' : 'MISSING',
        api_key_length: apiKey?.length || 0
      },
      diagnosis: 'Account may not be verified or API keys may be invalid',
      next_steps: [
        'Check ClickPesa merchant portal for account status',
        'Look for verification emails',
        'Contact ClickPesa support: support@clickpesa.com'
      ]
    });
    
  } catch (error) {
    console.error('❌ DEBUG ERROR:', error.message);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
