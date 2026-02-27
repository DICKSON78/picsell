import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<UserModel?>? _userStreamSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  int get credits => _user?.credits ?? 0;
  
  // Get current user (for compatibility)
  UserModel? get currentUser => _user;
  
  // Get user ID (for compatibility)
  String? get uid => _user?.id;

  // Initialize - check if user is already logged in
  Future<void> initializeAuth() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = await _firestoreService.getUser(firebaseUser.uid);
      notifyListeners();
      // Start listening for real-time updates
      _startUserStream(firebaseUser.uid);
    }
  }

  // Start listening to user data updates (real-time credits)
  void _startUserStream(String userId) {
    _userStreamSubscription?.cancel();
    _userStreamSubscription = _firestoreService.streamUser(userId).listen((updatedUser) {
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

  // Logout
  Future<void> logout() async {
    _stopUserStream();
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopUserStream();
    super.dispose();
  }

  // Refresh user data
  Future<void> refreshUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = await _firestoreService.getUser(firebaseUser.uid);
      notifyListeners();
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

  // Deduct credit
  Future<bool> deductCredit({int amount = 1}) async {
    if (_user == null) return false;
    if (_user!.credits < amount) {
      _error = 'Credits hazitoshi';
      notifyListeners();
      return false;
    }

    final success = await _firestoreService.deductCredit(_user!.id, amount: amount);
    if (success) {
      await refreshUser();
    }
    return success;
  }

  // Add credits (after purchase)
  Future<void> addCredits(int amount, {String? description, double? payment}) async {
    if (_user == null) return;
    await _firestoreService.addCredits(_user!.id, amount, description: description, payment: payment);
    await refreshUser();
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
