import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.whiteColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.whiteColor.withAlpha(80),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.name ?? 'Admin',
                  style: GoogleFonts.poppins(
                    color: AppTheme.whiteColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.whiteColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authProvider.role ?? 'Administrator',
                    style: GoogleFonts.poppins(
                      color: AppTheme.whiteColor.withAlpha(220),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSectionTitle('MAIN'),
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  route: '/dashboard',
                  isSelected: currentRoute == '/dashboard',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_rounded,
                  title: 'Customers',
                  route: '/customers',
                  isSelected: currentRoute == '/customers',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: 'Packages',
                  route: '/packages',
                  isSelected: currentRoute == '/packages',
                ),

                const SizedBox(height: 8),
                _buildSectionTitle('ANALYTICS'),
                _buildDrawerItem(
                  context,
                  icon: Icons.photo_library_rounded,
                  title: 'Photos',
                  route: '/photos',
                  isSelected: currentRoute == '/photos',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.bar_chart_rounded,
                  title: 'Reports',
                  route: '/reports',
                  isSelected: currentRoute == '/reports',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history_rounded,
                  title: 'Report History',
                  route: '/report-history',
                  isSelected: currentRoute == '/report-history',
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.payments_rounded,
                  title: 'Transactions',
                  route: '/transactions',
                  isSelected: currentRoute == '/transactions',
                ),

                const SizedBox(height: 8),
                _buildSectionTitle('SETTINGS'),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  route: '/settings',
                  isSelected: currentRoute == '/settings',
                ),
              ],
            ),
          ),

          // Logout button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.border),
              ),
            ),
            child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withAlpha(50)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.error,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        color: AppTheme.error,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withAlpha(30) : AppTheme.iconBgPurple.withAlpha(100),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? AppTheme.primaryColor : AppTheme.text,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
