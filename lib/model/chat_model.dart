// This file contains unused models that were created but never integrated.
// Keeping it for potential future use or reference.
// Current implementation in home_screen.dart uses its own _ChatMessage class.

/* UNUSED - For reference only
enum RoomType { public, private }

class ChatRoom {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String avatarUrl;
  final int unreadCount;
  final RoomType type;
  final List<String> members;

  ChatRoom({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    this.avatarUrl = '',
    this.unreadCount = 0,
    this.type = RoomType.public,
    this.members = const [],
  });
}

class Message {
  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
  });
}
*/
