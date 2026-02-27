import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
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
  int _selectedIndex = 2;

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
                  subtitle: 'M-Pesa, Tigo Pesa, Airtel Money, Halo Pesa',
                  color: AppTheme.accentGreen,
                  bgColor: AppTheme.iconBgGreen,
                  isSelected: _selectedPaymentMethod == 0,
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 0;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Bank
                _PaymentMethodCard(
                  icon: Icons.account_balance,
                  title: isSwahili ? 'Benki' : 'Bank',
                  subtitle: isSwahili
                      ? 'CRDB, NMB, NBC, Stanbic na nyingine'
                      : 'CRDB, NMB, NBC, Stanbic and others',
                  color: AppTheme.accentBlue,
                  bgColor: AppTheme.iconBgBlue,
                  isSelected: _selectedPaymentMethod == 1,
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 1;
                    });
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
                    ? () async {
                        setState(() => _isProcessing = true);
                        
                        try {
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final userId = auth.user?.id;
                          
                          if (userId == null) {
                            throw Exception('User not authenticated');
                          }

                          // Find the package ID from the packages list
                          final packages = await _firestoreService.getPackages();
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isSwahili
                                    ? 'Imeshindikana: ${e.toString()}'
                                    : 'Payment failed: ${e.toString()}',
                              ),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isProcessing = false);
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  disabledBackgroundColor: AppTheme.border,
                  padding: EdgeInsets.zero,
                  elevation: _selectedPaymentMethod >= 0 ? 4 : 0,
                  shadowColor: AppTheme.primaryColor.withAlpha(80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _selectedPaymentMethod >= 0
                        ? LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                          )
                        : null,
                    color: _selectedPaymentMethod >= 0 ? null : AppTheme.border,
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
                            isSwahili ? 'Endelea na Malipo' : 'Continue with Payment',
                            style: GoogleFonts.poppins(
                              color: _selectedPaymentMethod >= 0 && !_isProcessing
                                  ? AppTheme.whiteColor
                                  : AppTheme.textSecondary,
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
