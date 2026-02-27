import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/photoroom_service.dart';
import '../providers/localization_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final PhotoRoomService _photoRoomService = PhotoRoomService();
  int _selectedIndex = 1;
  int _selectedFilter = 0;

  List<_HistoryItem> _allItems = [];
  List<_HistoryItem> _filteredItems = [];
  bool _isLoading = true;

  // Multi-select mode
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final photos = await _photoRoomService.getAllProcessedImages();
      final items = photos.map((file) {
        final stat = file.statSync();
        return _HistoryItem(
          file: file,
          createdAt: stat.modified,
          fileName: file.path.split('/').last,
        );
      }).toList();

      // Sort by date (newest first)
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _allItems = items;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);

    switch (_selectedFilter) {
      case 0: // All
        _filteredItems = List.from(_allItems);
        break;
      case 1: // Today
        _filteredItems = _allItems.where((item) {
          final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
          return itemDate == today;
        }).toList();
        break;
      case 2: // This Week
        _filteredItems = _allItems.where((item) {
          return item.createdAt.isAfter(weekAgo);
        }).toList();
        break;
      case 3: // This Month
        _filteredItems = _allItems.where((item) {
          return item.createdAt.isAfter(monthAgo);
        }).toList();
        break;
      default:
        _filteredItems = List.from(_allItems);
    }
  }

  void _toggleSelection(String fileName) {
    setState(() {
      if (_selectedItems.contains(fileName)) {
        _selectedItems.remove(fileName);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(fileName);
      }
    });
  }

  void _shareSelectedPhotos() async {
    final filesToShare = _allItems
        .where((item) => _selectedItems.contains(item.fileName))
        .map((item) => XFile(item.file.path))
        .toList();

    if (filesToShare.isNotEmpty) {
      await Share.shareXFiles(filesToShare);
      setState(() {
        _isSelectionMode = false;
        _selectedItems.clear();
      });
    }
  }

  void _deleteSelectedPhotos() async {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isSwahili ? 'Futa Picha?' : 'Delete Photos?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isSwahili
              ? 'Je, una uhakika unataka kufuta picha ${_selectedItems.length}?'
              : 'Are you sure you want to delete ${_selectedItems.length} photos?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final fileName in _selectedItems) {
        final item = _allItems.firstWhere((i) => i.fileName == fileName);
        await _photoRoomService.deleteImage(item.file);
      }

      setState(() {
        _isSelectionMode = false;
        _selectedItems.clear();
      });

      _loadHistory();
    }
  }

  int _getTodayCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _allItems.where((item) {
      final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      return itemDate == today;
    }).length;
  }

  int _getWeekCount() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _allItems.where((item) => item.createdAt.isAfter(weekAgo)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildHeroSection(),
                          Transform.translate(
                            offset: const Offset(0, -40),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _buildHistoryInfoCard(),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -34),
                            child: _buildFilterTabs(),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -24),
                            child: _filteredItems.isEmpty
                                ? _buildEmptyState()
                                : _buildHistoryList(),
                          ),
                          const SizedBox(height: 0),
                        ],
                      ),
                    ),
                  ),
          ),
          // Selection mode action buttons
          if (_isSelectionMode && _selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareSelectedPhotos,
                      icon: const Icon(Icons.share),
                      label: Text(
                        'Share (${_selectedItems.length})',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteSelectedPhotos,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        'Delete',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!_isSelectionMode)
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

  Widget _buildHeroSection() {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1516321318423-f06f85e504b3?q=80&w=2070&auto=format&fit=crop'),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
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
                  _isSelectionMode
                      ? Text(
                          '${_selectedItems.length} selected',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.whiteColor,
                          ),
                        )
                      : Text(
                          'History',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                  _isSelectionMode
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSelectionMode = false;
                              _selectedItems.clear();
                            });
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppTheme.whiteColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _loadHistory,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppTheme.whiteColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.refresh,
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

  Widget _buildHistoryInfoCard() {
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
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.history,
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
                  'Photo History',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                Text(
                  '${_allItems.length} processed photos',
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
    );
  }

  Widget _buildFilterTabs() {
    final localization = Provider.of<LocalizationProvider>(context);
    final isSwahili = localization.isSwahili;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              count: _allItems.length,
              isSelected: _selectedFilter == 0,
              onTap: () => setState(() {
                _selectedFilter = 0;
                _applyFilter();
              }),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'Today',
              count: _getTodayCount(),
              isSelected: _selectedFilter == 1,
              onTap: () => setState(() {
                _selectedFilter = 1;
                _applyFilter();
              }),
            ),
            const SizedBox(width: 10),
            _FilterChip(
              label: 'This Week',
              count: _getWeekCount(),
              isSelected: _selectedFilter == 2,
              onTap: () => setState(() {
                _selectedFilter = 2;
                _applyFilter();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final localization = Provider.of<LocalizationProvider>(context);
    final isSwahili = localization.isSwahili;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
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
              Icons.history,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 0 ? 'No Photos Yet' : 'No Photos',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 0
                ? 'Your processed photos will appear here'
                : 'No photos for this period',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          if (_selectedFilter == 0) ...[
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
                  localization.tr('take_photo'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    // Group items by date
    final Map<String, List<_HistoryItem>> groupedItems = {};

    for (final item in _filteredItems) {
      final dateKey = _getDateKey(item.createdAt);
      groupedItems.putIfAbsent(dateKey, () => []);
      groupedItems[dateKey]!.add(item);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedItems.keys.length,
      itemBuilder: (context, index) {
        final dateKey = groupedItems.keys.elementAt(index);
        final items = groupedItems[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Text(
                dateKey,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistoryCard(
                item: item,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedItems.contains(item.fileName),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(item.fileName);
                  } else {
                    _showPhotoPreview(item);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedItems.add(item.fileName);
                    });
                  }
                },
                onShare: () => _sharePhoto(item.file),
                onDelete: () => _deletePhoto(item),
              ),
            )),
          ],
        );
      },
    );
  }

  String _getDateKey(DateTime date) {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final isSwahili = localization.isSwahili;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }

  void _showPhotoPreview(_HistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _HistoryFullscreenPage(
          item: item,
          onDelete: () => _deletePhoto(item),
          onShare: () => _sharePhoto(item.file),
        ),
      ),
    );
  }

  Future<void> _sharePhoto(File photo) async {
    try {
      await Share.shareXFiles(
        [XFile(photo.path)],
        text: 'Photo processed with PicSell',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share photo'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _deletePhoto(_HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Photo?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This photo will be deleted and cannot be recovered. Are you sure?',
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
              final success = await _photoRoomService.deleteImage(item.file);
              if (success && mounted) {
                setState(() {
                  _allItems.remove(item);
                  _applyFilter();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: AppTheme.whiteColor),
                        const SizedBox(width: 12),
                        const Text('Photo deleted'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeroSection(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(3, (index) => Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    height: 100,
                    margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
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
        // Already on history
        break;
      case 2:
        Navigator.of(context).pushNamed('/credits');
        break;
      case 3:
        Navigator.of(context).pushNamed('/account');
        break;
    }
  }
}

class _HistoryItem {
  final File file;
  final DateTime createdAt;
  final String fileName;

  _HistoryItem({
    required this.file,
    required this.createdAt,
    required this.fileName,
  });
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                )
              : null,
          color: isSelected ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AppTheme.border),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? AppTheme.whiteColor : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.whiteColor.withAlpha(50)
                      : AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.poppins(
                    color: isSelected ? AppTheme.whiteColor : AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final bool isSelectionMode;
  final bool isSelected;

  const _HistoryCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    required this.onShare,
    required this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final isSwahili = localization.isSwahili;
    final timeFormat = DateFormat('HH:mm');

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primarySoft : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Selection checkbox (show in selection mode)
              if (isSelectionMode) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
              ],

              // Thumbnail
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.file(
                    item.file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.primarySoft,
                        child: const Icon(
                          Icons.broken_image,
                          color: AppTheme.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Picha Iliyochakatwa' : 'Processed Photo',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeFormat.format(item.createdAt),
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onShare,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.share,
                        color: AppTheme.success,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
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
}

class _HistoryFullscreenPage extends StatelessWidget {
  final _HistoryItem item;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _HistoryFullscreenPage({
    required this.item,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen zoomable image
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.file(
                item.file,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
                      SizedBox(height: 12),
                      Text('Picha haionekani', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top bar: close + date
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
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(200), width: 1.5),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateFormat.format(item.createdAt),
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom gradient + buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withAlpha(200), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 36),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        onDelete();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
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
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        onShare();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
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
