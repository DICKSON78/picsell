#!/bin/bash

# Firebase Service Account JSON Formatter
# This script helps format your Firebase service account JSON for Vercel environment variables

if [ -z "$1" ]; then
    echo "Usage: bash format-firebase-key.sh <path-to-service-account.json>"
    echo ""
    echo "Example:"
    echo "  bash format-firebase-key.sh ~/Downloads/dukasell-firebase.json"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: File not found: $1"
    exit 1
fi

echo "📄 Reading Firebase service account JSON..."

# Extract all required values
PROJECT_ID=$(jq -r '.project_id' "$1")
PRIVATE_KEY_ID=$(jq -r '.private_key_id' "$1")
PRIVATE_KEY=$(jq -r '.private_key' "$1")
CLIENT_EMAIL=$(jq -r '.client_email' "$1")
CLIENT_ID=$(jq -r '.client_id' "$1")
AUTH_URI=$(jq -r '.auth_uri' "$1")
TOKEN_URI=$(jq -r '.token_uri' "$1")
AUTH_PROVIDER_X509=$(jq -r '.auth_provider_x509_cert_url' "$1")
CLIENT_X509=$(jq -r '.client_x509_cert_url' "$1")

echo "✅ Extracted values from Firebase service account JSON"
echo ""
echo "========== VERCEL ENVIRONMENT VARIABLES =========="
echo ""
echo "Run these commands in your terminal:"
echo ""
echo "vercel env add FIREBASE_PROJECT_ID"
echo "# Then paste: $PROJECT_ID"
echo ""
echo "vercel env add FIREBASE_PRIVATE_KEY_ID"
echo "# Then paste: $PRIVATE_KEY_ID"
echo ""
echo "vercel env add FIREBASE_PRIVATE_KEY"
echo "# Then paste: $PRIVATE_KEY"
echo ""
echo "vercel env add FIREBASE_CLIENT_EMAIL"
echo "# Then paste: $CLIENT_EMAIL"
echo ""
echo "vercel env add FIREBASE_CLIENT_ID"
echo "# Then paste: $CLIENT_ID"
echo ""
echo "vercel env add FIREBASE_AUTH_URI"
echo "# Then paste: $AUTH_URI"
echo ""
echo "vercel env add FIREBASE_TOKEN_URI"
echo "# Then paste: $TOKEN_URI"
echo ""
echo "vercel env add FIREBASE_AUTH_PROVIDER_X509_CERT_URL"
echo "# Then paste: $AUTH_PROVIDER_X509"
echo ""
echo "vercel env add FIREBASE_CLIENT_X509_CERT_URL"
echo "# Then paste: $CLIENT_X509"
echo ""
echo "========== OR USE THIS SCRIPT TO ADD ALL AT ONCE =========="
echo ""
echo "To add all variables at once, save this output and run it:"
echo ""
echo "vercel env add FIREBASE_PROJECT_ID <<< '$PROJECT_ID'"
echo "vercel env add FIREBASE_PRIVATE_KEY_ID <<< '$PRIVATE_KEY_ID'"
echo "vercel env add FIREBASE_PRIVATE_KEY <<< \"\$'$PRIVATE_KEY'\""
echo "vercel env add FIREBASE_CLIENT_EMAIL <<< '$CLIENT_EMAIL'"
echo "vercel env add FIREBASE_CLIENT_ID <<< '$CLIENT_ID'"
echo "vercel env add FIREBASE_AUTH_URI <<< '$AUTH_URI'"
echo "vercel env add FIREBASE_TOKEN_URI <<< '$TOKEN_URI'"
echo "vercel env add FIREBASE_AUTH_PROVIDER_X509_CERT_URL <<< '$AUTH_PROVIDER_X509'"
echo "vercel env add FIREBASE_CLIENT_X509_CERT_URL <<< '$CLIENT_X509'"
echo ""
echo "========== DONE =========="
echo ""
echo "⚠️  WARNING: This script output contains your private key!"
echo "   Do NOT commit this output to git or share publicly!"
echo ""
