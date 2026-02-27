import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Custom bottom navigation bar with floating pill design
/// Purple gradient background with white icons
class BottomNavBar extends StatelessWidget {
  final int activeIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      margin: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            isActive: activeIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.history_outlined,
            activeIcon: Icons.history,
            label: 'History',
            isActive: activeIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet,
            label: 'Credits',
            isActive: activeIndex == 2,
            onTap: () => onTap(2),
            showBadge: true,
          ),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Account',
            isActive: activeIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool showBadge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.whiteColor : AppTheme.whiteColor.withAlpha(0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppTheme.primaryColor : AppTheme.whiteColor.withAlpha(180),
                  size: 24,
                ),
                if (showBadge)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? AppTheme.whiteColor : AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTheme.poppinsMedium(
              fontSize: 11,
              color: isActive ? AppTheme.whiteColor : AppTheme.whiteColor.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}
