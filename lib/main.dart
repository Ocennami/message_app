import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message_app/onboarding_screen.dart';
// Dòng import 'package:message_app/auth_screen.dart'... sẽ được xóa
import 'package:message_app/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool userLoggedIn = prefs.getBool('userLoggedIn') ?? false;

  runApp(MyApp(userLoggedIn: userLoggedIn));
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
