import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load Environment Configuration (.env)
    await AppConfig.init();
  } catch (e) {
    debugPrint('AppConfig init error: $e');
  }

  try {
    // Initialize Firebase with timeout protection
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('Firebase initialization error/timeout: $e');
  }

  runApp(
    const ProviderScope(
      child: PayanoApp(),
    ),
  );
}
