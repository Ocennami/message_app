import 'package:flutter/material.dart';
import 'package:message_app/model/chat_model.dart'; // Assuming Message is defined here

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is a basic bubble. You might want to customize it further,
    // e.g., to differentiate between sender and receiver.
    return Align(
      // Example: Align to left for received messages
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.grey[300], // Example color for received messages
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          message.text, // Assuming Message has a 'text' field
          style: TextStyle(fontSize: 16.0, color: Colors.black87),
        ),
      ),
    );
  }
}
