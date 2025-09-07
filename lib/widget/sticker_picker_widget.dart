import 'package:flutter/material.dart';

class StickerPickerWidget extends StatelessWidget {
  final void Function(String) onStickerSelected;
  StickerPickerWidget({required this.onStickerSelected});

  final List<String> stickers = [
    'assets/images/OIP.jpg', // Thay bằng các đường dẫn sticker thật
    // Thêm các sticker khác nếu có
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stickers.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onStickerSelected(stickers[index]),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(stickers[index], height: 80),
            ),
          );
        },
      ),
    );
  }
}
