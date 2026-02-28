const axios = require('axios');

module.exports = async (req, res) => {
  try {
    console.log('🔑 Testing ClickPesa API...');
    console.log('Client ID:', process.env.CLICKPESA_CLIENT_ID);
    console.log('API Key present:', process.env.CLICKPESA_API_KEY ? 'YES' : 'NO');

    // Test token generation
    const tokenResponse = await axios.post('https://api.clickpesa.com/third-parties/generate-token', {}, {
      headers: {
        'api-key': process.env.CLICKPESA_API_KEY.trim(),
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ Token Response:', tokenResponse.data);

    res.status(200).json({
      success: true,
      tokenResponse: tokenResponse.data,
      message: 'ClickPesa API connection successful'
    });

  } catch (error) {
    console.error('❌ ClickPesa Test Error:', error.response?.data || error.message);
    
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data',
      status: error.response?.status
    });
  }
};
