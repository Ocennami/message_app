import 'package:flutter/material.dart';
import 'package:message_app/model/chat_model.dart'; // Added import for Message
import 'package:message_app/widget/message_bubble.dart'; // Added import for MessageBubble

class AnimatedMessageBubble extends StatefulWidget {
  final Message message;

  // Added constructor
  const AnimatedMessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  _AnimatedMessageBubbleState createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Added const
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() { // Added dispose method
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: MessageBubble(message: widget.message),
    );
  }
}
