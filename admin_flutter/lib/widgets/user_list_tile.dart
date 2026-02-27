import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../utils/theme.dart';

class UserListTile extends StatelessWidget {
  final User user;

  const UserListTile({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
        backgroundImage: user.picture != null 
            ? CachedNetworkImageProvider(user.picture!)
            : null,
        child: user.picture == null
            ? Icon(
                Icons.person,
                color: AppTheme.primaryColor,
                size: 24,
              )
            : null,
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        user.email,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${user.credits}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${user.totalPhotosProcessed}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () {
        // Navigate to user details
        Navigator.pushNamed(context, '/user-details', arguments: user);
      },
    );
  }
}
