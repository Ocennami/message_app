import 'package:flutter/material.dart';

class EmojiPickerWidget extends StatelessWidget {
  final void Function(String) onEmojiSelected;
  EmojiPickerWidget({required this.onEmojiSelected});

  final List<String> emojis = [
    '😀',
    '😂',
    '😍',
    '😎',
    '😭',
    '👍',
    '🙏',
    '🎉',
    '🔥',
    '🥰',
    '😡',
    '😱',
    '🤔',
    '😴',
    '😜',
    '😇',
    '🤩',
    '😢',
    '😅',
    '😆',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onEmojiSelected(emojis[index]),
            child: Center(
              child: Text(emojis[index], style: TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }
}
