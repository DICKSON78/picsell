import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<UserModel?>? _userStreamSubscription;

  int get credits => _user?.credits ?? 0;
  // Get current user (for compatibility)
  UserModel? get currentUser => _user;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  // Get user ID (for compatibility)
  String? get uid => _user?.id;

  UserModel? get user => _user;

  // Add credits (after purchase)
  Future<void> addCredits(int amount,
      {String? description, double? payment}) async {
    if (_user == null) return;
    await _firestoreService.addCredits(_user!.id, amount,
        description: description, payment: payment);
    await refreshUser();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Deduct credit
  Future<bool> deductCredit({int amount = 1}) async {
    if (_user == null) return false;
    if (_user!.credits < amount) {
      _error = 'Credits hazitoshi';
      notifyListeners();
      return false;
    }

    final success =
        await _firestoreService.deductCredit(_user!.id, amount: amount);
    if (success) {
      await refreshUser();
    }
    return success;
  }

  @override
  void dispose() {
    _stopUserStream();
    super.dispose();
  }

  // Initialize - check if user is already logged in
  Future<void> initializeAuth() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      // Get the current token and save it to ApiService
      try {
        final idToken = await firebaseUser.getIdToken();
        if (idToken != null) {
          await ApiService().setToken(idToken);
          debugPrint('✅ Token reloaded on app initialization');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to reload token: $e');
      }

      _user = await _firestoreService.getUser(firebaseUser.uid);
      notifyListeners();
      // Start listening for real-time updates
      _startUserStream(firebaseUser.uid);
    }
  }

  // Link Google account to existing email account
  Future<bool> linkGoogleAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.linkGoogleAccount();
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
      if (_user != null) {
        _startUserStream(_user!.id);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _stopUserStream();
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  // Refresh Firebase ID token
  Future<bool> refreshToken() async {
    try {
      final token = await _authService.refreshToken();
      return token != null;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = await _firestoreService.getUser(firebaseUser.uid);
      notifyListeners();
    }
  }

  // Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.registerWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      if (_user != null) {
        _startUserStream(_user!.id);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle();
      if (_user != null) {
        _startUserStream(_user!.id);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    if (_user == null) return false;

    try {
      await _authService.updateProfile(
        userId: _user!.id,
        name: name,
        phone: phone,
        photoUrl: photoUrl,
      );
      await refreshUser();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Start listening to user data updates (real-time credits)
  void _startUserStream(String userId) {
    _userStreamSubscription?.cancel();
    _userStreamSubscription =
        _firestoreService.streamUser(userId).listen((updatedUser) {
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
      }
    });
  }

  // Stop listening to user stream
  void _stopUserStream() {
    _userStreamSubscription?.cancel();
    _userStreamSubscription = null;
  }
}
