const axios = require("axios");
const crypto = require("crypto");
const User = require("../models/User");
const Transaction = require("../models/Transaction");

class ClickPesaService {
  constructor() {
    this.clientId = process.env.CLICKPESA_CLIENT_ID;
    this.apiKey = process.env.CLICKPESA_API_KEY;
    this.baseUrl = "https://api.clickpesa.com/third-parties";
    this.token = null;
    this.tokenExpiry = null;
  }

  // Generate JWT token for API authentication
  async generateToken() {
    try {
      const response = await axios.post(
        `${this.baseUrl}/generate-token`,
        {},
        {
          headers: {
            "api-key": this.apiKey,
            "client-id": this.clientId,
            "Content-Type": "application/json",
          },
        },
      );

      if (response.data.success) {
        // Token already includes "Bearer " prefix, so use it as is
        this.token = response.data.token;
        // Token expires in 1 hour (3600 seconds)
        this.tokenExpiry = Date.now() + 3600000;
        return this.token;
      }
      throw new Error("Failed to generate ClickPesa token");
    } catch (error) {
      console.error(
        "ClickPesa Token Generation Error:",
        error.response?.data || error.message,
      );
      throw new Error("Failed to generate ClickPesa token");
    }
  }

  // Get valid token or generate new one
  async getValidToken() {
    if (!this.token || Date.now() >= this.tokenExpiry) {
      await this.generateToken();
    }
    return this.token;
  }

  // Generate checksum for security
  generateChecksum(data) {
    // IMPORTANT: The checksum key is a separate "Checksum Secret" from ClickPesa merchant dashboard
    // See: https://docs.clickpesa.com/home/checksum
    // If CLICKPESA_CHECKSUM_SECRET is not set, the API will still require checksum
    // but you need to get the secret from your ClickPesa merchant account settings

    const checksumKey = process.env.CLICKPESA_CHECKSUM_SECRET;

    if (!checksumKey) {
      throw new Error(
        "CLICKPESA_CHECKSUM_SECRET not configured. " +
          "Please set the Checksum Secret from your ClickPesa merchant dashboard in the .env file. " +
          "See: https://docs.clickpesa.com/home/checksum",
      );
    }

    // Canonicalize the payload recursively for consistent ordering
    const canonicalPayload = this.canonicalize(data);

    // Serialize the canonical payload
    const payloadString = JSON.stringify(canonicalPayload);

    // Create HMAC with SHA256
    const hmac = crypto.createHmac("sha256", checksumKey);
    hmac.update(payloadString);
    return hmac.digest("hex");
  }

  // Canonicalize object recursively
  canonicalize(obj) {
    if (obj === null || typeof obj !== "object") return obj;
    if (Array.isArray(obj)) {
      return obj.map((item) => this.canonicalize(item));
    }
    return Object.keys(obj)
      .sort()
      .reduce((acc, key) => {
        acc[key] = this.canonicalize(obj[key]);
        return acc;
      }, {});
  }

  // Preview USSD payment
  async previewPayment(phoneNumber, amount, orderReference) {
    try {
      const token = await this.getValidToken();
      const amountStr = amount.toString();
      const data = {
        amount: amountStr,
        currency: "TZS",
        orderReference,
        phoneNumber,
        checksum: this.generateChecksum({
          amount: amountStr,
          currency: "TZS",
          orderReference,
          phoneNumber,
        }),
      };

      const response = await axios.post(
        `${this.baseUrl}/payments/preview-ussd-push-request`,
        data,
        {
          headers: {
            Authorization: token,
            "Content-Type": "application/json",
          },
        },
      );

      // Check if response has the expected structure
      if (response.data) {
        return {
          success: true,
          ...response.data,
        };
      } else {
        throw new Error("Invalid response format from ClickPesa");
      }
    } catch (error) {
      console.error(
        "ClickPesa Preview Error:",
        error.response?.data || error.message,
      );
      throw new Error(
        "Failed to preview payment: " +
          (error.response?.data?.message || error.message),
      );
    }
  }

  // Initiate USSD payment
  async initiatePayment(phoneNumber, amount, orderReference) {
    try {
      const token = await this.getValidToken();
      const amountStr = amount.toString();
      const data = {
        amount: amountStr,
        currency: "TZS",
        orderReference,
        phoneNumber,
        checksum: this.generateChecksum({
          amount: amountStr,
          currency: "TZS",
          orderReference,
          phoneNumber,
        }),
      };

      const response = await axios.post(
        `${this.baseUrl}/payments/initiate-ussd-push-request`,
        data,
        {
          headers: {
            Authorization: token,
            "Content-Type": "application/json",
          },
        },
      );

      // Check if response has the expected structure
      if (response.data && response.data.id) {
        return {
          success: true,
          paymentId: response.data.id,
          status: response.data.status,
          channel: response.data.channel,
          orderReference: response.data.orderReference,
          collectedAmount: response.data.collectedAmount,
          collectedCurrency: response.data.collectedCurrency,
          createdAt: response.data.createdAt,
          clientId: response.data.clientId,
        };
      } else {
        throw new Error("Invalid response format from ClickPesa");
      }
    } catch (error) {
      console.error(
        "ClickPesa Payment Error:",
        error.response?.data || error.message,
      );
      throw new Error(
        "Failed to initiate payment: " +
          (error.response?.data?.message || error.message),
      );
    }
  }

  // Check payment status
  async checkPaymentStatus(orderReference) {
    try {
      const token = await this.getValidToken();

      const response = await axios.get(
        `${this.baseUrl}/payments/query-all-payments?orderReference=${orderReference}`,
        {
          headers: {
            Authorization: token,
            "Content-Type": "application/json",
          },
        },
      );

      return response.data;
    } catch (error) {
      console.error(
        "ClickPesa Status Check Error:",
        error.response?.data || error.message,
      );
      throw new Error("Failed to check payment status");
    }
  }

  // Get ClickPesa account balance
  async getBalance() {
    try {
      const token = await this.getValidToken();

      const response = await axios.get(`${this.baseUrl}/account/balance`, {
        headers: {
          Authorization: token,
          "Content-Type": "application/json",
        },
      });

      return response.data;
    } catch (error) {
      console.error(
        "ClickPesa Balance Error:",
        error.response?.data || error.message,
      );
      throw new Error("Failed to get ClickPesa balance");
    }
  }

  // Preview Card Payment
  async previewCardPayment(amount, orderReference) {
    try {
      const token = await this.getValidToken();
      const data = {
        amount: amount.toString(),
        currency: "USD",
        orderReference,
        checksum: this.generateChecksum({
          amount,
          currency: "USD",
          orderReference,
        }),
      };

      const response = await axios.post(
        `${this.baseUrl}/payments/preview-card-payment`,
        data,
        {
          headers: {
            Authorization: token,
            "Content-Type": "application/json",
          },
        },
      );

      return response.data;
    } catch (error) {
      console.error(
        "ClickPesa Preview Card Payment Error:",
        error.response?.data || error.message,
      );
      throw new Error("Failed to preview card payment");
    }
  }

  // Initiate Card Payment
  async initiateCardPayment(amount, orderReference, customerId) {
    try {
      const token = await this.getValidToken();
      const data = {
        amount: amount.toString(),
        currency: "USD",
        orderReference,
        customer: {
          id: customerId,
        },
        checksum: this.generateChecksum({
          amount,
          currency: "USD",
          orderReference,
          customer: { id: customerId },
        }),
      };

      const response = await axios.post(
        `${this.baseUrl}/payments/initiate-card-payment`,
        data,
        {
          headers: {
            Authorization: token,
            "Content-Type": "application/json",
          },
        },
      );

      return response.data;
    } catch (error) {
      console.error(
        "ClickPesa Initiate Card Payment Error:",
        error.response?.data || error.message,
      );
      throw new Error("Failed to initiate card payment");
    }
  }

  // Get real-time exchange rate from Bank of Tanzania
  async getExchangeRate() {
    try {
      // Bank of Tanzania API for exchange rates
      const response = await axios.get(
        "https://www.bot.go.tz/api/exchangerates",
      );
      const rates = response.data;

      // Get TZS to USD rate
      if (rates && rates.rates && rates.rates.USD) {
        return rates.rates.USD;
      }

      // Fallback to default rate if API fails
      console.warn("Failed to get exchange rate, using fallback");
      return 2500;
    } catch (error) {
      console.error("Exchange Rate Error:", error);
      return 2500; // Fallback rate
    }
  }

  // Convert TZS to USD with real-time rate
  async convertTzsToUsd(tzsAmount) {
    const exchangeRate = await this.getExchangeRate();
    return Math.round((tzsAmount / exchangeRate) * 100) / 100; // Round to 2 decimal places
  }

  // Save user CRDB bank details
  async saveUserBankDetails(userId, bankDetails) {
    try {
      // This would typically save to database
      // For now, we'll use a simple in-memory storage
      const User = require("../models/User");
      await User.findByIdAndUpdate(userId, {
        bankDetails: {
          accountNumber: bankDetails.accountNumber,
          accountName: bankDetails.accountName,
          bankName: "CRDB",
          isDefault: bankDetails.isDefault || false,
          savedAt: new Date(),
        },
      });

      return { success: true };
    } catch (error) {
      console.error("Save Bank Details Error:", error);
      throw new Error("Failed to save bank details");
    }
  }

  // Get user saved bank details
  async getUserBankDetails(userId) {
    try {
      const User = require("../models/User");
      const user = await User.findById(userId);

      if (!user || !user.bankDetails) {
        return null;
      }

      return user.bankDetails;
    } catch (error) {
      console.error("Get Bank Details Error:", error);
      throw new Error("Failed to get bank details");
    }
  }

  // Process CRDB bank payment
  async processCRDBPayment(userId, amount, orderReference) {
    try {
      const bankDetails = await this.getUserBankDetails(userId);

      if (!bankDetails || bankDetails.bankName !== "CRDB") {
        throw new Error("No CRDB bank details found");
      }

      // In a real implementation, you would integrate with CRDB API
      // For now, we'll simulate the bank payment
      const paymentData = {
        accountNumber: bankDetails.accountNumber,
        accountName: bankDetails.accountName,
        bankName: "CRDB",
        amount: amount,
        currency: "TZS",
        orderReference,
        timestamp: new Date(),
      };

      // Simulate bank API call
      await new Promise((resolve) => setTimeout(resolve, 2000));

      return {
        success: true,
        transactionId: `CRDB_${Date.now()}`,
        status: "completed",
        paymentData,
      };
    } catch (error) {
      console.error("CRDB Payment Error:", error);
      throw new Error("Failed to process CRDB payment");
    }
  }

  // Webhook handler for ClickPesa payment notifications
  async handleWebhook(req, res) {
    try {
      const {
        eventType, // ClickPesa event type
        orderReference,
        status,
        amount,
        paymentMethod,
        customer,
        payout,
        timestamp,
      } = req.body;

      console.log("ClickPesa Webhook Received:", {
        eventType,
        orderReference,
        status,
        amount,
        paymentMethod,
        customer,
        payout,
        timestamp,
      });

      // Handle different ClickPesa events
      switch (eventType) {
        case "PAYMENT RECEIVED":
          await this.handlePaymentReceived(req.body);
          break;

        case "PAYMENT FAILED":
          await this.handlePaymentFailed(req.body);
          break;

        case "PAYOUT INITIATED":
          await this.handlePayoutInitiated(req.body);
          break;

        case "PAYOUT REFUNDED":
          await this.handlePayoutRefunded(req.body);
          break;

        case "PAYOUT REVERSED":
          await this.handlePayoutReversed(req.body);
          break;

        default:
          console.log("Unknown event type:", eventType);
          break;
      }

      // Send response to ClickPesa
      res.status(200).json({
        success: true,
        message: "Webhook received successfully",
      });
    } catch (error) {
      console.error("Webhook Error:", error);
      res.status(500).json({
        success: false,
        error: "Webhook processing failed",
      });
    }
  }

  // Handle payment received event
  async handlePaymentReceived(data) {
    const {
      orderReference,
      status,
      amount,
      paymentMethod,
      customer,
      timestamp,
    } = data;

    // Find pending transaction
    const Transaction = require("../models/Transaction");
    const User = require("../models/User");
    const transaction = await Transaction.findOne({
      orderReference,
      status: "pending",
    });

    if (transaction) {
      // Update transaction status
      transaction.status = "completed";
      transaction.completedAt = new Date();
      transaction.finalAmount = amount;
      transaction.webhookData = { status, customer, timestamp };
      await transaction.save();

      // Add credits to user
      const user = await User.findById(transaction.userId);
      if (user) {
        user.credits += transaction.credits;
        user.totalSpent += amount / 100; // Convert to TZS if needed
        await user.save();
      }

      console.log("Payment received successfully:", orderReference);
    }
  }

  // Handle payment failed event
  async handlePaymentFailed(data) {
    const {
      orderReference,
      status,
      amount,
      paymentMethod,
      customer,
      timestamp,
    } = data;

    // Update transaction status to failed
    const Transaction = require("../models/Transaction");
    const transaction = await Transaction.findOne({
      orderReference,
      status: "pending",
    });

    if (transaction) {
      transaction.status = "failed";
      transaction.error = "Payment failed";
      transaction.webhookData = { status, customer, timestamp };
      await transaction.save();
    }

    console.log("Payment failed:", orderReference);
  }

  // Handle payout initiated event
  async handlePayoutInitiated(data) {
    const { orderReference, status, payout, timestamp } = data;

    // Find payout transaction
    const Transaction = require("../models/Transaction");
    const User = require("../models/User");
    const transaction = await Transaction.findOne({
      orderReference,
      type: "payout",
      status: "pending",
    });

    if (transaction) {
      // Update transaction status
      transaction.status = "processing";
      transaction.payoutData = payout;
      transaction.webhookData = { status, payout, timestamp };
      await transaction.save();
    }

    console.log("Payout initiated:", orderReference);
  }

  // Handle payout refunded event
  async handlePayoutRefunded(data) {
    const { orderReference, status, payout, timestamp } = data;

    // Find payout transaction
    const Transaction = require("../models/Transaction");
    const User = require("../models/User");
    const transaction = await Transaction.findOne({
      orderReference,
      type: "payout",
      status: "processing",
    });

    if (transaction) {
      // Update transaction status
      transaction.status = "refunded";
      transaction.payoutData = payout;
      transaction.webhookData = { status, payout, timestamp };
      await transaction.save();

      // Add credits back to user (refund)
      const user = await User.findById(transaction.userId);
      if (user) {
        user.credits += transaction.credits; // Refund credits
        await user.save();
      }
    }

    console.log("Payout refunded:", orderReference);
  }

  // Handle payout reversed event
  async handlePayoutReversed(data) {
    const { orderReference, status, payout, timestamp } = data;

    // Find payout transaction
    const Transaction = require("../models/Transaction");
    const User = require("../models/User");
    const transaction = await Transaction.findOne({
      orderReference,
      type: "payout",
      status: "processing",
    });

    if (transaction) {
      // Update transaction status
      transaction.status = "reversed";
      transaction.payoutData = payout;
      transaction.webhookData = { status, payout, timestamp };
      await transaction.save();

      // Add credits back to user (reverse)
      const user = await User.findById(transaction.userId);
      if (user) {
        user.credits += transaction.credits; // Reverse credits
        await user.save();
      }
    }

    console.log("Payout reversed:", orderReference);
  }

  // Generate webhook signature (if needed)
  generateWebhookSignature(payload, secret) {
    const crypto = require("crypto");
    return crypto
      .createHmac("sha256", secret)
      .update(JSON.stringify(payload))
      .digest("hex");
  }
}

module.exports = new ClickPesaService();
