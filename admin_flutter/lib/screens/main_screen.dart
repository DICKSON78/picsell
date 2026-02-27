import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import 'dashboard_screen.dart';
import 'customers_screen.dart';
import 'packages_screen.dart';
import 'advertisements_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  final List<Widget> _screens = [
    const DashboardTab(),
    const CustomersTab(),
    const PackagesTab(),
    const AdvertisementsTab(),
    const SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withAlpha(80),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
              _buildNavItem(1, Icons.people_outlined, Icons.people_rounded, 'Customers'),
              _buildNavItem(2, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Packages'),
              _buildNavItem(3, Icons.campaign_outlined, Icons.campaign_rounded, 'Ads'),
              _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withAlpha(0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primaryColor : Colors.white.withAlpha(180),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}

// ============================================
// CUSTOMERS TAB
// ============================================
class CustomersTab extends StatelessWidget {
  const CustomersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomersScreen();
  }
}

// ============================================
// PACKAGES TAB
// ============================================
class PackagesTab extends StatelessWidget {
  const PackagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PackagesScreen();
  }
}

// ============================================
// ADVERTISEMENTS TAB
// ============================================
class AdvertisementsTab extends StatelessWidget {
  const AdvertisementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdvertisementsScreen();
  }
}

// ============================================
// SETTINGS TAB
// ============================================
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
