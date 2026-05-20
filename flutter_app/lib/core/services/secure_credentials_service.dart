import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive Nextcloud credentials in platform secure storage
/// (Keychain on iOS/macOS, Keystore on Android) instead of the plain SQLite DB.
class SecureCredentialsService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // useDataProtectionKeyChain=true (the v9 default) requires a real Apple
    // Developer signing identity and fails with -34018 on ad-hoc/unsigned
    // builds. The traditional macOS Keychain works fine for sandboxed apps.
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );
  static const _keyPassword = 'nc_password';

  static Future<String> readPassword() async =>
      await _storage.read(key: _keyPassword) ?? '';

  static Future<void> writePassword(String password) =>
      _storage.write(key: _keyPassword, value: password);

  static Future<void> clearPassword() => _storage.delete(key: _keyPassword);
}
