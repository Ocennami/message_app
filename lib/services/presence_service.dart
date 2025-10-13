import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:message_app/services/supabase_auth_service.dart';

/// Service quản lý online status và seen status
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final _authService = SupabaseAuthService();
  final _supabase = Supabase.instance.client;

  Timer? _heartbeatTimer;

  final Map<String, UserPresence> _presences = {};
  final StreamController<Map<String, UserPresence>> _presenceController =
      StreamController<Map<String, UserPresence>>.broadcast();

  Stream<Map<String, UserPresence>> get presenceStream =>
      _presenceController.stream;
  Map<String, UserPresence> get currentPresences =>
      Map.unmodifiable(_presences);

  // ============================================
  // ONLINE STATUS
  // ============================================

  /// Initialize presence tracking
  Future<void> initialize() async {
    final user = _authService.currentUser;
    if (user == null) return;

    await setOnlineStatus(true);
    await _startHeartbeat();
    await _subscribeToUserStatus();

    // Listen to app lifecycle changes
    _setupAppLifecycleListener();

    debugPrint('✅ PresenceService initialized for user: ${user.id}');
  }

  /// Setup app lifecycle listener for proper cleanup
  void _setupAppLifecycleListener() {
    // This will be called when app goes to background/foreground
    // Note: This is a basic implementation, more robust solution is in main.dart
    // with WidgetsBindingObserver
  }

  Future<void> _subscribeToUserStatus() async {
    // Subscribe to user_status changes
    _supabase.from('user_status').stream(primaryKey: ['user_id']).listen((
      data,
    ) {
      _updatePresencesFromData(data);
    });
  }

  void _updatePresencesFromData(List<Map<String, dynamic>> data) {
    _presences.clear();

    for (final row in data) {
      try {
        final userId = row['user_id'] as String;
        _presences[userId] = UserPresence(
          userId: userId,
          isOnline: row['is_online'] as bool? ?? false,
          lastSeen: row['last_seen'] != null
              ? DateTime.parse(row['last_seen'] as String)
              : null,
          deviceInfo: row['device'] as String?,
        );
      } catch (e) {
        debugPrint('Error parsing user status: $e');
      }
    }

    _presenceController.add(_presences);
  }

  /// Set user online/offline status
  Future<void> setOnlineStatus(bool isOnline) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      // Update in database
      await _supabase.from('user_status').upsert({
        'user_id': user.id,
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
        'device': defaultTargetPlatform.toString(),
      });

      debugPrint('✅ Online status updated: $isOnline');
    } catch (e) {
      debugPrint('❌ Error updating online status: $e');
    }
  }

  /// Start heartbeat to keep online status active
  Future<void> _startHeartbeat() async {
    // Update online status every 15 seconds (reduced from 30s)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await setOnlineStatus(true);
    });
  }

  /// Get online status of a specific user
  bool isUserOnline(String userId) {
    return _presences[userId]?.isOnline ?? false;
  }

  /// Get last seen of a specific user
  DateTime? getUserLastSeen(String userId) {
    return _presences[userId]?.lastSeen;
  }

  /// Get formatted last seen text
  String getLastSeenText(String userId) {
    if (isUserOnline(userId)) {
      return 'Online';
    }

    final lastSeen = getUserLastSeen(userId);
    if (lastSeen == null) {
      return 'Offline';
    }

    final difference = DateTime.now().difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  // ============================================
  // SEEN STATUS (Message Read Receipts)
  // ============================================

  /// Mark message as seen
  Future<void> markMessageAsSeen({
    required String messageId,
    required String senderId,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Don't mark own messages as seen
    if (senderId == user.id) return;

    try {
      // Insert/update seen status
      await _supabase.from('message_seen').upsert({
        'message_id': messageId,
        'user_id': user.id,
        'seen_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Message $messageId marked as seen');
    } catch (e) {
      debugPrint('❌ Error marking message as seen: $e');
    }
  }

  /// Mark all messages in a conversation as seen
  Future<void> markConversationAsSeen(String conversationId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      // Get all unseen messages in conversation
      final messages = await _supabase
          .from('messages')
          .select('id, sender_id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', user.id)
          .order('created_at', ascending: false);

      // Mark each as seen
      for (final message in messages) {
        await markMessageAsSeen(
          messageId: message['id'] as String,
          senderId: message['sender_id'] as String,
        );
      }

      debugPrint(
        '✅ All messages in conversation $conversationId marked as seen',
      );
    } catch (e) {
      debugPrint('❌ Error marking conversation as seen: $e');
    }
  }

  /// Check if a message has been seen by a specific user
  Future<bool> isMessageSeenBy({
    required String messageId,
    required String userId,
  }) async {
    try {
      final result = await _supabase
          .from('message_seen')
          .select()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('❌ Error checking message seen status: $e');
      return false;
    }
  }

  /// Get list of users who have seen a message
  Future<List<String>> getMessageSeenBy(String messageId) async {
    try {
      final results = await _supabase
          .from('message_seen')
          .select('user_id')
          .eq('message_id', messageId);

      return results.map((r) => r['user_id'] as String).toList();
    } catch (e) {
      debugPrint('❌ Error getting message seen list: $e');
      return [];
    }
  }

  /// Stream of seen status for a message
  Stream<List<String>> messageSeenStream(String messageId) {
    return _supabase
        .from('message_seen')
        .stream(primaryKey: ['message_id', 'user_id'])
        .eq('message_id', messageId)
        .map((data) => data.map((r) => r['user_id'] as String).toList());
  }

  /// Get unread message count for a conversation
  Future<int> getUnreadCount(String conversationId) async {
    final user = _authService.currentUser;
    if (user == null) return 0;

    try {
      // Get all messages in conversation not sent by user
      final messages = await _supabase
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', user.id);

      if (messages.isEmpty) return 0;

      // Check which ones have not been seen
      int unreadCount = 0;
      for (final message in messages) {
        final isSeen = await isMessageSeenBy(
          messageId: message['id'] as String,
          userId: user.id,
        );
        if (!isSeen) unreadCount++;
      }

      return unreadCount;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  // ============================================
  // TYPING INDICATOR
  // ============================================

  /// Broadcast typing status
  Future<void> setTyping({
    required String conversationId,
    required bool isTyping,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      if (isTyping) {
        await _supabase.from('typing_status').upsert({
          'conversation_id': conversationId,
          'user_id': user.id,
          'is_typing': true,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        await _supabase
            .from('typing_status')
            .delete()
            .eq('conversation_id', conversationId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      debugPrint('❌ Error setting typing status: $e');
    }
  }

  /// Listen to typing indicators in a conversation
  Stream<List<String>> typingStream(String conversationId) {
    // Use database stream for typing indicators
    return _supabase
        .from('typing_status')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .map((data) {
          // Filter for this conversation and is_typing = true
          return data
              .where(
                (r) =>
                    r['conversation_id'] == conversationId &&
                    r['is_typing'] == true,
              )
              .map((r) => r['user_id'] as String)
              .toList();
        });
  }

  // ============================================
  // CLEANUP
  // ============================================

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await setOnlineStatus(false);

    await _presenceController.close();
  }
}

// ============================================
// DATA MODELS
// ============================================

class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? deviceInfo;

  const UserPresence({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
    this.deviceInfo,
  });

  @override
  String toString() {
    return 'UserPresence(userId: $userId, isOnline: $isOnline, lastSeen: $lastSeen)';
  }
}
