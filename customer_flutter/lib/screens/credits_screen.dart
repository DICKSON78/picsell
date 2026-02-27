import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../services/firestore_service.dart';
import '../services/api_service.dart';

// CreditsScreenTheme class for consistent styling
class CreditsScreenTheme {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color text = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color error = Color(0xFFF44336);
  static const Color success = Color(0xFF4CAF50);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const BorderSide border = BorderSide(color: Color(0xFFE0E0E0));
}

class CreditsScreen extends StatefulWidget {
  final int credits;
  final double price;

  const CreditsScreen({
    super.key,
    this.credits = 25, // Default credits
    this.price = 5000.0, // Default price in TZS
  });

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedPaymentMethod = -1; // -1 = none selected, 0 = card, 1 = mobile money
  bool _isProcessing = false;
  bool _hasInternetConnection = true;
  Timer? _connectionTimer;
  
  // Phone number management
  String _savedPhoneNumber = '';
  bool _isPhoneVerified = false;
  bool _isSavingPhone = false;
  final TextEditingController _phoneController = TextEditingController();

  // Format phone number for ClickPesa API
  String _formatPhoneNumberForClickPesa(String phone) {
    String cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');
    
    // If starts with 0 and has 10 digits, convert to international format
    if (cleanPhone.startsWith('0') && cleanPhone.length == 10) {
      return '255${cleanPhone.substring(1)}';
    }
    
    // If already in international format, return as is
    if (cleanPhone.startsWith('255') && cleanPhone.length == 12) {
      return cleanPhone;
    }
    
    // If starts with +, remove the +
    if (cleanPhone.startsWith('+255') && cleanPhone.length == 13) {
      return cleanPhone.substring(1);
    }
    
    return cleanPhone; // Return as-is if no format matches
  }

  // Validate phone number format
  bool _isValidPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');
    
    // Check for 10-digit format (starting with 0)
    if (RegExp(r'^0[0-9]{9}$').hasMatch(cleanPhone)) {
      return true;
    }
    
    // Check for international format (255XXXXXXXXX)
    if (RegExp(r'^255[0-9]{9}$').hasMatch(cleanPhone)) {
      return true;
    }
    
    return false;
  }

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

  // Check internet connection
  Future<void> _checkInternetConnection() async {
    try {
      final hasConnection = await _apiService.testConnection();
      setState(() {
        _hasInternetConnection = hasConnection['success'] == true;
      });
    } catch (e) {
      setState(() {
        _hasInternetConnection = false;
      });
    }
  }

  // Start connection monitoring
  void _startConnectionMonitoring() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkInternetConnection();
    });
  }

  // Load saved phone number
  Future<void> _loadSavedPhoneNumber() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null && auth.currentUser!.id.isNotEmpty) {
        final userData = await _firestoreService.getUserData(auth.currentUser!.id);
        if (userData != null) {
          setState(() {
            _savedPhoneNumber = userData['phoneNumber'] ?? '';
            _isPhoneVerified = userData['phoneVerified'] ?? false;
          });
        }
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
      if (auth.currentUser != null && auth.currentUser!.id.isNotEmpty) {
        await _firestoreService.updateUserData(auth.currentUser!.id, {
          'phoneNumber': phoneNumber,
          'phoneVerified': true,
          'phoneUpdatedAt': DateTime.now().toIso8601String(),
        });
        setState(() {
          _savedPhoneNumber = phoneNumber;
          _isPhoneVerified = true;
        });
      }
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
                ? 'Weka namba yako ya simu kwa ajili ya malipo ya Mobile Money' 
                : 'Enter your phone number for Mobile Money payments',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Namba ya Simu' : 'Phone Number',
                hintText: isSwahili ? '0712345678' : '0712345678',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isSwahili ? 'Tafadhali weka namba ya simu' : 'Please enter phone number';
                }
                if (!_isValidPhoneNumber(value)) {
                  return isSwahili 
                    ? 'Namba lazima kuwa 07XXXXXXXX au 255XXXXXXXXX' 
                    : 'Phone number must be 07XXXXXXXX or 255XXXXXXXXX';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

  
  // Initiate Mobile Money Payment
  Future<void> _initiateMobileMoneyPayment() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    
    try {
      setState(() {
        _isProcessing = true;
      });

      // Create payment request with saved phone number
      // Format phone number for ClickPesa API
      String formattedPhone = _formatPhoneNumberForClickPesa(_savedPhoneNumber);
      
      // Validate phone number
      if (!_isValidPhoneNumber(_savedPhoneNumber)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSwahili 
                ? 'Nambari ya simu si sahihi. Tafadhali sahihi na jaribu tena.' 
                : 'Invalid phone number format. Please correct and try again.',
            ),
            backgroundColor: CreditsScreenTheme.error,
          ),
        );
        return;
      }
      
      print('📱 Phone verification:');
      print('   Original: $_savedPhoneNumber');
      print('   Formatted: $formattedPhone');
      
      final response = await _apiService.createPayment(
        packageId: 'pack_25', // Default to popular package
        phoneNumber: formattedPhone,
        paymentMethod: 'mobile_money',
      );

      if (response['success'] == true) {
        // Check if payment was initiated successfully
        if (response['paymentInitiated'] == true) {
          // Show success message that USSD push was sent
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isSwahili 
                  ? 'Ombi la malipo limetumwa. Tafadali angalia simu yako kukamilisha malipo.' 
                  : response['message'] ?? 'USSD push sent to your phone. Please complete the payment.',
              ),
              backgroundColor: CreditsScreenTheme.success,
              duration: const Duration(seconds: 5),
            ),
          );
          // Show payment instructions with order reference
          _showPaymentInstructions(response['orderReference'] ?? '');
        } else {
          // Fallback for old response format
          _showPaymentInstructions(response['orderReference'] ?? '');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSwahili 
                ? 'Imeshindikana: ${response['error'] ?? 'Unknown error'}' 
                : 'Payment failed: ${response['error'] ?? 'Unknown error'}',
            ),
            backgroundColor: CreditsScreenTheme.error,
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
          backgroundColor: CreditsScreenTheme.error,
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
              backgroundColor: CreditsScreenTheme.primaryColor,
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

  // Format price helper
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final localization = Provider.of<LocalizationProvider>(context);
      final isSwahili = localization.isSwahili;
      
      return Scaffold(
        backgroundColor: CreditsScreenTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: CreditsScreenTheme.backgroundColor,
          elevation: 0,
          title: Text(
            isSwahili ? 'Pata Credits' : 'Get Credits',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CreditsScreenTheme.text,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: CreditsScreenTheme.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
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
                      color: CreditsScreenTheme.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: CreditsScreenTheme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CreditsScreenTheme.primaryColor.withAlpha(50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt,
                          color: CreditsScreenTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.credits} ${localization.tr('credits') ?? 'credits'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CreditsScreenTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '•',
                          style: TextStyle(color: CreditsScreenTheme.primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'TZS ${_formatPrice(widget.price)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: CreditsScreenTheme.primaryColor,
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
                                  _savedPhoneNumber,
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
                    backgroundColor: _selectedPaymentMethod >= 0 ? CreditsScreenTheme.primaryColor : Colors.grey,
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
                            // Bank payment - TODO: Implement
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
    } catch (e) {
      // Fallback UI in case of errors
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Get Credits'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Something went wrong', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('Please try again later', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
  }
}

// Payment Method Card Widget
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
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
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
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CreditsScreenTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: CreditsScreenTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
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
                    color: CreditsScreenTheme.text,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: CreditsScreenTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: CreditsScreenTheme.primaryColor.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt,
                        color: CreditsScreenTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.widget.credits} ${widget.localization.tr('credits') ?? 'credits'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CreditsScreenTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '•',
                        style: TextStyle(color: CreditsScreenTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'TZS ${_formatPrice(widget.widget.price)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: CreditsScreenTheme.primaryColor,
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
                  backgroundColor: widget.selectedPaymentMethod >= 0 ? CreditsScreenTheme.primaryColor : Colors.grey,
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
