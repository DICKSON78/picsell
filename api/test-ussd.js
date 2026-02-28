// Simplified USSD test without database dependencies
const axios = require('axios');

module.exports = async (req, res) => {
  try {
    const { packageId, phoneNumber, paymentMethod } = req.body;
    
    // Package pricing
    const packages = {
      pack_10: { credits: 10, price: 12000 },
      pack_25: { credits: 25, price: 24000 },
      pack_50: { credits: 50, price: 43000 },
      pack_100: { credits: 100, price: 72000 },
    };

    const selectedPackage = packages[packageId];
    if (!selectedPackage) {
      return res.status(400).json({ error: 'Invalid package' });
    }

    // Format phone number
    let formattedPhone = phoneNumber;
    if (phoneNumber.startsWith('07')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    } else if (phoneNumber.startsWith('0')) {
      formattedPhone = '255' + phoneNumber.substring(1);
    }

    // Generate order reference
    const orderReference = `CRED_${Date.now()}`;

    // Test ClickPesa API call
    const clickpesaResponse = await axios.post(
      'https://api.clickpesa.com/v1/payments/preview',
      {
        amount: selectedPackage.price,
        currency: 'TZS',
        payment_method: 'mobile_money',
        customer: {
          phone: formattedPhone,
          email: 'test@example.com'
        },
        order_reference: orderReference
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${process.env.CLICKPESA_API_KEY}`,
          'X-Client-Id': process.env.CLICKPESA_CLIENT_ID
        }
      }
    );

    res.status(200).json({
      success: true,
      orderReference,
      paymentInitiated: true,
      package: selectedPackage,
      phoneNumber: formattedPhone,
      clickpesaResponse: clickpesaResponse.data,
      message: 'USSD push test completed'
    });

  } catch (error) {
    console.error('USSD Test Error:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      details: error.response?.data || 'No response data'
    });
  }
};
