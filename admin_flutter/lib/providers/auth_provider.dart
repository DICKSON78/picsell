import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final AdminAuthService _authService = AdminAuthService();
  final AdminFirestoreService _firestoreService = AdminFirestoreService();

  AdminModel? _admin;
  bool _isLoading = false;
  String? _error;

  // Getters
  AdminModel? get admin => _admin;
  bool get isAuthenticated => _admin != null && _admin!.isApproved;
  bool get isPendingApproval => _admin != null && !_admin!.isApproved;
  bool get isLoggedIn => _admin != null;
  String? get name => _admin?.name;
  String? get email => _admin?.email;
  String? get role => _admin?.role;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSuperAdmin => _admin?.isSuperAdmin ?? false;

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        _admin = await _authService.getAdminData(firebaseUser.uid)
            .timeout(const Duration(seconds: 8));
      }
      notifyListeners();
    } catch (e) {
      // Timeout or network error - proceed to login
      _admin = null;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _admin = await _authService.loginWithEmail(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return _admin != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _admin = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return _admin != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _admin = null;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        _admin = await _authService.getAdminData(firebaseUser.uid)
            .timeout(const Duration(seconds: 8));
      }
    } catch (e) {
      _admin = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Seed initial admin (for first-time setup)
  Future<void> createInitialAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create admin document
        await _firestoreService.seedInitialAdmin(
          uid: credential.user!.uid,
          email: email,
          name: name,
        );
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
