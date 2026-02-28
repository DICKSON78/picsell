const axios = require('axios');
const crypto = require('crypto');

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

    console.log('📱 CORRECT ClickPesa USSD Test');
    console.log('   Phone:', formattedPhone);
    console.log('   Amount:', amount);

    // Step 1: Generate Token (Correct Format)
    console.log('🔑 Step 1: Generating token...');
    const tokenResponse = await axios.post(
      'https://api.clickpesa.com/third-parties/generate-token',
      {},
      {
        headers: {
          'X-API-Key': process.env.CLICKPESA_API_KEY,
          'X-Client-Id': process.env.CLICKPESA_CLIENT_ID
        }
      }
    );

    const token = tokenResponse.data.token;
    console.log('✅ Token obtained:', token ? 'SUCCESS' : 'FAILED');

    // Step 2: Generate Checksum
    const orderReference = `DUKASELL_${Date.now()}`;
    const payload = {
      amount: amount.toString(),
      currency: 'TZS',
      orderReference,
      phoneNumber: formattedPhone
    };
    
    const checksum = crypto.createHmac('sha256', process.env.CLICKPESA_CLIENT_ID)
      .update(JSON.stringify(payload))
      .digest('hex');

    console.log('🔐 Checksum generated:', checksum.substring(0, 10) + '...');

    // Step 3: Initiate USSD Push (Correct Endpoint)
    console.log('📤 Step 3: Initiating USSD push...');
    const ussdResponse = await axios.post(
      'https://api.clickpesa.com/third-parties/payments/initiate-ussd-push-request',
      {
        amount: amount.toString(),
        currency: 'TZS',
        orderReference,
        phoneNumber: formattedPhone,
        checksum
      },
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );

    console.log('✅ USSD Push Response:', ussdResponse.data);

    res.status(200).json({
      success: true,
      message: 'USSD Push sent successfully!',
      transaction: ussdResponse.data,
      phone: formattedPhone,
      amount: amount,
      note: 'CHECK YOUR PHONE NOW - USSD should appear!'
    });

  } catch (error) {
    console.error('❌ Correct USSD Error:', error.response?.data || error.message);
    
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data',
      status: error.response?.status
    });
  }
};
