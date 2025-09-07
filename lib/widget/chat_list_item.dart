import 'package:flutter/material.dart';
import 'package:message_app/model/chat_model.dart'; // Assuming ChatRoom is in this file

class ChatListItem extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const ChatListItem({
    Key? key,
    required this.chatRoom,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: chatRoom.avatarUrl.isNotEmpty
            ? NetworkImage(chatRoom.avatarUrl)
            : null,
        child: chatRoom.avatarUrl.isEmpty
            ? Text(chatRoom.name[0].toUpperCase())
            : null,
      ),
      title: Text(
        chatRoom.name,
        style: TextStyle(
          fontWeight: chatRoom.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        chatRoom.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(chatRoom.lastMessageTime),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (chatRoom.unreadCount > 0)
            Container(
              margin: EdgeInsets.only(top: 4),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                chatRoom.unreadCount.toString(),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}