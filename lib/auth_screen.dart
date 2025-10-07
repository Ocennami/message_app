// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:message_app/home_screen.dart';
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Màn hình xác thực với hiệu ứng chuyển đổi 100% giống file CSS
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  /* ────────────────────────────── Controller & State ────────────────────── */
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegister = GlobalKey<FormState>();

  bool _isActive = false; // Tương ứng với class 'active' trong CSS
  bool _isLoading = false;

  // Animation Controllers để điều khiển chính xác các transition
  late AnimationController _toggleController;
  late AnimationController _formController;
  late AnimationController _panelController;

  // Animations
  late Animation<double> _toggleAnimation;
  late Animation<double> _formTransitionAnimation;
  late Animation<double> _panelLeftAnimation;
  late Animation<double> _panelRightAnimation;

  @override
  void initState() {
    super.initState();

    // Controller chính cho toggle background (1.8s ease-in-out)
    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _toggleAnimation = CurvedAnimation(
      parent: _toggleController,
      curve: Curves.easeInOut,
    );

    // Controller cho form transition (0.6s ease-in-out với delay)
    _formController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _formTransitionAnimation = CurvedAnimation(
      parent: _formController,
      curve: Curves.easeInOut,
    );

    // Controller cho panel transitions
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _panelLeftAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    );
    _panelRightAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _toggleController.dispose();
    _formController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  // Hàm chuyển đổi mode với timing chính xác như CSS
  void _toggleMode() {
    FocusScope.of(context).unfocus();

    setState(() {
      _isActive = !_isActive;
    });

    if (_isActive) {
      // Chuyển sang Register mode
      _toggleController.forward();

      // Form transition với delay 1.2s như CSS
      Timer(const Duration(milliseconds: 1200), () {
        _formController.forward();
      });

      // Panel transition với delay 0.6s
      Timer(const Duration(milliseconds: 600), () {
        _panelController.forward();
      });
    } else {
      // Chuyển về Login mode
      _toggleController.reverse();

      // Form transition ngay lập tức
      Timer(const Duration(milliseconds: 1200), () {
        _formController.reverse();
      });

      // Panel transition với delay 1.2s
      Timer(const Duration(milliseconds: 600), () {
        _panelController.reverse();
      });
    }
  }

  /* ─────────────────────────────── Helper Widgets ─────────────────────── */
  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: const Color(0xFF888888),
        fontWeight: FontWeight.w400,
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Icon(icon, color: const Color(0xFF333333), size: 20),
      ),
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: const Color(0xFFEEEEEE),
      contentPadding: const EdgeInsets.fromLTRB(20, 13, 50, 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _socialBtn(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCCCCCC), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          /* TODO: Social Auth */
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, size: 24, color: const Color(0xFF333333)),
        ),
      ),
    );
  }

  /* ─────────────────────────────── Form Widgets ─────────────────────── */
  Widget _buildLoginForm() {
    return Form(
      key: _formKeyLogin,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Text(
              'Login',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _emailController,
            decoration: _fieldDecoration(
              hint: 'Email',
              icon: Boxicons.bxs_envelope,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter email';
              if (!v.contains('@') || !v.contains('.'))
                return 'Invalid email format';
              return null;
            },
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 30),

          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: _fieldDecoration(
              hint: 'Password',
              icon: Boxicons.bxs_lock_alt,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter password';
              return null;
            },
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF333333),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: _forgotPassword,
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          _submitButton('Login'),
          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(
              'or login with social platforms',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialBtn(Boxicons.bxl_google),
              _socialBtn(Boxicons.bxl_facebook),
              _socialBtn(Boxicons.bxl_github),
              _socialBtn(Boxicons.bxl_linkedin),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKeyRegister,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Text(
                'Registration',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _usernameController,
              decoration: _fieldDecoration(
                hint: 'Username',
                icon: Boxicons.bxs_user,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Username cannot be empty';
                }
                return null;
              },
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            TextFormField(
              controller: _emailController,
              decoration: _fieldDecoration(
                hint: 'Email',
                icon: Boxicons.bxs_envelope,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email cannot be empty';
                }
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: _fieldDecoration(
                hint: 'Password',
                icon: Boxicons.bxs_lock_alt,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password cannot be empty';
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            _submitButton('Register'),
            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(
                'or register with social platforms',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialBtn(Boxicons.bxl_google),
                _socialBtn(Boxicons.bxl_facebook),
                _socialBtn(Boxicons.bxl_github),
                _socialBtn(Boxicons.bxl_linkedin),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7494EC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /* ─────────────────────────────── Core Logic ─────────────────────── */
  Future<void> _submitForm() async {
    final isLogin = !_isActive;
    final form = isLogin
        ? _formKeyLogin.currentState
        : _formKeyRegister.currentState;

    final isValid = form?.validate() ?? false;
    if (!isValid) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final authService = SupabaseAuthService();

      if (isLogin) {
        // Sign in with Supabase
        await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Register with Supabase
        final username = _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : _emailController.text.trim().split('@')[0];

        await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: username,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('userLoggedIn', true);

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on supabase.AuthException catch (e) {
      String msg = 'Something went wrong. Please try again.';

      // Supabase error codes
      if (e.message.contains('Invalid login credentials')) {
        msg = 'Incorrect email or password.';
      } else if (e.message.contains('User already registered')) {
        msg = 'This email is already registered.';
      } else if (e.message.contains('Email not confirmed')) {
        msg = 'Please verify your email before logging in.';
      } else if (e.message.contains('Password should be at least')) {
        msg = 'Password must be at least 6 characters.';
      } else {
        msg = e.message;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email to reset password.'),
        ),
      );
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    try {
      final authService = SupabaseAuthService();
      await authService.resetPassword(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Check your inbox.'),
        ),
      );
    } on supabase.AuthException catch (e) {
      String message = 'Could not send email. Try again later.';
      if (e.message.contains('User not found')) {
        message = 'No account found with this email.';
      } else if (e.message.contains('Invalid email')) {
        message = 'Invalid email format.';
      } else {
        message = e.message;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Check your connection.')),
      );
    }
  }

  /* ─────────────────────────────── Main Build Method ─────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTextStyle(
        style: GoogleFonts.poppins(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFE2E2E2), Color(0xFFC9D6FF)],
            ),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 650;
                final containerWidth = isWide
                    ? 850.0
                    : constraints.maxWidth - 40;
                final containerHeight = isWide
                    ? 550.0
                    : constraints.maxHeight - 40;

                return Container(
                  width: containerWidth,
                  height: containerHeight,
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.2).round()),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        // Login Form Box
                        AnimatedBuilder(
                          animation: _formTransitionAnimation,
                          builder: (context, child) {
                            return Positioned(
                              right: isWide
                                  ? Tween<double>(
                                      begin: 0,
                                      end: containerWidth * 0.5,
                                    ).animate(_formTransitionAnimation).value
                                  : 0,
                              bottom: isWide
                                  ? 0
                                  : Tween<double>(
                                      begin: 0,
                                      end: containerHeight * 0.3,
                                    ).animate(_formTransitionAnimation).value,
                              width: isWide
                                  ? containerWidth * 0.5
                                  : containerWidth,
                              height: isWide
                                  ? containerHeight
                                  : containerHeight * 0.7,
                              child: Opacity(
                                opacity: 1.0 - _formTransitionAnimation.value,
                                child: Container(
                                  color: Colors
                                      .white, // Ensures the form area is opaque during transition
                                  padding: EdgeInsets.symmetric(
                                    horizontal: constraints.maxWidth > 400
                                        ? 40
                                        : 20,
                                  ),
                                  child: _buildLoginForm(),
                                ),
                              ),
                            );
                          },
                        ),

                        // Register Form Box
                        AnimatedBuilder(
                          animation: _formTransitionAnimation,
                          builder: (context, child) {
                            return Positioned(
                              right: isWide
                                  ? Tween<double>(
                                      begin: 0,
                                      end: containerWidth * 0.5,
                                    ).animate(_formTransitionAnimation).value
                                  : 0,
                              bottom: isWide
                                  ? 0
                                  : Tween<double>(
                                      begin: 0,
                                      end: containerHeight * 0.3,
                                    ).animate(_formTransitionAnimation).value,
                              width: isWide
                                  ? containerWidth * 0.5
                                  : containerWidth,
                              height: isWide
                                  ? containerHeight
                                  : containerHeight * 0.7,
                              child: Opacity(
                                opacity: _formTransitionAnimation.value,
                                child: Container(
                                  color: Colors
                                      .white, // Ensures the form area is opaque during transition
                                  padding: EdgeInsets.symmetric(
                                    horizontal: constraints.maxWidth > 400
                                        ? 40
                                        : 20,
                                  ),
                                  child: _buildRegisterForm(),
                                ),
                              ),
                            );
                          },
                        ),

                        // Toggle Background (::before element)
                        AnimatedBuilder(
                          animation: _toggleAnimation,
                          builder: (context, child) {
                            return Positioned(
                              left: isWide
                                  ? Tween<double>(
                                      begin: -containerWidth * 2.5,
                                      end: containerWidth * 0.5,
                                    ).animate(_toggleAnimation).value
                                  : 0,
                              top: isWide
                                  ? 0
                                  : Tween<double>(
                                      begin: -containerHeight * 2.7,
                                      end: containerHeight * 0.7,
                                    ).animate(_toggleAnimation).value,
                              width: isWide
                                  ? containerWidth * 3
                                  : containerWidth,
                              height: isWide
                                  ? containerHeight
                                  : containerHeight * 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7494EC),
                                  borderRadius: BorderRadius.circular(
                                    isWide ? 150 : containerWidth * 0.2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Toggle Panel Left (Hello, Welcome!)
                        AnimatedBuilder(
                          animation: _panelLeftAnimation,
                          builder: (context, child) {
                            return Positioned(
                              left: isWide
                                  ? Tween<double>(
                                      begin: 0,
                                      end: -containerWidth * 0.5,
                                    ).animate(_panelLeftAnimation).value
                                  : 0,
                              top: isWide
                                  ? 0
                                  : Tween<double>(
                                      begin: 0,
                                      end: -containerHeight * 0.3,
                                    ).animate(_panelLeftAnimation).value,
                              width: isWide
                                  ? containerWidth * 0.5
                                  : containerWidth,
                              height: isWide
                                  ? containerHeight
                                  : containerHeight * 0.3,
                              child: IgnorePointer(
                                ignoring:
                                    _isActive, // Only clickable when Login form visible
                                child: _buildTogglePanel(
                                  title: 'Hello, Welcome!',
                                  text: "Don't have an account?",
                                  buttonText: 'Register',
                                  onPressed: _toggleMode,
                                ),
                              ),
                            );
                          },
                        ),

                        // Toggle Panel Right (Welcome Back!)
                        AnimatedBuilder(
                          animation: _panelRightAnimation,
                          builder: (context, child) {
                            return Positioned(
                              right: isWide
                                  ? Tween<double>(
                                      begin: -containerWidth * 0.5,
                                      end: 0,
                                    ).animate(_panelRightAnimation).value
                                  : 0,
                              bottom: isWide
                                  ? 0
                                  : Tween<double>(
                                      begin: -containerHeight * 0.3,
                                      end: 0,
                                    ).animate(_panelRightAnimation).value,
                              width: isWide
                                  ? containerWidth * 0.5
                                  : containerWidth,
                              height: isWide
                                  ? containerHeight
                                  : containerHeight * 0.3,
                              child: IgnorePointer(
                                ignoring:
                                    !_isActive, // Only clickable when Register form visible
                                child: _buildTogglePanel(
                                  title: 'Welcome Back!',
                                  text: 'Already have an account?',
                                  buttonText: 'Login',
                                  onPressed: _toggleMode,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTogglePanel({
    required String title,
    required String text,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14.5, color: Colors.white),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 160,
            height: 46,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
