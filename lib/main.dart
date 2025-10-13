import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:message_app/onboarding_screen.dart';
import 'package:message_app/home_screen.dart';
import 'package:message_app/config/supabase_config.dart';
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:message_app/services/notification_service.dart';
import 'package:message_app/services/presence_service.dart';
import 'package:message_app/services/background_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:message_app/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (for FCM on mobile)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized successfully');

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('✅ FCM background handler registered');
    } catch (e) {
      debugPrint('⚠️ Firebase initialization error: $e');
    }
  }

  // Initialize Supabase (replaces Firebase)
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase initialized successfully');
    debugPrint('✅ Supabase storage buckets ready');
  } catch (e) {
    debugPrint('⚠️ Supabase initialization error: $e');
  }

  // Initialize services
  final backgroundService = BackgroundService();
  final notificationService = NotificationService();
  final presenceService = PresenceService();

  // Initialize background service first
  await backgroundService.initialize();
  debugPrint('✅ Background service initialized');

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool userLoggedIn = prefs.getBool('userLoggedIn') ?? false;

  // Check actual Supabase Auth state (more reliable)
  final authService = SupabaseAuthService();
  final currentUser = authService.currentUser;
  final isActuallyLoggedIn = currentUser != null;

  debugPrint('📱 App starting with Supabase...');
  debugPrint('SharedPrefs userLoggedIn: $userLoggedIn');
  debugPrint(
    'Supabase currentUser: ${currentUser?.email} (id: ${currentUser?.id})',
  );
  debugPrint('Final isActuallyLoggedIn: $isActuallyLoggedIn');

  // If SharedPrefs says logged in but Supabase says no, clear the preference
  if (userLoggedIn && !isActuallyLoggedIn) {
    debugPrint('⚠️ Mismatch detected! Clearing userLoggedIn preference.');
    await prefs.setBool('userLoggedIn', false);
    userLoggedIn = false;
  }

  // If user is logged in, initialize notification and presence services
  if (isActuallyLoggedIn) {
    await notificationService.initialize();
    await notificationService
        .startMessageListener(); // ← Start message notifications
    await presenceService.initialize();

    // Initialize FCM (Firebase Cloud Messaging)
    if (Platform.isAndroid || Platform.isIOS) {
      final fcmService = FCMService();
      await fcmService.initialize();
      debugPrint('✅ FCM Service initialized');
    }

    debugPrint('✅ User services initialized with message notifications');
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: backgroundService)],
      child: MyApp(userLoggedIn: isActuallyLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool userLoggedIn;

  const MyApp({super.key, required this.userLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Message App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _getInitialScreen(),
      routes: {},
    );
  }

  Widget _getInitialScreen() {
    if (userLoggedIn) {
      return const HomeScreen();
    } else {
      return const OnboardingScreen();
    }
  }
}
