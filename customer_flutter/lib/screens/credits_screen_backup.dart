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
import 'dart:async';

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
  bool _hasInternetConnection = true;
  Timer? _connectionTimer;
  
  // Phone number management
  String _savedPhoneNumber = '';
  bool _isPhoneVerified = false;
  bool _isSavingPhone = false;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _startConnectionMonitoring();
    _loadSavedPhoneNumber();
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  void _startConnectionMonitoring() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkInternetConnection();
    });
  }

  Future<void> _checkInternetConnection() async {
    try {
      // Try to reach a reliable endpoint
      final response = await _apiService.testConnection();
      setState(() {
        _hasInternetConnection = response['success'] ?? false;
      });
    } catch (e) {
      setState(() {
        _hasInternetConnection = false;
      });
    }
  }

  // Load saved phone number
  Future<void> _loadSavedPhoneNumber() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userData = await _firestoreService.getUserData(auth.currentUser!.uid);
      if (userData != null && userData['phoneNumber'] != null) {
        setState(() {
          _savedPhoneNumber = userData['phoneNumber'];
          _isPhoneVerified = userData['phoneVerified'] ?? false;
          _phoneController.text = _savedPhoneNumber;
        });
      }
    } catch (e) {
      print('Error loading phone number: $e');
    }
  }

  // Save phone number
  Future<void> _savePhoneNumber(String phoneNumber) async {
    try {
      setState(() {
        _isSavingPhone = true;
      });
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await _firestoreService.updateUserData(auth.currentUser!.uid, {
        'phoneNumber': phoneNumber,
        'phoneVerified': true,
        'phoneUpdatedAt': DateTime.now().toIso8601String(),
      });
      setState(() {
        _savedPhoneNumber = phoneNumber;
        _isPhoneVerified = true;
      });
    } catch (e) {
      print('Error saving phone number: $e');
      rethrow; // Re-throw to handle in dialog
    } finally {
      setState(() {
        _isSavingPhone = false;
      });
    }
  }

  // Show phone verification dialog
  void _showPhoneVerificationDialog() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isSwahili ? 'Thibitisha Namba ya Simu' : 'Verify Phone Number',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSwahili 
                ? 'Tafadhali weka namba yako ya simu ili kuendelea na malipo ya Mobile Money.'
                : 'Please enter your phone number to continue with Mobile Money payment.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Namba ya Simu' : 'Phone Number',
                hintText: isSwahili ? '0712345678' : '0712345678',
                prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isSwahili ? 'Namba ya simu inahitajika' : 'Phone number is required';
                }
                if (!RegExp(r'^[0-9]{10}$').hasMatch(value.replaceAll(' ', ''))) {
                  return isSwahili ? 'Namba lazima kuwa tarakimu 10' : 'Number must be 10 digits';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSavingPhone ? null : () async {
              final phone = _phoneController.text.replaceAll(' ', '');
              if (RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                try {
                  await _savePhoneNumber(phone);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSwahili ? 'Namba imehifadhiwa!' : 'Phone number saved!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSwahili ? 'Imeshindikana kuhifadhi' : 'Failed to save',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: _isSavingPhone
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSwahili ? 'Inahifadhi...' : 'Saving...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : Text(
                    isSwahili ? 'Hifadhi' : 'Save',
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  void _showClickPesaBottomSheet() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentBottomSheet(
        widget: widget,
        localization: localization,
        isSwahili: isSwahili,
        hasInternetConnection: _hasInternetConnection,
        isPhoneVerified: _isPhoneVerified,
        savedPhoneNumber: _savedPhoneNumber,
        isProcessing: _isProcessing,
        selectedPaymentMethod: _selectedPaymentMethod,
        apiService: _apiService,
        onPaymentMethodSelected: (method) {
          setState(() {
            _selectedPaymentMethod = method;
          });
          if (method == 1 && !_isPhoneVerified) {
            _showPhoneVerificationDialog();
          }
        },
        onInitiatePayment: () {
          if (_selectedPaymentMethod == 1) {
            _initiateMobileMoneyPayment();
          }
        },
        onShowPhoneVerification: _showPhoneVerificationDialog,
      ),
    );
  }
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
        paymentMethod: 'mobile_money', // Add payment method parameter
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
      
      if (response['success'] && response['status'] == 'SUCCESS') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSwahili ? 'Malipo yamekamilika!' : 'Payment completed successfully!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        
        // Refresh user data
        // await auth.refreshUserData();
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
            TextFormField(
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
            TextFormField(
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
                ? 'Bei: \$${paymentData['usdAmount']} USD (${paymentData['amount']} TZS)' 
                : 'Price: \$${paymentData['usdAmount']} USD (${paymentData['amount']} TZS)',
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

          // Internet Connection Status
          if (!_hasInternetConnection)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.red[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Internet Connection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please check your internet connection and try again.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
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
                  subtitle: _isPhoneVerified 
                      ? 'TIGO PESA, Airtel Money, Halotel ($_savedPhoneNumber)'
                      : 'TIGO PESA, Airtel Money, Halotel',
                  color: Colors.green,
                  isSelected: _selectedPaymentMethod == 1,
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 1;
                    });
                    if (!_isPhoneVerified) {
                      _showPhoneVerificationDialog();
                    }
                  },
                ),
                
                // Card Payment (CRDB Bank)
                _PaymentMethodCard(
                  icon: Icons.account_balance,
                  title: 'Bank Payment',
                  subtitle: 'CRDB Bank',
                  color: Colors.blue,
                  isSelected: _selectedPaymentMethod == 0,
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 0;
                    });
                    // _showCRDBPaymentDialog(); // TODO: Implement method
                  },
                ),

                // Phone Number Status (for Mobile Money)
                if (_selectedPaymentMethod == 1 && !_isPhoneVerified)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone Number Required',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please add and verify your phone number to continue with Mobile Money payment.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Verified Phone Number Display
                if (_selectedPaymentMethod == 1 && _isPhoneVerified)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Phone Number',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_savedPhoneNumber',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showPhoneVerificationDialog,
                          child: Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPaymentMethod >= 0 ? AppTheme.primaryColor : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (_selectedPaymentMethod >= 0 && !_isProcessing && _hasInternetConnection && 
                (_selectedPaymentMethod == 0 || (_selectedPaymentMethod == 1 && _isPhoneVerified)))
                    ? () {
                        if (_selectedPaymentMethod == 1) {
                          // Mobile Money - Proceed with payment
                          _initiateMobileMoneyPayment();
                        } else if (_selectedPaymentMethod == 0) {
                          // _handleCRDBPayment(); // TODO: Implement method
                        }
                      }
                    : null,
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            localization.isSwahili ? 'Inachambua...' : 'Processing...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        !_hasInternetConnection 
                            ? 'No Internet Connection' 
                            : (_selectedPaymentMethod == 1 && !_isPhoneVerified)
                                ? 'Add Phone Number'
                                : (localization.isSwahili ? 'Endelea na Malipo' : 'Continue to Payment'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Initiate Mobile Money Payment
  Future<void> _initiateMobileMoneyPayment() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    try {
      setState(() {
        _isProcessing = true;
      });

      // Create payment request with saved phone number
      final response = await _apiService.createPayment(
        packageId: 'pack_25', // Default to popular package
        phoneNumber: _savedPhoneNumber,
        paymentMethod: 'mobile_money',
      );

      if (response['success']) {
        // Show payment instructions
        _showPaymentInstructions(response['orderReference']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSwahili 
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
            isSwahili 
              ? 'Hitilafu: $e' 
              : 'Error: $e',
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

  // Show payment instructions
  void _showPaymentInstructions(String orderReference) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isSwahili ? 'Maelekezo ya Malipo' : 'Payment Instructions',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSwahili 
                ? 'Tafadhali kamilisha malipo kwa kutumia namba:' 
                : 'Please complete payment using:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone_android, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    _savedPhoneNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSwahili 
                ? 'Kumbukumbu ya malipo: $orderReference' 
                : 'Payment reference: $orderReference',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili 
                ? 'Malipo yatachambuliwa moja kwa moja na credits zitaongezwa.' 
                : 'Payment will be processed automatically and credits will be added.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              isSwahili ? 'Sawa' : 'OK',
              style: const TextStyle(color: Colors.white),
            ),
          ),
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
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
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
  final double price;
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
                  _row(isSwahili ? 'Kiasi' : 'Amount',             'TZS ${_formatPrice(price.toInt())}'),
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

// Payment Bottom Sheet Widget
class _PaymentBottomSheet extends StatefulWidget {
  final dynamic widget; // CreditsScreen widget
  final LocalizationProvider localization;
  final bool isSwahili;
  final bool hasInternetConnection;
  final bool isPhoneVerified;
  final String savedPhoneNumber;
  final bool isProcessing;
  final int selectedPaymentMethod;
  final ApiService apiService;
  final Function(int) onPaymentMethodSelected;
  final VoidCallback onInitiatePayment;
  final VoidCallback onShowPhoneVerification;

  const _PaymentBottomSheet({
    required this.widget,
    required this.localization,
    required this.isSwahili,
    required this.hasInternetConnection,
    required this.isPhoneVerified,
    required this.savedPhoneNumber,
    required this.isProcessing,
    required this.selectedPaymentMethod,
    required this.apiService,
    required this.onPaymentMethodSelected,
    required this.onInitiatePayment,
    required this.onShowPhoneVerification,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  // Format price helper
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 16),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  widget.isSwahili ? 'Chagua Njia ya Malipo' : 'Select Payment Method',
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
                        '${widget.widget.credits} ${widget.localization.tr('credits')}',
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
                        'TZS ${_formatPrice(widget.widget.price)}',
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

          // Internet Connection Status
          if (!widget.hasInternetConnection)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.red[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Internet Connection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please check your internet connection and try again.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
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
                  subtitle: widget.isPhoneVerified 
                      ? 'TIGO PESA, Airtel Money, Halotel (${widget.savedPhoneNumber})'
                      : 'TIGO PESA, Airtel Money, Halotel',
                  color: Colors.green,
                  isSelected: widget.selectedPaymentMethod == 1,
                  onTap: () {
                    widget.onPaymentMethodSelected(1);
                  },
                ),
                
                // Card Payment (CRDB Bank)
                _PaymentMethodCard(
                  icon: Icons.account_balance,
                  title: 'Bank Payment',
                  subtitle: 'CRDB Bank',
                  color: Colors.blue,
                  isSelected: widget.selectedPaymentMethod == 0,
                  onTap: () {
                    widget.onPaymentMethodSelected(0);
                  },
                ),

                // Phone Number Status (for Mobile Money)
                if (widget.selectedPaymentMethod == 1 && !widget.isPhoneVerified)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone Number Required',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please add and verify your phone number to continue with Mobile Money payment.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Verified Phone Number Display
                if (widget.selectedPaymentMethod == 1 && widget.isPhoneVerified)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Phone Number',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.savedPhoneNumber,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onShowPhoneVerification,
                          child: Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.selectedPaymentMethod >= 0 ? AppTheme.primaryColor : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (widget.selectedPaymentMethod >= 0 && !widget.isProcessing && widget.hasInternetConnection && 
                (widget.selectedPaymentMethod == 0 || (widget.selectedPaymentMethod == 1 && widget.isPhoneVerified)))
                    ? widget.onInitiatePayment
                    : null,
                child: widget.isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.isSwahili ? 'Inachambua...' : 'Processing...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        !widget.hasInternetConnection 
                            ? 'No Internet Connection' 
                            : (widget.selectedPaymentMethod == 1 && !widget.isPhoneVerified)
                                ? 'Add Phone Number'
                                : (widget.isSwahili ? 'Endelea na Malipo' : 'Continue to Payment'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
