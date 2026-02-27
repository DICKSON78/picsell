import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/theme.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../models/shared_models.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _numberController = TextEditingController();
  String _selectedProvider = 'M-Pesa';
  bool _isLinking = false;

  final List<String> _providers = ['M-Pesa', 'Yas Mixx', 'Airtel Money'];

  void _showAddPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Link Mobile Money',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your provider and enter your number',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              
              // Provider Selector
              Text(
                'Network Provider',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _providers.map((p) => _buildProviderOption(p, setModalState)).toList(),
              ),
              
              const SizedBox(height: 24),
              Text(
                'Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: '07XX XXX XXX',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textLight),
                    prefixIcon: const Icon(Icons.phone_iphone, color: AppTheme.primaryColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLinking ? null : () => _linkNumber(setModalState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLinking 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Link Account',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderOption(String provider, StateSetter setModalState) {
    bool isSelected = _selectedProvider == provider;
    Color pColor = provider == 'M-Pesa' ? Colors.green : (provider == 'Tigo Pesa' ? Colors.blue : Colors.red);
    
    return GestureDetector(
      onTap: () => setModalState(() => _selectedProvider = provider),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? pColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? pColor : AppTheme.border, width: 2),
        ),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet, color: isSelected ? pColor : AppTheme.textLight, size: 24),
            const SizedBox(height: 4),
            Text(
              provider.split(' ')[0],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? pColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _linkNumber(StateSetter setModalState) async {
    if (_numberController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid number')));
      return;
    }

    setModalState(() => _isLinking = true);
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        final method = PaymentMethodModel(
          id: '',
          userId: auth.user!.id,
          provider: _selectedProvider,
          number: _numberController.text,
          isDefault: true,
          createdAt: DateTime.now(),
        );
        
        await _firestoreService.savePaymentMethod(method);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_selectedProvider linked successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
          _numberController.clear();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setModalState(() => _isLinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeroSection(),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildInfoCard(),
            ),
          ),
          Expanded(
            child: user == null
              ? _buildShimmerList()
              : StreamBuilder<List<PaymentMethodModel>>(
                  stream: _firestoreService.streamPaymentMethods(user.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerList();
                    }
                    
                    final methods = snapshot.data ?? [];
                    
                    if (methods.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Transform.translate(
                      offset: const Offset(0, -20),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: methods.length,
                        itemBuilder: (context, index) => _buildMethodCard(methods[index]),
                      ),
                    );
                  },
                ),
          ),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1556742049-02e43bc37fc8?q=80&w=2070&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  AppTheme.primaryDark.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.whiteColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryDark.withAlpha(40),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      'Payment Methods',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.whiteColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.security,
              color: AppTheme.whiteColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Link',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                Text(
                  'Your payment accounts are linked securely',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethodModel method) {
    Color pColor = method.provider == 'M-Pesa' ? Colors.green : (method.provider == 'Tigo Pesa' ? Colors.blue : Colors.red);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: method.isDefault ? pColor : AppTheme.border, width: method.isDefault ? 2 : 1),
        boxShadow: method.isDefault ? AppTheme.shadowSm : null,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: pColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.phone_iphone, color: pColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.provider,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    if (method.isDefault)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: pColor),
                        ),
                      ),
                  ],
                ),
                Text(
                  method.number,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(method.id),
            icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Account'),
        content: const Text('Are you sure you want to remove this payment method?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _firestoreService.deletePaymentMethod(id);
              if (mounted) Navigator.pop(context);
            }, 
            child: const Text('Remove', style: TextStyle(color: AppTheme.error))
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: AppTheme.textLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No accounts linked yet',
            style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: AppTheme.primarySoft,
              highlightColor: AppTheme.surface,
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showAddPaymentMethod,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Link New Account'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}
