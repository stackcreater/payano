import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefBiometricKey = 'payano_biometric_enabled';

  /// Check if device hardware supports biometrics and has enrolled fingerprints / face
  Future<bool> canAuthenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint('[BiometricService] Error checking support: $e');
      return false;
    }
  }

  /// Check available biometric types (e.g. fingerprint, face)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('[BiometricService] Error getting types: $e');
      return [];
    }
  }

  /// Prompt biometric / device lock authentication
  Future<bool> authenticate({String reason = 'Authenticate to access Payano security settings'}) async {
    try {
      final supported = await canAuthenticate();
      if (!supported) {
        debugPrint('[BiometricService] Biometrics not supported on this device');
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
      return authenticated;
    } catch (e) {
      debugPrint('[BiometricService] Authentication failed or cancelled: $e');
      return false;
    }
  }

  /// Get stored preference
  Future<bool> isBiometricLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefBiometricKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Save preference
  Future<void> setBiometricLockEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefBiometricKey, enabled);
    } catch (_) {}
  }
}

