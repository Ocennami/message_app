// Bên trong OnboardingScreen, ví dụ khi nhấn nút "Hoàn thành"
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:message_app/auth_screen.dart'; // Import AuthScreen

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);

    // Sau khi lưu, điều hướng đến màn hình Đăng nhập/Đăng ký
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()), // Điều hướng đến AuthScreen
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Đã sửa: CustomScaffold -> Scaffold
      body: Center( // Giữ Center để căn giữa nội dung Column
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa các con của Column theo chiều dọc
          children: [
            Flexible(
              child: Center( // Center widget cho RichText
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Welcome to Alliance Organization":v"\n',
                        style: TextStyle(
                          fontSize: 41,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: 'Group Chat App chỉ dành cho thành viên Alliance Organization":v"\n',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Padding( // Thêm Padding để tạo khoảng cách cho nút
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: ElevatedButton(
                onPressed: () => _completeOnboarding(context),
                child: const Text('Bắt đầu sử dụng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}