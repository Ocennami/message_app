enum RoomType { public, private }

class ChatRoom {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String avatarUrl;
  final int unreadCount;
  final RoomType type;
  final List<String> members; // Chỉ dùng cho phòng private

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
  final String senderId; // To identify who sent the message
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
  });
}
