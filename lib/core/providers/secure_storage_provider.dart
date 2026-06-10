import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/secure_storage_service.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
