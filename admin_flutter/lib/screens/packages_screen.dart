import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/theme.dart';
import '../services/firestore_service.dart';
import '../models/shared_models.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  late final Stream<List<PackageModel>> _packagesStream;

  @override
  void initState() {
    super.initState();
    _packagesStream = _firestoreService.streamPackages();
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
    return buffer.toString().split('').reversed.join('');
  }

  // Helper functions for stats
  int _getTotalSales(List<PackageModel> packages) {
    return packages.fold<int>(0, (sum, pkg) => sum + pkg.sales);
  }

  int _getTotalRevenue(List<PackageModel> packages) {
    return packages.fold<int>(0, (sum, pkg) => sum + (pkg.sales * pkg.price));
  }

  int _getActivePackages(List<PackageModel> packages) {
    return packages.where((pkg) => pkg.isActive).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: StreamBuilder<List<PackageModel>>(
          stream: _packagesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoading();
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final packages = snapshot.data ?? [];

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  _buildHeroSection(packages),

                  // Packages Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Packages',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${packages.length} Packages',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your credit packages and pricing',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Packages List
                  packages.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 48,
                                      color: AppTheme.textSecondary),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No packages available',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add your first package to get started',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color:
                                          AppTheme.textSecondary.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: packages.length,
                          itemBuilder: (context, index) {
                            final package = packages[index];
                            return _PackageCard(
                              package: package,
                              onEdit: () => _showEditPackage(package),
                              onToggle: () => _togglePackage(package),
                              onDelete: () => _deletePackage(package),
                            );
                          },
                        ),

                  // Bottom padding for FAB (increased to avoid overflow)
                  const SizedBox(height: 120),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _showAddPackage,
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.add, color: AppTheme.whiteColor),
          label: Text(
            'Add Package',
            style: GoogleFonts.poppins(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section Shimmer
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryDark,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Shimmer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.5),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.5),
                        child: Container(
                          width: 150,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.5),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Stats Shimmer
                  Shimmer.fromColors(
                    baseColor: Colors.white.withOpacity(0.3),
                    highlightColor: Colors.white.withOpacity(0.5),
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section title shimmer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: AppTheme.primarySoft,
                  highlightColor: AppTheme.surface,
                  child: Container(
                    height: 18,
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: AppTheme.primarySoft,
                  highlightColor: AppTheme.surface,
                  child: Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Package cards shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Shimmer.fromColors(
                    baseColor: AppTheme.primarySoft,
                    highlightColor: AppTheme.surface,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom padding
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildHeroSection(List<PackageModel> packages) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryDark,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 20),
                  ),
                ),
                Text(
                  'Package Management',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _showAddPackage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Revenue',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TZS ${_formatPrice(_getTotalRevenue(packages))}',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Sales',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '${_getTotalSales(packages)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Active',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '${_getActivePackages(packages)}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPackage() {
    _showPackageDialog(null);
  }

  void _showEditPackage(PackageModel package) {
    _showPackageDialog(package);
  }

  void _showPackageDialog(PackageModel? package) {
    final isEditing = package != null;
    final nameController = TextEditingController(text: package?.name ?? '');
    final creditsController =
        TextEditingController(text: package?.credits.toString() ?? '');
    final priceController =
        TextEditingController(text: package?.price.toString() ?? '');
    final discountController = TextEditingController(text: package?.discount ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isPopular = package?.isPopular ?? false;
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Package' : 'Add New Package',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: 'Package Name',
                                labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
                                prefixIcon: Icon(Icons.label, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.border)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.border)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.primaryColor)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: creditsController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Credits',
                                labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
                                prefixIcon: Icon(Icons.confirmation_number, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.border)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.border)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.primaryColor)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price (TZS)',
                                labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
                                prefixIcon: Icon(Icons.attach_money, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.border)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.border)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.primaryColor)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: discountController,
                              decoration: InputDecoration(
                                labelText: 'Discount (Optional)',
                                labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
                                prefixIcon: Icon(Icons.discount, color: AppTheme.primaryColor),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.border)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.border)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppTheme.primaryColor)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPopular
                                      ? AppTheme.primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isPopular,
                                    onChanged: (value) {
                                      setState(() {
                                        isPopular = value ?? false;
                                      });
                                    },
                                    activeColor: AppTheme.primaryColor,
                                    checkColor: AppTheme.whiteColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Popular Package',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.text,
                                          ),
                                        ),
                                        Text(
                                          'Mark this package as popular for special highlighting',
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final credits =
                              int.tryParse(creditsController.text) ?? 0;
                          final price =
                              int.tryParse(priceController.text) ?? 0;
                          final discount =
                              discountController.text.trim().isEmpty
                                  ? null
                                  : discountController.text.trim();

                          if (name.isEmpty || credits <= 0 || price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please fill all required fields correctly'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            return;
                          }

                          // Capture context-dependent objects before async gap
                          final nav = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            final newPackage = PackageModel(
                              id: isEditing ? package!.id : '',
                              name: name,
                              credits: credits,
                              price: price,
                              isActive: isEditing ? package!.isActive : true,
                              sales: isEditing ? package!.sales : 0,
                              discount: discount,
                              isPopular: isPopular,
                            );

                            if (isEditing) {
                              await _firestoreService.updatePackage(newPackage);
                            } else {
                              await _firestoreService.createPackage(newPackage);
                            }

                            if (mounted) {
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(isEditing
                                      ? 'Package updated!'
                                      : 'Package added!'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppTheme.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Update Package' : 'Add Package',
                          style: GoogleFonts.poppins(
                            color: AppTheme.whiteColor,
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
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      creditsController.dispose();
      priceController.dispose();
      discountController.dispose();
    });
  }

void _deletePackage(PackageModel package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Package?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete "${package.name}". This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestoreService.deletePackage(package.id);
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _togglePackage(PackageModel package) async {
    await _firestoreService.togglePackageStatus(package.id, !package.isActive);
  }
}

// Package Card Widget
class _PackageCard extends StatelessWidget {
  final PackageModel package;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PackageCard({
    required this.package,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: package.isActive
              ? AppTheme.primaryColor.withAlpha(50)
              : AppTheme.border,
          width: package.isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            package.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.text,
                            ),
                          ),
                          if (package.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Popular',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppTheme.whiteColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${package.credits} credits • TZS ${_formatPrice(package.price)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit,
                          color: AppTheme.primaryColor, size: 20),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete,
                          color: AppTheme.error, size: 20),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales: ${package.sales}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Switch(
                  value: package.isActive,
                  onChanged: (_) => onToggle(),
                  activeColor: AppTheme.primaryColor,
                  activeTrackColor: AppTheme.primaryColor.withOpacity(0.5),
                ),
              ],
            ),
          ],
        ),
      ),
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
    return buffer.toString().split('').reversed.join('');
  }
}