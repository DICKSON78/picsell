import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoSaveEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'App Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.text,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General Settings Section
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'General Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                ),

                _buildSettingItem(
                  Icons.notifications,
                  'Push Notifications',
                  'Receive notifications about new features',
                  AppTheme.iconBgOrange,
                  hasSwitch: true,
                  switchValue: _notificationsEnabled,
                  onSwitchChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),

                const Divider(height: 1, color: AppTheme.border),

                _buildSettingItem(
                  Icons.dark_mode,
                  'Dark Mode',
                  'Switch between light and dark theme',
                  AppTheme.iconBgPurple,
                  hasSwitch: true,
                  switchValue: _darkModeEnabled,
                  onSwitchChanged: (value) {
                    setState(() => _darkModeEnabled = value);
                  },
                ),

                const Divider(height: 1, color: AppTheme.border),

                _buildSettingItem(
                  Icons.language,
                  'Language',
                  'Change app language',
                  AppTheme.iconBgBlue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Storage Section
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Storage',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                ),

                _buildSettingItem(
                  Icons.save,
                  'Auto Save Photos',
                  'Automatically save generated photos',
                  AppTheme.iconBgGreen,
                  hasSwitch: true,
                  switchValue: _autoSaveEnabled,
                  onSwitchChanged: (value) {
                    setState(() => _autoSaveEnabled = value);
                  },
                ),

                const Divider(height: 1, color: AppTheme.border),

                _buildSettingItem(
                  Icons.storage,
                  'Clear Cache',
                  'Clear temporary files and cache',
                  AppTheme.iconBgCyan,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // About Section
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'About',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.text,
                    ),
                  ),
                ),

                _buildSettingItem(
                  Icons.privacy_tip,
                  'Privacy Policy',
                  'View our privacy policy',
                  AppTheme.iconBgPink,
                ),

                const Divider(height: 1, color: AppTheme.border),

                _buildSettingItem(
                  Icons.description,
                  'Terms of Service',
                  'View terms and conditions',
                  AppTheme.iconBgOrange,
                ),

                const Divider(height: 1, color: AppTheme.border),

                _buildSettingItem(
                  Icons.info,
                  'About App',
                  'Version 1.0.0',
                  AppTheme.iconBgPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    Color iconBgColor, {
    bool hasSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.text,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: hasSwitch
          ? Switch(
              value: switchValue,
              onChanged: onSwitchChanged,
              activeThumbColor: AppTheme.primaryColor,
              activeTrackColor: AppTheme.primarySoft,
            )
          : const Icon(
              Icons.chevron_right,
              color: AppTheme.textLight,
            ),
      onTap: hasSwitch ? null : onTap,
    );
  }
}
