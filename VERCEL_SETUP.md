# Vercel Webhook Setup for ClickPesa

## 🎯 Webhook URL (Vercel)

### Production URL
```
https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa
```

## 📋 ClickPesa Event Types Configured

### ✅ Payment Events
- **PAYMENT RECEIVED** - Payment completed successfully
- **PAYMENT FAILED** - Payment failed

### ✅ Payout Events  
- **PAYOUT INITIATED** - Payout started processing
- **PAYOUT REFUNDED** - Payout was refunded
- **PAYOUT REVERSED** - Payout was reversed

## 📋 Vercel Setup Steps

### 1. Create Vercel Account
- Go to: https://vercel.com
- Sign up with GitHub
- Install Vercel GitHub app

### 2. Prepare Project Structure
```
dukasell/
├── api/
│   └── webhook.js          # Webhook handler (updated)
├── backend/
│   └── src/
│       └── models/
│           ├── Transaction.js
│           └── User.js
├── vercel.json             # Vercel configuration
└── package.json
```

### 3. Deploy to Vercel

#### Method 1: Git Integration
```bash
# Push to GitHub
git add .
git commit -m "Add ClickPesa webhook with all event types"
git push origin main

# Deploy via Vercel dashboard
# 1. Go to vercel.com
# 2. Click "New Project"
# 3. Select your repository
# 4. Configure settings
# 5. Deploy
```

#### Method 2: Vercel CLI
```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
vercel --prod
```

### 4. Configure Environment Variables
In Vercel dashboard:
1. Go to **Settings** → **Environment Variables**
2. Add these variables:
   ```
   MONGODB_URI=mongodb://localhost:27017/dukasell
   JWT_SECRET=your_jwt_secret_here
   CLICKPESA_CLIENT_ID=your_clickpesa_client_id
   CLICKPESA_API_KEY=your_clickpesa_api_key
   WEBHOOK_SECRET=your_webhook_secret
   ```

## 🎯 ClickPesa Configuration

### 1. Login to ClickPesa Merchant Portal
- URL: https://merchant.clickpesa.com
- Username: augustinodickson78@gmail.com
- Password: 0675919794@Das

### 2. Add Webhook URLs
1. Navigate to **Settings** → **Webhooks**
2. Click **Add New Webhook** for each event:

#### PAYMENT RECEIVED
```
Event: PAYMENT RECEIVED
URL: https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa
```

#### PAYMENT FAILED
```
Event: PAYMENT FAILED  
URL: https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa
```

#### PAYOUT INITIATED
```
Event: PAYOUT INITIATED
URL: https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa
```

#### PAYOUT REFUNDED
```
Event: PAYOUT REFUNDED
URL: https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa
```

#### PAYOUT REVERSED
```
Event: PAYOUT REVERSED
URL: https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa
```

3. Click **Save** for each webhook

## 🧪 Test Webhook Events

### 1. Payment Received Test
```bash
curl -X POST https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa \
  -H "Content-Type: application/json" \
  -d '{
    "eventType": "PAYMENT RECEIVED",
    "orderReference": "TEST_PAYMENT_123",
    "status": "SUCCESS",
    "amount": "24000",
    "paymentMethod": "mobile_money",
    "customer": {"id": "test_user", "phone": "255712345678"},
    "timestamp": "2024-02-27T09:00:00Z"
  }'
```

### 2. Payment Failed Test
```bash
curl -X POST https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa \
  -H "Content-Type: application/json" \
  -d '{
    "eventType": "PAYMENT FAILED",
    "orderReference": "TEST_PAYMENT_456",
    "status": "FAILED",
    "amount": "24000",
    "paymentMethod": "mobile_money",
    "customer": {"id": "test_user", "phone": "255712345678"},
    "timestamp": "2024-02-27T09:00:00Z"
  }'
```

### 3. Payout Initiated Test
```bash
curl -X POST https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa \
  -H "Content-Type: application/json" \
  -d '{
    "eventType": "PAYOUT INITIATED",
    "orderReference": "TEST_PAYOUT_789",
    "status": "PROCESSING",
    "payout": {"amount": "50000", "method": "mobile_money"},
    "timestamp": "2024-02-27T09:00:00Z"
  }'
```

## 📊 Webhook Event Handling

### PAYMENT RECEIVED
- ✅ **Adds credits** to user account
- ✅ **Updates transaction** to 'completed'
- ✅ **Logs payment** details
- ✅ **Sends notification** (if implemented)

### PAYMENT FAILED
- ✅ **Updates transaction** to 'failed'
- ✅ **Logs error** details
- ✅ **No credits** added
- ✅ **User can retry** payment

### PAYOUT INITIATED
- ✅ **Updates payout** to 'processing'
- ✅ **Deducts credits** from user
- ✅ **Logs payout** details
- ✅ **Tracks admin** payouts

### PAYOUT REFUNDED
- ✅ **Refunds credits** to user
- ✅ **Updates payout** to 'refunded'
- ✅ **Logs refund** details
- ✅ **Maintains audit** trail

### PAYOUT REVERSED
- ✅ **Reverses credits** to user
- ✅ **Updates payout** to 'reversed'
- ✅ **Logs reversal** details
- ✅ **Financial** reconciliation

## 🔍 Check Vercel Logs

### 1. Function Logs
1. Go to Vercel dashboard
2. Click on "picsell" project
3. Go to **Functions** tab
4. Check webhook logs for:
   - "ClickPesa Webhook Received:"
   - "Payment received successfully:"
   - "Payment failed:"
   - "Payout initiated:"
   - "Payout refunded:"
   - "Payout reversed:"

### 2. Real-time Monitoring
```bash
# Install Vercel CLI
npm install -g vercel

# Watch logs in real-time
vercel logs --follow
```

## 📈 Transaction Status Flow

### Payment Flow
```
pending → webhook(PAYMENT RECEIVED) → completed
pending → webhook(PAYMENT FAILED) → failed
```

### Payout Flow
```
pending → webhook(PAYOUT INITIATED) → processing
processing → webhook(PAYOUT REFUNDED) → refunded
processing → webhook(PAYOUT REVERSED) → reversed
```

## 🎯 Quick Checklist

- [ ] Deploy updated webhook to Vercel
- [ ] Configure all 5 webhook events in ClickPesa
- [ ] Test each event type
- [ ] Verify transaction status updates
- [ ] Check credit additions/refunds
- [ ] Monitor Vercel function logs
- [ ] Test end-to-end payment flow

---

**All ClickPesa events implemented! 🚀**

**Webhook URL: `https://dickson78s-projects-picsell.vercel.app/webhook/clickpesa`** 🎯
