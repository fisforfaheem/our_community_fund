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
        apiKey: _require(_androidApiKey, 'FIREBASE_ANDROID_API_KEY'),
        appId: _require(_androidAppId, 'FIREBASE_ANDROID_APP_ID'),
        messagingSenderId:
            _require(_messagingSenderId, 'FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require(_projectId, 'FIREBASE_PROJECT_ID'),
        storageBucket: _require(_storageBucket, 'FIREBASE_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _require(_iosApiKey, 'FIREBASE_IOS_API_KEY'),
        appId: _require(_iosAppId, 'FIREBASE_IOS_APP_ID'),
        messagingSenderId:
            _require(_messagingSenderId, 'FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require(_projectId, 'FIREBASE_PROJECT_ID'),
        storageBucket: _require(_storageBucket, 'FIREBASE_STORAGE_BUCKET'),
        iosClientId: _optional(_iosClientId),
        iosBundleId: _optional(_iosBundleId),
      );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _require(_webApiKey, 'FIREBASE_WEB_API_KEY'),
        appId: _require(_webAppId, 'FIREBASE_WEB_APP_ID'),
        messagingSenderId:
            _require(_messagingSenderId, 'FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require(_projectId, 'FIREBASE_PROJECT_ID'),
        authDomain: _require(_authDomain, 'FIREBASE_AUTH_DOMAIN'),
        storageBucket: _require(_storageBucket, 'FIREBASE_STORAGE_BUCKET'),
        measurementId: _optional(_measurementId),
      );

  // ponytail: fromEnvironment requires string-literal keys at each call site.
  static const _androidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: '');
  static const _androidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '');
  static const _iosApiKey =
      String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: '');
  static const _iosAppId =
      String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '');
  static const _webApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: '');
  static const _webAppId =
      String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '');
  static const _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const _projectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const _authDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  static const _iosClientId = String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');
  static const _iosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const _measurementId =
      String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  static String _require(String value, String key) {
    if (value.isEmpty) {
      throw StateError(
        'Missing compile-time define: $key. '
        'Run via run_dev.sh or pass --dart-define=$key=...',
      );
    }
    return value;
  }

  static String? _optional(String value) =>
      value.isEmpty ? null : value;
}
