import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  File? _imageFile;
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.refreshUser();
    final user = auth.user;
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone;
        _isLoadingData = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  String _getUserInitial(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Change Profile Photo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildPhotoOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: AppTheme.accent,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildPhotoOption(
                  icon: Icons.delete,
                  label: 'Remove',
                  color: AppTheme.error,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imageFile = null);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = _imageFile!.path;
      }

      final success = await auth.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: photoUrl,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.whiteColor),
                  const SizedBox(width: 12),
                  Text('Profile updated successfully!', style: GoogleFonts.poppins()),
                ],
              ),
              backgroundColor: AppTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${auth.error ?? 'Unknown error'}'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoadingData
          ? _buildShimmer()
          : Column(
              children: [
                _buildHeader(context, user),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Space for avatar that overlaps header
                          const SizedBox(height: 60),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldRow(
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                  hintText: 'Enter your full name',
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  keyboardType: TextInputType.name,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
                                ),
                                const SizedBox(height: 20),
                                _buildFieldRow(
                                  label: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  hintText: 'Enter your phone number',
                                  controller: _phoneController,
                                  focusNode: _phoneFocus,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 20),
                                _buildFieldRow(
                                  label: 'Email Address',
                                  icon: Icons.email_outlined,
                                  hintText: '',
                                  controller: _emailController,
                                  readOnly: true,
                                ),
                                const SizedBox(height: 32),
                                _buildSaveButton(),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Header: gradient + avatar ───────────────────────────────────

  Widget _buildHeader(BuildContext context, user) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Gradient background
        Container(
          height: 180,
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
        // Back button top-left
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.whiteColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.whiteColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 44), // balance back button
                ],
              ),
            ),
          ),
        ),
        // Avatar centered at bottom, overlapping below
        Positioned(
          bottom: -48,
          child: Column(
            children: [
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.whiteColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryDark.withAlpha(60),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: user!.photoUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, url) => Shimmer.fromColors(
                                      baseColor: AppTheme.primarySoft,
                                      highlightColor: AppTheme.surface,
                                      child: Container(color: AppTheme.primarySoft),
                                    ),
                                    errorWidget: (ctx, url, err) => _buildInitialAvatar(user?.name),
                                  )
                                : _buildInitialAvatar(user?.name),
                      ),
                    ),
                    // Camera badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 15),
                      ),
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

  Widget _buildInitialAvatar(String? name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getUserInitial(name),
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Login-style field row ────────────────────────────────────────

  Widget _buildFieldRow({
    required String label,
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    FocusNode? focusNode,
    bool readOnly = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? AppTheme.backgroundColor : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            validator: validator,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: readOnly ? AppTheme.textSecondary : AppTheme.text,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(color: AppTheme.textLight),
              prefixIcon: Icon(
                icon,
                color: readOnly ? AppTheme.textSecondary : AppTheme.primaryColor,
              ),
              suffixIcon: readOnly
                  ? const Icon(Icons.lock_outline, color: AppTheme.textLight, size: 18)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  // ── Save button ──────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _isLoading ? null : _saveProfile,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: _isLoading ? null : AppTheme.primaryGradient,
            color: _isLoading ? AppTheme.primarySoft : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.primaryColor.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: _isLoading
              ? Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ── Shimmer loading ──────────────────────────────────────────────

  Widget _buildShimmer() {
    return Column(
      children: [
        // Header shimmer
        Shimmer.fromColors(
          baseColor: AppTheme.primarySoft,
          highlightColor: AppTheme.surface,
          child: Container(height: 180, color: AppTheme.primarySoft),
        ),
        const SizedBox(height: 64),
        // Fields shimmer
        ...List.generate(3, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Shimmer.fromColors(
            baseColor: AppTheme.primarySoft,
            highlightColor: AppTheme.surface,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),
      ],
    );
  }
}
