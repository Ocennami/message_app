import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'dart:math' as math; // Import math for PI

class IntroPage3 extends StatefulWidget {
  final VoidCallback? onCommitmentUnderstood; // Callback function

  const IntroPage3({Key? key, this.onCommitmentUnderstood})
    : super(key: key); // Updated constructor

  @override
  _IntroPage3State createState() => _IntroPage3State();
}

class _IntroPage3State extends State<IntroPage3> with TickerProviderStateMixin {
  static const String commitmentText = '''Điều Khoản Cam Kết Cá Nhân

Tôi, [Tên của bạn/Người dùng], khi sử dụng ứng dụng này, xin tự nguyện cam kết:

1.  **Tôn trọng và Lịch sự**: Sẽ luôn đối xử với mọi người dùng khác bằng sự tôn trọng, không sử dụng ngôn từ gây tổn thương, xúc phạm hay phân biệt đối xử.
2.  **Bảo mật Thông tin**: Ý thức được tầm quan trọng của việc bảo vệ thông tin cá nhân của bản thân và của người khác. Không chia sẻ thông tin nhạy cảm một cách bừa bãi.
3.  **Nội dung Tích cực**: Chỉ chia sẻ và tạo ra những nội dung lành mạnh, mang tính xây dựng, phù hợp với thuần phong mỹ tục và pháp luật.
4.  **Chống Tin giả và Spam**: Không lan truyền tin tức sai sự thật, tin đồn thất thiệt hoặc gửi các tin nhắn không mong muốn (spam) gây phiền hà cho cộng đồng.
5.  **Đóng góp Xây dựng**: Sẵn sàng đóng góp ý kiến để cải thiện ứng dụng và cộng đồng người dùng một cách tích cực.

Tôi hiểu rằng việc duy trì một môi trường trực tuyến an toàn và thân thiện là trách nhiệm chung. Bằng việc chấp nhận những điều khoản này, tôi đồng ý hành động một cách có trách nhiệm.

(Cuộn xuống để đồng ý)''';

  late AnimationController _hoverAnimationController;
  late Animation<Offset> _offsetAnimation;
  late AnimationController _flipAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _contentSizeAnimation;

  late ScrollController _scrollController;
  bool _hasScrolledToEnd = false;
  // bool _letterInteractionCompleted = false; // Removed this state variable

  @override
  void initState() {
    super.initState();
    _hoverAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, -0.05),
        ).animate(
          CurvedAnimation(
            parent: _hoverAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _flipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _contentFadeAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    );

    _contentSizeAnimation = CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    );

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _hoverAnimationController.dispose();
    _flipAnimationController.dispose();
    _contentAnimationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 10) {
      if (!_hasScrolledToEnd) {
        setState(() {
          _hasScrolledToEnd = true;
        });
      }
    }
  }

  void _handleCommitmentUnderstood() {
    if (!_hasScrolledToEnd) return;

    widget.onCommitmentUnderstood?.call(); // Call the callback

    _toggleLetterOpenClose(); // Proceed to close the letter
  }

  void _toggleLetterOpenClose() {
    if (_flipAnimationController.isAnimating ||
        _contentAnimationController.isAnimating)
      return;

    if (_flipAnimationController.status == AnimationStatus.dismissed) {
      setState(() {
        _hasScrolledToEnd = false;
      });
      _flipAnimationController.forward().then((_) {
        if (mounted) {
          _contentAnimationController.forward().then((_) {
            if (mounted &&
                _scrollController.hasClients &&
                _scrollController.position.maxScrollExtent == 0) {
              setState(() {
                _hasScrolledToEnd = true;
              });
            }
          });
        }
      });
    } else {
      _contentAnimationController.reverse().then((_) {
        if (mounted) _flipAnimationController.reverse();
      });
    }
  }

  Widget _buildLetterContentWidget() {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizeTransition(
      sizeFactor: _contentSizeAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _contentFadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.45),
              child: Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Điều Khoản Cam Kết',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Text(
                          commitmentText,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _hasScrolledToEnd
                            ? Colors.pinkAccent.shade100
                            : Colors.grey.shade400,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'Đã Hiểu',
                        style: TextStyle(
                          color: _hasScrolledToEnd
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: _hasScrolledToEnd
                          ? _handleCommitmentUnderstood
                          : null, // Calls _handleCommitmentUnderstood
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.pinkAccent,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Cảm ơn các bạn đã tới đây <3\n',
                    textAlign: TextAlign.center,
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
                pause: const Duration(milliseconds: 1000),
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),
              const SizedBox(height: 40),
              SlideTransition(
                position: _offsetAnimation,
                child: GestureDetector(
                  onTap: _toggleLetterOpenClose,
                  child: AnimatedBuilder(
                    animation: _flipAnimationController,
                    builder: (BuildContext context, Widget? child) {
                      final animationValue = _flipAnimationController.value;
                      final angle = animationValue * math.pi;
                      Widget iconToDisplay;
                      if (animationValue < 0.5) {
                        iconToDisplay = Icon(
                          Icons.mail_outline,
                          size: 60,
                          color: Colors.white,
                        );
                      } else {
                        iconToDisplay = Transform(
                          transform: Matrix4.rotationY(math.pi),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            size: 60,
                            color: Colors.white,
                          ),
                        );
                      }
                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.7),
                                blurRadius: 15.0,
                                spreadRadius: 5.0,
                              ),
                            ],
                          ),
                          child: iconToDisplay,
                        ),
                      );
                    },
                  ),
                ),
              ),
              _buildLetterContentWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
