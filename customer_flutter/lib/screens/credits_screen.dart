import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';
import '../models/shared_models.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../utils/theme.dart';
import '../widgets/bottom_nav_bar.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();
  int _selectedIndex = 2;
  int _selectedPaymentMethod = -1; // -1 = none selected, 0 = card, 1 = mobile money
  bool _isProcessing = false;

  void _showClickPesaBottomSheet() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isSwahili ? 'Malipo ya ClickPesa' : 'ClickPesa Payment',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Phone input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: isSwahili 
                    ? 'Ingiza namba ya simu (255712345678)' 
                    : 'Enter phone number (255712345678)',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                onChanged: (value) {
                  // Store phone number
                },
              ),
            ),
            
            // Instructions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili ? 'Hatua za Malipo:' : 'Payment Instructions:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSwahili 
                      ? '1. Ingiza namba ya simu yako.\n2. Bonyeza USSD utakapoke.\n3. Ingiza PIN kuthibitisha malipo.\n4. Subiri confirmation.' 
                      : '1. Enter your phone number.\n2. Wait for USSD prompt.\n3. Enter your PIN to confirm payment.\n4. Wait for confirmation.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[400]!),
                          ),
                          child: Text(
                            isSwahili ? 'Ghairi' : 'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _initiateClickPesaPayment();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            isSwahili ? 'Tuma Malipo' : 'Send Payment',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateClickPesaPayment() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      setState(() {
        _isProcessing = true;
      });

      // Create payment request
      final response = await _apiService.createPayment(
        packageId: 'pack_25', // Default to popular package
        phoneNumber: '255712345678', // Will be updated to get actual phone
      );

      if (response['success']) {
        _showPaymentInstructions(response['orderReference']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.isSwahili 
                ? 'Imeshindikwa: ${response['error']}' 
                : 'Payment failed: ${response['error']}',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isSwahili 
              ? 'Hitilafu: ${e.toString()}' 
              : 'Error: ${e.toString()}',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPaymentInstructions(String orderReference) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isSwahili ? 'Malipo Yanzoanzwa' : 'Payment Initiated',
          style: TextStyle(color: AppTheme.primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSwahili 
                ? 'Tafadhali angalia simu yako kwa USSD prompt.' 
                : 'Please check your phone for USSD prompt.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              isSwahili 
                ? 'Ingiza PIN kuthibitisha malipo.' 
                : 'Enter your PIN to complete payment.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili ? 'Namba ya Kumbukumbuko:' : 'Order Reference:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    orderReference,
                    style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkPaymentStatus(orderReference);
            },
            child: Text(
              isSwahili ? 'Sawa' : 'OK',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPaymentStatus(String orderReference) async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    try {
      final response = await _apiService.checkPaymentStatus(orderReference);
      
      if (response['success'] && response['status'] === 'SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Malipo yamekamilika!' : 'Payment completed successfully!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        
        // Refresh user data
        await auth.refreshUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Malipo bado yanaendelea...' : 'Payment still processing...',
            ),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSwahili ? 'Hitilafu: ${e.toString()}' : 'Error: ${e.toString()}',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handleCardPayment() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    try {
      setState(() {
        _isProcessing = true;
      });

      // Create ClickPesa card payment
      final response = await _apiService.createPayment(
        packageId: 'pack_25', // Default to popular package
        paymentMethod: 'card',
      );

      if (response['success']) {
        // Show card payment dialog with payment link
        _showClickPesaCardPaymentDialog(response);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.isSwahili 
                ? 'Imeshindikana: ${response['error']}' 
                : 'Payment failed: ${response['error']}',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isSwahili 
              ? 'Hitilafu: ${e.toString()}' 
              : 'Error: ${e.toString()}',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _handleCRDBPayment() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    try {
      setState(() {
        _isProcessing = true;
      });

      // Check if user has bank details
      final bankDetailsResponse = await _apiService.getBankDetails();
      
      if (!bankDetailsResponse['hasBankDetails']) {
        // Show save bank details dialog
        _showSaveBankDetailsDialog();
        return;
      }

      // Process CRDB payment
      final response = await _apiService.createPayment(
        packageId: 'pack_25', // Default to popular package
        paymentMethod: 'card',
      );

      if (response['success']) {
        // Show payment success dialog
        _showCRDBPaymentSuccessDialog(response);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.isSwahili 
                ? 'Imeshindikana: ${response['error']}' 
                : 'Payment failed: ${response['error']}',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isSwahili 
              ? 'Hitilafu: ${e.toString()}' 
              : 'Error: ${e.toString()}',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSaveBankDetailsDialog() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    final accountController = TextEditingController();
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isSwahili ? 'Hifadhi Maelezo ya Benki' : 'Save Bank Details',
          style: TextStyle(color: AppTheme.primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSwahili 
                ? 'Hifadhi maelezo ya CRDB bank yako kwa malipo rahisi.' 
                : 'Save your CRDB bank details for easy payments.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Account Number
            TextField(
              controller: accountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Namba ya Akaunti' : 'Account Number',
                hintText: '1234567890',
                prefixIcon: const Icon(Icons.account_balance, color: AppTheme.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isSwahili ? 'Namba ya akaunti inahitajika' : 'Account number is required';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                  return isSwahili ? 'Namba ya akaunti lazima kuwa tarakimu 10' : 'Account number must be 10 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Account Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Jina la Akaunti' : 'Account Name',
                hintText: 'John Doe',
                prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isSwahili ? 'Jina la akaunti linahitajika' : 'Account name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Bank Name (fixed to CRDB)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withAlpha(30)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'CRDB Bank',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSwahili 
                        ? 'Maelezo yako yatakuhifadhiwa salama na yatumetumika kwa malipo zote za baadaye.' 
                        : 'Your details will be saved securely and used for all future payments.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
              });
            },
            child: Text(
              isSwahili ? 'Ghairi' : 'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (accountController.text.isEmpty || nameController.text.isEmpty) {
                return;
              }
              
              try {
                setState(() {
                  _isProcessing = true;
                });
                
                // Save bank details
                final response = await _apiService.saveBankDetails(
                  accountNumber: accountController.text.trim(),
                  accountName: nameController.text.trim(),
                  bankName: 'CRDB',
                );
                
                if (response['success']) {
                  Navigator.pop(context);
                  _showBankDetailsSavedDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        localization.isSwahili 
                          ? 'Imeshindikana: ${response['error']}' 
                          : 'Failed to save bank details',
                      ),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      localization.isSwahili 
                        ? 'Hitilafu: ${e.toString()}' 
                        : 'Error: ${e.toString()}',
                    ),
                    backgroundColor: AppTheme.error,
                  ),
                );
              } finally {
                setState(() {
                  _isProcessing = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              isSwahili ? 'Hifadhi' : 'Save',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showBankDetailsSavedDialog() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSwahili ? 'Maelezo Yamehifadhiwa!' : 'Bank Details Saved!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili 
                ? 'Sasa unaweza kutumia malipo ya CRDB kwa urahisi.' 
                : 'You can now use CRDB bank payments for quick purchases.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleCRDBPayment(); // Retry payment after saving
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text(
                isSwahili ? 'Endelea na Malipo' : 'Continue to Payment',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCRDBPaymentSuccessDialog(Map<String, dynamic> paymentData) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSwahili ? 'Malipo Yamekamilika!' : 'Payment Completed!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili 
                ? 'Credits ${paymentData['credits']} zimeongezwa kwenye akaunti yako.' 
                : '${paymentData['credits']} credits have been added to your account.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili 
                ? 'Jumla: TZS ${paymentData['amount']}' 
                : 'Amount: TZS ${paymentData['amount']}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close payment sheet
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text(
                isSwahili ? 'Sawa' : 'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClickPesaCardPaymentDialog(Map<String, dynamic> paymentData) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isSwahili ? 'Malipo ya Kadi' : 'Card Payment',
          style: TextStyle(color: AppTheme.primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSwahili 
                ? 'Tafadhali bonyeza "Endelea na Malipo" ili kufungua ukurasa wa malipo.' 
                : 'Please click "Continue to Payment" to open payment page.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              isSwahili 
                ? 'Bei: $${paymentData['usdAmount']} USD (${paymentData['amount']} TZS)' 
                : 'Price: $${paymentData['usdAmount']} USD (${paymentData['amount']} TZS)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili 
                ? 'Credits: ${paymentData['credits']}' 
                : 'Credits: ${paymentData['credits']}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili ? 'Maelezo ya Malipo:' : 'Payment Details:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSwahili 
                      ? 'Namba ya Kumbukumbuko: ${paymentData['orderReference']}' 
                      : 'Order Reference: ${paymentData['orderReference']}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                  Text(
                    isSwahili 
                      ? 'Njia ya Malipo: ClickPesa Card Payment' 
                      : 'Payment Method: ClickPesa Card Payment',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isProcessing = false;
              });
            },
            child: Text(
              isSwahili ? 'Ghairi' : 'Cancel',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openClickPesaCardPayment(paymentData['cardPaymentLink']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              isSwahili ? 'Endelea na Malipo' : 'Continue to Payment',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _openClickPesaCardPayment(String paymentLink) async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    try {
      // In a real app, you would use url_launcher to open the payment link
      // For now, we'll show a dialog with the link
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            isSwahili ? 'Ukurasa wa Malipo' : 'Payment Page',
            style: TextStyle(color: AppTheme.primaryColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSwahili 
                  ? 'Tafadhali nukuuvi link hii kwenye browser: ' 
                  : 'Please copy this link to your browser: ',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  paymentLink,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSwahili 
                  ? 'Malipo yatakamilika baada ya kumaliza kwenye ukurasa wa ClickPesa.' 
                  : 'Payment will be completed after finishing on ClickPesa page.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startPaymentStatusCheck();
              },
              child: Text(
                isSwahili ? 'Sawa' : 'OK',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSwahili ? 'Hitilafu: ${e.toString()}' : 'Error: ${e.toString()}',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _startPaymentStatusCheck() {
    // Start checking payment status
    // In a real implementation, you would poll the payment status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Provider.of<LocalizationProvider>(context, listen: false).isSwahili
            ? 'Inasubiri malipo kukamilika...'
            : 'Waiting for payment completion...',
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isSwahili = localization.isSwahili;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Hero Section (Mobile Operator Style Balance)
                  _buildHeroSection(auth),

                  // Section title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isSwahili ? 'Chagua Kifurushi' : 'Pick a Package',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSwahili ? 'Ongeza krediti ili kuendelea' : 'Top up your credits to continue',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Credit packages - Real-time updates with StreamBuilder
                  StreamBuilder<List<PackageModel>>(
                    stream: _firestoreService.streamPackages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerPackages();
                      }

                      if (snapshot.hasError) {
                        return _buildEmptyState();
                      }

                      final packages = snapshot.data ?? [];

                      if (packages.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: packages.length,
                        itemBuilder: (context, index) {
                          final package = packages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CreditPackageCard(
                              title: package.name,
                              credits: package.credits,
                              price: package.price,
                              description: package.isPopular ? 'Best Seller' : 'Great Value',
                              isSwahili: isSwahili,
                              animalIndex: index,
                              onBuy: () {
                                _showPaymentBottomSheet(
                                  package.name,
                                  package.credits,
                                  package.price,
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom navigation
          BottomNavBar(
            activeIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _navigateToScreen(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(AuthProvider auth) {
    final user = auth.user;
    final credits = user?.credits ?? 0;
    final isSwahili = Provider.of<LocalizationProvider>(context, listen: false).isSwahili;

    return Stack(
      children: [
        // Full solid purple gradient — same family as Buy buttons
        Container(
          height: 260,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryLight,
                AppTheme.primaryColor,
                AppTheme.primaryDark,
              ],
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    Text(
                      isSwahili ? 'Salio Langu' : 'My Balance',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    // Placeholder to keep title centered
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Balance card — M-Pesa / voucher style
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 12)),
                  ],
                ),
                child: Column(
                  children: [
                    // Label
                    Text(
                      isSwahili ? 'SALIO LA CREDITS' : 'CREDITS BALANCE',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[400],
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Big balance number — like SIM card balance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(Icons.bolt_rounded, color: AppTheme.accentOrange, size: 36),
                        const SizedBox(width: 6),
                        Text(
                          '$credits',
                          style: GoogleFonts.poppins(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: credits > 0 ? AppTheme.text : AppTheme.error,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            isSwahili ? 'credits' : 'credits',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Rate info — shown always (especially useful when balance is low/zero)
                    StreamBuilder<List<PackageModel>>(
                      stream: _firestoreService.streamPackages(),
                      builder: (context, snapshot) {
                        // Get the cheapest package to show base rate
                        String rateText;
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final cheapest = snapshot.data!.reduce(
                            (a, b) => a.price < b.price ? a : b,
                          );
                          rateText = isSwahili
                              ? '${cheapest.credits} credit${cheapest.credits > 1 ? 's' : ''} = TZS ${_formatPrice(cheapest.price)}'
                              : '${cheapest.credits} credit${cheapest.credits > 1 ? 's' : ''} = TZS ${_formatPrice(cheapest.price)}';
                        } else {
                          rateText = isSwahili ? 'Nunua credits hapa chini' : 'Top up below';
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: credits == 0
                                ? AppTheme.error.withAlpha(15)
                                : AppTheme.primarySoft.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: credits == 0
                                  ? AppTheme.error.withAlpha(40)
                                  : AppTheme.primaryColor.withAlpha(30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                credits == 0 ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                size: 14,
                                color: credits == 0 ? AppTheme.error : AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                credits == 0
                                    ? (isSwahili ? 'Salio limeisha — $rateText' : 'Balance empty — $rateText')
                                    : rateText,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: credits == 0 ? AppTheme.error : AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    final String priceStr = price.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      buffer.write(priceStr[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  Widget _buildShimmerPackages() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No packages available at the moment.', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  void _showPaymentBottomSheet(
    String packageName,
    int credits,
    int price,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentBottomSheet(
        packageName: packageName,
        credits: credits,
        price: price,
      ),
    );
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (Route<dynamic> route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushNamed('/history');
        break;
      case 2:
        // Already on credits
        break;
      case 3:
        Navigator.of(context).pushNamed('/account');
        break;
    }
  }
}

class _CreditPackageCard extends StatelessWidget {
  final String title;
  final int credits;
  final int price;
  final String description;
  final bool isSwahili;
  final int animalIndex;
  final VoidCallback onBuy;

  // African animal emojis + matching background colours
  static const List<Map<String, dynamic>> _animals = [
    {'emoji': '🦒', 'name': 'Twiga',      'bg': Color(0xFFFFF3E0), 'border': Color(0xFFFFB74D)}, // Giraffe
    {'emoji': '🦁', 'name': 'Simba',      'bg': Color(0xFFFFF8E1), 'border': Color(0xFFFFCA28)}, // Lion
    {'emoji': '🐘', 'name': 'Tembo',      'bg': Color(0xFFE8EAF6), 'border': Color(0xFF7986CB)}, // Elephant
    {'emoji': '🦓', 'name': 'Punda Milia','bg': Color(0xFFF3E5F5), 'border': Color(0xFFBA68C8)}, // Zebra
    {'emoji': '🦏', 'name': 'Kifaru',     'bg': Color(0xFFE8F5E9), 'border': Color(0xFF66BB6A)}, // Rhino
    {'emoji': '🐆', 'name': 'Chui',       'bg': Color(0xFFFBE9E7), 'border': Color(0xFFFF7043)}, // Cheetah
  ];

  const _CreditPackageCard({
    required this.title,
    required this.credits,
    required this.price,
    required this.description,
    required this.isSwahili,
    required this.animalIndex,
    required this.onBuy,
  });

  String _formatPrice(int price) {
    final String priceStr = price.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      buffer.write(priceStr[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Animal icon — cycles through African animals per package
            Builder(builder: (_) {
              final animal = _animals[animalIndex % _animals.length];
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: animal['bg'] as Color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (animal['border'] as Color).withAlpha(80),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    animal['emoji'] as String,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              );
            }),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$credits Credits',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Price & Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'TZS ${_formatPrice(price)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onBuy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      isSwahili ? 'Nunua' : 'Buy',
                      style: GoogleFonts.poppins(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentBottomSheet extends StatefulWidget {
  final String packageName;
  final int credits;
  final int price;

  const _PaymentBottomSheet({
    required this.packageName,
    required this.credits,
    required this.price,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  int _selectedPaymentMethod = -1;
  bool _isProcessing = false;
  final FirestoreService _firestoreService = FirestoreService();

  String _formatPrice(int price) {
    final String priceStr = price.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      buffer.write(priceStr[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final isSwahili = localization.isSwahili;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  isSwahili ? 'Chagua Njia ya Malipo' : 'Select Payment Method',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.credits} ${localization.tr('credits')}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '•',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'TZS ${_formatPrice(widget.price)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Payment methods
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Mobile Money
                _PaymentMethodCard(
                  icon: Icons.phone_android,
                  title: 'Mobile Money',
                  subtitle: 'TIGO PESA, Airtel Money, Halotel',
                  isSelected: _selectedPaymentMethod == 1,
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 1;
                    });
                    _showClickPesaBottomSheet();
                  },
                ),
                
                // Card Payment (CRDB Bank)
                _PaymentMethodCard(
                  icon: Icons.account_balance,
                  title: 'Bank Payment',
                  subtitle: 'CRDB Bank',
                  isSelected: _selectedPaymentMethod == 0,
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 0;
                    });
                    _showCRDBPaymentDialog();
                  },
                ),
              ],
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPaymentMethod >= 0 && !_isProcessing
                    ? () {
                        if (_selectedPaymentMethod == 1) {
                          _initiateClickPesaPayment();
                        } else if (_selectedPaymentMethod == 0) {
                          _handleCRDBPayment();
                        }
                      }
                    : null,
                          final purchasedPackage = packages.firstWhere(
                            (p) => p.name == widget.packageName && 
                                   p.credits == widget.credits && 
                                   p.price == widget.price,
                            orElse: () => throw Exception('Package not found'),
                          );

                          // Add credits to user
                          await _firestoreService.addCredits(
                            userId,
                            widget.credits,
                            description: 'Purchase of ${widget.packageName}',
                            payment: widget.price.toDouble(),
                          );

                          // Update package sales count
                          await _firestoreService.updatePackageSales(purchasedPackage.id);

                          Navigator.pop(context); // close payment sheet

                          final method = _selectedPaymentMethod == 0
                              ? 'Mobile Money'
                              : (isSwahili ? 'Benki' : 'Bank');

                          // Show a full success dialog instead of a snackbar
                          if (context.mounted) {
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => _PurchaseSuccessDialog(
                                packageName: widget.packageName,
                                credits: widget.credits,
                                price: widget.price,
                                method: method,
                                isSwahili: isSwahili,
                              ),
                            );
                          }

                          // Go home after dialog is dismissed
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/home',
                              (Route<dynamic> route) => false,
                            );
                          }
                        } catch (e) {
                          Navigator.pop(context);
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: AppTheme.border,
                  padding: EdgeInsets.zero,
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withAlpha(80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    ),
                    color: null,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    alignment: Alignment.center,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isSwahili ? 'Tuma Malipo' : 'Send Payment',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Safe payment note
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  isSwahili ? 'Malipo salama na encrypted' : 'Secure and encrypted payments',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppTheme.border,
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppTheme.whiteColor,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Success dialog shown after a successful credit purchase.
// ============================================================
class _PurchaseSuccessDialog extends StatelessWidget {
  final String packageName;
  final int credits;
  final int price;
  final String method;
  final bool isSwahili;

  const _PurchaseSuccessDialog({
    required this.packageName,
    required this.credits,
    required this.price,
    required this.method,
    required this.isSwahili,
  });

  String _formatPrice(int p) {
    final s = p.toString();
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i > 0) { buf.write(','); count = 0; }
    }
    return buf.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),

            Text(
              isSwahili ? 'Umenunua Credits!' : 'Purchase Successful!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isSwahili
                  ? 'Malipo yamefanikiwa, credits zimeongezwa kwenye akaunti yako.'
                  : 'Payment confirmed. Credits added to your account.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Purchase details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _row(isSwahili ? 'Kifurushi' : 'Package',       packageName),
                  const Divider(height: 16),
                  _row('Credits',                                   '$credits credits'),
                  const Divider(height: 16),
                  _row(isSwahili ? 'Kiasi' : 'Amount',             'TZS ${_formatPrice(price)}'),
                  const Divider(height: 16),
                  _row(isSwahili ? 'Njia ya Malipo' : 'Payment',   method),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Home button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: Text(
                      isSwahili ? 'Rudi Nyumbani' : 'Go to Home',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        Text(value,  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.text)),
      ],
    );
  }
}
