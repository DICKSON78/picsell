import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_model.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login with email and password
  Future<AdminModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return await _processUserLogin(credential.user);
    } on FirebaseAuthException catch (e) {
      // Auto-seed default admin on first use from Firestore config
      // Newer Firebase Auth returns 'invalid-credential' instead of 'user-not-found'
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        final seeded = await _tryAutoSeedAdmin(email, password);
        if (seeded != null) return seeded;
      }
      throw _handleAuthError(e);
    }
  }

  // Check Firestore for default admin config and seed if credentials match
  Future<AdminModel?> _tryAutoSeedAdmin(String email, String password) async {
    try {
      // Read admin defaults from Firestore config only
      final configDoc = await _firestore
          .collection('config')
          .doc('admin_defaults')
          .get()
          .timeout(const Duration(seconds: 8));
      if (!configDoc.exists) return null;

      final data = configDoc.data()!;
      if (data['seeded'] == true) return null; // Already seeded

      final defaultEmail = data['email']?.toString() ?? '';
      final defaultPassword = data['password']?.toString() ?? '';
      final defaultName = data['name']?.toString() ?? 'Super Admin';

      if (defaultEmail.isEmpty || defaultPassword.isEmpty) return null;
      if (email != defaultEmail || password != defaultPassword) return null;

      // Credentials match - create the Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      final newAdmin = AdminModel(
        id: user.uid,
        email: email,
        name: defaultName,
        role: 'super_admin',
        isActive: true,
        isApproved: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _firestore.collection('admins').doc(user.uid).set(newAdmin.toFirestore());

      // Mark config as used
      try {
        await _firestore.collection('config').doc('admin_defaults').set({
          'email': defaultEmail,
          'password': defaultPassword,
          'name': defaultName,
          'seeded': true,
          'seededAt': Timestamp.now(),
        });
      } catch (_) {}

      return newAdmin;
    } catch (e) {
      // Auto-seed failed silently
      return null;
    }
  }

  // Google Sign-In with Registration
  Future<AdminModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) return null;

      // Check existence
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();

      if (!adminDoc.exists) {
        // Create new Admin account - needs approval from super_admin
        final newAdmin = AdminModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'Admin',
          role: 'admin',
          isActive: true,
          isApproved: false, // Requires approval from existing admin
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _firestore.collection('admins').doc(user.uid).set(newAdmin.toFirestore());
        return newAdmin; // Return the model - caller checks isApproved
      } else {
        // Existing user - check approval status
        final admin = AdminModel.fromFirestore(adminDoc);

        if (!admin.isApproved) {
          return admin; // Return unapproved admin - caller handles navigation
        }

        // Update last login
        await _firestore.collection('admins').doc(user.uid).update({
          'lastLogin': Timestamp.now(),
        });
        return admin;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<AdminModel?> _processUserLogin(User? user) async {
    if (user == null) return null;

    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();

    if (!adminDoc.exists) {
      await _auth.signOut();
      throw Exception('Admin account not found.');
    }

    final admin = AdminModel.fromFirestore(adminDoc);

    if (!admin.isActive) {
      await _auth.signOut();
      throw Exception('Account is disabled.');
    }

    // Update last login
    await _firestore.collection('admins').doc(user.uid).update({
      'lastLogin': Timestamp.now(),
    });

    return admin; // Caller checks isApproved
  }

  // Get admin data from Firestore
  Future<AdminModel?> getAdminData(String adminId) async {
    try {
      final doc = await _firestore.collection('admins').doc(adminId).get();
      if (doc.exists) {
        return AdminModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore
    }
    await _auth.signOut();
  }

  // Handle auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Hakuna akaunti kwa email hii';
      case 'wrong-password':
        return 'Password si sahihi';
      case 'invalid-email':
        return 'Email si sahihi';
      case 'user-disabled':
        return 'Akaunti imezuiwa';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Tatizo limetokea. Jaribu tena.';
    }
  }
}
