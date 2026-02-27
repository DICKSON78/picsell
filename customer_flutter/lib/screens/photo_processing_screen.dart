import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../utils/watermark_util.dart';
import '../utils/theme.dart';
import '../services/photoroom_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../models/category_config.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';

class PhotoProcessingScreen extends StatefulWidget {
  const PhotoProcessingScreen({super.key});

  @override
  State<PhotoProcessingScreen> createState() => _PhotoProcessingScreenState();
}

class _PhotoProcessingScreenState extends State<PhotoProcessingScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final PhotoRoomService _photoRoomService = PhotoRoomService();
  final FirestoreService _firestoreService = FirestoreService();

  File? _originalImage;
  File? _processedImage;
  bool _isProcessing = false;
  String _processingStatus = '';
  int _userCredits = 5;
  List<BrandingSuggestion> _brandingSuggestions = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _hasAutoOpened = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadUserCredits();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasAutoOpened) {
      _hasAutoOpened = true;
      // Check if we should auto-open camera or gallery
      final args = ModalRoute.of(context)?.settings.arguments as String?;
      if (args != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (args == 'camera') {
            _pickImage(ImageSource.camera);
          } else if (args == 'gallery') {
            _pickImage(ImageSource.gallery);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCredits() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final userData = await _firestoreService.getUser(authProvider.user!.id);
        if (mounted && userData != null) {
          setState(() {
            _userCredits = userData.credits;
          });
        }
      }
    } catch (e) {
      // Use default credits if fetch fails
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );

      if (pickedFile != null) {
        setState(() {
          _originalImage = File(pickedFile.path);
          _processedImage = null;
          _brandingSuggestions = [];
        });

        // Automatically start processing
        await _processImage();
      }
    } catch (e) {
      _showError(localization.isSwahili ? 'Imeshindwa kuchagua picha' : 'Failed to select image');
    }
  }

  Future<void> _processImage() async {
    if (_originalImage == null) return;
    final localization = Provider.of<LocalizationProvider>(context, listen: false);

    if (_userCredits < 1) {
      _showInsufficientCreditsDialog();
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = localization.isSwahili ? 'Inaandaa picha...' : 'Preparing image...';
    });

    try {
      // Show processing status
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _processingStatus = localization.isSwahili ? 'Inaboresha picha...' : 'Enhancing image...');
      }

      // Process image using Products category (solid bg, lighting, shadow)
      final result = await _photoRoomService.processByMode(_originalImage!, ProcessingMode.products);

      if (mounted) {
        setState(() => _processingStatus = localization.isSwahili ? 'Inahifadhi picha...' : 'Saving image...');
      }
      await Future.delayed(const Duration(milliseconds: 400));

      // Deduct credit locally
      _userCredits = _userCredits - 1;

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processedImage = result.processedFile;
          _brandingSuggestions = result.brandingSuggestions;
        });

        // Show before/after comparison with branding suggestions
        _showComparisonDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = '';
        });
        _showError(localization.isSwahili
            ? 'Imeshindwa kuchakata picha: ${e.toString()}'
            : 'Failed to process image: ${e.toString()}');
      }
    }
  }

  void _showInsufficientCreditsDialog() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber, color: AppTheme.error),
            ),
            const SizedBox(width: 12),
            Text(
              localization.isSwahili ? 'Krediti Hazitoshi' : 'Insufficient Credits',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          localization.isSwahili
              ? 'Una krediti $_userCredits tu. Unahitaji angalau krediti 1 kuchakata picha.'
              : 'You have $_userCredits credits. You need at least 1 credit to process a photo.',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.isSwahili ? 'Baadaye' : 'Later', style: GoogleFonts.poppins()),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/credits');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                localization.isSwahili ? 'Nunua Krediti' : 'Buy Credits',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComparisonDialog() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BeforeAfterDialog(
        originalImage: _originalImage!,
        processedImage: _processedImage!,
        brandingSuggestions: _brandingSuggestions,
        isSwahili: localization.isSwahili,
        onSave: () {
          Navigator.pop(context);
          _showSaveSuccessDialog();
        },
        onRetry: () {
          Navigator.pop(context);
          setState(() {
            _originalImage = null;
            _processedImage = null;
            _brandingSuggestions = [];
          });
        },
      ),
    );
  }

  void _showSaveSuccessDialog() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 45),
            ),
            const SizedBox(height: 20),
            Text(
              localization.isSwahili ? 'Picha Imehifadhiwa!' : 'Photo Saved!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localization.isSwahili
                  ? 'Picha yako imehifadhiwa kwenye galari'
                  : 'Your photo has been saved to the gallery',
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    localization.isSwahili
                        ? 'Krediti zilizobaki: $_userCredits'
                        : 'Credits remaining: $_userCredits',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _originalImage = null;
                        _processedImage = null;
                        _brandingSuggestions = [];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          localization.isSwahili ? 'Picha Nyingine' : 'New Photo',
                          style: GoogleFonts.poppins(
                            color: AppTheme.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/gallery');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          localization.isSwahili ? 'Tazama Galari' : 'View Gallery',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isProcessing ? _buildProcessingView() : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    final localization = Provider.of<LocalizationProvider>(context);
    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(Icons.arrow_back, color: AppTheme.text),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'PicSell Studio',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                ),
                // Credits badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$_userCredits',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Hero illustration
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withAlpha(20),
                          AppTheme.accent.withAlpha(20),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withAlpha(80),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          localization.isSwahili ? 'Piga au Pakia Picha' : 'Take or Upload Photo',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localization.isSwahili
                              ? 'Picha yako itaboreshwa papo hapo'
                              : 'Your photo will be enhanced instantly',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      // Take Photo
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickImage(ImageSource.camera),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withAlpha(60),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(40),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  localization.isSwahili ? 'Piga Picha' : 'Take Photo',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  localization.isSwahili ? 'Tumia kamera' : 'Use camera',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withAlpha(180),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Upload Photo
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.border, width: 2),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primarySoft,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.photo_library,
                                    color: AppTheme.primaryColor,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  localization.isSwahili ? 'Pakia Picha' : 'Upload Photo',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  localization.isSwahili ? 'Chagua kutoka galari' : 'Choose from gallery',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Features list
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.isSwahili ? 'PicSell Inafanya Nini?' : 'What PicSell Does',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          Icons.auto_fix_high,
                          localization.isSwahili ? 'Inaondoa Background' : 'Removes Background',
                          localization.isSwahili
                              ? 'Picha yako inapata background nyeupe safi'
                              : 'Your photo gets a clean white background',
                          AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          Icons.wb_sunny,
                          localization.isSwahili ? 'Inaboresha Mwangaza' : 'Enhances Lighting',
                          localization.isSwahili
                              ? 'Mwangaza unarekebishwa kiautomatiki'
                              : 'Lighting is automatically adjusted',
                          AppTheme.accentOrange,
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureItem(
                          Icons.high_quality,
                          localization.isSwahili ? 'Ubora wa Juu' : 'High Quality',
                          localization.isSwahili
                              ? 'Picha inatoka kwa ubora wa professional'
                              : 'Professional quality output',
                          AppTheme.accentGreen,
                        ),
                      ],
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

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.text,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primaryColor,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated AI icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primaryColor,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Original image preview
              if (_originalImage != null)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(50), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.file(
                      _originalImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Processing status
              Text(
                _processingStatus,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // Loading indicator
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withAlpha(200),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Builder(
                builder: (context) {
                  final localization = Provider.of<LocalizationProvider>(context, listen: false);
                  return Text(
                    localization.isSwahili ? 'Tafadhali subiri...' : 'Please wait...',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withAlpha(180),
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Before/After Comparison Dialog
class _BeforeAfterDialog extends StatefulWidget {
  final File originalImage;
  final File processedImage;
  final List<BrandingSuggestion> brandingSuggestions;
  final bool isSwahili;
  final VoidCallback onSave;
  final VoidCallback onRetry;

  const _BeforeAfterDialog({
    required this.originalImage,
    required this.processedImage,
    required this.brandingSuggestions,
    required this.isSwahili,
    required this.onSave,
    required this.onRetry,
  });

  @override
  State<_BeforeAfterDialog> createState() => _BeforeAfterDialogState();
}

class _BeforeAfterDialogState extends State<_BeforeAfterDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showOriginal = false;
  bool _showBrandingSuggestions = false;
  bool _isSharing = false;
  String? _copiedText;

  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _sellerController = TextEditingController();
  final _sizeController = TextEditingController();
  final _productFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _productNameController.dispose();
    _priceController.dispose();
    _sellerController.dispose();
    _sizeController.dispose();
    _productFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveCaption() async {
    final caption = {
      'product': _productNameController.text.trim(),
      'price': _priceController.text.trim(),
      'seller': _sellerController.text.trim(),
      'size': _sizeController.text.trim(),
    };
    await LocalStorageService().saveCaption(widget.processedImage, caption);
  }

  Future<void> _shareWithCaption() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      // Save caption details to JSON sidecar first
      await _saveCaption();

      // Try watermark; fall back to original processed image if it fails
      File fileToShare;
      try {
        fileToShare = await addCaptionWatermark(
          widget.processedImage,
          productName: _productNameController.text.trim(),
          price: _priceController.text.trim(),
          seller: _sellerController.text.trim(),
          size: _sizeController.text.trim(),
        );
      } catch (_) {
        fileToShare = widget.processedImage;
      }
      if (!mounted) return;
      await Share.shareXFiles([XFile(fileToShare.path)]);
    } catch (_) {}

    if (mounted) setState(() => _isSharing = false);
  }

  Widget _captionField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    String? prefix,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      focusNode: focusNode,
      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 18),
        prefixText: prefix,
        prefixStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedText = text);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedText = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withAlpha(40),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.compare,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isSwahili ? 'Picha Imekamilika!' : 'Photo Complete!',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.text,
                            ),
                          ),
                          Text(
                            widget.isSwahili ? 'Linganisha kabla na baada' : 'Compare before and after',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Image comparison
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Processed image (default)
                        Image.file(
                          widget.processedImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.backgroundColor,
                              child: const Center(
                                child: Icon(Icons.error, color: AppTheme.error, size: 40),
                              ),
                            );
                          },
                        ),

                        // Original image overlay
                        if (_showOriginal)
                          Image.file(
                            widget.originalImage,
                            fit: BoxFit.cover,
                          ),

                        // Labels
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _showOriginal
                                  ? AppTheme.error.withAlpha(220)
                                  : AppTheme.success.withAlpha(220),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _showOriginal
                                  ? (widget.isSwahili ? 'KABLA' : 'BEFORE')
                                  : (widget.isSwahili ? 'BAADA' : 'AFTER'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Toggle button
                GestureDetector(
                  onTapDown: (_) => setState(() => _showOriginal = true),
                  onTapUp: (_) => setState(() => _showOriginal = false),
                  onTapCancel: () => setState(() => _showOriginal = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showOriginal ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isSwahili ? 'Bonyeza kuona awali' : 'Hold to see original',
                          style: GoogleFonts.poppins(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Branding Suggestions Section
                if (widget.brandingSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),

                  // Toggle branding suggestions
                  GestureDetector(
                    onTap: () => setState(() => _showBrandingSuggestions = !_showBrandingSuggestions),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentOrange.withAlpha(20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.accentOrange.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.auto_awesome, color: AppTheme.accentOrange, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isSwahili ? 'Maneno ya Kubrand' : 'Branding Text',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.text,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  widget.isSwahili ? 'Bonyeza kuchagua' : 'Tap to select',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _showBrandingSuggestions ? Icons.expand_less : Icons.expand_more,
                            color: AppTheme.accentOrange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Branding suggestions list
                  if (_showBrandingSuggestions) ...[
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.brandingSuggestions.take(6).map((suggestion) {
                            final text = widget.isSwahili ? suggestion.text : suggestion.textEn;
                            final isCopied = _copiedText == text;
                            return GestureDetector(
                              onTap: () => _copyToClipboard(text),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isCopied ? AppTheme.success.withAlpha(20) : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isCopied ? AppTheme.success : AppTheme.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isCopied ? Icons.check : Icons.copy,
                                      size: 14,
                                      color: isCopied ? AppTheme.success : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      text,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isCopied ? AppTheme.success : AppTheme.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isSwahili ? 'Bonyeza kunakili' : 'Tap to copy',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 16),

                // Caption / Product Details
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryColor.withAlpha(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sell_outlined, color: AppTheme.primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            widget.isSwahili ? 'Maelezo ya Bidhaa' : 'Product Details',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _captionField(
                        controller: _productNameController,
                        hint: widget.isSwahili ? 'Jina la bidhaa...' : 'Product name...',
                        label: 'Product',
                        icon: Icons.inventory_2_outlined,
                        focusNode: _productFocusNode,
                      ),
                      const SizedBox(height: 8),
                      _captionField(
                        controller: _priceController,
                        hint: widget.isSwahili ? 'Bei (TZS)...' : 'Price (TZS)...',
                        label: 'Price',
                        icon: Icons.attach_money,
                        prefix: 'TZS  ',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      _captionField(
                        controller: _sellerController,
                        hint: widget.isSwahili ? 'Jina la duka (mfano: Hidaya Shop)...' : 'Shop name (e.g. Hidaya Shop)...',
                        label: 'Seller',
                        icon: Icons.store_outlined,
                      ),
                      const SizedBox(height: 8),
                      _captionField(
                        controller: _sizeController,
                        hint: widget.isSwahili ? 'Ukubwa (mfano: XL, 42, Large)...' : 'Size (e.g. XL, 42, Large)...',
                        label: 'Size',
                        icon: Icons.straighten_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons: Edit | Share
                Row(
                  children: [
                    // Save — persist caption to JSON sidecar
                    Expanded(
                      child: GestureDetector(
                        onTap: _isSharing ? null : () async {
                          await _saveCaption();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.isSwahili ? 'Maelezo yamehifadhiwa' : 'Details saved',
                                    style: GoogleFonts.poppins(fontSize: 13),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isSharing ? AppTheme.border : AppTheme.primaryColor.withAlpha(160),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bookmark_outline,
                                  color: _isSharing ? AppTheme.textLight : AppTheme.primaryColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                widget.isSwahili ? 'Hifadhi' : 'Save',
                                style: GoogleFonts.poppins(
                                  color: _isSharing ? AppTheme.textLight : AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Share — burn caption watermark and share
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _isSharing ? null : _shareWithCaption,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            gradient: _isSharing ? null : AppTheme.primaryGradient,
                            color: _isSharing ? AppTheme.border : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _isSharing
                                ? []
                                : [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withAlpha(60),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSharing)
                                const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              else
                                const Icon(Icons.share, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _isSharing
                                    ? (widget.isSwahili ? 'Inatuma...' : 'Sharing...')
                                    : (widget.isSwahili ? 'Share' : 'Share'),
                                style: GoogleFonts.poppins(
                                  color: _isSharing ? AppTheme.textSecondary : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
