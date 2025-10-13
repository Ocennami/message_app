import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service quản lý Firebase Cloud Messaging (FCM)
/// Cho phép app nhận notification ngay cả khi bị kill
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _authService = SupabaseAuthService();
  final _supabase = Supabase.instance.client;
  String? _currentToken;

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> initialize() async {
    try {
      // 1. Request permission (iOS/Android 13+)
      await _requestPermission();

      // 2. Get FCM token
      _currentToken = await _fcm.getToken();
      if (_currentToken != null) {
        debugPrint('✅ FCM Token: $_currentToken');
        await _saveFCMTokenToDatabase(_currentToken!);
      } else {
        debugPrint('⚠️ FCM Token is null');
      }

      // 3. Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _currentToken = newToken;
        _saveFCMTokenToDatabase(newToken);
      });

      // 4. Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Handle background messages (app opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 6. Check if app was opened from terminated state
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('✅ FCM Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  // ============================================
  // PERMISSIONS
  // ============================================

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ FCM permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('✅ FCM provisional permission granted');
    } else {
      debugPrint('⚠️ FCM permission denied');
    }
  }

  // ============================================
  // TOKEN MANAGEMENT
  // ============================================

  /// Lưu FCM token vào Supabase database
  Future<void> _saveFCMTokenToDatabase(String token) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, cannot save FCM token');
        return;
      }

      // Get device ID
      final deviceId = await _getDeviceId();
      final platform = _getPlatformName();

      // Upsert token vào database
      final response = await _supabase.from('fcm_tokens').upsert(
        {
          'user_id': user.id,
          'fcm_token': token,
          'device_id': deviceId,
          'platform': platform,
          'last_used_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,device_id', // Update nếu đã tồn tại
      ).select();

      debugPrint('✅ FCM token saved to database: ${response.length} row(s)');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Get unique device ID
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Android ID
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    } else {
      return 'unknown_device';
    }
  }

  String _getPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'web';
  }

  /// Xóa FCM token khỏi database (khi logout)
  Future<void> deleteToken() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final deviceId = await _getDeviceId();

      await _supabase
          .from('fcm_tokens')
          .delete()
          .eq('user_id', user.id)
          .eq('device_id', deviceId);

      await _fcm.deleteToken();
      _currentToken = null;

      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }

  // ============================================
  // MESSAGE HANDLERS
  // ============================================

  /// Handle message khi app đang foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 FCM Foreground Message:');
    debugPrint('  Title: ${message.notification?.title}');
    debugPrint('  Body: ${message.notification?.body}');
    debugPrint('  Data: ${message.data}');

    // Note: NotificationService sẽ tự động show notification
    // qua Realtime subscription, không cần show lại ở đây
    // để tránh duplicate notifications
  }

  /// Handle khi user tap vào notification
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 User tapped notification:');
    debugPrint('  Data: ${message.data}');

    // TODO: Navigate to chat screen
    final senderId = message.data['senderId'];

    if (senderId != null) {
      // Navigate to chat với senderId
      // Bạn có thể dùng Navigator hoặc Provider để navigate
      debugPrint('  Navigate to chat with: $senderId');
    }
  }

  // ============================================
  // GETTERS
  // ============================================

  String? get currentToken => _currentToken;
}

// ============================================
// BACKGROUND MESSAGE HANDLER
// ============================================

/// Handler cho messages khi app bị kill (top-level function)
/// PHẢI là top-level function, KHÔNG thể là class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 FCM Background Message (app killed):');
  debugPrint('  Title: ${message.notification?.title}');
  debugPrint('  Body: ${message.notification?.body}');
  debugPrint('  Data: ${message.data}');

  // Android sẽ tự động show notification
  // iOS cần xử lý riêng
}
