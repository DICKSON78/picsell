import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/photoroom_service.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../models/photo_model.dart';
import '../models/category_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/notification_provider.dart';
import '../utils/watermark_util.dart';
import '../services/local_storage_service.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  final PhotoRoomService _photoRoomService = PhotoRoomService();

  // Processing state
  bool _isProcessing = false;
  String _processingStatus = '';
  File? _selectedImage;

  // Branding suggestions from smart processing
  List<BrandingSuggestion> _brandingSuggestions = [];

  // Recent photos from Device
  List<File> _localRecentPhotos = [];
  bool _isLoadingPhotos = true;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Promotional slider
  int _currentPromoIndex = 0;

  // Default promotional slides (always shown when no active ads)
  static const List<Map<String, String>> _defaultSlides = [
    {
      'image': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800',
      'title': 'Selling Made Easy',
      'subtitle': 'Quality photos ready in seconds!',
    },
    {
      'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800',
      'title': 'Stand Out Online',
      'subtitle': 'Make your products shine on any platform',
    },
    {
      'image': 'https://images.unsplash.com/photo-1560343090-f0409e92791a?w=800',
      'title': 'Professional Results',
      'subtitle': 'Studio-quality photos from your phone',
    },
    {
      'image': 'https://images.unsplash.com/photo-1491637639811-60e2756cc1c7?w=800',
      'title': 'Boost Your Sales',
      'subtitle': 'Attract more buyers with better photos',
    },
    {
      'image': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800',
      'title': 'Your Online Store',
      'subtitle': 'Present your products like a pro',
    },
    {
      'image': 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800',
      'title': 'Fashion & Style',
      'subtitle': 'Clothing and apparel that stands out',
    },
    {
      'image': 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=800',
      'title': 'Shoes & Accessories',
      'subtitle': 'Your products shine in the market',
    },
    {
      'image': 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800',
      'title': 'Home & Furniture',
      'subtitle': 'Show your products from every angle',
    },
    {
      'image': 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=800',
      'title': 'Tech & Gadgets',
      'subtitle': 'Electronics that capture attention',
    },
    {
      'image': 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800',
      'title': 'Clean White Background',
      'subtitle': 'Pure white background in one tap',
    },
    {
      'image': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800',
      'title': 'Beauty Products',
      'subtitle': 'Your cosmetics look premium instantly',
    },
    {
      'image': 'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=800',
      'title': 'Sports & Fitness',
      'subtitle': 'Sportswear photos full of energy',
    },
    {
      'image': 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=800',
      'title': "Kids' Clothing",
      'subtitle': "Children's wear displayed beautifully",
    },
    {
      'image': 'https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?w=800',
      'title': 'Food & Beverages',
      'subtitle': 'Menu photos that make mouths water',
    },
    {
      'image': 'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=800',
      'title': 'Grow Your Business',
      'subtitle': 'Join thousands of successful sellers',
    },
  ];

  // Live ads from Firestore (active + not expired)
  List<Map<String, dynamic>> _liveAds = [];

  // Time timer (for status bar updates)
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();

    // Set status bar to light (white icons/text)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _loadRecentPhotos();
    _loadLiveAds();
    _startTimeTimer();

    // Start auto-slide immediately after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlide());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _timeTimer?.cancel();
    super.dispose();
  }

  void _startAutoSlide() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 6));
      if (!mounted) return false;
      setState(() => _currentPromoIndex++);
      return true;
    });
  }

  Future<void> _loadLiveAds() async {
    try {
      // Simple query — no composite index needed; expiry is filtered locally
      final snapshot = await FirebaseFirestore.instance
          .collection('advertisements')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      final now = DateTime.now();
      final ads = snapshot.docs.map((d) => d.data()).where((ad) {
        final ts = ad['expiresAt'] as Timestamp?;
        if (ts == null) return true; // no expiry set → always show
        return ts.toDate().isAfter(now);
      }).toList();

      if (mounted) {
        setState(() => _liveAds = ads);
        // _startAutoSlide() is already running via Future.doWhile — it reads live state each iteration
      }
    } catch (_) {
      // On error, keep the default-slides timer already started in initState
    }
  }

  void _startTimeTimer() {
    _timeTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Can be used for periodic data refresh
    });
  }

  // Load recent photos from Local Device Storage
  Future<void> _loadRecentPhotos() async {
    setState(() => _isLoadingPhotos = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user != null) {
        // Listen to notifications as well
        Provider.of<NotificationProvider>(context, listen: false).listenToNotifications(user.id);
        
        // Fetch from local storage
        final photos = await _photoRoomService.getRecentImages(limit: 3);
        if (mounted) {
          setState(() {
            _localRecentPhotos = photos;
            _isLoadingPhotos = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingPhotos = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPhotos = false);
      }
    }
  }

  // Pick image from camera or gallery - Show preview first
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
        final file = File(pickedFile.path);
        final fileSizeKb = await file.length() ~/ 1024;
        // Flag images under 200KB as potentially low quality
        final isLowQuality = fileSizeKb < 200;
        setState(() {
          _selectedImage = file;
          _brandingSuggestions = [];
        });
        // Show preview dialog with Process/Retake options
        _showImagePreviewDialog(source, isLowQuality: isLowQuality);
      }
    } catch (e) {
      _showError(localization.isSwahili ? 'Imeshindwa kuchagua picha' : 'Failed to select image');
    }
  }

  // Show image preview with Process/Retake options
  void _showImagePreviewDialog(ImageSource source, {bool isLowQuality = false}) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => _ImagePreviewSheet(
        imageFile: _selectedImage!,
        isSwahili: localization.isSwahili,
        isLowQuality: isLowQuality,
        onRetake: () {
          Navigator.pop(context);
          setState(() => _selectedImage = null);
          _pickImage(source);
        },
        onProcess: () {
          Navigator.pop(context);
          _showCategorySelectionDialog();
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => _selectedImage = null);
        },
      ),
    );
  }

  // Show category selection dialog
  void _showCategorySelectionDialog() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => _CategorySelectionSheet(
        isSwahili: localization.isSwahili,
        onCategorySelected: (ProcessingMode mode) async {
          Navigator.pop(context);
          await _processImageWithMode(mode);
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => _selectedImage = null);
        },
      ),
    );
  }

  // Process image with selected processing mode
  Future<void> _processImageWithMode(ProcessingMode mode) async {
    if (_selectedImage == null) return;

    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user has enough credits (2 per image)
    if (authProvider.credits < 2) {
      _showError(localization.isSwahili
          ? 'Credits hazitoshi. Unahitaji credits 2 kwa picha moja.'
          : 'Not enough credits. You need 2 credits per image.');
      Navigator.pushNamed(context, '/credits');
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = localization.isSwahili ? 'Inaandaa picha...' : 'Preparing image...';
    });

    try {
      // Deduct 2 credits
      final deducted = await authProvider.deductCredit(amount: 2);
      if (!deducted) {
        setState(() => _isProcessing = false);
        _showError(localization.isSwahili
            ? 'Imeshindwa kutoa credits.'
            : 'Failed to deduct credits.');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _processingStatus = localization.tr('enhancing_ai'));
      }

      // Process with selected mode
      final result = await _photoRoomService.processByMode(_selectedImage!, mode);

      if (mounted) {
        setState(() => _processingStatus = localization.isSwahili ? 'Inakamilisha...' : 'Finishing...');
      }
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show Before/After comparison
        _showBeforeAfterDialog(result.processedFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = '';
        });
        _showError(localization.isSwahili
            ? 'Imeshindwa kuprocess picha: ${e.toString()}'
            : 'Failed to process image: ${e.toString()}');
      }
    }
  }

  // Show Before/After comparison dialog
  void _showBeforeAfterDialog(File processedFile) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BeforeAfterDialog(
        originalImage: _selectedImage!,
        processedImage: processedFile,
        isSwahili: localization.isSwahili,
        onSave: () async {
          Navigator.pop(context);
          await _loadRecentPhotos();
          setState(() {
            _isProcessing = false;
            _brandingSuggestions = _photoRoomService.generateBrandingSuggestions();
            _selectedImage = null;
          });
          // Show caption editor immediately after saving
          _showCaptionEditorAfterSave(processedFile);
        },
        onReprocess: () {
          Navigator.pop(context);
          _photoRoomService.deleteImage(processedFile);
          _showCategorySelectionDialog();
        },
        onCancel: () {
          Navigator.pop(context);
          _photoRoomService.deleteImage(processedFile);
          setState(() {
            _selectedImage = null;
          });
        },
      ),
    );
  }

  // Show caption editor immediately after the processed image is saved.
  // User can add product name, price, seller, size then share or skip.
  void _showCaptionEditorAfterSave(File processedFile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostSaveCaptionSheet(
        processedFile: processedFile,
        onViewGallery: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/gallery');
        },
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Oops!',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('OK', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeroSection(),
                      _buildActionCards(),
                      _buildRecentPhotosSection(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              BottomNavBar(
                activeIndex: _selectedIndex,
                onTap: (index) {
                  setState(() => _selectedIndex = index);
                  _navigateToScreen(index);
                },
              ),
            ],
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.3),
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
                          child: const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 40),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              if (_selectedImage != null)
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 40),
              Text(
                _processingStatus,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final localization = Provider.of<LocalizationProvider>(context, listen: false);
                  return Text(
                    localization.isSwahili ? 'Tafadhali subiri...' : 'Please wait...',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    // East Africa Time is UTC+3
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon,';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening,';
    } else {
      return 'Good Night,';
    }
  }

  Widget _buildHeroSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final localization = Provider.of<LocalizationProvider>(context);
    final fullName = authProvider.user?.name ?? 'User';
    final userName = fullName.split(' ').first;
    final userPhoto = authProvider.user?.photoUrl;

    // Combine live ads + default slides into one list (ads first)
    final List<Map<String, String?>> combinedSlides = [
      ..._liveAds.map((ad) => {
        'image': ad['imageUrl'] as String?,
        'title': ad['title'] as String?,
        'subtitle': ad['subtitle'] as String?,
      }),
      ..._defaultSlides,
    ];
    final int totalCount = combinedSlides.length;

    return Stack(
      children: [
        // Dark branded background — always visible behind slides
        Container(
          height: 380,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryDark, AppTheme.primaryColor],
            ),
          ),
        ),
        SizedBox(
          height: 380,
          width: double.infinity,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 1200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            child: _buildSlideImage(
              key: ValueKey(_currentPromoIndex),
              slide: combinedSlides[_currentPromoIndex % totalCount],
            ),
          ),
        ),
        // Uniform dark scrim over images so all text is always readable
        Positioned.fill(
          child: Container(
            height: 380,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.35, 0.65, 1.0],
                colors: [
                  Colors.black.withAlpha(110),
                  Colors.black.withAlpha(60),
                  Colors.black.withAlpha(80),
                  Colors.black.withAlpha(160),
                ],
              ),
            ),
          ),
        ),
        // Bottom fade to page background
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 160,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.backgroundColor,
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
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Glow logo (tappable → account)
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/account'),
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, _) {
                        return SizedBox(
                          width: 46,
                          height: 46,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withAlpha((50 + (_glowAnimation.value * 70)).toInt()),
                                      blurRadius: 8 + (_glowAnimation.value * 10),
                                      spreadRadius: 1 + (_glowAnimation.value * 3),
                                    ),
                                  ],
                                ),
                              ),
                              // Ring
                              Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withAlpha((80 + (_glowAnimation.value * 120)).toInt()),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              // White circle with logo
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // PicSell text with dark pill background for visibility
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: Text(
                      'PicSell',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                    child: Stack(
                      children: [
                        Container(
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
                          child: const Icon(Icons.notifications_outlined, color: AppTheme.primaryColor, size: 24),
                        ),
                        Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, _) {
                            if (notificationProvider.unreadCount == 0) return const SizedBox.shrink();
                            return Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '${notificationProvider.unreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
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
          ),
        ),
         Builder(builder: (context) {
          final slide = combinedSlides[_currentPromoIndex % totalCount];
          final String adTitle = slide['title'] ?? '';
          final String adSubtitle = slide['subtitle'] ?? '';
          return Positioned(
          top: 130,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (adTitle.isNotEmpty)
                Text(
                  adTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black.withAlpha(100), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                ),
              if (adSubtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  adSubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withAlpha(230),
                    shadows: [Shadow(color: Colors.black.withAlpha(80), blurRadius: 6, offset: const Offset(0, 1))],
                  ),
                ),
              ],
            ],
          ),
        );
        }),
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.shadowLg,
              border: Border.all(color: AppTheme.border.withAlpha(50)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: userPhoto == null ? AppTheme.primaryGradient : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: userPhoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: userPhoto,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Center(child: Text('U', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24))),
                          ),
                        )
                      : Center(
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.whiteColor),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getGreeting(), style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                      Text(userName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/credits'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accentBlue]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                         Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: AppTheme.whiteColor, size: 18),
                            const SizedBox(width: 4),
                             Text('${authProvider.user?.credits ?? 0}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.whiteColor)),
                          ],
                        ),
                        Text(localization.tr('credits'), style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.whiteColor.withAlpha(200))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideImage({required Key key, required Map<String, String?> slide}) {
    final imageUrl = slide['image'] ?? '';
    if (imageUrl.isEmpty) {
      return SizedBox(key: key, width: double.infinity, height: 380, child: _buildBrandedFallback());
    }
    return CachedNetworkImage(
      key: key,
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 380,
      placeholder: (context, url) => _buildShimmer(380, double.infinity),
      errorWidget: (context, url, error) => _buildBrandedFallback(),
    );
  }

  Widget _buildBrandedFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'PicSell Studio',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'AI Photo Studio kwa Wachuuzi',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(double height, double width) {
    return Shimmer.fromColors(
      baseColor: AppTheme.primarySoft,
      highlightColor: AppTheme.surface,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    final localization = Provider.of<LocalizationProvider>(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              icon: Icons.camera_alt_rounded,
              title: localization.tr('take_photo'),
              subtitle: localization.tr('capture_camera'),
              gradientColors: [AppTheme.primaryColor, AppTheme.primaryLight],
              shadowColor: AppTheme.primaryColor,
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ActionCard(
              icon: Icons.cloud_upload_rounded,
              title: localization.tr('upload_photo'),
              subtitle: localization.tr('select_gallery'),
              gradientColors: [AppTheme.accent, AppTheme.accentBlue],
              shadowColor: AppTheme.accent,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPhotosSection() {
    final localization = Provider.of<LocalizationProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(localization.tr('recent_photos'), style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/gallery'),
                child: Text(localization.tr('view_all'), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: _isLoadingPhotos
              ? _buildShimmerPhotosList()
              : _localRecentPhotos.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _localRecentPhotos.length,
                      itemBuilder: (context, index) {
                        return _buildLocalPhotoCard(_localRecentPhotos[index], index, _localRecentPhotos.length);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildShimmerPhotosList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final localization = Provider.of<LocalizationProvider>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 8),
          Text(localization.isSwahili ? 'Hakuna picha bado' : 'No photos yet', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14)),
          Text(localization.isSwahili ? 'Piga au pakia picha kuanza' : 'Take or upload a photo to start', style: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(PhotoModel photo, int index, int total) {
    final localization = Provider.of<LocalizationProvider>(context);
    final imageUrl = photo.processedUrl ?? photo.originalUrl;

    return GestureDetector(
      onTap: () {
         if (imageUrl != null) {
            showDialog(
              context: context,
              builder: (ctx) => Dialog(
                backgroundColor: Colors.transparent,
                child: ClipRRect(borderRadius: BorderRadius.circular(20), child: CachedNetworkImage(imageUrl: imageUrl, placeholder: (c,u) => Shimmer.fromColors(baseColor: AppTheme.primarySoft, highlightColor: AppTheme.surface, child: Container(color: Colors.white)))),
              ),
            );
         }
      },
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: index < total - 1 ? 16 : 0),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border), boxShadow: AppTheme.shadowSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppTheme.backgroundColor),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageUrl != null 
                    ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, width: double.infinity, placeholder: (c,u) => Shimmer.fromColors(baseColor: AppTheme.primarySoft, highlightColor: AppTheme.surface, child: Container(color: Colors.white)), errorWidget: (c,u,e) => const Icon(Icons.error))
                    : const Center(child: Icon(Icons.image)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localization.isSwahili ? 'Picha ${index + 1}' : 'Photo ${index + 1}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.text), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(photo.statusString, style: GoogleFonts.poppins(fontSize: 12, color: photo.statusString == 'completed' ? AppTheme.success : AppTheme.warning)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalPhotoCard(File photo, int index, int total) {
    final localization = Provider.of<LocalizationProvider>(context);

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => PhotoFullscreenPage(
              photos: _localRecentPhotos,
              initialIndex: index,
              onDelete: (deletedPhoto) async {
                await _photoRoomService.deleteImage(deletedPhoto);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ),
        );
        // Refresh list in case user deleted a photo
        if (mounted) {
          final photos = await _photoRoomService.getRecentImages(limit: 3);
          if (mounted) setState(() => _localRecentPhotos = photos);
        }
      },
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: index < total - 1 ? 16 : 0),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppTheme.backgroundColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(photo, fit: BoxFit.cover, width: double.infinity),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.isSwahili ? 'Picha ${index + 1}' : 'Photo ${index + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'completed',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0: break;
      case 1: Navigator.pushNamed(context, '/history'); break;
      case 2: Navigator.pushNamed(context, '/credits'); break;
      case 3: Navigator.pushNamed(context, '/account'); break;
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.gradientColors, required this.shadowColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: shadowColor.withAlpha(80), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: AppTheme.whiteColor.withAlpha(50), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: AppTheme.whiteColor, size: 26),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.whiteColor)),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.whiteColor.withAlpha(180))),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewSheet extends StatelessWidget {
  final File imageFile;
  final bool isSwahili;
  final bool isLowQuality;
  final VoidCallback onRetake;
  final VoidCallback onProcess;
  final VoidCallback onCancel;

  const _ImagePreviewSheet({
    required this.imageFile,
    required this.isSwahili,
    required this.onRetake,
    required this.onProcess,
    required this.onCancel,
    this.isLowQuality = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(imageFile, height: 280, fit: BoxFit.cover),
          ),
          if (isLowQuality) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFCA28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isSwahili ? 'Picha ina ubora mdogo' : 'Low quality image detected',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSwahili
                        ? 'Kwa matokeo mazuri zaidi:\n• Piga picha mahali penye mwanga mzuri\n• Bidhaa iwe wazi na isiwe na ukungu\n• Bidhaa ijaze sehemu kubwa ya picha\n• Epuka mwanga wa nyuma (backlight)'
                        : 'For best results:\n• Use good lighting (natural light works best)\n• Keep the product in sharp focus, no blur\n• Fill most of the frame with the product\n• Avoid shooting against a bright background',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF78350F),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRetake,
                  child: Text(isSwahili ? 'Piga Tena' : 'Retake'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onProcess,
                  child: Text(isSwahili ? 'Endelea' : 'Continue'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onCancel, child: Text(isSwahili ? 'Ghairi' : 'Cancel', style: const TextStyle(color: AppTheme.textSecondary))),
        ],
      ),
    );
  }
}

class _CategorySelectionSheet extends StatelessWidget {
  final bool isSwahili;
  final Function(ProcessingMode) onCategorySelected;
  final VoidCallback onCancel;

  const _CategorySelectionSheet({required this.isSwahili, required this.onCategorySelected, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final categories = CategoryRegistry.allCategories;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Chagua Aina ya Uhariri' : 'Choose Editing Style',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text),
                    ),
                    Text(
                      isSwahili ? 'Chagua unavyotaka picha yako ichakatwe' : 'Select how you want your image processed',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Categories - 2x2 grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final config = categories[index];
              return _buildCategoryCard(context, config);
            },
          ),

          const SizedBox(height: 16),

          // Cancel button
          Center(
            child: TextButton(
              onPressed: onCancel,
              child: Text(
                isSwahili ? 'Ghairi' : 'Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryConfig config) {
    return GestureDetector(
      onTap: () => onCategorySelected(config.mode),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: config.iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(config.icon, color: config.iconColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili ? config.nameSwahili : config.nameEnglish,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BeforeAfterDialog extends StatelessWidget {
  final File originalImage;
  final File processedImage;
  final bool isSwahili;
  final VoidCallback onSave;
  final VoidCallback onReprocess;
  final VoidCallback onCancel;

  const _BeforeAfterDialog({
    required this.originalImage,
    required this.processedImage,
    required this.isSwahili,
    required this.onSave,
    required this.onReprocess,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.shadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSwahili ? 'Linganisha' : 'Comparison',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildComparisonItem(
                    image: originalImage,
                    label: isSwahili ? 'KABLA' : 'BEFORE',
                    badgeColor: Colors.grey[700]!,
                    isAfter: false,
                  ),
                  const SizedBox(width: 12),
                  _buildComparisonItem(
                    image: processedImage,
                    label: isSwahili ? 'BAADA' : 'AFTER',
                    badgeColor: AppTheme.primaryColor,
                    isAfter: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isSwahili ? 'Hifadhi Picha' : 'Save Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReprocess,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: AppTheme.border),
                          ),
                          child: Text(
                            isSwahili ? 'Rudia' : 'Reprocess',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: onCancel,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            isSwahili ? 'Ghairi' : 'Cancel',
                            style: GoogleFonts.poppins(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }

  Widget _buildComparisonItem({
    required File image,
    required String label,
    required Color badgeColor,
    bool isAfter = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          // Styled label above the image
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAfter ? Icons.auto_awesome : Icons.image_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          // Image below the label
          AspectRatio(
            aspectRatio: 0.8,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(image, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Caption editor shown immediately after a processed image is saved.
// User adds product name, price, seller/shop, size — then shares
// with caption burned top-left on the image (white text + shadow,
// no gradient, works on any background).
// ============================================================
class _PostSaveCaptionSheet extends StatefulWidget {
  final File processedFile;
  final VoidCallback onViewGallery;

  const _PostSaveCaptionSheet({
    required this.processedFile,
    required this.onViewGallery,
  });

  @override
  State<_PostSaveCaptionSheet> createState() => _PostSaveCaptionSheetState();
}

class _PostSaveCaptionSheetState extends State<_PostSaveCaptionSheet> {
  final _nameCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _sellerCtrl = TextEditingController();
  final _sizeCtrl   = TextEditingController();
  bool _isSaving = false;
  String _currency = 'TZS';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _sellerCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveWithCaption() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final name   = _nameCtrl.text.trim();
      final rawPrice = _priceCtrl.text.trim();
      final seller = _sellerCtrl.text.trim();
      final size   = _sizeCtrl.text.trim();
      // Format price for watermark: "100,000/=TZS"
      final priceForCaption = rawPrice.isNotEmpty ? '$rawPrice/=$_currency' : '';

      // Burn caption into the saved file if any field is filled.
      // Always burn from the .orig backup so edits never stack on top of each other.
      if (name.isNotEmpty || rawPrice.isNotEmpty || seller.isNotEmpty || size.isNotEmpty) {
        // Save a clean original backup once (before the first burn)
        final origFile = File('${widget.processedFile.path}.orig');
        if (!origFile.existsSync()) {
          await widget.processedFile.copy(origFile.path);
        }
        final captioned = await addCaptionWatermark(
          origFile,
          productName: name,
          price: priceForCaption,
          seller: seller,
          size: size,
        );
        final bytes = await captioned.readAsBytes();
        await widget.processedFile.writeAsBytes(bytes);
        try { await captioned.delete(); } catch (_) {}
        await FileImage(widget.processedFile).evict();
      }

      // Persist caption text for future editing (raw price + currency stored separately)
      await LocalStorageService().saveCaption(widget.processedFile, {
        'product':  name,
        'price':    rawPrice,
        'currency': _currency,
        'seller':   seller,
        'size':     size,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text('Caption saved!', style: GoogleFonts.poppins()),
          ]),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
      ),
    );
  }

  Widget _currencyToggle() {
    return Row(
      children: [
        Text('Currency:', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(width: 10),
        _currencyChip('TZS'),
        const SizedBox(width: 8),
        _currencyChip('USD'),
      ],
    );
  }

  Widget _currencyChip(String value) {
    final selected = _currency == value;
    return GestureDetector(
      onTap: () => setState(() => _currency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primaryColor : AppTheme.border, width: 1.5),
        ),
        child: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),

            // Image preview + header
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(widget.processedFile, width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Caption', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.text)),
                      Text('Caption appears top-left on your photo', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Fields
            _field(controller: _nameCtrl, label: 'Product Name', icon: Icons.inventory_2_outlined),
            const SizedBox(height: 10),
            _field(
              controller: _priceCtrl,
              label: 'Price (e.g. 100,000)',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorFormatter()],
            ),
            const SizedBox(height: 8),
            _currencyToggle(),
            const SizedBox(height: 10),
            _field(controller: _sellerCtrl, label: 'Shop / Seller', icon: Icons.store_outlined),
            const SizedBox(height: 10),
            _field(controller: _sizeCtrl, label: 'Size (optional)', icon: Icons.straighten_outlined),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                // Skip / View Gallery
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onViewGallery,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border, width: 1.5),
                      ),
                      child: Text('View Gallery', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Save caption button
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _isSaving ? null : _saveWithCaption,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: _isSaving ? null : AppTheme.primaryGradient,
                        color: _isSaving ? AppTheme.border : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSaving)
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryColor))
                          else
                            const Icon(Icons.save_alt, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isSaving ? 'Saving...' : 'Save Caption',
                            style: GoogleFonts.poppins(color: _isSaving ? AppTheme.textSecondary : Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
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
    );
  }
}

/// Formats a number field with thousands separators as the user types.
/// "100000" → displays "100,000". Raw digits stored without commas.
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    if (int.tryParse(digits) == null) return oldValue;
    final formatted = _addCommas(digits);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _addCommas(String digits) {
    final buf = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buf.write(digits[i]);
      count++;
      if (count == 3 && i > 0) { buf.write(','); count = 0; }
    }
    return buf.toString().split('').reversed.join();
  }
}
