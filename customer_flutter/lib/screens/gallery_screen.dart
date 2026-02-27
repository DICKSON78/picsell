import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/theme.dart';
import '../utils/watermark_util.dart';
import '../services/photoroom_service.dart';
import '../services/local_storage_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Static cache — survives navigation, never shows shimmer on re-open
  static List<File>? _cachedPhotos;

  final PhotoRoomService _photoRoomService = PhotoRoomService();
  List<File> _photos = [];
  bool _isLoading = true;

  // Multi-select
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    if (_cachedPhotos != null) {
      // Instant display — show cached photos immediately, no shimmer
      _photos = List.from(_cachedPhotos!);
      _isLoading = false;
      // Silently refresh in background to pick up any new photos
      _refreshSilently();
    } else {
      // First ever open — show shimmer once while scanning storage
      _loadPhotos();
    }
  }

  /// First-time load: shows shimmer until done.
  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final photos = await _photoRoomService.getAllProcessedImages();
      _cachedPhotos = List.from(photos);
      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Background refresh: updates list only if something changed.
  Future<void> _refreshSilently() async {
    try {
      final photos = await _photoRoomService.getAllProcessedImages();
      _cachedPhotos = List.from(photos);
      // Only rebuild if the file list actually changed
      final currentPaths = _photos.map((f) => f.path).toSet();
      final newPaths     = photos.map((f) => f.path).toSet();
      if (mounted && !currentPaths.containsAll(newPaths) || !newPaths.containsAll(currentPaths)) {
        setState(() => _photos = photos);
      }
    } catch (_) {}
  }

  /// Manual pull-to-refresh: also silent (no shimmer).
  Future<void> _onRefresh() => _refreshSilently();

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _enterSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedIndices.add(index);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
  }

  Future<void> _shareSelected() async {
    final files = _selectedIndices.map((i) => XFile(_photos[i].path)).toList();
    if (files.isNotEmpty) {
      await Share.shareXFiles(files);
      _exitSelectionMode();
    }
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${_selectedIndices.length} photo${_selectedIndices.length == 1 ? '' : 's'}?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Picha zilizochaguliwa zitafutwa na hazitaweza kurudishwa.',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Ghairi', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Futa', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final indices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indices) {
        await _photoRoomService.deleteImage(_photos[i]);
      }
      _cachedPhotos = null; // invalidate cache
      _exitSelectionMode();
      _loadPhotos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildShimmerGrid()
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildHeroSection(),
                              Positioned(
                                bottom: -48,
                                left: 16,
                                right: 16,
                                child: _buildGalleryInfoCard(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 64),
                          _photos.isEmpty
                              ? _buildEmptyState()
                              : _buildPhotoGrid(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
          ),
          // Multi-select action bar
          if (_isSelectionMode && _selectedIndices.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _shareSelected,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withAlpha(60),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Share (${_selectedIndices.length})',
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _deleteSelected,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withAlpha(15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.error.withAlpha(180), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Delete (${_selectedIndices.length})',
                                style: GoogleFonts.poppins(color: AppTheme.error, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
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

  Widget _buildHeroSection() {
    return Stack(
      children: [
        Container(
          height: 140,
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _isSelectionMode
                        ? _exitSelectionMode
                        : () => Navigator.of(context).pop(),
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
                      child: Icon(
                        _isSelectionMode ? Icons.close : Icons.arrow_back,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    _isSelectionMode
                        ? '${_selectedIndices.length} selected'
                        : 'My PicSell Gallery',
                    style: GoogleFonts.poppins(
                      fontSize: _isSelectionMode ? 18 : 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isSelectionMode ? null : _onRefresh,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.whiteColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _isSelectionMode ? Icons.check_box_outlined : Icons.refresh,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
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

  Widget _buildGalleryInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
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
                  'Your Processed Photos',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                Text(
                  _photos.isEmpty
                      ? 'No photos yet'
                      : '${_photos.length} photo${_photos.length == 1 ? '' : 's'} ready to share',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_photos.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_photos.length}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildHeroSection(),
              Positioned(
                bottom: -48,
                left: 16,
                right: 16,
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 64),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 9,
              itemBuilder: (context, index) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
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
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Photos Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your processed photos will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Take Photo',
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

  Widget _buildPhotoGrid() {
    return ColoredBox(
      color: Colors.grey[300]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          final isSelected = _selectedIndices.contains(index);
          return _PhotoTile(
            photo: photo,
            isSelectionMode: _isSelectionMode,
            isSelected: isSelected,
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(index);
              } else {
                _openFullscreen(photo, index);
              }
            },
            onLongPress: () => _enterSelectionMode(index),
            onMenuTap: () => _showEditCaption(photo),
          );
        },
      ),
    );
  }

  void _showEditCaption(File photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCaptionSheet(
        photo: photo,
        onSaved: () {
          // Evict only this one image from Flutter's cache so its
          // thumbnail refreshes without reloading the entire grid.
          FileImage(photo).evict();
        },
      ),
    );
  }

  void _openFullscreen(File photo, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoFullscreenPage(
          photos: _photos,
          initialIndex: index,
          onDelete: (deletedPhoto) {
            Navigator.of(context).pop();
            final idx = _photos.indexOf(deletedPhoto);
            if (idx != -1) _deletePhoto(deletedPhoto, idx);
          },
        ),
      ),
    );
  }

  void _deletePhoto(File photo, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Photo?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This photo will be deleted and cannot be recovered. Are you sure?',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _photoRoomService.deleteImage(photo);
              if (success) {
                setState(() {
                  _photos.removeAt(index);
                  _cachedPhotos = List.from(_photos); // keep cache in sync
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: AppTheme.whiteColor),
                        const SizedBox(width: 12),
                        Text('Photo deleted', style: GoogleFonts.poppins()),
                      ],
                    ),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final File photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onMenuTap;
  final bool isSelectionMode;
  final bool isSelected;

  const _PhotoTile({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
    this.onMenuTap,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            photo,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.primarySoft,
              child: const Icon(Icons.broken_image, color: AppTheme.primaryColor),
            ),
          ),
          // Selection overlay
          if (isSelectionMode)
            Container(
              color: isSelected
                  ? AppTheme.primaryColor.withAlpha(80)
                  : Colors.black.withAlpha(30),
            ),
          // Checkmark badge (selection mode)
          if (isSelectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white.withAlpha(200),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
          // 3-dot menu (normal mode)
          if (!isSelectionMode && onMenuTap != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onMenuTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(110),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// Full-screen image viewer — swipe between all photos (PageView)
// ============================================================
class PhotoFullscreenPage extends StatefulWidget {
  final List<File> photos;
  final int initialIndex;
  /// Called with the deleted file so the parent can remove it from its list
  final void Function(File deletedPhoto) onDelete;

  const PhotoFullscreenPage({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<PhotoFullscreenPage> createState() => _PhotoFullscreenPageState();
}

class _PhotoFullscreenPageState extends State<PhotoFullscreenPage> {
  late final PageController _pageController;
  late int _currentIndex;

  File get _currentPhoto => widget.photos[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _share() async {
    // Caption is already burned into the file at save time — share directly
    await Share.shareXFiles([XFile(_currentPhoto.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Swipeable PageView ──────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(
                    widget.photos[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                        SizedBox(height: 12),
                        Text('Picha haionekani', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Top bar: close + page indicator ────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(200), width: 1.5),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 22),
                      ),
                    ),
                    // Photo counter (e.g. 3 / 12)
                    if (widget.photos.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.photos.length}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(width: 42), // balance
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom bar: Delete + Share ──────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withAlpha(180), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 36),
              child: Row(
                children: [
                  // Delete
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onDelete(_currentPhoto),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withAlpha(200), width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Share
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _share,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.share, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('Share', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
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
}

// ============================================================
// Edit caption sheet — opened from the gallery 3-dot menu.
// Loads existing metadata, lets user edit, re-burns caption
// onto the photo file, and updates the stored metadata.
// ============================================================
class _EditCaptionSheet extends StatefulWidget {
  final File photo;
  /// Called after the caption is saved so the gallery can refresh.
  final VoidCallback onSaved;

  const _EditCaptionSheet({
    required this.photo,
    required this.onSaved,
  });

  @override
  State<_EditCaptionSheet> createState() => _EditCaptionSheetState();
}

class _EditCaptionSheetState extends State<_EditCaptionSheet> {
  final _nameCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _sellerCtrl = TextEditingController();
  final _sizeCtrl   = TextEditingController();
  bool   _isLoading = true;
  bool   _isSaving  = false;
  String _currency  = 'TZS';

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _sellerCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final data = await LocalStorageService().loadCaption(widget.photo);
    if (!mounted) return;
    setState(() {
      _nameCtrl.text   = data['product'] ?? '';
      _priceCtrl.text  = data['price']   ?? '';
      _sellerCtrl.text = data['seller']  ?? '';
      _sizeCtrl.text   = data['size']    ?? '';
      _currency        = data['currency'] ?? 'TZS';
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final name     = _nameCtrl.text.trim();
      final rawPrice = _priceCtrl.text.trim();
      final seller   = _sellerCtrl.text.trim();
      final size     = _sizeCtrl.text.trim();
      // Format price for watermark: "100,000/=TZS"
      final priceForCaption = rawPrice.isNotEmpty ? '$rawPrice/=$_currency' : '';

      // Burn new caption. Always burn FROM the .orig backup so repeated
      // edits never stack caption text on top of each other.
      if (name.isNotEmpty || rawPrice.isNotEmpty || seller.isNotEmpty || size.isNotEmpty) {
        final origFile = File('${widget.photo.path}.orig');
        if (!origFile.existsSync()) {
          await widget.photo.copy(origFile.path);
        }
        final captioned = await addCaptionWatermark(
          origFile,
          productName: name,
          price: priceForCaption,
          seller: seller,
          size: size,
        );
        final bytes = await captioned.readAsBytes();
        await widget.photo.writeAsBytes(bytes);
        try { await captioned.delete(); } catch (_) {}
      }

      // Persist updated metadata (raw price + currency stored separately)
      await LocalStorageService().saveCaption(widget.photo, {
        'product':  name,
        'price':    rawPrice,
        'currency': _currency,
        'seller':   seller,
        'size':     size,
      });

      if (!mounted) return;
      widget.onSaved();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 10),
          Text('Caption updated!', style: GoogleFonts.poppins()),
        ]),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
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
        _chip('TZS'),
        const SizedBox(width: 8),
        _chip('USD'),
      ],
    );
  }

  Widget _chip(String value) {
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
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary),
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

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_note, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Caption', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.text)),
                      Text('Caption will be re-burned onto the photo', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(),
              ))
            else ...[
              _field(controller: _nameCtrl,   label: 'Product Name',    icon: Icons.inventory_2_outlined),
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
              _field(controller: _sellerCtrl, label: 'Shop / Seller',   icon: Icons.store_outlined),
              const SizedBox(height: 10),
              _field(controller: _sizeCtrl,   label: 'Size (optional)', icon: Icons.straighten_outlined),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border, width: 1.5),
                        ),
                        child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isSaving ? null : _save,
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
          ],
        ),
      ),
    );
  }
}

// ── Thousands separator formatter ────────────────────────────────────────────
// Formats a numeric string as "100,000" while the user types.
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
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
      if (count == 3 && i > 0) {
        buf.write(',');
        count = 0;
      }
    }
    return buf.toString().split('').reversed.join();
  }
}
