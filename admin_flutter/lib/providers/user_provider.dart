import 'package:flutter/material.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // API Base URL - update this to your backend URL
  static const String _baseUrl = 'http://localhost:5000/api';

  Future<void> fetchUsers() async {
    _setLoading(true);
    _error = null;
    try {
      // For now, return mock data - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      _users = [
        User(
          id: '1',
          name: 'John Doe',
          email: 'john@example.com',
          credits: 25,
          totalCreditsPurchased: 50,
          totalPhotosProcessed: 15,
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastActive: DateTime.now(),
          picture: 'https://via.placeholder.com/100',
        ),
        User(
          id: '2',
          name: 'Jane Smith',
          email: 'jane@example.com',
          credits: 12,
          totalCreditsPurchased: 25,
          totalPhotosProcessed: 8,
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          lastActive: DateTime.now().subtract(const Duration(hours: 2)),
          picture: 'https://via.placeholder.com/100',
        ),
        User(
          id: '3',
          name: 'Mike Johnson',
          email: 'mike@example.com',
          credits: 5,
          totalCreditsPurchased: 5,
          totalPhotosProcessed: 2,
          isActive: false,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          lastActive: DateTime.now().subtract(const Duration(days: 1)),
          picture: null,
        ),
      ];
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleUserStatus(String userId) async {
    try {
      // For now, just update locally - replace with actual API call
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          isActive: !_users[userIndex].isActive,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addUserCredits(String userId, int credits) async {
    try {
      // For now, just update locally - replace with actual API call
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          credits: _users[userIndex].credits + credits,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Alias for addUserCredits
  Future<void> addCreditsToUser(String userId, int credits) async {
    await addUserCredits(userId, credits);
  }

  Future<void> addUser(User user) async {
    try {
      // For now, just add locally - replace with actual API call
      _users.add(user);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateUser(String userId, {String? name, String? email, String? phone}) async {
    try {
      // For now, just update locally - replace with actual API call
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          name: name,
          email: email,
          phone: phone,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  User? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
