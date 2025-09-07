import 'package:flutter/material.dart';
import 'package:message_app/model/chat_model.dart'; // Assuming ChatRoom and Message are here
import '../widget/message_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatDetailScreen({super.key, required this.chatRoom}); // Updated to use super parameter

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState(); // Updated return type
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> messages = []; // Assuming Message is from chat_model.dart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.chatRoom.avatarUrl.isNotEmpty
                  ? NetworkImage(widget.chatRoom.avatarUrl)
                  : null,
              child: widget.chatRoom.avatarUrl.isEmpty
                  ? Text(widget.chatRoom.name[0])
                  : null,
            ),
            SizedBox(width: 10),
            Text(widget.chatRoom.name),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () {/* TODO: Video call */},
          ),
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {/* TODO: Voice call */},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: messages[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((255 * 0.3).round()), // Updated for withOpacity
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      // TODO: Gửi tin nhắn qua Firebase
      _messageController.clear();
    }
  }
}
