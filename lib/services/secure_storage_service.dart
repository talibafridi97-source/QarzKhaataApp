import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage Service using flutter_secure_storage to store sensitive flags and credentials.
class SecureStorageService {
  SecureStorageService._privateConstructor();
  static final SecureStorageService instance = SecureStorageService._privateConstructor();

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserEmail = 'user_email';

  // Configured storage with encrypted SharedPreferences for Android and Keychain accessibility for iOS
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Set the biometric enabled flag in secure storage
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Check if biometric login is enabled for the device
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Save logged-in user email
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  /// Retrieve stored user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  /// Clear all secure storage data (on reset or logout if desired)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
