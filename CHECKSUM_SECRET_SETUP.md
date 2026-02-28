# 🔑 ClickPesa Checksum Secret Configuration Guide

## 🎯 Problem Identified

Your payment system fails because the **Checksum Secret** is missing from your environment configuration.

### What is Checksum Secret?

According to ClickPesa official documentation (https://docs.clickpesa.com/home/checksum):

- **Checksum Secret** is a unique key generated in your ClickPesa merchant account
- It's **different from** API Key and Client ID
- It's required to generate HMAC-SHA256 checksums for payment requests
- Without it, the ClickPesa API rejects all payment requests with "Invalid checksum"

## ✅ Solution: Get Your Checksum Secret

### Step 1: Login to ClickPesa Merchant Dashboard

1. Visit: https://merchant.clickpesa.com
2. Login with your merchant credentials

### Step 2: Find API Settings

Navigate to:

- **Settings** → **API Configuration** (or similar)
- Look for **"Checksum Secret"** or **"Checksum Key"**
- The Checksum Secret should be displayed (often looks like: `chk_xxxxxxxxxxxxxxxxxxxxx`)

### Step 3: Add to Environment Variables

Add to your `.env` file:

```
CLICKPESA_CHECKSUM_SECRET=chk_xxxxxxxxxxxxxxxxxxxxx
```

Replace `chk_xxxxxxxxxxxxxxxxxxxxx` with your actual Checksum Secret from the dashboard.

### Step 4: Regenerate API Tokens

**⚠️ IMPORTANT**: After changing checksum settings, you MUST regenerate your API tokens:

1. Go back to ClickPesa merchant dashboard
2. Find **"Regenerate Tokens"** or **"Reset API Keys"** option
3. Copy the new tokens
4. Update your environment variables if needed

## 🧪 Testing After Configuration

Once you have the Checksum Secret configured:

### Test 1: Direct API Test

```bash
cd /home/dickson/Documents/Work/dukasell
node direct_api_test.js
```

Expected output:

```
✅ SUCCESS! Preview API worked!
Response: { ... payment preview data ... }
```

### Test 2: Payment Initiation Test

```bash
node test_ussd_push.js
```

Expected output:

```
✅ USSD Push initiated successfully!
Check your phone for the USSD message!
```

### Test 3: Backend Test

```bash
cd backend
node test_clickpesa.js
```

## 📋 Checksum Algorithm (FYI)

The code now uses the correct algorithm from ClickPesa docs:

```javascript
function canonicalize(obj) {
  // Recursively sort all object keys alphabetically
  if (obj === null || typeof obj !== "object") return obj;
  if (Array.isArray(obj)) {
    return obj.map(canonicalize);
  }
  return Object.keys(obj)
    .sort()
    .reduce((acc, key) => {
      acc[key] = canonicalize(obj[key]);
      return acc;
    }, {});
}

// Canonicalize payload
const canonicalPayload = canonicalize(payload);

// Serialize to JSON (no extra whitespace)
const payloadString = JSON.stringify(canonicalPayload);

// Generate HMAC-SHA256
const checksum = crypto
  .createHmac("sha256", checksumSecret)
  .update(payloadString)
  .digest("hex");
```

## 🔗 Useful Links

- **ClickPesa Checksum Documentation**: https://docs.clickpesa.com/home/checksum
- **Checksum Demo Repository**: https://github.com/ClickPesa/clickpesa-api-checksum-demo
- **ClickPesa Merchant Dashboard**: https://merchant.clickpesa.com
- **ClickPesa API Docs**: https://docs.clickpesa.com

## 📝 Files Updated

- ✅ `/backend/src/services/clickpesaService.js` - Updated `generateChecksum()` method
- ✅ Configuration now looks for `CLICKPESA_CHECKSUM_SECRET` environment variable

## ⚠️ If Checksum Secret Not Found

If you can't find the Checksum Secret in your merchant dashboard:

1. **Contact ClickPesa Support**:
   - Email: support@clickpesa.com
   - Tell them: "I need to enable checksum for my API account"

2. **Check if checksum is enabled**:
   - Some accounts may have checksum disabled by default
   - Ask ClickPesa to enable checksum feature
   - Then a Checksum Secret will be generated

3. **Alternatively**, ask if checksum can be disabled for your account:
   - Some older accounts might not require it
   - But ClickPesa recommends enabling it for security

## 🎯 Next Steps

1. Find your Checksum Secret in ClickPesa merchant dashboard
2. Add it to `.env`: `CLICKPESA_CHECKSUM_SECRET=your_secret_here`
3. Regenerate API tokens in ClickPesa dashboard
4. Run the test scripts to verify
5. Test payment flow in Flutter app

---

**Status**: 🎯 **Code is ready! Just needs the Checksum Secret configured.**
