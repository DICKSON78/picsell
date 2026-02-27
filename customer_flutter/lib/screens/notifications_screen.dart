import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../models/shared_models.dart';
import '../utils/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Today, 2: Yesterday, 3: This Week

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      Provider.of<NotificationProvider>(context, listen: false).listenToNotifications(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return RefreshIndicator(
                  onRefresh: () async {
                    if (user != null) {
                      provider.listenToNotifications(user.id);
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeroSection(),
                        Transform.translate(
                          offset: const Offset(0, -40),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildNotificationInfoCard(),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -34),
                          child: _buildFilterTabs(),
                        ),
                        provider.isLoading && provider.notifications.isEmpty
                            ? _buildShimmerGrid()
                            : _getFilteredNotifications(provider.notifications).isEmpty
                                ? _buildEmptyState()
                                : _buildNotificationList(provider.notifications),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
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
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1579546929518-9e396f3cc809?q=80&w=2070&auto=format&fit=crop'),
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
                    onTap: () => Navigator.pop(context),
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
                  Text(
                    'Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.whiteColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Provider.of<NotificationProvider>(context, listen: false).markAllAsRead(),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.whiteColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.done_all,
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

  Widget _buildNotificationInfoCard() {
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
              Icons.notifications_active,
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
                  'Stay Updated',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                Text(
                  'Check your latest alerts and info',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 0),
            const SizedBox(width: 10),
            _buildFilterChip('Today', 1),
            const SizedBox(width: 10),
            _buildFilterChip('Yesterday', 2),
            const SizedBox(width: 10),
            _buildFilterChip('This Week', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    bool isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.border),
          boxShadow: isSelected ? AppTheme.shadowSm : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  List<NotificationModel> _getFilteredNotifications(List<NotificationModel> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    switch (_selectedFilter) {
      case 1: // Today
        return all.where((n) => n.createdAt.isAfter(today)).toList();
      case 2: // Yesterday
        return all.where((n) => n.createdAt.isAfter(yesterday) && n.createdAt.isBefore(today)).toList();
      case 3: // This Week
        return all.where((n) => n.createdAt.isAfter(weekAgo)).toList();
      default: // All
        return all;
    }
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    final filtered = _getFilteredNotifications(notifications);
    return Transform.translate(
      offset: const Offset(0, -24),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildNotificationCard(filtered[index]),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppTheme.primarySoft.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: notification.isRead ? Colors.grey[100]! : AppTheme.primaryLight.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getIconColor(notification.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(notification.type), color: _getIconColor(notification.type), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: notification.isRead ? AppTheme.text : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd MMM, hh:mm a').format(notification.createdAt),
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w500),
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

  IconData _getIcon(String type) {
    switch (type) {
      case 'promo': return Icons.local_offer_outlined;
      case 'alert': return Icons.warning_amber_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'promo': return AppTheme.accentOrange;
      case 'alert': return AppTheme.error;
      default: return AppTheme.primaryColor;
    }
  }

  Widget _buildEmptyState() {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Transform.translate(
      offset: const Offset(0, -24),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}
