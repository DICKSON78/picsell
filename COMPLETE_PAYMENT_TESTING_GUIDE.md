# 💳 Complete Payment Testing Guide

## 🚀 Before You Start

Make sure you have configured:

1. ✅ ClickPesa Client ID - **Already configured**
2. ✅ ClickPesa API Key - **Already configured**
3. ❌ **ClickPesa Checksum Secret - MISSING** (See `CHECKSUM_SECRET_SETUP.md`)

## 📋 Payment Flow Overview

```
User enters phone → Flutter app → Backend API → ClickPesa API → USSD Push to Phone
                                                        ↓
                                                 Checksum validation
                                                        ↓
                                                   Success/Failure
```

## 🧪 Test 1: Environment Setup Check

### Command:

```bash
cd /home/dickson/Documents/Work/dukasell
node -e "
require('dotenv').config();
console.log('✅ CLICKPESA_CLIENT_ID:', process.env.CLICKPESA_CLIENT_ID ? 'SET' : 'MISSING');
console.log('✅ CLICKPESA_API_KEY:', process.env.CLICKPESA_API_KEY ? 'SET' : 'MISSING');
console.log('❌ CLICKPESA_CHECKSUM_SECRET:', process.env.CLICKPESA_CHECKSUM_SECRET ? 'SET' : 'MISSING');
"
```

### Expected Output:

```
✅ CLICKPESA_CLIENT_ID: SET
✅ CLICKPESA_API_KEY: SET
❌ CLICKPESA_CHECKSUM_SECRET: MISSING  ← This is what we need to fix!
```

---

## 🧪 Test 2: Token Generation

After you get the Checksum Secret, run:

```bash
node direct_api_test.js
```

### Expected Output:

```
🧪 Direct API Test with Correct Checksum

✅ Token obtained
📋 Payload with checksum:
{
  "amount": "1000",
  "currency": "TZS",
  "orderReference": "DIRECT_TEST_xxxx",
  "phoneNumber": "255678960706",
  "checksum": "abc123def456..."
}

🔄 Calling Preview API...
✅ SUCCESS! Preview API worked!
Response: { ... payment data ... }
```

---

## 🧪 Test 3: Payment Preview

```bash
node backend/test_clickpesa.js
```

### What it tests:

1. ✅ Environment variables
2. ✅ Token generation
3. ✅ Exchange rate retrieval
4. ✅ Payment preview (without actual USSD)
5. ✅ Payment initiation (sends REAL USSD push)

### Expected Output:

```
🧪 Testing ClickPesa Integration...

1️⃣ Checking environment variables...
   CLICKPESA_CLIENT_ID: ✅ Set
   CLICKPESA_API_KEY: ✅ Set

2️⃣ Testing token generation...
   ✅ Token generated successfully

3️⃣ Testing exchange rate...
   ✅ Exchange rate retrieved: 2500

4️⃣ Testing payment preview...
   ✅ Payment preview successful
   Response: { ... }

5️⃣ Testing payment initiation...
   ✅ USSD Push initiated successfully!
   Payment ID: xxxxx
   Status: PROCESSING
   🎉 USSD Push should appear on phone: 255678960706
```

---

## 🧪 Test 4: Full Payment Flow (Flutter App)

### Prerequisites:

- [ ] Checksum Secret configured in `.env`
- [ ] API Key and Client ID set
- [ ] Backend tests passing
- [ ] Flutter app running on device

### Steps:

1. Open Flutter app → Credits screen
2. Select a package (e.g., "25 Credits")
3. Enter phone number: `0678960706`
4. Select "Mobile Money" payment
5. Watch console for:
   ```
   📱 Phone formatting: 0678960706 → 255678960706
   🔐 Checksum: abc123def456...
   📤 Sending payment request to ClickPesa
   ✅ USSD Push sent!
   ```
6. **Check your phone** for USSD message

---

## ⚠️ Troubleshooting

### Issue 1: "CLICKPESA_CHECKSUM_SECRET not configured"

**Solution**: See `CHECKSUM_SECRET_SETUP.md`

### Issue 2: Token Error (401 Unauthorized)

**Cause**: Invalid API Key or Client ID
**Solution**:

- Verify credentials in ClickPesa merchant dashboard
- Ensure they're copied correctly to `.env` (no extra spaces)

### Issue 3: "Invalid checksum"

**Cause**: Wrong Checksum Secret
**Solution**:

- Double-check Checksum Secret in merchant dashboard
- Make sure you regenerated tokens after enabling checksum
- Check that no extra spaces in `.env`

### Issue 4: Payment initiated but no USSD appears

**Cause**: Could be several things:

- [ ] Phone number format incorrect
- [ ] Phone not registered for mobile money
- [ ] Network issues
- [ ] Payment amount too large/small

**Test**:

```bash
# Test with small amount (1000 TZS) and known active number
node test_ussd_push.js
```

### Issue 5: "HMAC validation failed" after webhook

**Cause**: Webhook signature verification issue
**Solution**: Make sure webhook secret is set in `.env` and matches ClickPesa dashboard

---

## 📊 Complete Checklist

- [ ] ClickPesa Client ID configured ✅
- [ ] ClickPesa API Key configured ✅
- [ ] ClickPesa Checksum Secret obtained from dashboard
- [ ] Checksum Secret added to `.env`
- [ ] API tokens regenerated in ClickPesa dashboard
- [ ] Backend environment test passes
- [ ] Token generation test passes
- [ ] Payment preview test passes
- [ ] Payment initiation test passes (USSD received)
- [ ] Flutter app payment flow tested
- [ ] Webhook signature verified
- [ ] Production credentials configured for Vercel

---

## 🚀 Next Steps

1. **Get Checksum Secret** from ClickPesa merchant dashboard
2. **Add to .env**: `CLICKPESA_CHECKSUM_SECRET=your_secret`
3. **Run tests** in order:
   - `direct_api_test.js`
   - `backend/test_clickpesa.js`
   - `test_ussd_push.js`
4. **Test in Flutter app**
5. **Deploy to Vercel** when all tests pass

---

## 📞 Support

If you get stuck:

1. Check `CHECKSUM_SECRET_SETUP.md`
2. Review ClickPesa docs: https://docs.clickpesa.com/home/checksum
3. Contact ClickPesa support: support@clickpesa.com
4. Check payment system logs in console

---

**Status**: 🎯 **All code ready! Just needs Checksum Secret configured!**
