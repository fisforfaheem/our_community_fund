import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration loaded at compile time via --dart-define.
/// Never commit real values — see `.env.example` and `run_dev.sh`.
class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform. '
          'Add platform defines or use Android/iOS/Web.',
        );
      default:
        throw UnsupportedError(
          'Firebase is not supported on this platform.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _require('FIREBASE_ANDROID_API_KEY'),
        appId: _require('FIREBASE_ANDROID_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _require('FIREBASE_IOS_API_KEY'),
        appId: _require('FIREBASE_IOS_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
        iosClientId: _optional('FIREBASE_IOS_CLIENT_ID'),
        iosBundleId: _optional('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _require('FIREBASE_WEB_API_KEY'),
        appId: _require('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        authDomain: _require('FIREBASE_AUTH_DOMAIN'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
        measurementId: _optional('FIREBASE_MEASUREMENT_ID'),
      );

  static String _require(String key) {
    const value = String.fromEnvironment(key);
    if (value.isEmpty) {
      throw StateError(
        'Missing compile-time define: $key. '
        'Run via run_dev.sh or pass --dart-define=$key=...',
      );
    }
    return value;
  }

  static String? _optional(String key) {
    const value = String.fromEnvironment(key);
    return value.isEmpty ? null : value;
  }
}
