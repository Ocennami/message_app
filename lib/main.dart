import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:message_app/onboarding_screen.dart';
import 'package:message_app/home_screen.dart';
import 'package:message_app/user_profile_update_screen.dart';
import 'package:message_app/config/supabase_config.dart';
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:message_app/services/notification_service.dart';
import 'package:message_app/services/presence_service.dart';
import 'package:message_app/services/background_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:message_app/services/fcm_service.dart';
import 'package:message_app/services/windows_background_service.dart';
import 'package:message_app/services/version_check_service.dart';
import 'package:message_app/providers/theme_provider.dart';

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

  if (Platform.isWindows) {
    final windowsBgService = WindowsBackgroundService();
    await windowsBgService.initialize();
    debugPrint('✅ Windows Background Service enabled');
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

  // Use a global navigator key so services can show dialogs after runApp
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: backgroundService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(
        userLoggedIn: isActuallyLoggedIn,
        navigatorKey: navigatorKey,
      ),
    ),
  );

  // After runApp, perform a version check (non-blocking)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      // Sử dụng Supabase Edge Function để check version
      final metadataUrl =
          '${SupabaseConfig.supabaseUrl}/functions/v1/releases?platform=${Platform.isAndroid ? 'android' : 'windows'}';

      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        final checker = VersionCheckService(metadataUrl: metadataUrl);
        await checker.checkAndPrompt(ctx);
      }
    } catch (e) {
      debugPrint('Error during post-launch version check: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  final bool userLoggedIn;
  final GlobalKey<NavigatorState>? navigatorKey;

  const MyApp({super.key, required this.userLoggedIn, this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Message App',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: _getInitialScreen(),
          routes: {},
        );
      },
    );
  }

  Widget _getInitialScreen() {
    if (userLoggedIn) {
      return FutureBuilder<bool>(
        future: _checkIfProfileUpdateRequired(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF1a1a1a),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final needsProfileUpdate = snapshot.data ?? false;
          if (needsProfileUpdate) {
            return const UserProfileUpdateScreen();
          } else {
            return const HomeScreen();
          }
        },
      );
    } else {
      return const OnboardingScreen();
    }
  }

  Future<bool> _checkIfProfileUpdateRequired() async {
    try {
      final authService = SupabaseAuthService();
      final user = authService.currentUser;

      if (user == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final profileUpdated = prefs.getBool('profileUpdated') ?? false;

      // Kiểm tra nếu email chứa 'username' và chưa cập nhật profile
      final email = user.email ?? '';
      final isDefaultAccount = email.contains('username');

      return isDefaultAccount && !profileUpdated;
    } catch (e) {
      debugPrint('Error checking profile update requirement: $e');
      return false;
    }
  }
}
