import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';
import 'secure_storage_provider.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final service = SocketService(secureStorage);

  // Watch auth state and connect/disconnect accordingly
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.isAuthenticated && !service.isConnected) {
      // User logged in, connect socket
      service.connect();
    } else if (!next.isAuthenticated && service.isConnected) {
      // User logged out, disconnect socket
      service.disconnect();
    }
  });

  // Connect if already authenticated
  final authState = ref.read(authProvider);
  if (authState.isAuthenticated && !service.isConnected) {
    service.connect();
  }

  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
