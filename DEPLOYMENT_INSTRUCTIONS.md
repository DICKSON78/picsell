# 🚀 Vercel Deployment Instructions - DukaSell

## Files Created/Updated

### 1. API Endpoints
- ✅ `api/credits.js` - Handles payment creation and balance
- ✅ `api/webhook.js` - Handles ClickPesa webhooks (already existed)

### 2. Configuration
- ✅ `package.json` - Dependencies for backend
- ✅ `vercel.json` - Updated routes for Vercel deployment
- ✅ `.env` - Environment variables template

### 3. Flutter App Updates
- ✅ Updated API URL to `https://dukasell.vercel.app/api`

## Next Steps for Deployment

### 1. Update ClickPesa Credentials
Edit your `.env` file with REAL ClickPesa credentials:
```env
CLICKPESA_CLIENT_ID=your_real_client_id_here
CLICKPESA_API_KEY=your_real_api_key_here
```

### 2. Deploy to Vercel
```bash
# Push to GitHub first
git add .
git commit -m "Add Vercel API endpoints for payments"
git push origin main

# Then deploy to Vercel
vercel --prod
```

### 3. Configure ClickPesa Webhook
Login to ClickPesa Merchant Portal:
- URL: https://merchant.clickpesa.com
- Username: augustinodickson78@gmail.com
- Password: 0675919794@Das

Set webhook URL to: `https://dukasell.vercel.app/webhook/clickpesa`

### 4. Test the Payment Flow
1. Open Flutter app
2. Go to Credits screen
3. Enter phone number (e.g., 0678960706)
4. Select mobile money payment
5. Check console logs for phone formatting
6. Verify USSD push is received

## Current Status

### ✅ Fixed Issues
1. Phone number formatting (07XXXXXXXX → 255XXXXXXXXX)
2. API endpoints created for Vercel
3. Payment initiation logic fixed
4. Authorization header format corrected
5. Flutter app updated to use production URL

### ⚠️ Remaining Issues
1. Need real ClickPesa credentials in .env
2. Need to deploy to Vercel
3. Need to test USSD push functionality

## Debug Information

When you test payments, check console for:
```
📱 Phone verification:
   Original: 0678960706
   Formatted: 255678960706
```

## API Endpoints

### Production URLs
- Payment API: `https://dukasell.vercel.app/api/credits/create-payment`
- Balance API: `https://dukasell.vercel.app/api/credits/balance`
- Webhook: `https://dukasell.vercel.app/webhook/clickpesa`

### Request Format
```json
POST /api/credits/create-payment
{
  "packageId": "pack_25",
  "phoneNumber": "255678960706",
  "paymentMethod": "mobile_money"
}
```

### Response Format
```json
{
  "success": true,
  "orderReference": "CRED_123456789",
  "paymentInitiated": true,
  "paymentId": "clickpesa_payment_id",
  "message": "USSD push sent to your phone"
}
```

## Troubleshooting

### If No USSD Push:
1. Check ClickPesa credentials are correct
2. Verify phone number format (255XXXXXXXXX)
3. Check Vercel function logs
4. Verify webhook is configured in ClickPesa portal

### If API Errors:
1. Check Vercel deployment logs
2. Verify environment variables in Vercel dashboard
3. Check ClickPesa API status

---

**Status**: 🎯 **Ready for Deployment** - All code is ready, just need to deploy!
