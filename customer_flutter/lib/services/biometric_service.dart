import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  final LocalAuthentication _localAuth = LocalAuthentication();

  factory BiometricService() {
    return _instance;
  }

  BiometricService._internal();

  /// Authenticate user with biometric
  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
    bool stickyAuth = true,
  }) async {
    try {
      final isSupported = await canUseBiometric();
      if (!isSupported) {
        print('⚠️ Biometric not supported on this device');
        return false;
      }

      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
          sensitiveTransaction: true,
        ),
      );

      if (result) {
        print('✅ Biometric authentication successful');
      } else {
        print('❌ Biometric authentication failed');
      }

      return result;
    } on PlatformException catch (e) {
      print('❌ Biometric platform error: ${e.code}');
      if (e.code == 'NotAvailable') {
        return false;
      }
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        print('⚠️ Biometric locked out - use pin instead');
        return false;
      }
      if (e.code == 'NotEnrolled') {
        print('⚠️ No biometric enrolled on device');
        return false;
      }
      // User canceled
      if (e.code == 'UserCanceled') {
        return false;
      }
      return false;
    } catch (e) {
      print('❌ Unexpected biometric error: $e');
      return false;
    }
  }

  /// Check if device supports biometric authentication
  Future<bool> canUseBiometric() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return canCheckBiometrics;
    } catch (e) {
      print('❌ Biometric check error: $e');
      return false;
    }
  }

  /// Get available biometric types on device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('❌ Error getting available biometrics: $e');
      return [];
    }
  }

  /// Get readable biometric name
  String getBiometricName(List<BiometricType> types) {
    if (types.isEmpty) return 'Biometric';
    if (types.contains(BiometricType.face)) return 'Face Recognition';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris Recognition';
    return 'Biometric';
  }

  /// Verify payment with biometric
  Future<bool> verifyPayment({
    required BuildContext context,
    String? reason,
  }) async {
    final isSwahili = Localizer.isSwahili(context);

    return authenticate(
      reason: reason ??
          (isSwahili
              ? 'Thibitisha malipo kwa mwelekeo wako'
              : 'Verify payment with your biometric'),
      biometricOnly: false, // Allow PIN fallback
      stickyAuth: true, // Lock after auth
    );
  }
}

// Helper class for localization
class Localizer {
  static bool isSwahili(BuildContext context) {
    // This assumes you have localization in context
    // Adjust based on your localization provider
    return Localizations.localeOf(context).languageCode == 'sw';
  }
}
