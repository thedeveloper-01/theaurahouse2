import 'package:flutter/foundation.dart';

/// Logger utility with production-safe logging
class AppLogger {
  static const bool _isProduction = kReleaseMode;

  /// Log debug information (only in debug mode)
  static void debug(String message, [dynamic data]) {
    if (!_isProduction) {
      debugPrint('🔍 DEBUG: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  /// Log info (only in debug mode)
  static void info(String message, [dynamic data]) {
    if (!_isProduction) {
      debugPrint('ℹ️ INFO: $message${data != null ? ' | Data: $data' : ''}');
    }
  }

  /// Log warnings (always logged)
  static void warning(String message, [dynamic data]) {
    debugPrint('⚠️ WARNING: $message${data != null ? ' | Data: $data' : ''}');
  }

  /// Log errors (always logged, but sanitized in production)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isProduction) {
      // In production, log sanitized error without sensitive data
      debugPrint('❌ ERROR: $message');
    } else {
      debugPrint('❌ ERROR: $message${error != null ? ' | Error: $error' : ''}');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Log API calls (only in debug mode, never log tokens/passwords)
  static void api(String method, String endpoint, [int? statusCode]) {
    if (!_isProduction) {
      debugPrint(
        '🌐 API: $method $endpoint${statusCode != null ? ' | Status: $statusCode' : ''}',
      );
    }
  }
}
