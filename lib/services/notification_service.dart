import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message_app/config/notification_config.dart';
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:message_app/services/supabase_message_service.dart';
import 'package:message_app/services/windows_notification_helper.dart';

/// Service quản lý tất cả notifications trong app
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final _authService = SupabaseAuthService();
  final _windowsNotifier = WindowsNotificationHelper();

  Timer? _dailyCheckTimer;
  bool _isInitialized = false;

  // 🔥 MethodChannel để check app state
  static const MethodChannel _appStateChannel = MethodChannel(
    'com.oceanami.message_app/app_state',
  );

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Windows notifications if on Windows
    if (Platform.isWindows) {
      await _windowsNotifier.initialize();
    }

    // Initialize local notifications for mobile
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    // 🔥 Create notification channels with Bubbles support
    await _createNotificationChannels();

    // Start daily check for birthdays and holidays
    _startDailyCheck();

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized with Bubbles support');
  }

  // 🔥 Tạo notification channel với Bubbles support
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    // Channel cho tin nhắn với Bubbles support
    const messageChannel = AndroidNotificationChannel(
      'messages_channel',
      'Messages',
      description: 'New message notifications with chat bubbles',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(messageChannel);
    debugPrint('✅ Notification channels created with Bubbles support');
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap
    // Navigate to appropriate screen based on payload
  }

  // ============================================
  // DAILY CHECK FOR BIRTHDAYS & HOLIDAYS
  // ============================================

  void _startDailyCheck() {
    // Check immediately
    _checkTodayNotifications();

    // Then check every hour
    _dailyCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkTodayNotifications(),
    );
  }

  Future<void> _checkTodayNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications') ?? true;

    if (!notificationsEnabled) return;

    final today = DateTime.now();
    final lastCheckDate = prefs.getString('lastNotificationCheck');

    // Only check once per day
    if (lastCheckDate == _formatDate(today)) {
      return;
    }

    // Check holidays
    await _checkHolidays();

    // Check birthdays
    await _checkBirthdays();

    // Save last check date
    await prefs.setString('lastNotificationCheck', _formatDate(today));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================
  // HOLIDAY NOTIFICATIONS
  // ============================================

  Future<void> _checkHolidays() async {
    final holidays = NotificationConfig.getTodayHolidays();

    for (final holiday in holidays) {
      await _showHolidayNotification(holiday);
    }
  }

  Future<void> _showHolidayNotification(NotificationData notification) async {
    const androidDetails = AndroidNotificationDetails(
      'holiday_channel',
      'Holiday Notifications',
      channelDescription: 'Notifications for special holidays',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      notification.icon ?? '🎉' + ' Special Day!',
      notification.message,
      details,
      payload: 'holiday',
    );
  }

  // ============================================
  // BIRTHDAY NOTIFICATIONS
  // ============================================

  Future<void> _checkBirthdays() async {
    // TODO: Get birthdays from Supabase
    // For now, check current user's birthday
    final user = _authService.currentUser;
    if (user == null) return;

    // Get user metadata with birthday
    final metadata = user.userMetadata;
    if (metadata == null || !metadata.containsKey('birthday')) return;

    final birthdayStr = metadata['birthday'] as String?;
    if (birthdayStr == null) return;

    try {
      final birthday = DateTime.parse(birthdayStr);
      final today = DateTime.now();

      if (birthday.month == today.month && birthday.day == today.day) {
        final userName = metadata['display_name'] ?? 'You';
        await _showBirthdayNotification(userName);
      }
    } catch (e) {
      debugPrint('Error parsing birthday: $e');
    }
  }

  Future<void> _showBirthdayNotification(String userName) async {
    final notification = NotificationConfig.getBirthdayNotification(userName);

    const androidDetails = AndroidNotificationDetails(
      'birthday_channel',
      'Birthday Notifications',
      channelDescription: 'Notifications for birthdays',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      notification.icon ?? '🎂' + ' Birthday!',
      notification.message,
      details,
      payload: 'birthday:$userName',
    );
  }

  // ============================================
  // MESSAGE NOTIFICATIONS
  // ============================================

  Future<void> showNewMessageNotification({
    required String senderId,
    required String senderName,
    required String messagePreview,
    String? senderAvatar,
    bool isGroup = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications') ?? true;
    final soundEnabled = prefs.getBool('sound') ?? true;

    if (!notificationsEnabled) return;

    final notification = NotificationConfig.getNewMessageNotification(
      senderName: senderName,
      messagePreview: messagePreview,
      senderAvatar: senderAvatar,
      isGroup: isGroup,
    );

    final androidDetails = AndroidNotificationDetails(
      'message_channel',
      'Message Notifications',
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(
        messagePreview,
        contentTitle: senderName,
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      senderId.hashCode,
      notification.icon ?? '💬' + ' $senderName',
      messagePreview,
      details,
      payload: 'message:$senderId',
    );
  }

  // ============================================
  // MANUAL NOTIFICATIONS
  // ============================================

  /// Show a custom notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ============================================
  // CANCEL NOTIFICATIONS
  // ============================================

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ============================================
  // MESSAGE NOTIFICATIONS (NEW!)
  // ============================================

  StreamSubscription? _messageSubscription;
  int _unreadCount = 0;

  /// Start listening for new messages
  Future<void> startMessageListener() async {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      debugPrint('⚠️ Cannot start message listener: No user logged in');
      return;
    }

    // Get message service
    final messageService = _getMessageService();
    if (messageService == null) return;

    // Listen to messages stream
    _messageSubscription = messageService
        .getMessagesStream(conversationId: 'common-channel')
        .listen((messages) {
          if (messages.isEmpty) return;

          // Get the latest message
          final latestMessage = messages.last;

          // Don't notify if it's from current user
          if (latestMessage['user_id'] == currentUserId) return;

          // Don't notify if message is old (older than 5 seconds)
          final createdAt = DateTime.parse(
            latestMessage['created_at'] as String,
          );
          final now = DateTime.now();
          if (now.difference(createdAt).inSeconds > 5) return;

          // Increment unread count
          _unreadCount++;

          // 🔥 Check app state trước khi show notification
          _showMessageNotificationIfNeeded(
            senderId: latestMessage['user_id'] as String,
            senderEmail: latestMessage['user_email'] as String? ?? 'Someone',
            message: latestMessage['text'] as String? ?? 'Sent an attachment',
            messageId: latestMessage['id'] as String,
            hasAttachment: latestMessage['attachment_url'] != null,
          );
        });

    debugPrint('✅ Message notification listener started');
  }

  /// Get message service instance
  SupabaseMessageService? _getMessageService() {
    try {
      return SupabaseMessageService();
    } catch (e) {
      debugPrint('❌ Failed to load message service: $e');
      return null;
    }
  }

  /// Stop message listener
  void stopMessageListener() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _unreadCount = 0;
    debugPrint('❌ Message notification listener stopped');
  }

  // 🔥 Check app state trước khi show notification
  Future<void> _showMessageNotificationIfNeeded({
    required String senderId,
    required String senderEmail,
    required String message,
    required String messageId,
    bool hasAttachment = false,
  }) async {
    // Show notification on Windows always, on mobile only when in background
    final shouldShow = Platform.isWindows || await _isAppInBackground();

    if (shouldShow) {
      await _showMessageNotification(
        senderId: senderId,
        senderEmail: senderEmail,
        message: message,
        messageId: messageId,
        hasAttachment: hasAttachment,
      );
    } else {
      debugPrint('⏭️ App in foreground (mobile), skipping notification');
    }
  }

  // 🔥 Check if app is in background
  Future<bool> _isAppInBackground() async {
    if (!Platform.isAndroid) return true; // Always show on other platforms

    try {
      final String state = await _appStateChannel.invokeMethod('getAppState');
      return state != 'resumed'; // paused or stopped = background
    } catch (e) {
      debugPrint('❌ Error checking app state: $e');
      return true; // Default: show notification
    }
  }

  /// Show notification for new message
  Future<void> _showMessageNotification({
    required String senderId,
    required String senderEmail,
    required String message,
    required String messageId,
    bool hasAttachment = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications') ?? true;

    if (!notificationsEnabled) return;

    // Extract username from email
    final senderName = senderEmail.split('@').first;
    final displayMessage = hasAttachment && message.isEmpty
        ? '📎 Sent an attachment'
        : message;

    // Windows: Use Windows notifications
    if (Platform.isWindows) {
      await _windowsNotifier.showNotification(
        title: senderName,
        body: displayMessage.length > 100
            ? '${displayMessage.substring(0, 100)}...'
            : displayMessage,
      );
      debugPrint('✅ Windows notification shown: $senderName - $displayMessage');
      return;
    }

    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      number: _unreadCount, // Badge count on notification
      styleInformation: BigTextStyleInformation(
        displayMessage,
        contentTitle: senderName,
        summaryText: 'Alliance Organization',
      ),
    );

    // iOS notification details
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: _unreadCount,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _notifications.show(
      1, // Use fixed ID so new messages replace old ones
      senderName,
      displayMessage.length > 100
          ? '${displayMessage.substring(0, 100)}...'
          : displayMessage,
      details,
      payload: 'message:$messageId',
    );

    debugPrint('✅ Message notification shown: $senderName - $displayMessage');
  }

  /// Reset unread count
  void resetUnreadCount() {
    _unreadCount = 0;
    debugPrint('✅ Unread count reset');
  }

  // ============================================
  // CLEANUP
  // ============================================

  void dispose() {
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = null;
    stopMessageListener();
  }
}
