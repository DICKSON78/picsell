import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/theme.dart';
import '../services/firestore_service.dart';
import '../models/customer_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  
  String _selectedType = 'info';
  String _selectedTarget = 'all';
  CustomerModel? _selectedCustomer;
  bool _isSending = false;
  Future<List<CustomerModel>>? _customersFuture;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_selectedTarget != 'all' && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await _firestoreService.sendNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        userId: _selectedTarget == 'all' ? 'all' : _selectedCustomer!.id,
        type: _selectedType,
      );

      if (mounted) {
        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _selectedTarget = 'all';
          _selectedCustomer = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryDark,
                      AppTheme.primaryColor,
                      AppTheme.primaryLight,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Send Notification',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.whiteColor,
                                    ),
                                  ),
                                  Text(
                                    'Communicate with customers',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.whiteColor.withAlpha(200),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Form Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Selection
                  Text(
                    'Notification Type',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeChip('info', Icons.info_outline, AppTheme.accentBlue),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeChip('promo', Icons.local_offer_outlined, AppTheme.accentOrange),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTypeChip('alert', Icons.warning_amber_outlined, AppTheme.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Target Selection
                  Text(
                    'Send To',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTargetChip('all', 'All Users', Icons.groups),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTargetChip('specific', 'Specific User', Icons.person),
                      ),
                    ],
                  ),
                  
                  if (_selectedTarget == 'specific') ...[
                    const SizedBox(height: 12),
                    _buildCustomerSelector(),
                  ],

                  const SizedBox(height: 24),

                  // Title Input
                  Text(
                    'Title',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.poppins(color: AppTheme.text),
                    decoration: InputDecoration(
                      hintText: 'e.g. Special Offer!',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Body Input
                  Text(
                    'Message',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyController,
                    maxLines: 5,
                    style: GoogleFonts.poppins(color: AppTheme.text),
                    decoration: InputDecoration(
                      hintText: 'Enter your message here...',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.whiteColor,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send, color: AppTheme.whiteColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Send Notification',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.whiteColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(
              type.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetChip(String target, String label, IconData icon) {
    final isSelected = _selectedTarget == target;
    return GestureDetector(
      onTap: () => setState(() => _selectedTarget = target),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withAlpha(25) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    _customersFuture ??= _firestoreService.getCustomers(limit: 100);
    return FutureBuilder<List<CustomerModel>>(
      future: _customersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 50,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text(
            'No customers found',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary),
          );
        }

        final customers = snapshot.data!;
        final isValueValid = _selectedCustomer == null ||
            customers.any((c) => c.id == _selectedCustomer!.id);
        final dropdownValue = isValueValid ? _selectedCustomer?.id : null;
        if (!isValueValid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedCustomer = null);
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButton<String>(
            value: dropdownValue,
            hint: Text(
              'Select a customer',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
            isExpanded: true,
            underline: const SizedBox(),
            items: customers.map((customer) {
              return DropdownMenuItem<String>(
                value: customer.id,
                child: Text(
                  '${customer.name} (${customer.email})',
                  style: GoogleFonts.poppins(color: AppTheme.text),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (customerId) {
              final found = customers.where((c) => c.id == customerId).isNotEmpty
                  ? customers.firstWhere((c) => c.id == customerId)
                  : null;
              if (found != null) setState(() => _selectedCustomer = found);
            },
          ),
        );
      },
    );
  }
}
