import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message_app/onboarding_screen.dart';
import 'package:message_app/home_screen.dart';
import 'package:message_app/config/supabase_config.dart';
import 'package:message_app/services/supabase_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (replaces Firebase)
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase initialized successfully');
    debugPrint('✅ Supabase storage buckets ready');
  } catch (e) {
    debugPrint('⚠️ Supabase initialization error: $e');
  }

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

  runApp(MyApp(userLoggedIn: isActuallyLoggedIn));
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
