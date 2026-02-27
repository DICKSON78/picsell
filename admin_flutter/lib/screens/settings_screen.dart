import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/firestore_service.dart';
import '../models/system_settings_model.dart';
import '../models/admin_model.dart';
import 'package:shimmer/shimmer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AdminFirestoreService _firestoreService = AdminFirestoreService();
  bool _isLoading = true;
  SystemSettingsModel _settings = SystemSettingsModel.defaultSettings();
  List<AdminModel> _adminUsers = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _firestoreService.getSystemSettings();
      final admins = await _firestoreService.getAdminUsers();
      if (mounted) {
        setState(() {
          _settings = settings;
          _adminUsers = admins;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // Error loading settings
    }
  }

  Future<void> _updateSettings(SystemSettingsModel newSettings) async {
    setState(() => _settings = newSettings);
    try {
      await _firestoreService.updateSystemSettings(newSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating settings: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              child: SafeArea(
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
                        const Expanded(child: Text('System Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Configure your admin panel preferences and system controls', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            _buildShimmerBody()
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Global Configuration'),
                    _buildSettingsCard([
                      _buildSwitchTile(
                        'Maintenance Mode',
                        'Temporarily disable user access to the app',
                        Icons.build_outlined,
                        _settings.maintenanceMode,
                        (val) => _updateSettings(_settings.copyWith(maintenanceMode: val)),
                        isDestructive: true,
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        'Auto-Approve Photos',
                        'Automatically approve AI processed results',
                        Icons.auto_awesome,
                        _settings.autoApprovePhotos,
                        (val) => _updateSettings(_settings.copyWith(autoApprovePhotos: val)),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Notifications'),
                    _buildSettingsCard([
                      _buildSwitchTile(
                        'Push Notifications',
                        'Send alerts to users for processed photos',
                        Icons.notifications_active_outlined,
                        _settings.pushNotifications,
                        (val) => _updateSettings(_settings.copyWith(pushNotifications: val)),
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        'Email Alerts',
                        'Send system alerts and reports to admins',
                        Icons.email_outlined,
                        _settings.emailNotifications,
                        (val) => _updateSettings(_settings.copyWith(emailNotifications: val)),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _buildSectionTitle('App Limits & Defaults'),
                    _buildSettingsCard([
                      _buildDropdownTile(
                        'Welcome Bonus',
                        'Credits given to new registered users',
                        Icons.card_giftcard,
                        _settings.defaultWelcomeCredits.toString(),
                        ['0', '5', '10', '20', '50'],
                        (val) => _updateSettings(_settings.copyWith(defaultWelcomeCredits: int.parse(val!))),
                      ),
                      _buildDivider(),
                      _buildDropdownTile(
                        'Daily Photo Limit',
                        'Max photos a user can upload per day',
                        Icons.photo_library_outlined,
                        _settings.maxPhotosPerDay == 0 ? 'Unlimited' : _settings.maxPhotosPerDay.toString(),
                        ['25', '50', '100', 'Unlimited'],
                        (val) => _updateSettings(_settings.copyWith(maxPhotosPerDay: val == 'Unlimited' ? 0 : int.parse(val!))),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    _buildSectionTitle('User Management'),
                    _buildSettingsCard([
                      _buildNavigationTile(
                        'Admin Users',
                        'Manage admin accounts and permissions',
                        Icons.admin_panel_settings_outlined,
                        () => _showAdminUsers(),
                      ),
                      _buildDivider(),
                      _buildNavigationTile(
                        'Activity Logs',
                        'View comprehensive system activity',
                        Icons.history,
                        () { /* Implement logs */ },
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1.1)),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey[100]);

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (isDestructive ? Colors.red : AppTheme.primaryColor).withAlpha(20), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: isDestructive ? Colors.red : AppTheme.primaryColor, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      trailing: Switch.adaptive(value: value, activeThumbColor: isDestructive ? Colors.red : AppTheme.primaryColor, onChanged: onChanged),
    );
  }

  Widget _buildDropdownTile(String title, String subtitle, IconData icon, String value, List<String> options, ValueChanged<String?> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppTheme.primaryColor, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNavigationTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppTheme.primaryColor, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  Widget _buildShimmerBody() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
            ),
          )),
        ),
      ),
    );
  }

  void _showAdminUsers() {
    // Separate pending and approved admins
    final pendingAdmins = _adminUsers.where((a) => !a.isApproved).toList();
    final approvedAdmins = _adminUsers.where((a) => a.isApproved).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Admin Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        await _loadSettings();
                        if (mounted) {
                          nav.pop();
                          _showAdminUsers();
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _adminUsers.isEmpty
                  ? const Center(child: Text('No admin users found'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        // Pending approval section
                        if (pendingAdmins.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.pending_actions, color: Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Pending Approval (${pendingAdmins.length})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...pendingAdmins.map((admin) => _buildPendingAdminCard(admin, setModalState)),
                          const SizedBox(height: 20),
                        ],
                        // Active admins section
                        if (approvedAdmins.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Active Admins (${approvedAdmins.length})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...approvedAdmins.map((admin) => _buildAdminUserCard(admin)),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingAdminCard(AdminModel admin, StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withAlpha(40)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(
                  (admin.name.isNotEmpty ? admin.name[0] : 'A').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                    Text(admin.email, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.orange.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                child: const Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final updated = AdminModel(
                      id: admin.id, name: admin.name, email: admin.email,
                      role: admin.role, isActive: false, isApproved: false,
                      createdAt: admin.createdAt,
                    );
                    await _firestoreService.updateAdminUser(updated);
                    await _loadSettings();
                    if (mounted) {
                      Navigator.pop(context);
                      _showAdminUsers();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withAlpha(40)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded, color: Colors.red, size: 18),
                        SizedBox(width: 6),
                        Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final updated = AdminModel(
                      id: admin.id, name: admin.name, email: admin.email,
                      role: admin.role, isActive: true, isApproved: true,
                      createdAt: admin.createdAt,
                    );
                    await _firestoreService.updateAdminUser(updated);
                    await _loadSettings();
                    if (mounted) {
                      Navigator.pop(context);
                      _showAdminUsers();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminUserCard(AdminModel admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(admin.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                      child: Text(admin.role, style: const TextStyle(fontSize: 9, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(admin.email, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: admin.isActive,
            onChanged: (val) async {
              final updated = AdminModel(
                id: admin.id, name: admin.name, email: admin.email,
                role: admin.role, isActive: val, isApproved: admin.isApproved,
                createdAt: admin.createdAt,
              );
              await _firestoreService.updateAdminUser(updated);
              _loadSettings();
            },
          ),
        ],
      ),
    );
  }
}
