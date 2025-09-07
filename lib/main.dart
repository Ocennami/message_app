import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message_app/onboarding_screen.dart';
import 'package:message_app/auth_screen.dart';// Màn hình onboarding của bạn
import 'package:message_app/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );

  // Kiểm tra xem người dùng đã hoàn thành onboarding chưa
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
  bool userLoggedIn = prefs.getBool('userLoggedIn') ?? false;

  runApp(MyApp(
    onboardingCompleted: onboardingCompleted,
    userLoggedIn: userLoggedIn,
  ));
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;
  final bool userLoggedIn;

  const MyApp({
    super.key,
    required this.onboardingCompleted,
    required this.userLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Message App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    if (!userLoggedIn) { // Ưu tiên 1: Nếu chưa đăng nhập -> OnboardingScreen
      return const OnboardingScreen();
    } else { // Ngược lại (đã đăng nhập) -> HomeScreen
      return const HomeScreen();
    }
  }
}
