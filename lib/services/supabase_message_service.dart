import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Message Service
/// Handles all message-related operations with PostgreSQL
class SupabaseMessageService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Get messages stream (real-time)
  /// Note: Using 'messages' table directly because Realtime doesn't support views
  Stream<List<Map<String, dynamic>>> getMessagesStream({
    String conversationId = 'default',
    int limit = 50,
  }) async* {
    // Get all users data once for mapping
    final usersData = await _client
        .from('users')
        .select('id, display_name, photo_url, email');

    final usersMap = {for (var user in usersData) user['id']: user};

    // Stream messages from table (not view)
    // Note: Supabase Realtime streams don't support all query filters
    await for (final messages
        in _client.from('messages').stream(primaryKey: ['id'])) {
      // Filter, sort and limit in memory
      final filteredMessages =
          messages
              .where(
                (msg) =>
                    msg['conversation_id'] == conversationId &&
                    msg['is_deleted'] == false,
              )
              .toList()
            ..sort((a, b) {
              final aTime = DateTime.parse(a['created_at']);
              final bTime = DateTime.parse(b['created_at']);
              return aTime.compareTo(
                bTime,
              ); // Ascending order - oldest first, newest last
            });

      final limitedMessages = filteredMessages.take(limit).toList();

      // Get message IDs for batch fetching reactions and seen status
      final messageIds = limitedMessages.map((m) => m['id']).toList();

      // Fetch reactions for all messages
      final reactions = messageIds.isNotEmpty
          ? await _client
                .from('message_reactions')
                .select('message_id, user_id, emoji')
                .inFilter('message_id', messageIds)
          : [];

      // Fetch seen status for all messages
      final seenStatus = messageIds.isNotEmpty
          ? await _client
                .from('message_seen')
                .select('message_id, user_id')
                .inFilter('message_id', messageIds)
          : [];

      // Group reactions by message_id
      final reactionsMap = <String, Map<String, String>>{};
      for (final reaction in reactions) {
        final msgId = reaction['message_id'] as String;
        final emoji = reaction['emoji'] as String;
        final userId = reaction['user_id'] as String;

        reactionsMap[msgId] ??= {};
        reactionsMap[msgId]![emoji] = userId;
      }

      // Group seen status by message_id
      final seenMap = <String, int>{};
      for (final seen in seenStatus) {
        final msgId = seen['message_id'] as String;
        seenMap[msgId] = (seenMap[msgId] ?? 0) + 1;
      }

      // Enrich messages with user info, reactions, and seen status
      final enrichedMessages = limitedMessages.map((msg) {
        final msgId = msg['id'] as String;
        final userId = msg['user_id'];
        final user = usersMap[userId];
        final replyToId = msg['reply_to_id'] as String?;

        // Find replied message for preview
        Map<String, dynamic>? repliedMsg;
        if (replyToId != null) {
          repliedMsg = limitedMessages.firstWhere(
            (m) => m['id'] == replyToId,
            orElse: () => {},
          );
        }

        return {
          ...msg,
          'sender_name': user?['display_name'],
          'sender_photo': user?['photo_url'],
          'sender_email': user?['email'],
          'reactions': reactionsMap[msgId] ?? {},
          'seen_count': seenMap[msgId] ?? 0,
          'reply_to_text': repliedMsg?['text'],
          'reply_to_sender': usersMap[repliedMsg?['user_id']]?['display_name'],
        };
      }).toList();

      yield enrichedMessages;
    }
  }

  /// Send text message
  Future<Map<String, dynamic>> sendMessage({
    required String text,
    String conversationId = 'default',
    String? replyToId,
    bool isForwarded = false,
  }) async {
    final userId = await _getCurrentUserId();

    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'user_id': userId,
          'text': text,
          'reply_to_id': replyToId,
          'is_forwarded': isForwarded,
        })
        .select()
        .single();

    return response;
  }

  /// Send attachment (image, file, voice, gif)
  Future<Map<String, dynamic>> sendAttachment({
    required String attachmentUrl,
    required String attachmentType,
    String? attachmentName,
    String? text,
    String conversationId = 'default',
  }) async {
    final userId = await _getCurrentUserId();

    final response = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'user_id': userId,
          'text': text,
          'attachment_url': attachmentUrl,
          'attachment_type': attachmentType,
          'attachment_name': attachmentName,
        })
        .select()
        .single();

    return response;
  }

  /// Delete message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    await _client
        .from('messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  /// Search messages
  Future<List<Map<String, dynamic>>> searchMessages(
    String query, {
    String conversationId = 'default',
  }) async {
    final response = await _client.rpc(
      'search_messages',
      params: {'search_query': query, 'conv_id': conversationId},
    );

    return List<Map<String, dynamic>>.from(response);
  }

  /// Add reaction to message
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    final userId = await _getCurrentUserId();

    await _client.from('message_reactions').upsert({
      'message_id': messageId,
      'user_id': userId,
      'emoji': emoji,
    });
  }

  /// Remove reaction from message
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    final userId = await _getCurrentUserId();

    await _client
        .from('message_reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .eq('emoji', emoji);
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    final userId = await _getCurrentUserId();

    await _client.from('message_seen').upsert({
      'message_id': messageId,
      'user_id': userId,
    });
  }

  /// Get messages with pagination
  Future<List<Map<String, dynamic>>> getMessagesPaginated({
    String conversationId = 'default',
    int page = 0,
    int pageSize = 50,
  }) async {
    final response = await _client.rpc(
      'get_messages',
      params: {
        'conv_id': conversationId,
        'page_size': pageSize,
        'offset_val': page * pageSize,
      },
    );

    return List<Map<String, dynamic>>.from(response);
  }

  /// Update typing status
  Future<void> updateTypingStatus({
    bool isTyping = true,
    String conversationId = 'default',
  }) async {
    final userId = await _getCurrentUserId();

    if (isTyping) {
      await _client.from('typing_status').upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      await _client
          .from('typing_status')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    }
  }

  /// Get typing users stream with user info
  Stream<List<Map<String, dynamic>>> getTypingUsersStream({
    String conversationId = 'default',
  }) async* {
    // Get users data once for mapping
    final usersData = await _client
        .from('users')
        .select('id, display_name, email');
    final usersMap = {for (var user in usersData) user['id']: user};

    // Also try to get from user_profiles
    final profilesData = await _client
        .from('user_profiles')
        .select('user_id, display_name');
    final profilesMap = {
      for (var profile in profilesData) profile['user_id']: profile,
    };

    await for (final data
        in _client
            .from('typing_status')
            .stream(primaryKey: ['conversation_id', 'user_id'])) {
      // Filter in stream
      final filtered = data
          .where(
            (item) =>
                item['conversation_id'] == conversationId &&
                item['is_typing'] == true,
          )
          .map((item) {
            // Enrich with user info
            final userId = item['user_id'];
            final user = usersMap[userId];
            final profile = profilesMap[userId];

            return {
              ...item,
              'display_name': profile?['display_name'] ?? user?['display_name'],
              'email': user?['email'],
            };
          })
          .toList();
      yield filtered;
    }
  }

  /// Helper: Get current user ID from Supabase
  Future<String> _getCurrentUserId() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Return Supabase Auth user ID directly
    // User table uses same UUID as Auth
    return user.id;
  }
}
