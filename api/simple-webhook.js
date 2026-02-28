module.exports = async (req, res) => {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    console.log('📥 ClickPesa Webhook Received');
    console.log('Body:', JSON.stringify(req.body, null, 2));
    
    const { 
      eventType,           // ClickPesa event type
      orderReference,      // Order reference
      status,             // Payment status
      amount,             // Amount
      paymentMethod,       // Payment method
      customer,           // Customer details
      timestamp           // Timestamp
    } = req.body;

    console.log(`🎯 Event: ${eventType}`);
    console.log(`📋 Order: ${orderReference}`);
    console.log(`💰 Amount: ${amount}`);
    console.log(`📱 Status: ${status}`);

    // Handle different event types
    switch (eventType) {
      case 'PAYMENT RECEIVED':
        console.log('✅ Payment received successfully');
        break;
        
      case 'PAYMENT FAILED':
        console.log('❌ Payment failed');
        break;
        
      case 'PAYOUT INITIATED':
        console.log('🔄 Payout initiated');
        break;
        
      case 'PAYOUT REFUNDED':
        console.log('💸 Payout refunded');
        break;
        
      case 'PAYOUT REVERSED':
        console.log('🔄 Payout reversed');
        break;
        
      default:
        console.log(`❓ Unknown event: ${eventType}`);
    }

    // Send success response
    res.status(200).json({
      success: true,
      message: 'Webhook processed successfully',
      eventType,
      orderReference,
      status,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Webhook Error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
