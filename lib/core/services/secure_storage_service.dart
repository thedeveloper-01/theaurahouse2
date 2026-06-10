import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service for sensitive data like auth tokens
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Keys
  static const String _authTokenKey = 'auth_token';

  /// Save auth token securely
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// Get auth token
  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  /// Delete auth token
  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  /// Clear all secure storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Migrate token from SharedPreferences to secure storage (one-time migration)
  Future<void> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString('auth_token');

      if (oldToken != null && oldToken.isNotEmpty) {
        // Check if we haven't already migrated
        final existingToken = await getAuthToken();
        if (existingToken == null) {
          await saveAuthToken(oldToken);
          await prefs.remove('auth_token');
        }
      }
    } catch (e) {
      // Silent fail - migration is best effort
    }
  }
}
