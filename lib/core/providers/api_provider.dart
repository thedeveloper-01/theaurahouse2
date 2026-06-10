import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'secure_storage_provider.dart';

// Global instance to store the initialized SharedPreferences
SharedPreferences? _sharedPreferencesInstance;

/// Initialize SharedPreferences and store the instance
Future<void> initializeSharedPreferences() async {
  _sharedPreferencesInstance = await SharedPreferences.getInstance();
}

/// Provider that returns the initialized SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  if (_sharedPreferencesInstance == null) {
    throw Exception(
      'SharedPreferences not initialized. Call initializeSharedPreferences() in main() before runApp().',
    );
  }
  return _sharedPreferencesInstance!;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return ApiService(secureStorage);
});
