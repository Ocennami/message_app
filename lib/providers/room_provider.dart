import 'package:flutter/material.dart';
import 'package:message_app/model/chat_model.dart';

class RoomProvider extends ChangeNotifier {
  final List<ChatRoom> _rooms = [];

  List<ChatRoom> get rooms => _rooms;

  void createRoom({
    required String name,
    RoomType type = RoomType.public,
    List<String> members = const [],
    String avatarUrl = '',
  }) {
    final room = ChatRoom(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      avatarUrl: avatarUrl,
      type: type,
      members: members,
    );
    _rooms.add(room);
    notifyListeners();
  }

  bool joinRoom(String roomId, String userId) {
    final room = _rooms.where((r) => r.id == roomId).toList();
    if (room.isEmpty) return false;
    final foundRoom = room.first;
    if (foundRoom.type == RoomType.public) {
      // Public room: anyone can join
      return true;
    } else {
      // Private room: only members can join
      if (foundRoom.members.contains(userId)) {
        return true;
      }
      return false;
    }
  }
}
