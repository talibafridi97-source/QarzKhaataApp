import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Result object for biometric authentication operations.
class BiometricResult {
  final bool success;
  final String? errorMessage;

  BiometricResult({
    required this.success,
    this.errorMessage,
  });

  factory BiometricResult.success() => BiometricResult(success: true);
  factory BiometricResult.failure(String message) => BiometricResult(success: false, errorMessage: message);
}

/// Service handling device biometric hardware detection and authentication.
class BiometricService {
  BiometricService._privateConstructor();
  static final BiometricService instance = BiometricService._privateConstructor();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device hardware supports biometrics and can check them.
  Future<bool> canAuthenticate() async {
    try {
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      return isDeviceSupported && canCheckBiometrics;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric support: $e');
      return false;
    }
  }

  /// Get list of available biometric sensors (e.g. fingerprint, face).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Trigger biometric authentication prompt.
  /// Uses [biometricOnly: true] and [stickyAuth: true] for security.
  Future<BiometricResult> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
  }) async {
    try {
      final bool hasHardware = await canAuthenticate();
      if (!hasHardware) {
        // Check if there are biometrics enrolled
        final available = await getAvailableBiometrics();
        if (available.isEmpty) {
          return BiometricResult.failure(
            'Biometric authentication is not supported or not configured on this device.',
          );
        }
      }

      final bool authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      if (authenticated) {
        return BiometricResult.success();
      } else {
        return BiometricResult.failure('Biometric authentication was cancelled or failed.');
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication platform exception: [${e.code}] ${e.message}');
      String errorMessage;

      switch (e.code) {
        case auth_error.notEnrolled:
          errorMessage = 'No fingerprint or biometric enrolled. Please set it up in your phone Settings.';
          break;
        case auth_error.lockedOut:
          errorMessage = 'Biometrics locked out due to too many attempts. Please try again in 30 seconds.';
          break;
        case auth_error.permanentlyLockedOut:
          errorMessage = 'Biometrics permanently locked out. Please unlock your device with your phone PIN.';
          break;
        case auth_error.notAvailable:
          errorMessage = 'Biometric security is not available on this device.';
          break;
        case auth_error.passcodeNotSet:
          errorMessage = 'Please set a lock screen passcode or PIN on your device first.';
          break;
        case auth_error.otherOperatingSystem:
          errorMessage = 'Biometrics not supported on this platform.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during biometric authentication.';
      }

      return BiometricResult.failure(errorMessage);
    } catch (e) {
      debugPrint('Unexpected biometric error: $e');
      return BiometricResult.failure('Authentication error: $e');
    }
  }

  /// Cancel any pending biometric authentication if active
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      debugPrint('Error stopping authentication: $e');
    }
  }
}
