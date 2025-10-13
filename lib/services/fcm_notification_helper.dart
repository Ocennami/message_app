import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Helper class để gửi FCM notification thông qua Supabase Edge Function
class FCMNotificationHelper {
  static final _supabase = Supabase.instance.client;

  /// Gửi notification khi có tin nhắn mới
  /// Call Edge Function: send-fcm-notification
  static Future<void> sendMessageNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String message,
    required String messageId,
    String? chatId,
  }) async {
    try {
      debugPrint('📤 Sending FCM notification via Edge Function...');

      final response = await _supabase.functions.invoke(
        'send-fcm-notification',
        body: {
          'recipientId': recipientId,
          'senderId': senderId,
          'senderName': senderName,
          'message': message,
          'messageId': messageId,
          'chatId': chatId ?? senderId,
        },
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('✅ FCM notification sent: ${data['sentCount']} device(s)');
      } else {
        debugPrint('⚠️ FCM notification failed: ${response.status}');
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
    }
  }

  /// Test FCM bằng cách gửi test notification
  static Future<void> sendTestNotification({
    required String recipientId,
  }) async {
    await sendMessageNotification(
      recipientId: recipientId,
      senderId: 'test_sender',
      senderName: 'Test User',
      message: '🔔 This is a test notification from FCM',
      messageId: 'test_message_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
