# OTP Payment Implementation Guide

## Overview

Replaced authentication requirement for payments with a simple OTP (One-Time Password) verification system. Users can now pay without logging in by verifying their phone number with an OTP.

## Changes Made

### Backend (api/index.js)

#### 1. **OTP Generation & Storage**

- Added `generateAndSendOTP(phoneNumber)` function
- Generates 6-digit OTP valid for 10 minutes
- Stores OTP in memory with expiry tracking
- Logs OTP in development mode for testing

```javascript
// Example: OTP expires after 10 minutes
const expiryTime = Date.now() + 10 * 60 * 1000;
```

#### 2. **OTP Verification**

- Added `verifyOTP(phoneNumber, otp)` function
- Validates OTP against stored value
- Tracks failed attempts (max 3)
- Deletes OTP after successful verification
- Returns user-friendly error messages

#### 3. **New API Endpoints**

**POST /api/otp/request**

```json
Request:
{
  "phoneNumber": "0654321098"
}

Response:
{
  "success": true,
  "message": "OTP sent to your phone",
  "phoneNumber": "255654321098",
  "testOtp": "123456" // Only in development
}
```

**POST /api/otp/verify**

```json
Request:
{
  "phoneNumber": "0654321098",
  "otp": "123456"
}

Response (Success):
{
  "success": true,
  "phoneNumber": "255654321098"
}

Response (Error):
{
  "success": false,
  "error": "Invalid OTP",
  "attemptsLeft": 2
}
```

#### 4. **Modified Payment Endpoint**

**POST /api/credits/create-payment**

- Now supports both authenticated and unauthenticated payments
- For unauthenticated users: requires `otp` field
- For authenticated users: optional OTP (uses auth token)

```json
// Unauthenticated payment request
{
  "packageId": "pack_25",
  "phoneNumber": "0654321098",
  "paymentMethod": "mobile_money",
  "otp": "123456"  // Required for unauthenticated users
}

// Authenticated payment request (OTP optional)
{
  "packageId": "pack_25",
  "phoneNumber": "0654321098",
  "paymentMethod": "mobile_money"
  // Authorization header with token
}
```

### Frontend (Flutter)

#### 1. **API Service Updates**

Added to `ApiService` class:

```dart
// Request OTP
Future<Map<String, dynamic>> requestOTP(String phoneNumber)

// Verify OTP
Future<Map<String, dynamic>> verifyOTP({
  required String phoneNumber,
  required String otp,
})

// Updated createPayment to support OTP
Future<Map<String, dynamic>> createPayment({
  required String packageId,
  String? phoneNumber,
  required String paymentMethod,
  String? payerName,
  String? otp,  // NEW: Optional OTP parameter
})
```

#### 2. **New OTP Verification Dialog**

Created `widgets/otp_verification_dialog.dart`:

- Clean UI for entering 6-digit OTP
- Supports English and Swahili
- Resend OTP functionality with cooldown timer
- Input validation and error handling
- Loading state during verification

#### 3. **Updated Payment Flow**

In `screens/credits_screen.dart`:

**Old Flow (Authenticated Only):**

```
Login → Select Payment → Enter Phone → Process Payment
```

**New Flow (Supports Both):**

```
┌─ Logged In User
│  → Refresh Token → Select Payment → Enter Phone → Process Payment
│
└─ Not Logged In User
   → Select Payment → Enter Phone → Request OTP → Enter OTP → Process Payment
```

## Payment Flow Diagram

```
START
  ↓
Is User Logged In?
  ├─ YES → Refresh Auth Token
  │        ↓
  │        Process Payment with Token
  │        ↓
  │        PAYMENT SENT
  │
  └─ NO → Request OTP
           ↓
           User Enters Phone
           ↓
           OTP Sent (SMS/USSD)
           ↓
           User Enters OTP
           ↓
           Verify OTP
           ↓
           Process Payment with OTP
           ↓
           PAYMENT SENT
```

## Security Considerations

### Current Implementation

- ✅ Phone number verification with OTP
- ✅ 10-minute OTP expiry
- ✅ 3 failed attempt limit
- ✅ OTP deleted after use
- ✅ No password/authentication required for payments

### For Production

1. **SMS Integration**
   - Replace console logging with actual SMS provider
   - Recommended: Twilio, Africa's Talking, or local provider

   ```javascript
   // Example: Africa's Talking
   const AfricasTalking = require("africastalking");
   const sms = AfricasTalking({ apiKey: "YOUR_API_KEY" }).SMS;
   await sms.send({
     recipients: [formattedPhone],
     message: `Your OTP: ${otp}`,
   });
   ```

2. **OTP Storage**
   - Replace in-memory Map with Redis for distributed systems
   - ```javascript
     // Example: Redis
     await redis.setex(`otp_${phoneNumber}`, 600, otp);
     const storedOtp = await redis.get(`otp_${phoneNumber}`);
     ```

   ```

   ```

3. **Rate Limiting**
   - Add rate limiting to prevent OTP spam
   - Limit OTP requests per phone: 3 requests per hour
   - Limit OTP verification attempts: 3 per OTP

4. **Fraud Detection**
   - Track repeated failed verifications
   - Alert on suspicious patterns
   - Implement IP-based restrictions if needed

5. **Audit Logging**
   - Log all OTP requests and verifications
   - Track which phone numbers are used for payments
   - Monitor for abuse patterns

## Testing

### Manual Testing Steps

1. **Request OTP**

   ```bash
   curl -X POST https://dukasell.vercel.app/api/otp/request \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber": "0654321098"}'
   ```

2. **Verify OTP**

   ```bash
   curl -X POST https://dukasell.vercel.app/api/otp/verify \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber": "0654321098", "otp": "123456"}'
   ```

3. **Create Payment with OTP**
   ```bash
   curl -X POST https://dukasell.vercel.app/api/credits/create-payment \
     -H "Content-Type: application/json" \
     -d '{
       "packageId": "pack_25",
       "phoneNumber": "0654321098",
       "paymentMethod": "mobile_money",
       "otp": "123456"
     }'
   ```

### Development Mode

- In development, OTP is logged in console
- Use the logged OTP for testing
- Set `NODE_ENV=production` to disable OTP logging

## Files Modified

### Backend

- `/api/index.js` - Added OTP functions and endpoints

### Frontend

- `/customer_flutter/lib/services/api_service.dart` - Added OTP methods
- `/customer_flutter/lib/screens/credits_screen.dart` - Added OTP payment flow
- `/customer_flutter/lib/widgets/otp_verification_dialog.dart` - New OTP dialog widget

## Benefits

✅ **User-Friendly**

- No need to create account/login for payments
- Quick verification with OTP
- Works with any phone number

✅ **Secure**

- Phone number verification before payment
- OTP expires after 10 minutes
- Limited failed attempts

✅ **Simple**

- Minimal data required (just phone number)
- No password management
- No account creation needed

✅ **Flexible**

- Logged-in users can still use their auth token
- Support for guest payments
- Works for new and existing customers

## Next Steps (Optional)

1. Integrate real SMS provider for OTP delivery
2. Add Redis for distributed OTP storage
3. Implement rate limiting per phone number
4. Add fraud detection logging
5. Create admin dashboard for payment monitoring
6. Add email notifications for payments
7. Implement push notifications to app
