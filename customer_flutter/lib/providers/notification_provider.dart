import 'package:flutter/material.dart';
import '../models/shared_models.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  bool _isFirstLoad = true;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  void listenToNotifications(String userId) {
    _isLoading = true;
    _firestoreService.streamNotifications(userId).listen(
      (newNotifications) {
        // Check for new unread notifications to show alert
        if (!_isFirstLoad && newNotifications.length > _notifications.length) {
          final latest = newNotifications.first;
          if (!latest.isRead) {
            NotificationService.showNotification(
              id: latest.id.hashCode,
              title: latest.title,
              body: latest.body,
            );
          }
        }

        _notifications = newNotifications;
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        _isLoading = false;
        _isFirstLoad = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to notifications: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestoreService.markNotificationAsRead(notificationId);
      // Local update for immediate feedback
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        // We don't need to manually update if we are listening to a stream, 
        // but it helps if the stream is slow.
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    for (var notification in _notifications.where((n) => !n.isRead)) {
      await markAsRead(notification.id);
    }
  }
}
