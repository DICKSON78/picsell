import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../utils/theme.dart';
import '../widgets/bottom_nav_bar.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  int _selectedIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Hero Section
                  _buildHeroSection(),

                  // Menu Items
                  _buildMenuItems(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom navigation
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
        // Purple gradient background
        Container(
          height: 280,
          width: double.infinity,
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
          child: Stack(
            children: [
              // Pattern overlay
              Positioned(
                right: -30,
                top: 30,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.person,
                    size: 180,
                    color: AppTheme.whiteColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // White gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundColor.withAlpha(0),
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),
        ),

        // App Bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Back button with white background
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

                  // Title — Expanded so it never overflows
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final localization = Provider.of<LocalizationProvider>(context);
                        return Text(
                          localization.isSwahili ? 'Akaunti' : 'Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.whiteColor,
                          ),
                        );
                      },
                    ),
                  ),

                  // Settings button with white background
                  GestureDetector(
                    onTap: () => _showAppSettings(),
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
                        Icons.settings,
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

        // User Profile Card
        Positioned(
          bottom: 30,
          left: 16,
          right: 16,
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final localization = Provider.of<LocalizationProvider>(context);
              final user = authProvider.user;
              final userName = user?.name ?? (localization.isSwahili ? 'Mtumiaji' : 'User');
              final userEmail = user?.email ?? 'email@example.com';
              final userPhoto = user?.photoUrl;
              final userCredits = user?.credits ?? 0;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.shadowLg,
                ),
                child: Row(
                  children: [
                    // Profile picture
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: userPhoto == null ? AppTheme.primaryGradient : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: userPhoto != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                userPhoto,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.whiteColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.whiteColor,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(width: 16),

                    // Profile info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              color: AppTheme.text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Credits badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accentBlue],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: AppTheme.whiteColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$userCredits',
                            style: GoogleFonts.poppins(
                              color: AppTheme.whiteColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    final localization = Provider.of<LocalizationProvider>(context);
    final tr = localization.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _MenuItem(
            icon: Icons.edit,
            title: tr('edit_profile'),
            subtitle: tr('update_info'),
            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.camera_alt,
            title: localization.isSwahili ? 'Galari Yangu ya PicSell' : 'My PicSell Gallery',
            subtitle: tr('manage_gallery'),
            onTap: () {
              Navigator.of(context).pushNamed('/gallery');
            },
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.account_balance_wallet,
            title: tr('payment_methods'),
            subtitle: tr('add_remove_payment'),
            onTap: () => Navigator.pushNamed(context, '/payment-methods'),
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.notifications,
            title: tr('notifications'),
            subtitle: tr('manage_notifications'),
            onTap: () => _showNotificationSettings(),
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.privacy_tip,
            title: tr('privacy_security'),
            subtitle: tr('control_privacy'),
            onTap: () => _showPrivacySettings(),
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.language,
            title: '${tr('language')} / Lugha',
            subtitle: 'English • Kiswahili',
            onTap: () => _showLanguageSettings(),
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.help,
            title: tr('help_support'),
            subtitle: tr('get_help'),
            onTap: () => Navigator.pushNamed(context, '/help-support'),
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.logout,
            title: tr('sign_out'),
            subtitle: tr('sign_out_account'),
            isDestructive: true,
            onTap: () {
              _showSignOutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    final localization = Provider.of<LocalizationProvider>(context, listen: false);
    final tr = localization.tr;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            tr('sign_out'),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          content: Text(
            localization.currentLanguage == AppLanguage.english
                ? 'Are you sure you want to sign out?'
                : 'Una uhakika unataka kutoka?',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                tr('cancel'),
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.of(dialogContext).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tr('sign_out'),
                  style: GoogleFonts.poppins(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
        Navigator.of(context).pushNamed('/history');
        break;
      case 2:
        Navigator.of(context).pushNamed('/credits');
        break;
      case 3:
        // Already on account
        break;
    }
  }

  void _showAppSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppSettingsSheet(),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationSettingsSheet(),
    );
  }

  void _showPrivacySettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PrivacySettingsSheet(),
    );
  }

  void _showLanguageSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageSettingsSheet(),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.error.withAlpha(20)
                    : AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppTheme.error : AppTheme.primaryColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDestructive ? AppTheme.error : AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppTheme.textLight,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppSettingsSheet extends StatefulWidget {
  @override
  State<_AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends State<_AppSettingsSheet> {
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.settings, color: AppTheme.whiteColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('App Settings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text)),
                    Text('Customize your app experience', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingSwitch('Dark Mode', 'Enable dark theme', Icons.dark_mode, _darkMode, (v) => setState(() => _darkMode = v)),
          const SizedBox(height: 12),
          _buildSettingDropdown('Language', 'Select app language', Icons.language, _language, ['English', 'Swahili', 'French'], (v) => setState(() => _language = v!)),
          const SizedBox(height: 12),
          _buildSettingAction('Clear Cache', 'Free up storage space', Icons.cleaning_services, () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared successfully'), backgroundColor: AppTheme.success));
          }),
          const SizedBox(height: 12),
          _buildSettingAction('App Version', '1.0.0 (Build 2024.01)', Icons.info_outline, null),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.primaryColor, size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)), Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary))])),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildSettingDropdown(String title, String subtitle, IconData icon, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.primaryColor, size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)), Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary))])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
            child: DropdownButton<String>(value: value, underline: const SizedBox(), isDense: true, items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: GoogleFonts.poppins(fontSize: 13)))).toList(), onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingAction(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.primaryColor, size: 22)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)), Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary))])),
            if (onTap != null) const Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  @override
  State<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _promoEnabled = false;
  bool _photoReady = true;
  bool _creditAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.notifications, color: AppTheme.whiteColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text)),
                    Text('Manage your alerts', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNotifSwitch('Push Notifications', 'Receive push alerts', _pushEnabled, (v) => setState(() => _pushEnabled = v)),
          const SizedBox(height: 10),
          _buildNotifSwitch('Email Notifications', 'Get updates via email', _emailEnabled, (v) => setState(() => _emailEnabled = v)),
          const SizedBox(height: 10),
          _buildNotifSwitch('Photo Ready Alerts', 'When photos are processed', _photoReady, (v) => setState(() => _photoReady = v)),
          const SizedBox(height: 10),
          _buildNotifSwitch('Credit Alerts', 'Low credit warnings', _creditAlerts, (v) => setState(() => _creditAlerts = v)),
          const SizedBox(height: 10),
          _buildNotifSwitch('Promotional', 'Offers and discounts', _promoEnabled, (v) => setState(() => _promoEnabled = v)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification settings saved'), backgroundColor: AppTheme.success));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: AppTheme.whiteColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('Save Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNotifSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)), Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary))])),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primaryColor),
        ],
      ),
    );
  }
}

class _PrivacySettingsSheet extends StatefulWidget {
  @override
  State<_PrivacySettingsSheet> createState() => _PrivacySettingsSheetState();
}

class _PrivacySettingsSheetState extends State<_PrivacySettingsSheet> {
  bool _profilePublic = false;
  bool _showActivity = true;
  bool _dataSharing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.privacy_tip, color: AppTheme.whiteColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Privacy & Security', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text)),
                    Text('Control your data', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPrivacySwitch('Public Profile', 'Allow others to see your profile', _profilePublic, (v) => setState(() => _profilePublic = v)),
          const SizedBox(height: 10),
          _buildPrivacySwitch('Show Activity Status', 'Let others see when you\'re online', _showActivity, (v) => setState(() => _showActivity = v)),
          const SizedBox(height: 10),
          _buildPrivacySwitch('Data Sharing', 'Share usage data to improve app', _dataSharing, (v) => setState(() => _dataSharing = v)),
          const SizedBox(height: 16),
          _buildPrivacyAction('Change Password', Icons.lock_outline, () {
            Navigator.pop(context);
            _showChangePasswordDialog(context);
          }),
          const SizedBox(height: 10),
          _buildPrivacyAction('Two-Factor Auth', Icons.security, () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA settings opened'), backgroundColor: AppTheme.primaryColor));
          }),
          const SizedBox(height: 10),
          _buildPrivacyAction('Download My Data', Icons.download, () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data export started. Check your email.'), backgroundColor: AppTheme.success));
          }),
          const SizedBox(height: 10),
          _buildPrivacyAction('Delete Account', Icons.delete_forever, () {
            Navigator.pop(context);
            _showDeleteAccountDialog(context);
          }, isDestructive: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPrivacySwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)), Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary))])),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildPrivacyAction(String title, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDestructive ? AppTheme.error.withAlpha(50) : AppTheme.border)),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppTheme.error : AppTheme.primaryColor, size: 22),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: isDestructive ? AppTheme.error : AppTheme.text))),
            Icon(Icons.chevron_right, color: isDestructive ? AppTheme.error : AppTheme.textLight, size: 20),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'Current Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'New Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 12),
            TextField(obscureText: true, decoration: InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password changed successfully'), backgroundColor: AppTheme.success));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Update', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.error)),
        content: Text('Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(ctx).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LanguageSettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localization, child) {
        final isEnglish = localization.currentLanguage == AppLanguage.english;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.language, color: AppTheme.whiteColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Language / Lugha', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.text)),
                        Text(
                          isEnglish ? 'Select your preferred language' : 'Chagua lugha unayopendelea',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // English Option
              GestureDetector(
                onTap: () {
                  localization.setLanguage(AppLanguage.english);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Language changed to English'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isEnglish ? AppTheme.primaryGradient : null,
                    color: isEnglish ? null : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isEnglish ? null : Border.all(color: AppTheme.border),
                    boxShadow: isEnglish
                        ? [BoxShadow(color: AppTheme.primaryColor.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Row(
                    children: [
                      const Text('🇬🇧', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('English', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: isEnglish ? AppTheme.whiteColor : AppTheme.text)),
                            Text('Default language', style: GoogleFonts.poppins(fontSize: 12, color: isEnglish ? AppTheme.whiteColor.withAlpha(180) : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      if (isEnglish)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(color: AppTheme.whiteColor, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: AppTheme.primaryColor, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Kiswahili Option
              GestureDetector(
                onTap: () {
                  localization.setLanguage(AppLanguage.swahili);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lugha imebadilishwa kuwa Kiswahili'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: !isEnglish ? AppTheme.primaryGradient : null,
                    color: !isEnglish ? null : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: !isEnglish ? null : Border.all(color: AppTheme.border),
                    boxShadow: !isEnglish
                        ? [BoxShadow(color: AppTheme.primaryColor.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Row(
                    children: [
                      const Text('🇹🇿', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kiswahili', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: !isEnglish ? AppTheme.whiteColor : AppTheme.text)),
                            Text('Lugha ya Kiswahili', style: GoogleFonts.poppins(fontSize: 12, color: !isEnglish ? AppTheme.whiteColor.withAlpha(180) : AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      if (!isEnglish)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(color: AppTheme.whiteColor, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: AppTheme.primaryColor, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
