import 'dart:ui'; // Cần cho ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For LogicalKeyboardKey
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'intro_screens/intro_page_1.dart';
import 'intro_screens/intro_page_2.dart';
import 'intro_screens/intro_page_3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message_app/home_screen.dart';
import 'package:message_app/auth_screen.dart'; // Thêm import cho AuthScreen

// Intents for keyboard actions
class NextPageIntent extends Intent {}
class PreviousPageIntent extends Intent {}
class DoneIntent extends Intent {} // Represents action triggered by Enter/Space

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final FocusNode _focusNode = FocusNode();
  bool onLastPage = false;
  bool _isIntro3CommitmentUnderstood = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true); // Vẫn lưu trạng thái này
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()), // Chuyển đến AuthScreen
    );
  }

  Widget _buildGlassButton({
    required String text,
    required VoidCallback? onPressed,
    double width = 80,
    double height = 40,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: onPressed != null
                   ? Colors.white.withAlpha((0.2 * 255).round())
                   : Colors.white.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              color: onPressed != null
                     ? Colors.white.withAlpha((0.3 * 255).round())
                     : Colors.white.withAlpha((0.15 * 255).round()),
              width: 1.5,
            ),
          ),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: onPressed != null ? Colors.white : Colors.white54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
      focusNode: _focusNode,
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowRight): NextPageIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): PreviousPageIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): DoneIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): DoneIntent(),
      },
      actions: <Type, Action<Intent>>{
        NextPageIntent: CallbackAction<NextPageIntent>(
          onInvoke: (NextPageIntent intent) {
            if (onLastPage) {
              if (_isIntro3CommitmentUnderstood) {
                _completeOnboarding();
              }
            } else {
              _controller.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
              );
            }
            return null;
          },
        ),
        PreviousPageIntent: CallbackAction<PreviousPageIntent>(
          onInvoke: (PreviousPageIntent intent) {
            if (_controller.page != null && _controller.page! > 0) {
              _controller.previousPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
              );
            }
            return null;
          },
        ),
        DoneIntent: CallbackAction<DoneIntent>(
          onInvoke: (DoneIntent intent) {
            if (onLastPage) {
              if (_isIntro3CommitmentUnderstood) {
                _completeOnboarding();
              }
            } else {
              _controller.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
              );
            }
            return null;
          },
        ),
      },
      child: Scaffold(
        body: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  onLastPage = (index == 2);
                  if (index != 2) {
                    _isIntro3CommitmentUnderstood = false;
                  }
                });
              },
              children: [
                IntroPage1(),
                IntroPage2(),
                IntroPage3(
                  onCommitmentUnderstood: () {
                    setState(() {
                      _isIntro3CommitmentUnderstood = true;
                    });
                  },
                ),
              ],
            ),
            Container(
              alignment: const Alignment(0, 0.75),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGlassButton(
                    text: 'Return',
                    onPressed: () {
                       if (_controller.page != null && _controller.page! > 0) {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeIn,
                        );
                       }
                    },
                  ),
                  SmoothPageIndicator(controller: _controller, count: 3),
                  onLastPage
                      ? _buildGlassButton(
                          text: 'Done',
                          onPressed: _isIntro3CommitmentUnderstood
                              ? _completeOnboarding
                              : null,
                        )
                      : _buildGlassButton(
                          text: 'Next',
                          onPressed: () {
                            if (!onLastPage) {
                               _controller.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeIn,
                              );
                            }
                          },
                        ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
