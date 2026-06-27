import 'package:flutter/foundation.dart';

/// Release-safe logging. Debug/info suppressed in release builds.
class AppLogger {
  AppLogger._();

  static void debug(String message) {
    if (!kReleaseMode) debugPrint('[DEBUG] $message');
  }

  static void info(String message) {
    if (!kReleaseMode) debugPrint('[INFO] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kReleaseMode) {
      debugPrint('[ERROR] $message');
    } else {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('  $error');
      if (stackTrace != null) debugPrint('  $stackTrace');
    }
  }
}
