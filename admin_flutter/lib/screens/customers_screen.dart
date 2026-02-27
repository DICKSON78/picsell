import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/customers_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import '../models/customer_model.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';
  final ApiService _apiService = ApiService();

  final _addNameController = TextEditingController();
  final _addEmailController = TextEditingController();
  final _addPhoneController = TextEditingController();
  final _addCreditsController = TextEditingController(text: '10');
  final _addFormKey = GlobalKey<FormState>();

  // ClickPesa payout controllers
  final _payoutPhoneController = TextEditingController();
  final _payoutAmountController = TextEditingController();
  final _payoutFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomersProvider>(context, listen: false).loadCustomers();
    });
  }

  @override
  void dispose() {
    _addNameController.dispose();
    _addEmailController.dispose();
    _addPhoneController.dispose();
    _addCreditsController.dispose();
    _payoutPhoneController.dispose();
    _payoutAmountController.dispose();
    super.dispose();
  }

  List<CustomerModel> _getFilteredUsers(List<CustomerModel> users) {
    return users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterStatus == 'all' ||
          (_filterStatus == 'active' && user.isActive) ||
          (_filterStatus == 'inactive' && !user.isActive);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _showAddCustomer() {
    _addNameController.clear();
    _addEmailController.clear();
    _addPhoneController.clear();
    _addCreditsController.text = '10';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Form(
          key: _addFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.person_add, color: AppTheme.whiteColor, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add New Customer', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text)),
                          Text('Create a new customer account', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildFormField(controller: _addNameController, label: 'Full Name', hint: 'Enter customer name', icon: Icons.person_outline, validator: (v) => v == null || v.isEmpty ? 'Please enter name' : null),
                const SizedBox(height: 16),
                _buildFormField(controller: _addEmailController, label: 'Email Address', hint: 'customer@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.isEmpty ? 'Please enter email' : (!v.contains('@') ? 'Invalid email' : null)),
                const SizedBox(height: 16),
                _buildFormField(controller: _addPhoneController, label: 'Phone Number', hint: '+255 7XX XXX XXX', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v == null || v.isEmpty ? 'Please enter phone' : null),
                const SizedBox(height: 16),
                _buildFormField(controller: _addCreditsController, label: 'Initial Credits', hint: '10', icon: Icons.bolt, keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Enter credits' : (int.tryParse(v) == null ? 'Invalid number' : null)),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary, side: const BorderSide(color: AppTheme.border), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _submitAddCustomer,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: AppTheme.whiteColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                        child: Text('Add Customer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.text)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: GoogleFonts.poppins(color: AppTheme.text, fontSize: 15),
            decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.poppins(color: AppTheme.textLight), prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          ),
        ),
      ],
    );
  }

  void _submitAddCustomer() async {
    if (!_addFormKey.currentState!.validate()) return;
    
    final customer = CustomerModel(
      id: '', // Will be generated by Firestore
      email: _addEmailController.text.trim(),
      name: _addNameController.text.trim(),
      phone: _addPhoneController.text.trim(),
      credits: int.parse(_addCreditsController.text),
      createdAt: DateTime.now(),
      isActive: true,
      totalSpent: 0,
      totalPhotosProcessed: 0,
    );

    try {
      await Provider.of<CustomersProvider>(context, listen: false).addCustomer(customer);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer added successfully!'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersProvider = Provider.of<CustomersProvider>(context);
    final filteredUsers = _getFilteredUsers(customersProvider.customers);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeroSection(customersProvider.customers.length),
          _buildSearchAndFilter(),
          Expanded(
            child: customersProvider.isLoading
                ? _buildShimmerGrid()
                : RefreshIndicator(
                    onRefresh: () => customersProvider.loadCustomers(),
                    color: AppTheme.primaryColor,
                    child: filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) => _CustomerCard(user: filteredUsers[index], onTap: () => _showCustomerDetails(filteredUsers[index])),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _showAddCustomer,
          backgroundColor: AppTheme.primaryColor,
          icon: const Icon(Icons.person_add, color: AppTheme.whiteColor),
          label: Text('Add Customer', style: GoogleFonts.poppins(color: AppTheme.whiteColor, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar Shimmer
              Shimmer.fromColors(
                baseColor: AppTheme.primarySoft,
                highlightColor: AppTheme.surface,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info Shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Shimmer.fromColors(
                          baseColor: AppTheme.primarySoft,
                          highlightColor: AppTheme.surface,
                          child: Container(
                            height: 16,
                            width: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Shimmer.fromColors(
                          baseColor: AppTheme.primarySoft,
                          highlightColor: AppTheme.surface,
                          child: Container(
                            height: 16,
                            width: 50,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: AppTheme.primarySoft,
                      highlightColor: AppTheme.surface,
                      child: Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Shimmer.fromColors(
                          baseColor: AppTheme.primarySoft,
                          highlightColor: AppTheme.surface,
                          child: Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Shimmer.fromColors(
                          baseColor: AppTheme.primarySoft,
                          highlightColor: AppTheme.surface,
                          child: Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(int totalCustomers) {
    return Container(
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
            const SizedBox(height: 20), 
            // App Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                Text(
                  'Customers',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _showAddCustomer,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add, color: Colors.white, size: 20),
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
                  'Total Customers',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalCustomers',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your customer accounts',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDark.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.poppins(color: AppTheme.text),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: GoogleFonts.poppins(color: AppTheme.textLight),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _filterStatus == 'all',
                onTap: () => setState(() => _filterStatus = 'all'),
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Active',
                isSelected: _filterStatus == 'active',
                onTap: () => setState(() => _filterStatus = 'active'),
                color: AppTheme.success,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Inactive',
                isSelected: _filterStatus == 'inactive',
                onTap: () => setState(() => _filterStatus = 'inactive'),
                color: AppTheme.error,
              ),
            ],
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
          Icon(Icons.people_outline, size: 80, color: AppTheme.textLight.withAlpha(100)),
          const SizedBox(height: 16),
          Text('No customers found', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filters', style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textLight)),
        ],
      ),
    );
  }

  void _showCustomerDetails(CustomerModel user) {
    Provider.of<CustomersProvider>(context, listen: false).selectCustomer(user.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerDetailSheet(user: user)
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor : AppTheme.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.whiteColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// Customer Card Widget - Updated to match the PackagesScreen recent customers design
class _CustomerCard extends StatelessWidget {
  final CustomerModel user;
  final VoidCallback onTap;

  const _CustomerCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.border,
            width: 1,
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Name and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: user.isActive 
                                  ? AppTheme.accentGreen.withAlpha(20)
                                  : AppTheme.error.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user.isActive ? 'Active' : 'Inactive',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: user.isActive 
                                    ? AppTheme.accentGreen 
                                    : AppTheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar on the right
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Row - Credits and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${user.credits} credits',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Joined ${_formatDate(user.createdAt)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CustomerDetailSheet extends StatelessWidget {
  final CustomerModel user;

  const _CustomerDetailSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryDark, AppTheme.primaryColor, AppTheme.primaryLight]
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryDark.withAlpha(40),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.whiteColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  Text(
                    user.email,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.bolt,
                          label: 'Credits',
                          value: '${user.credits}',
                          color: AppTheme.accentOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.photo,
                          label: 'Photos',
                          value: '${user.totalPhotosProcessed}',
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DetailStatCard(
                          icon: Icons.shopping_cart,
                          label: 'Spent',
                          value: '\$${user.totalSpent.toStringAsFixed(0)}',
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Add Credits',
                    color: AppTheme.success,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddCreditsDialog(context, user);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit Customer',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showEditCustomerDialog(context, user);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: user.isActive ? Icons.block : Icons.check_circle_outline,
                    label: user.isActive ? 'Deactivate Account' : 'Activate Account',
                    color: user.isActive ? AppTheme.error : AppTheme.success,
                    onTap: () {
                      Navigator.pop(context);
                      _toggleUserStatus(context, user);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.phone_android,
                    label: 'Pay by Mobile',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      _showClickPesaPayoutDialog(context, user);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.history,
                    label: 'View History',
                    color: AppTheme.accentBlue,
                    onTap: () {
                      Navigator.pop(context);
                      _showUserHistory(context, user);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCreditsDialog(BuildContext context, CustomerModel user) {
    final creditsController = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AnimatedPadding(
        padding: MediaQuery.of(ctx).viewInsets,
        duration: const Duration(milliseconds: 100),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Credits', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add credits to ${user.name}\'s account', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  controller: creditsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Credits to add',
                    prefixIcon: const Icon(Icons.bolt, color: AppTheme.accentOrange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                final credits = int.tryParse(creditsController.text) ?? 0;
                if (credits > 0) {
                  Provider.of<CustomersProvider>(ctx, listen: false).addCredits(user.id, credits);
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added $credits credits to ${user.name}'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Add Credits', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).whenComplete(() => creditsController.dispose());
  }

  void _showEditCustomerDialog(BuildContext context, CustomerModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    showDialog(
      context: context,
      builder: (ctx) => AnimatedPadding(
        padding: MediaQuery.of(ctx).viewInsets,
        duration: const Duration(milliseconds: 100),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Customer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () async {
                final updated = user.copyWith(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                );
                await Provider.of<CustomersProvider>(context, listen: false).updateCustomer(updated);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Customer updated successfully'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    });
  }

  void _toggleUserStatus(BuildContext context, CustomerModel user) {
    Provider.of<CustomersProvider>(context, listen: false).toggleCustomerStatus(user.id, !user.isActive);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(user.isActive ? '${user.name} has been deactivated' : '${user.name} has been activated'),
        backgroundColor: user.isActive ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  void _showClickPesaPayoutDialog(BuildContext context, CustomerModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.phone_android, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text('Pay by Mobile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: _payoutFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Send money to ${user.name} via ClickPesa', 
                     style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),
                
                // Phone Number
                TextFormField(
                  controller: _payoutPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '255712345678',
                    prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!RegExp(r'^255[0-9]{9}$').hasMatch(value)) {
                      return 'Enter valid Tanzanian phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Amount
                TextFormField(
                  controller: _payoutAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (TZS)',
                    hintText: '10000',
                    prefixIcon: const Icon(Icons.money, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Amount is required';
                    }
                    final amount = int.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Enter valid amount';
                    }
                    if (amount < 1000) {
                      return 'Minimum amount is TZS 1,000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ClickPesa Instructions:',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Enter recipient phone number\n2. Enter amount in TZS\n3. Click "Send Payment"\n4. USSD prompt will appear\n5. Enter PIN to confirm',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_payoutFormKey.currentState!.validate()) {
                final phoneNumber = _payoutPhoneController.text.trim();
                final amount = int.parse(_payoutAmountController.text);
                
                // Generate order reference
                final orderReference = 'PAYOUT_${DateTime.now().millisecondsSinceEpoch}';
                
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Initiating payment...'),
                        ],
                      ),
                    ),
                  );
                  
                  // Initiate payout
                  final response = await _apiService.initiateClickPesaPayout(
                    phoneNumber: phoneNumber,
                    amount: amount,
                    orderReference: orderReference,
                  );
                  
                  // Close loading dialog
                  Navigator.pop(ctx);
                  
                  if (response['success']) {
                    // Show success message
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Payment Initiated!', style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Check your phone for USSD prompt', 
                                 style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                            const SizedBox(height: 8),
                            Text('Order Reference: $orderReference', 
                                 style: GoogleFonts.poppins(fontFamily: 'monospace')),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment failed: ${response['error']}'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Send Payment', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUserHistory(BuildContext context, CustomerModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<CustomersProvider>(
        builder: (context, provider, child) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(Icons.history, color: AppTheme.accentBlue, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      '${user.name}\'s History',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.customerTransactions.isEmpty
                        ? const Center(child: Text('No transaction history available'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: provider.customerTransactions.length,
                            itemBuilder: (context, index) {
                              final tx = provider.customerTransactions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: tx.typeString == 'usage' ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        tx.typeString == 'usage' ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                        color: tx.typeString == 'usage' ? AppTheme.error : AppTheme.success,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.description ?? (tx.typeString == 'usage' ? 'Credits used' : 'Credits added'),
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt),
                                            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      tx.typeString == 'usage' ? '-${tx.credits}' : '+${tx.credits}',
                                      style: GoogleFonts.poppins(
                                        color: tx.typeString == 'usage' ? AppTheme.error : AppTheme.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}