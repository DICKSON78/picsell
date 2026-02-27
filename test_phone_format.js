#!/usr/bin/env node

/**
 * Test phone number formatting for ClickPesa
 */

// Phone number formatting function (same as in Flutter app)
function formatPhoneNumberForClickPesa(phone) {
  let cleanPhone = phone.replace(/ /g, '').replace(/-/g, '');
  
  // If starts with 0 and has 10 digits, convert to international format
  if (cleanPhone.startsWith('0') && cleanPhone.length === 10) {
    return '255' + cleanPhone.substring(1);
  }
  
  // If already in international format, return as is
  if (cleanPhone.startsWith('255') && cleanPhone.length === 12) {
    return cleanPhone;
  }
  
  // If starts with +, remove the +
  if (cleanPhone.startsWith('+255') && cleanPhone.length === 13) {
    return cleanPhone.substring(1);
  }
  
  return cleanPhone;
}

// Phone number validation function
function isValidPhoneNumber(phone) {
  let cleanPhone = phone.replace(/ /g, '').replace(/-/g, '');
  
  // Check for 10-digit format (starting with 0)
  if (/^0[0-9]{9}$/.test(cleanPhone)) {
    return true;
  }
  
  // Check for international format (255XXXXXXXXX)
  if (/^255[0-9]{9}$/.test(cleanPhone)) {
    return true;
  }
  
  return false;
}

console.log('📱 Testing Phone Number Formatting\n');

const testNumbers = [
  '0678960706',  // Your number
  '0712345678',  // Standard format
  '255712345678', // International format
  '+255712345678', // With plus
  '0654321098',  // Another provider
  '712345678',   // Invalid (missing 0)
  '07123456789', // Invalid (too many digits)
];

testNumbers.forEach(phone => {
  const isValid = isValidPhoneNumber(phone);
  const formatted = formatPhoneNumberForClickPesa(phone);
  
  console.log(`${isValid ? '✅' : '❌'} ${phone.padEnd(15)} → ${formatted.padEnd(15)} ${isValid ? '(Valid)' : '(Invalid)'}`);
});

console.log('\n🎯 Summary:');
console.log('✅ Valid numbers will be formatted to 255XXXXXXXXX');
console.log('❌ Invalid numbers will show error in app');
console.log('📱 Your number 0678960706 → 255678960706');
