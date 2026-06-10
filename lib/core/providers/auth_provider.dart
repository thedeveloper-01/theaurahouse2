import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/logger.dart';
import 'api_provider.dart';
import 'secure_storage_provider.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SecureStorageService _secureStorage;

  AuthNotifier(this._apiService, this._secureStorage) : super(AuthState()) {
    // Load user asynchronously without blocking
    _loadUser();
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      // Check if there's a response with error message
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final responseData = error.response!.data;

        // Try to extract message from response
        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'] ?? responseData['error'];
          if (message != null) {
            return message.toString();
          }
        }

        // Provide user-friendly messages based on status code
        switch (statusCode) {
          case 409:
            return 'Username or email already exists. Please try a different one.';
          case 400:
            return 'Invalid registration data. Please check your input.';
          case 401:
            return 'Invalid credentials. Please check your username and password.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'Request failed. Please try again.';
        }
      }

      // Network or connection errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Connection timeout. Please check your internet connection.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to server. Please check your internet connection.';
      }
    }

    // Fallback to error string
    return error.toString().replaceAll('DioException [bad response]: ', '');
  }

  Future<void> _loadUser() async {
    final token = await _secureStorage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        // Set loading state to show splash screen while checking auth
        state = state.copyWith(isLoading: true, error: null);

        // Add timeout to prevent long waits (5 seconds max for initial load)
        final response = await _apiService.getProfile().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException(
              'Authentication check timed out',
              const Duration(seconds: 5),
            );
          },
        );

        if (response.data != null) {
          // Handle both Map and direct user object formats
          Map<String, dynamic> userData;
          if (response.data is Map) {
            userData = Map<String, dynamic>.from(response.data as Map);
          } else {
            // If response.data is already a Map<String, dynamic>, use it directly
            userData = response.data as Map<String, dynamic>;
          }

          final user = UserModel.fromJson(userData);
          // Update state with loaded user
            state = state.copyWith(user: user, isLoading: false, error: null);
        } else {
          // No user data, clear token and state
          await _secureStorage.deleteAuthToken();
          state = state.copyWith(isLoading: false, error: null, user: null);
        }
      } catch (e) {
        // Token is invalid, expired, or timeout - clear it and show login
        AppLogger.warning('Auth token validation failed', e);
        await _secureStorage.deleteAuthToken();
        state = state.copyWith(isLoading: false, error: null, user: null);
      }
    } else {
      // No token found, user needs to login - no need to set state, already correct
      // Initial state is already isLoading: false, user: null
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );

      if (response.data == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid response from server',
        );
        return false;
      }

      final token = response.data['accessToken'];
      final userData = response.data['user'];

      if (token == null || userData == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid response format from server',
        );
        return false;
      }

      try {
        final user = UserModel.fromJson(userData);
        await _secureStorage.saveAuthToken(token);
        state = state.copyWith(user: user, isLoading: false, error: null);
        return true;
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to parse user data: ${e.toString()}',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _apiService.login(
        username: username,
        password: password,
      );

      if (response.data == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid response from server',
        );
        return false;
      }

      final token = response.data['accessToken'];
      final userData = response.data['user'];

      if (token == null || userData == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid response format from server',
        );
        return false;
      }

      try {
        final user = UserModel.fromJson(userData);
        await _secureStorage.saveAuthToken(token);
        state = state.copyWith(user: user, isLoading: false, error: null);
        return true;
      } catch (e) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to parse user data: ${e.toString()}',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteAuthToken();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthNotifier(apiService, secureStorage);
});
