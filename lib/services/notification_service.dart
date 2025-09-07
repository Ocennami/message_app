import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission();

    // Get token
    String? token = await _messaging.getToken();
    // Consider using a logger instead of print for production code
    // print('FCM Token: $token');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_foregroundHandler);
  }

  static Future<void> _backgroundHandler(RemoteMessage message) async {
    // Consider using a logger instead of print for production code
    // print('Background message: ${message.notification?.title}');
  }

  static void _foregroundHandler(RemoteMessage message) {
    // Consider using a logger instead of print for production code
    // print('Foreground message: ${message.notification?.title}');
  }
}