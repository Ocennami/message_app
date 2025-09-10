import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class IntroPage2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purpleAccent,
      child: Center(
        child: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Đây là Message Application dành cho tất cả mọi người trong Alliance Organization ":v"\n',
              textAlign: TextAlign.center,
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white, // Bạn có thể cần điều chỉnh màu sắc ở đây
              ),
              speed: const Duration(
                milliseconds: 100,
              ), // Điều chỉnh tốc độ gõ chữ
            ),
          ],
          totalRepeatCount: 1, // Số lần lặp lại animation
          pause: const Duration(
            milliseconds: 1000,
          ), // Thời gian dừng sau khi gõ xong
          displayFullTextOnTap: true, // Hiển thị toàn bộ text khi chạm vào
          stopPauseOnTap: true, // Dừng animation khi chạm vào
        ),
      ),
    );
  }
}
