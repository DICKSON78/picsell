# Firebase Environment Variable Fix for Vercel

## Problem Found ❌
The Vercel logs show:
```
Firebase initialization error: Failed to parse private key: Error: Invalid PEM formatted message.
```

This means your `FIREBASE_PRIVATE_KEY` environment variable in Vercel is not properly formatted.

## Root Cause
The private key from your Firebase service account JSON needs to be properly formatted when storing in Vercel. The newline characters (`\n`) need to be preserved as literal `\n` strings, not converted to actual newlines.

## How to Fix

### Step 1: Get Your Firebase Service Account JSON
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your **dukasell** project
3. Go to **Project Settings** (gear icon)
4. Click on **Service Accounts** tab
5. Click **Generate New Private Key** button
6. This downloads a JSON file

### Step 2: Extract and Format the Private Key
The downloaded JSON file looks like:
```json
{
  "type": "service_account",
  "project_id": "dukasell-xxx",
  "private_key_id": "xxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG...\n-----END PRIVATE KEY-----\n",
  ...
}
```

**Copy the value of `private_key`** (it includes the `\n` characters as literal text).

### Step 3: Update Vercel Environment Variables

Run this command to update the private key:
```bash
vercel env add FIREBASE_PRIVATE_KEY
```

When prompted to enter the value, **paste the entire private key string** including:
- `-----BEGIN PRIVATE KEY-----\n`
- All the base64 content
- `\n-----END PRIVATE KEY-----\n`

The value should look like:
```
-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCsKQbPvbAZ...(long base64 string)...4ScG1gMQA==\n-----END PRIVATE KEY-----\n
```

### Step 4: Set Other Firebase Variables
Run these commands to update the other Firebase environment variables:

```bash
vercel env add FIREBASE_PROJECT_ID
vercel env add FIREBASE_PRIVATE_KEY_ID
vercel env add FIREBASE_CLIENT_EMAIL
vercel env add FIREBASE_CLIENT_ID
```

For each one, copy the corresponding value from your Firebase service account JSON file.

### Step 5: Deploy
Once all variables are updated, run:
```bash
git add -A
git commit -m "Update Firebase environment variables in Vercel"
git push
```

This triggers Vercel to redeploy with the correct environment variables.

### Step 6: Verify
Check the logs again:
```bash
vercel logs --expand --limit=5
```

You should see:
```
✅ Firebase Admin SDK initialized successfully
```

## Important Notes
- **Do NOT edit `.env` file** - Vercel will read from the dashboard variables
- **The private key MUST start with** `-----BEGIN PRIVATE KEY-----` 
- **The private key MUST end with** `-----END PRIVATE KEY-----`
- **Keep the `\n` as literal text** (not actual newlines) in the environment variable

## Troubleshooting
If you still get "Invalid PEM formatted" error:
1. Verify you copied the ENTIRE private key string (it's usually very long)
2. Make sure no quotes were accidentally included
3. Regenerate a new private key from Firebase Console
4. Paste it exactly as-is into Vercel

## Testing Payment After Fix
1. Log in to the app
2. Go to Credits screen
3. Enter phone number
4. Click "Continue to Payment"
5. If successful, you should see the ClickPesa USSD push request
6. Check logs: `vercel logs --expand --limit=5`
