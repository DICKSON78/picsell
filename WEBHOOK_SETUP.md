# ClickPesa Webhook Setup Guide

## 🎯 Webhook URL

### Production URL (Recommended)
```
https://dukasell.onrender.com/webhook/clickpesa
```

### Local Development URL
```
http://localhost:5000/webhook/clickpesa
```

### Ngrok Testing URL
```
https://your-ngrok-id.ngrok.io/webhook/clickpesa
```

## 📋 Setup Instructions

### 1. Login to ClickPesa Merchant Portal
- Go to: https://merchant.clickpesa.com
- Login with your credentials:
  - Username: augustinodickson78@gmail.com
  - Password: 0675919794@Das

### 2. Configure Webhook
1. Navigate to **Settings** → **Webhooks**
2. Click **Add New Webhook**
3. Enter webhook URL: `https://dukasell.onrender.com/webhook/clickpesa`
4. Select events:
   - ✅ Payment Success
   - ✅ Payment Failed
   - ✅ Payment Pending (optional)
5. Click **Save**

### 3. Test Webhook
1. Use ClickPesa test tools
2. Make a test payment
3. Check if webhook receives notification
4. Verify transaction status updates

## 🔧 Environment Variables

Add to your `.env` file:
```env
# Webhook Configuration
WEBHOOK_SECRET=your_webhook_secret_here
WEBHOOK_URL=https://dukasell.onrender.com/webhook/clickpesa
```

## 🚀 Deployment Steps

### 1. Deploy to Render
```bash
# Push to GitHub
git add .
git commit -m "Add ClickPesa webhook support"
git push origin main

# Deploy to Render
# Your app will be available at: https://dukasell.onrender.com
```

### 2. Update ClickPesa Merchant Portal
- Login to merchant portal
- Update webhook URL to production URL
- Test webhook connectivity

### 3. Verify Webhook
- Make test payment
- Check server logs
- Verify credit addition

## 📊 Webhook Events

### Payment Success
```json
{
  "orderReference": "CRED_123456789",
  "status": "SUCCESS",
  "amount": "24000",
  "paymentMethod": "mobile_money",
  "customer": {
    "id": "user_123",
    "phone": "255712345678"
  },
  "timestamp": "2024-02-27T09:00:00Z"
}
```

### Payment Failed
```json
{
  "orderReference": "CRED_123456789",
  "status": "FAILED",
  "amount": "24000",
  "paymentMethod": "mobile_money",
  "customer": {
    "id": "user_123",
    "phone": "255712345678"
  },
  "timestamp": "2024-02-27T09:00:00Z"
}
```

## 🔍 Testing Webhook

### 1. Local Testing with Ngrok
```bash
# Start ngrok
ngrok http 5000

# Copy ngrok URL
# Update ClickPesa webhook to ngrok URL
```

### 2. Test Webhook Endpoint
```bash
# Test webhook manually
curl -X POST http://localhost:5000/webhook/clickpesa \
  -H "Content-Type: application/json" \
  -d '{
    "orderReference": "TEST_123",
    "status": "SUCCESS",
    "amount": "24000",
    "paymentMethod": "mobile_money",
    "customer": {"id": "test_user"},
    "timestamp": "2024-02-27T09:00:00Z"
  }'
```

### 3. Check Server Logs
```bash
# Check webhook logs
tail -f logs/app.log

# Look for:
# "ClickPesa Webhook Received:"
# "Payment completed successfully:"
# "Payment failed:"
```

## ⚠️ Important Notes

1. **HTTPS Required**: ClickPesa requires HTTPS webhook URLs
2. **Public Access**: Webhook must be publicly accessible
3. **Response Time**: Webhook should respond within 30 seconds
4. **Retry Logic**: ClickPesa will retry failed webhooks
5. **Security**: Use webhook secret for signature verification

## 🎯 Quick Setup Checklist

- [ ] Deploy app to production
- [ ] Get production webhook URL
- [ ] Login to ClickPesa merchant portal
- [ ] Configure webhook URL
- [ ] Select webhook events
- [ ] Test webhook connectivity
- [ ] Verify payment processing
- [ ] Monitor webhook logs

## 📞 Support

If you need help:
1. Check server logs for webhook errors
2. Verify webhook URL is accessible
3. Contact ClickPesa support for merchant portal issues
4. Check firewall/proxy settings

---

**Webhook URL: `https://dukasell.onrender.com/webhook/clickpesa`** 🚀
