import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';

/// Windows-specific notification handler
class WindowsNotificationHelper {
  static final WindowsNotificationHelper _instance =
      WindowsNotificationHelper._internal();
  factory WindowsNotificationHelper() => _instance;
  WindowsNotificationHelper._internal();

  WindowsNotification? _winNotifier;

  /// Initialize Windows notifications
  Future<void> initialize() async {
    if (!Platform.isWindows) return;

    try {
      _winNotifier = WindowsNotification(applicationId: r'Oceanami.MessageApp');
      debugPrint('✅ Windows notification initialized');
    } catch (e) {
      debugPrint('❌ Windows notification initialization error: $e');
    }
  }

  /// Show Windows toast notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? group,
  }) async {
    if (!Platform.isWindows || _winNotifier == null) return;

    try {
      final message = NotificationMessage.fromPluginTemplate(
        'message_template',
        title,
        body,
        group: group ?? 'messages',
      );

      await _winNotifier!.showNotificationPluginTemplate(message);
      debugPrint('✅ Windows notification shown: $title - $body');
    } catch (e) {
      debugPrint('❌ Windows notification error: $e');
    }
  }

  /// Clear all Windows notifications
  Future<void> clearAll() async {
    if (!Platform.isWindows || _winNotifier == null) return;

    try {
      // Note: windows_notification package doesn't have clearNotificationGroup
      // Notifications will auto-dismiss after user interaction
      debugPrint('✅ Windows notifications clear requested (auto-dismiss)');
    } catch (e) {
      debugPrint('❌ Windows notification clear error: $e');
    }
  }
}
