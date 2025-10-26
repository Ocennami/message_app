// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:message_app/services/unified_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:message_app/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screen yêu cầu người dùng cập nhật thông tin cá nhân sau khi đăng nhập với tài khoản mặc định
class UserProfileUpdateScreen extends StatefulWidget {
  const UserProfileUpdateScreen({super.key});

  @override
  _UserProfileUpdateScreenState createState() =>
      _UserProfileUpdateScreenState();
}

class _UserProfileUpdateScreenState extends State<UserProfileUpdateScreen> {
  final _authService = SupabaseAuthService();
  final _storageService = UnifiedStorageService();
  final _imagePicker = ImagePicker();

  // Form controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Form keys
  final _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  bool _isUpdatingAvatar = false;
  String? _photoUrl;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Validation flags
  bool _isUsernameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _hasAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();

    // Show instruction dialog after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentEmail = _authService.currentUser?.email?.toLowerCase() ?? '';
      if (currentEmail.contains('username')) {
        _showInstructionDialog();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _emailController.text = user.email ?? '';
        _usernameController.text = user.userMetadata?['display_name'] ?? '';
        _photoUrl = user.userMetadata?['photo_url'];
        _hasAvatar = _photoUrl != null && _photoUrl!.isNotEmpty;
      });
    }
  }

  bool get _canProceed {
    return _isUsernameValid && _isEmailValid && _isPasswordValid && _hasAvatar;
  }

  void _validateForm() {
    setState(() {
      _isUsernameValid =
          _usernameController.text.trim().isNotEmpty &&
          _usernameController.text.trim().length >= 3;

      // Check if email is valid and not a temp account pattern
      final email = _emailController.text.trim().toLowerCase();
      final currentEmail = _authService.currentUser?.email?.toLowerCase() ?? '';
      final isTempEmail =
          email.contains('username') ||
          email.startsWith('temp_') ||
          email.contains('temp@');

      _isEmailValid =
          _isValidEmail(email) && !isTempEmail && email != currentEmail;

      _isPasswordValid =
          _newPasswordController.text.isNotEmpty &&
          _newPasswordController.text.length >= 8 &&
          _newPasswordController.text == _confirmPasswordController.text;
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Chọn ảnh từ gallery và upload trực tiếp
  Future<void> _pickAndUploadAvatar() async {
    try {
      setState(() {
        _isUpdatingAvatar = true;
      });

      // Pick image from gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() {
          _isUpdatingAvatar = false;
        });
        return;
      }

      // Read image bytes
      final Uint8List imageBytes = await pickedFile.readAsBytes();

      // Upload to storage
      final fileName =
          '${_authService.currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final downloadUrl = await _storageService.uploadAvatar(
        userId: _authService.currentUserId!,
        fileName: fileName,
        bytes: imageBytes,
      );

      setState(() {
        _photoUrl = downloadUrl;
        _hasAvatar = true;
        _isUpdatingAvatar = false;
      });

      _validateForm();
      _showSnackBar('Tải lên avatar thành công!', isError: false);
    } catch (error) {
      setState(() {
        _isUpdatingAvatar = false;
      });
      _showSnackBar('Lỗi khi tải lên avatar: $error');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate() || !_canProceed) {
      _showSnackBar('Vui lòng hoàn thành tất cả thông tin bắt buộc');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verify current password
      final isValidPassword = await _authService.reauthenticate(
        _currentPasswordController.text,
      );
      if (!isValidPassword) {
        throw Exception('Mật khẩu hiện tại không đúng');
      }

      final currentEmail = _authService.currentUser?.email ?? '';
      final newEmail = _emailController.text.trim().toLowerCase();

      // Check if this is a temporary account
      // Patterns: username@..., temp_...@..., or any email with 'temp' prefix
      final isDefaultAccount =
          currentEmail.toLowerCase().contains('username') ||
          currentEmail.toLowerCase().startsWith('temp_') ||
          currentEmail.toLowerCase().contains('temp@');

      // Validate new email for default accounts
      if (isDefaultAccount) {
        // Check if new email is also a temp email
        if (newEmail.contains('username') ||
            newEmail.startsWith('temp_') ||
            newEmail.contains('temp@')) {
          throw Exception(
            'Email không hợp lệ. Vui lòng sử dụng email THẬT của bạn (ví dụ: yourname@gmail.com)',
          );
        }
        if (newEmail == currentEmail.toLowerCase()) {
          throw Exception(
            'Bạn phải đổi email mới. Vui lòng nhập email thật của bạn.',
          );
        }

        // Validate email format more strictly
        if (!_isValidEmail(newEmail)) {
          throw Exception(
            'Định dạng email không hợp lệ. Vui lòng nhập email đúng định dạng.',
          );
        }

        // For test accounts, we need to MIGRATE to a new account
        // because Supabase won't allow updating email from invalid format
        await _authService.migrateTestAccount(
          newEmail: newEmail,
          newPassword: _newPasswordController.text,
          displayName: _usernameController.text.trim(),
          photoUrl: _photoUrl,
        );

        // Mark profile as updated
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('profileUpdated', true);

        setState(() {
          _isLoading = false;
        });

        _showSnackBar(
          '🎉 Chuyển đổi tài khoản thành công!\n\n'
          'Tài khoản mới của bạn:\n'
          'Email: $newEmail\n'
          'Tên: ${_usernameController.text.trim()}',
          isError: false,
        );

        // Wait a bit for user to see the success message
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );

        return; // Exit early for test account migration
      }

      // Update display name
      await _authService.updateDisplayName(_usernameController.text.trim());

      // Update email if changed (and not already updated above)
      if (!isDefaultAccount && newEmail != currentEmail.toLowerCase()) {
        await _authService.updateEmail(newEmail);
      }

      // Update password (if not updated above)
      if (!isDefaultAccount) {
        await _authService.updatePassword(_newPasswordController.text);
      }

      // Update avatar
      if (_photoUrl != null) {
        await _authService.updatePhotoUrl(_photoUrl!);
      }

      // Mark profile as updated
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profileUpdated', true);

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Cập nhật thông tin thành công!', isError: false);

      // Navigate to home screen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      // Parse error message
      String errorMessage = 'Lỗi khi cập nhật thông tin: $error';

      // Log full error for debugging
      print('❌ Update Profile Error: $error');
      print('❌ Error Type: ${error.runtimeType}');

      // Handle specific Supabase errors
      final errorStr = error.toString().toLowerCase();

      if (errorStr.contains('email_address_invalid') ||
          errorStr.contains('invalid email')) {
        // Check if the NEW email is actually valid
        final newEmail = _emailController.text.trim();
        if (newEmail.toLowerCase().contains('username')) {
          errorMessage =
              '❌ Email mới không hợp lệ!\n\n'
              'Email "$newEmail" có chứa "username".\n'
              'Vui lòng nhập EMAIL THẬT của bạn (ví dụ: yourname@gmail.com)';
        } else {
          // The new email is valid, so the error might be from the old email in database
          final currentEmail = _authService.currentUser?.email ?? '';
          errorMessage =
              '❌ Lỗi từ Supabase!\n\n'
              'Email hiện tại trong hệ thống: $currentEmail\n'
              'Email mới bạn nhập: $newEmail\n\n'
              'Chi tiết lỗi: $error\n\n'
              'Có thể bạn cần liên hệ admin để xử lý tài khoản test này.';
        }
      } else if (errorStr.contains('email')) {
        errorMessage =
            '❌ Lỗi liên quan đến email!\n\n'
            'Chi tiết: $error\n\n'
            'Vui lòng kiểm tra lại email và đảm bảo đây là email thật của bạn.';
      } else if (errorStr.contains('password')) {
        errorMessage =
            '❌ Lỗi mật khẩu!\n\n'
            'Chi tiết: $error\n\n'
            'Vui lòng kiểm tra lại mật khẩu hiện tại hoặc mật khẩu mới.';
      }

      _showSnackBar(errorMessage);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInstructionDialog() {
    final currentEmail = _authService.currentUser?.email ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2a2a2a),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text(
              'Hướng dẫn cập nhật',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đang sử dụng tài khoản mặc định:',
                style: GoogleFonts.inter(color: Colors.grey[300], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.email, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentEmail,
                            style: GoogleFonts.inter(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '11111111',
                          style: GoogleFonts.inter(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '⚠️ Quan trọng:',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              _buildInstructionItem(
                '1️⃣',
                'Bạn PHẢI đổi sang EMAIL THẬT của bạn',
                'Ví dụ: yourname@gmail.com, yourname@outlook.com',
              ),
              const SizedBox(height: 8),
              _buildInstructionItem(
                '2️⃣',
                'Không được dùng email có chứa "username"',
                'Email có "username" không hợp lệ với hệ thống',
              ),
              const SizedBox(height: 8),
              _buildInstructionItem(
                '3️⃣',
                'Chọn avatar và điền đầy đủ thông tin',
                'Tất cả các trường đều bắt buộc',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Đã hiểu',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String emoji, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Ngăn người dùng quay lại trước khi hoàn thành cập nhật
          _showSnackBar('Vui lòng hoàn thành cập nhật thông tin để tiếp tục');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a1a),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 32),

                  // Avatar Section
                  _buildAvatarSection(),
                  const SizedBox(height: 32),

                  // Username Field
                  _buildUsernameField(),
                  const SizedBox(height: 24),

                  // Email Field
                  _buildEmailField(),
                  const SizedBox(height: 24),

                  // Password Fields
                  _buildPasswordFields(),
                  const SizedBox(height: 32),

                  // Progress Indicator
                  _buildProgressIndicator(),
                  const SizedBox(height: 24),

                  // Continue Button
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentEmail = _authService.currentUser?.email?.toLowerCase() ?? '';
    final isDefaultAccount =
        currentEmail.contains('username') ||
        currentEmail.startsWith('temp_') ||
        currentEmail.contains('temp@');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoàn thiện thông tin',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng cập nhật thông tin cá nhân để tiếp tục sử dụng ứng dụng',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[400]),
        ),
        if (isDefaultAccount) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              border: Border.all(color: Colors.orange, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tài khoản mặc định',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn đang dùng tài khoản tạm ($currentEmail). Vui lòng đổi sang EMAIL THẬT của bạn (ví dụ: yourname@gmail.com)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.orange[200],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUpdatingAvatar ? null : _pickAndUploadAvatar,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _hasAvatar ? Colors.green : Colors.grey[600]!,
                  width: 3,
                ),
              ),
              child: _isUpdatingAvatar
                  ? const Center(child: CircularProgressIndicator())
                  : _photoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(
                          Boxicons.bx_user,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Icon(Boxicons.bx_camera, size: 60, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _hasAvatar ? 'Nhấn để thay đổi avatar' : 'Nhấn để thêm avatar',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
          ),
          if (_hasAvatar)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tên người dùng',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            if (_isUsernameValid)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          onChanged: (_) => _validateForm(),
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập tên người dùng (ít nhất 3 ký tự)',
            hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: const Icon(Boxicons.bx_user, color: Colors.grey),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tên người dùng không được để trống';
            }
            if (value.trim().length < 3) {
              return 'Tên người dùng phải có ít nhất 3 ký tự';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Email',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            if (_isEmailValid)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          onChanged: (_) => _validateForm(),
          style: GoogleFonts.inter(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Nhập email thật của bạn (ví dụ: yourname@gmail.com)',
            hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: const Icon(Boxicons.bx_envelope, color: Colors.grey),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email không được để trống';
            }
            final email = value.trim().toLowerCase();
            if (!_isValidEmail(email)) {
              return 'Định dạng email không hợp lệ';
            }
            if (email.contains('username')) {
              return 'Vui lòng sử dụng email thật của bạn (ví dụ: yourname@gmail.com)';
            }
            final currentEmail =
                _authService.currentUser?.email?.toLowerCase() ?? '';
            if (email == currentEmail && currentEmail.contains('username')) {
              return 'Bạn phải thay đổi email mới';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mật khẩu',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            if (_isPasswordValid)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        const SizedBox(height: 16),

        // Current Password
        TextFormField(
          controller: _currentPasswordController,
          obscureText: _obscureCurrentPassword,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Mật khẩu hiện tại',
            hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: const Icon(Boxicons.bx_lock, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureCurrentPassword ? Boxicons.bx_hide : Boxicons.bx_show,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureCurrentPassword = !_obscureCurrentPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu hiện tại';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // New Password
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          onChanged: (_) => _validateForm(),
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Mật khẩu mới (ít nhất 8 ký tự)',
            hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: const Icon(Boxicons.bx_lock_alt, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Boxicons.bx_hide : Boxicons.bx_show,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mật khẩu mới không được để trống';
            }
            if (value.length < 8) {
              return 'Mật khẩu phải có ít nhất 8 ký tự';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          onChanged: (_) => _validateForm(),
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Xác nhận mật khẩu mới',
            hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF2a2a2a),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            prefixIcon: const Icon(Boxicons.bx_lock_alt, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Boxicons.bx_hide : Boxicons.bx_show,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng xác nhận mật khẩu';
            }
            if (value != _newPasswordController.text) {
              return 'Mật khẩu xác nhận không khớp';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final completedSteps = [
      _hasAvatar,
      _isUsernameValid,
      _isEmailValid,
      _isPasswordValid,
    ].where((step) => step).length;
    final totalSteps = 4;
    final progress = completedSteps / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tiến độ hoàn thành: $completedSteps/$totalSteps',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[700],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress == 1.0 ? Colors.green : Colors.blue,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStepIndicator('Avatar', _hasAvatar),
            _buildStepIndicator('Tên', _isUsernameValid),
            _buildStepIndicator('Email', _isEmailValid),
            _buildStepIndicator('Mật khẩu', _isPasswordValid),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(String label, bool isCompleted) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _canProceed && !_isLoading ? _updateProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _canProceed ? Colors.blue : Colors.grey[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Hoàn thành và tiếp tục',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
