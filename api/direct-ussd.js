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

    console.log('📱 Testing direct USSD push...');
    console.log('   Original:', phoneNumber);
    console.log('   Formatted:', formattedPhone);
    console.log('   Amount:', amount);

    // Try different ClickPesa endpoints
    const endpoints = [
      {
        url: 'https://api.clickpesa.com/v1/ussd-push',
        method: 'post',
        data: {
          phone_number: formattedPhone,
          amount: amount,
          currency: 'TZS'
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${process.env.CLICKPESA_API_KEY}`,
          'X-Client-Id': process.env.CLICKPESA_CLIENT_ID
        }
      },
      {
        url: 'https://api.clickpesa.com/third-parties/ussd-push',
        method: 'post',
        data: {
          phoneNumber: formattedPhone,
          amount: amount,
          currency: 'TZS'
        },
        headers: {
          'Content-Type': 'application/json',
          'api-key': process.env.CLICKPESA_API_KEY,
          'client-id': process.env.CLICKPESA_CLIENT_ID
        }
      }
    ];

    let lastError = null;
    
    for (const endpoint of endpoints) {
      try {
        console.log(`🔄 Trying: ${endpoint.url}`);
        
        const response = await axios[endpoint.method](endpoint.url, endpoint.data, {
          headers: endpoint.headers,
          timeout: 10000
        });

        console.log('✅ Success:', response.data);
        
        return res.status(200).json({
          success: true,
          endpoint: endpoint.url,
          response: response.data,
          message: 'USSD push initiated successfully'
        });

      } catch (error) {
        console.log(`❌ Failed: ${endpoint.url} - ${error.message}`);
        lastError = error;
        continue;
      }
    }

    // All endpoints failed
    throw lastError;

  } catch (error) {
    console.error('❌ Direct USSD Error:', error.response?.data || error.message);
    
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data',
      status: error.response?.status
    });
  }
};
