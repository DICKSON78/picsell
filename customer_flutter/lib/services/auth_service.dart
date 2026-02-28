import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../firebase_options.dart';
import 'api_service.dart';

class AuthService {
  // Lazy initialization to avoid accessing Firebase before it's ready
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;
  GoogleSignIn? _googleSignInInstance;

  // OTP verification state
  String? _verificationId;
  int? _resendToken;

  /// Ensure Firebase is initialized before using any Firebase services
  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('Firebase not initialized, initializing now...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase initialized successfully in AuthService');
      } catch (e) {
        debugPrint('Firebase initialization error: $e');
        throw 'Imeshindwa kuanzisha Firebase. Jaribu tena.';
      }
    }
  }

  FirebaseAuth get _auth {
    _authInstance ??= FirebaseAuth.instance;
    return _authInstance!;
  }

  FirebaseFirestore get _firestore {
    _firestoreInstance ??= FirebaseFirestore.instance;
    return _firestoreInstance!;
  }

  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(
      scopes: ['email', 'profile'],
    );
    return _googleSignInInstance!;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // ==================== GOOGLE SIGN IN ====================

  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Ensure Firebase is initialized
      await _ensureFirebaseInitialized();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) return null;

      // Get Firebase ID token and save it to ApiService
      try {
        final idToken = await userCredential.user!.getIdToken();
        if (idToken != null) {
          await ApiService().setToken(idToken);
          debugPrint('✅ Firebase ID token saved to ApiService (Google Sign-In)');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to save token: $e');
      }

      // Check if user exists in Firestore
      final existingUser = await getUserData(userCredential.user!.uid);

      if (existingUser != null) {
        // Update last login
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': Timestamp.now(),
        });
        return existingUser;
      }

      // Create new user in Firestore
      final userModel = UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        name: userCredential.user!.displayName ?? googleUser.displayName ?? 'Mtumiaji',
        phone: userCredential.user!.phoneNumber ?? '',
        photoUrl: userCredential.user!.photoURL ?? googleUser.photoUrl,
        credits: 2, // Welcome bonus - 2 free credits for new users
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toFirestore());

      // Create welcome bonus transaction
      await _firestore.collection('transactions').add({
        'userId': userCredential.user!.uid,
        'type': 'bonus',
        'credits': 2,
        'description': 'Welcome bonus credits - Google Sign In',
        'createdAt': Timestamp.now(),
      });

      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign In Error: ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      throw 'Imeshindwa kuingia na Google. Jaribu tena.';
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign Out Error: $e');
    }
  }

  // ==================== PHONE OTP AUTHENTICATION ====================

  /// Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(UserModel? user) onAutoVerified,
  }) async {
    try {
      // Ensure Firebase is initialized
      await _ensureFirebaseInitialized();

      // Format phone number (ensure it has country code)
      String formattedPhone = phoneNumber.trim();
      if (!formattedPhone.startsWith('+')) {
        // Default to Tanzania country code if not specified
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+255${formattedPhone.substring(1)}';
        } else {
          formattedPhone = '+255$formattedPhone';
        }
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          try {
            final user = await _signInWithPhoneCredential(credential, formattedPhone);
            onAutoVerified(user);
          } catch (e) {
            onError(e.toString());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('OTP Verification Failed: ${e.message}');
          onError(_handlePhoneAuthError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('Send OTP Error: $e');
      onError('Imeshindwa kutuma OTP. Jaribu tena.');
    }
  }

  /// Verify OTP code
  Future<UserModel?> verifyOTP({
    required String otp,
    required String phoneNumber,
  }) async {
    try {
      // Ensure Firebase is initialized
      await _ensureFirebaseInitialized();

      if (_verificationId == null) {
        throw 'Hakuna OTP iliyotumwa. Tafadhali omba OTP mpya.';
      }

      // Create a PhoneAuthCredential with the OTP
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      return await _signInWithPhoneCredential(credential, phoneNumber);
    } on FirebaseAuthException catch (e) {
      debugPrint('OTP Verification Error: ${e.message}');
      throw _handlePhoneAuthError(e);
    } catch (e) {
      debugPrint('OTP Verification Error: $e');
      if (e is String) rethrow;
      throw 'OTP si sahihi. Jaribu tena.';
    }
  }

  /// Sign in with phone credential
  Future<UserModel?> _signInWithPhoneCredential(
    PhoneAuthCredential credential,
    String phoneNumber,
  ) async {
    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user == null) return null;

    // Format phone for storage
    String formattedPhone = phoneNumber.trim();
    if (!formattedPhone.startsWith('+')) {
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+255${formattedPhone.substring(1)}';
      } else {
        formattedPhone = '+255$formattedPhone';
      }
    }

    // Check if user exists
    final existingUser = await getUserData(userCredential.user!.uid);

    if (existingUser != null) {
      // Update last login and phone
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': Timestamp.now(),
        'phone': formattedPhone,
      });
      return existingUser.copyWith(phone: formattedPhone);
    }

    // Create new user
    final userModel = UserModel(
      id: userCredential.user!.uid,
      email: '',
      name: 'Mtumiaji',
      phone: formattedPhone,
      credits: 2, // Welcome bonus - 2 free credits for new users
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set(userModel.toFirestore());

    // Create welcome bonus transaction
    await _firestore.collection('transactions').add({
      'userId': userCredential.user!.uid,
      'type': 'bonus',
      'credits': 2,
      'description': 'Welcome bonus credits - Phone OTP',
      'createdAt': Timestamp.now(),
    });

    return userModel;
  }

  /// Resend OTP
  Future<void> resendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerified: (_) {},
    );
  }

  // ==================== EMAIL AUTHENTICATION ====================

  // Register with email and password
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    try {
      // Ensure Firebase is initialized
      await _ensureFirebaseInitialized();

      // Create auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // Create user document in Firestore
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        credits: 2, // Welcome bonus - 2 free credits for new users
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());

      // Create welcome bonus transaction
      await _firestore.collection('transactions').add({
        'userId': credential.user!.uid,
        'type': 'bonus',
        'credits': 2,
        'description': 'Welcome bonus credits',
        'createdAt': Timestamp.now(),
      });

      // Update display name
      await credential.user!.updateDisplayName(name);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Login with email and password
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Ensure Firebase is initialized
      await _ensureFirebaseInitialized();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;

      // Update last login
      await _firestore.collection('users').doc(credential.user!.uid).update({
        'lastLogin': Timestamp.now(),
      });

      // Get Firebase ID token and save it to ApiService
      try {
        final idToken = await credential.user!.getIdToken();
        if (idToken != null) {
          await ApiService().setToken(idToken);
          debugPrint('✅ Firebase ID token saved to ApiService');
        }
      } catch (e) {
        debugPrint('⚠️ Failed to save token: $e');
      }

      // Get user data
      return await getUserData(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ==================== USER DATA ====================

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Get User Data Error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update(updates);
    }
  }

  // ==================== SIGN OUT ====================

  // Sign out
  Future<void> signOut() async {
    try {
      await signOutGoogle();
    } catch (e) {
      // Ignore Google sign out errors
    }
    await _auth.signOut();
    _verificationId = null;
    _resendToken = null;
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ==================== ERROR HANDLING ====================

  // Handle auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Hakuna akaunti kwa email hii';
      case 'wrong-password':
        return 'Password si sahihi';
      case 'email-already-in-use':
        return 'Email hii tayari inatumika';
      case 'weak-password':
        return 'Password ni dhaifu sana';
      case 'invalid-email':
        return 'Email si sahihi';
      case 'user-disabled':
        return 'Akaunti hii imezuiwa';
      case 'operation-not-allowed':
        return 'Njia hii ya kuingia haijawezeshwa';
      case 'account-exists-with-different-credential':
        return 'Akaunti tayari ipo kwa njia nyingine ya kuingia';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Tatizo limetokea. Jaribu tena.';
    }
  }

  // Handle phone auth errors
  String _handlePhoneAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Nambari ya simu si sahihi';
      case 'too-many-requests':
        return 'Maombi mengi sana. Subiri kidogo.';
      case 'invalid-verification-code':
        return 'OTP si sahihi';
      case 'session-expired':
        return 'OTP imeisha muda. Omba mpya.';
      case 'quota-exceeded':
        return 'Umezidi kikomo. Jaribu baadaye.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Tatizo limetokea. Jaribu tena.';
    }
  }
}
