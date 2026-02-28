#!/usr/bin/env node
require("dotenv").config();
const crypto = require("crypto");

// Test different checksum algorithms
const testData = {
  amount: "24000",
  currency: "TZS",
  orderReference: "TEST_123456",
  phoneNumber: "255712345678",
};

const checksumSecret = process.env.CLICKPESA_CHECKSUM_SECRET;
console.log("Checksum Secret:", checksumSecret);
console.log("Test Data:", testData, "\n");

// Method 1: Canonical JSON + HMAC
console.log("Method 1: Canonical JSON + HMAC-SHA256");
const canonicalPayload = JSON.stringify(sortObject(testData));
console.log("Payload:", canonicalPayload);
const checksum1 = crypto
  .createHmac("sha256", checksumSecret)
  .update(canonicalPayload)
  .digest("hex");
console.log("Checksum:", checksum1, "\n");

// Method 2: Pipe separated values
console.log("Method 2: Pipe-separated values + HMAC-SHA256");
const values = Object.values(testData).join("|");
console.log("Payload:", values);
const checksum2 = crypto
  .createHmac("sha256", checksumSecret)
  .update(values)
  .digest("hex");
console.log("Checksum:", checksum2, "\n");

// Method 3: Amount|Currency|OrderRef|Phone
console.log("Method 3: Amount|Currency|OrderRef|Phone + HMAC-SHA256");
const payload3 = `${testData.amount}|${testData.currency}|${testData.orderReference}|${testData.phoneNumber}`;
console.log("Payload:", payload3);
const checksum3 = crypto
  .createHmac("sha256", checksumSecret)
  .update(payload3)
  .digest("hex");
console.log("Checksum:", checksum3, "\n");

// Method 4: Base64 encoding
console.log("Method 4: Canonical JSON + Base64 + HMAC-SHA256");
const base64Payload = Buffer.from(canonicalPayload).toString("base64");
console.log("Payload (B64):", base64Payload);
const checksum4 = crypto
  .createHmac("sha256", checksumSecret)
  .update(base64Payload)
  .digest("hex");
console.log("Checksum:", checksum4, "\n");

function sortObject(obj) {
  return Object.keys(obj)
    .sort()
    .reduce((acc, key) => {
      acc[key] = obj[key];
      return acc;
    }, {});
}

console.log(
  "Try each checksum above in ClickPesa API and let me know which one works!",
);
