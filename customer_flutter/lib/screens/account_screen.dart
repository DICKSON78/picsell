import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeroSection(context, user),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: _buildProfileCard(user),
                  ),
                  const SizedBox(height: 0),
                  _buildSettingsSection(context),
                  const SizedBox(height: 16),
                  _buildSignOutButton(context, authProvider),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, user) {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?q=80&w=2070&auto=format&fit=crop'),
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
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Account Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildProfileCard(user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor, width: 3),
              ),
              child: ClipOval(
                child: (user?.photoUrl != null)
                    ? Image.network(user!.photoUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, size: 50, color: AppTheme.primaryColor))
                    : const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'User Name',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.text),
          ),
          Text(
            user?.email ?? 'user@example.com',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Credits', '${user?.credits ?? 0}', Icons.bolt, AppTheme.accentOrange),
              _buildStat('Total Spent', 'TZS ${user?.totalSpent.toInt() ?? 0}', Icons.account_balance_wallet, AppTheme.accentGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.text,
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
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          _buildAccountItem(Icons.edit_outlined, 'Edit Profile', AppTheme.primarySoft, () {
            Navigator.pushNamed(context, '/edit-profile');
          }),
          const Divider(height: 1, indent: 64, color: AppTheme.border),
          _buildAccountItem(Icons.history_outlined, 'Payment History', AppTheme.iconBgBlue, () {
            // Navigator.pushNamed(context, '/payment-history');
          }),
          const Divider(height: 1, indent: 64, color: AppTheme.border),
          _buildAccountItem(Icons.notifications_outlined, 'Notifications', AppTheme.iconBgOrange, () {
            Navigator.pushNamed(context, '/notifications');
          }),
          const Divider(height: 1, indent: 64, color: AppTheme.border),
          _buildAccountItem(Icons.help_outline, 'Help & Support', AppTheme.iconBgGreen, () {
            // Navigator.pushNamed(context, '/help');
          }),
        ],
      ),
    );
  }

  Widget _buildAccountItem(IconData icon, String title, Color iconBgColor, VoidCallback onTap) {
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
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textLight,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _showSignOutDialog(context, auth),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.error.withOpacity(0.3))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: AppTheme.error, size: 20),
            const SizedBox(width: 8),
            Text('Sign Out', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.error)),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out from your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
