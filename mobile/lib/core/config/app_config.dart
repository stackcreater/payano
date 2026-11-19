import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      // Fallback if .env is missing during build tests
    }
  }

  static String _getEnv(String key, String fallback) {
    try {
      if (dotenv.isInitialized) {
        return dotenv.env[key] ?? fallback;
      }
    } catch (_) {}
    return fallback;
  }

  static String get appName => _getEnv('APP_NAME', 'Payano');
  static String get appEnv => _getEnv('APP_ENV', 'development');

  static String get apiBaseUrl {
    var raw = _getEnv('API_BASE_URL', '');
    if (kIsWeb && raw.isEmpty) {
      // In production web on Firebase Hosting, API requests route via /api or Cloud Functions
      // If deployed on Firebase or any domain, use relative /api or default cloud function
      return '/api';
    }
    if (raw.isEmpty) {
      raw = 'http://localhost:5000';
    }
    // Ensure default points to port 5000
    if (raw.contains(':8000')) {
      raw = raw.replaceAll(':8000', ':5000');
    }
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return raw.replaceAll('10.0.2.2', 'localhost');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return raw.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
    }
    return raw;
  }

  static String get localApiUrl {
    var raw = _getEnv('LOCAL_API_URL', 'http://localhost:5000');
    if (raw.contains(':8000')) {
      raw = raw.replaceAll(':8000', ':5000');
    }
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return raw.replaceAll('10.0.2.2', 'localhost');
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return raw.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
    }
    return raw;
  }

  static String get googleMapsApiKey => _getEnv('GOOGLE_MAPS_API_KEY', '');

  static String get firebaseApiKey => _getEnv('FIREBASE_API_KEY', '');
  static String get firebaseAppId => _getEnv('FIREBASE_APP_ID', '');
  static String get firebaseMessagingSenderId => _getEnv('FIREBASE_MESSAGING_SENDER_ID', '');
  static String get firebaseProjectId => _getEnv('FIREBASE_PROJECT_ID', '');
  static String get firebaseStorageBucket => _getEnv('FIREBASE_STORAGE_BUCKET', '');

  static String get paymentGateway => _getEnv('PAYMENT_GATEWAY', 'RAZORPAY');
  static String get razorpayKeyId => _getEnv('RAZORPAY_KEY_ID', '');

  static String get defaultCurrency => _getEnv('DEFAULT_CURRENCY', '₹');
  static String get defaultCountryCode => _getEnv('DEFAULT_COUNTRY_CODE', '+91');
  static bool get mockLocationEnabled => _getEnv('MOCK_LOCATION_ENABLED', 'true') == 'true';

  // Admin credentials from .env
  static String get adminUsername => _getEnv('ADMIN_USERNAME', 'admin');
  static String get adminPassword => _getEnv('ADMIN_PASSWORD', 'Admin@5645');
}
