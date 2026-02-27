import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../providers/photos_provider.dart';
import '../models/photo_model.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Pending', 'Processed', 'Flagged'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PhotosProvider>(context, listen: false).loadPhotos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PhotoModel> _getFilteredPhotos(List<PhotoModel> photos) {
    return photos.where((photo) {
      final matchesSearch = photo.userId.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = true;
      if (_selectedFilter != 'All') {
        final statusStr = _getStatusDisplayName(photo.status).toLowerCase();
        matchesFilter = statusStr == _selectedFilter.toLowerCase();
      }
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  String _getStatusDisplayName(PhotoStatus status) {
    switch (status) {
      case PhotoStatus.completed: return 'Processed';
      case PhotoStatus.processing: return 'Pending';
      case PhotoStatus.failed: return 'Failed';
      case PhotoStatus.flagged: return 'Flagged';
    }
  }

  Color _getStatusColor(PhotoStatus status) {
    switch (status) {
      case PhotoStatus.completed: return Colors.green;
      case PhotoStatus.processing: return Colors.orange;
      case PhotoStatus.flagged: return Colors.red;
      case PhotoStatus.failed: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, HH:mm').format(date);
  }

  void _showPhotoDetail(int initialIndex, List<PhotoModel> photos) {
    final PageController pageController = PageController(initialPage: initialIndex);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: photos.length,
                onPageChanged: (_) => _tabController.animateTo(0),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return _buildPhotoDetailContent(photo);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoDetailContent(PhotoModel photo) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppTheme.primaryColor.withAlpha(30), child: Text(photo.userId.isNotEmpty ? photo.userId[0].toUpperCase() : 'P', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Photo by ${photo.userId.length > 8 ? photo.userId.substring(0, 8) : photo.userId}...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(_formatDate(photo.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _getStatusColor(photo.status).withAlpha(30), borderRadius: BorderRadius.circular(20)), child: Text(_getStatusDisplayName(photo.status).toUpperCase(), style: TextStyle(color: _getStatusColor(photo.status), fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildImageFrame(photo.originalUrl),
              _buildImageFrame(photo.processedUrl ?? photo.originalUrl),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: TabBar(controller: _tabController, indicator: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(12)), labelColor: Colors.white, unselectedLabelColor: Colors.grey[600], tabs: const [Tab(text: 'Original'), Tab(text: 'AI Enhanced')]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _buildStatItem(Icons.photo_camera, 'Photo ID', photo.id.length > 6 ? photo.id.substring(0, 6) : photo.id)),
              Expanded(child: _buildStatItem(Icons.stars, 'Category', photo.category)),
              Expanded(child: _buildStatItem(Icons.access_time, 'Date', DateFormat('HH:mm').format(photo.createdAt))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Provider.of<PhotosProvider>(context, listen: false).flagPhoto(photo.id, photo.status != PhotoStatus.flagged);
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.flag_outlined, color: photo.status == PhotoStatus.flagged ? Colors.green : Colors.orange),
                  label: Text(photo.status == PhotoStatus.flagged ? 'Unflag' : 'Flag', style: TextStyle(color: photo.status == PhotoStatus.flagged ? Colors.green : Colors.orange)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: photo.status == PhotoStatus.flagged ? Colors.green : Colors.orange), padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(photo);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageFrame(String url) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, lp) => lp == null ? child : Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))),
          errorBuilder: (context, err, st) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 48, color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  void _showDeleteConfirmation(PhotoModel photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Provider.of<PhotosProvider>(context, listen: false).deletePhoto(photo.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo deleted successfully'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotosProvider>(context);
    final filteredPhotos = _getFilteredPhotos(provider.photos);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.arrow_back, color: Colors.white)),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: Text('Photo Management', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildHeroStat('Total', '${provider.photos.length}', Icons.photo_library),
                          const SizedBox(width: 16),
                          _buildHeroStat('Processed', '${provider.photos.where((p) => p.status == PhotoStatus.completed).length}', Icons.check_circle),
                          const SizedBox(width: 16),
                          _buildHeroStat('Flagged', '${provider.photos.where((p) => p.status == PhotoStatus.flagged).length}', Icons.flag),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(16)),
                        child: TextField(
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'Search by User ID...', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none, icon: Icon(Icons.search, color: Colors.white70)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterDelegate(
              child: Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(filter),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          backgroundColor: Colors.white,
                          selectedColor: AppTheme.primaryColor,
                          checkmarkColor: Colors.white,
                          side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!),
                          onSelected: (selected) => setState(() => _selectedFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: provider.isLoading 
          ? _buildShimmerGrid()
          : filteredPhotos.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text('No photos found', style: TextStyle(color: Colors.grey[600], fontSize: 16))]))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2, childAspectRatio: 0.75),
                itemCount: filteredPhotos.length,
                itemBuilder: (context, index) {
                  final photo = filteredPhotos[index];
                  return GestureDetector(
                    onTap: () => _showPhotoDetail(index, filteredPhotos),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          photo.processedUrl ?? photo.originalUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, lp) => lp == null ? child : Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))),
                          errorBuilder: (context, err, st) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withAlpha(180)])),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(photo.userId.length > 8 ? photo.userId.substring(0, 8) : photo.userId, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis), Text(DateFormat('dd MMM').format(photo.createdAt), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 9))]),
                          ),
                        ),
                        Positioned(top: 6, right: 6, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: _getStatusColor(photo.status), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2, childAspectRatio: 0.75),
      itemCount: 12,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(height: 4), Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(label, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11))]),
      ),
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyFilterDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}
