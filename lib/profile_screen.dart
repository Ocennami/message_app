import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:message_app/services/unified_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = SupabaseAuthService();
  final _storageService =
      UnifiedStorageService(); // ✅ Sử dụng UnifiedStorageService để tận dụng R2
  final _imagePicker = ImagePicker();

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isUpdating = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _displayNameController.text = _authService.displayName;
        _emailController.text = user.email ?? '';
        _photoUrl = _authService.photoUrl;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
      });

      // Upload to Supabase Storage
      final bytes = await image.readAsBytes();
      final fileName = '${_authService.currentUserId}.jpg';
      final downloadUrl = await _storageService.uploadAvatar(
        userId: _authService.currentUserId!,
        fileName: fileName,
        bytes: bytes,
      );

      // Update user profile
      await _authService.updatePhotoUrl(downloadUrl);

      setState(() {
        _photoUrl = downloadUrl;
        _isLoading = false;
      });

      _showSnackBar('Cập nhật avatar thành công!', isError: false);
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Lỗi khi cập nhật avatar: $error');
    }
  }

  Future<void> _updateDisplayName() async {
    final newName = _displayNameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBar('Tên không được để trống');
      return;
    }

    try {
      setState(() {
        _isUpdating = true;
      });

      await _authService.updateDisplayName(newName);

      setState(() {
        _isUpdating = false;
      });

      _showSnackBar('Cập nhật tên thành công!', isError: false);
    } catch (error) {
      setState(() {
        _isUpdating = false;
      });
      _showSnackBar('Lỗi khi cập nhật tên: $error');
    }
  }

  Future<void> _updateEmail() async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      _showSnackBar('Email không được để trống');
      return;
    }

    if (!_isValidEmail(newEmail)) {
      _showSnackBar('Email không hợp lệ');
      return;
    }

    // Require re-authentication for email change
    final password = await _showPasswordDialog(
      title: 'Xác thực',
      message: 'Vui lòng nhập mật khẩu hiện tại để thay đổi email',
    );

    if (password == null) return;

    try {
      setState(() {
        _isUpdating = true;
      });

      // Re-authenticate with Supabase
      final isValid = await _authService.reauthenticate(password);
      if (!isValid) {
        throw Exception('Mật khẩu không đúng');
      }

      // Update email
      await _authService.updateEmail(newEmail);

      setState(() {
        _isUpdating = false;
      });

      _showSnackBar(
        'Email xác thực đã được gửi đến $newEmail. Vui lòng kiểm tra hộp thư!',
        isError: false,
      );
    } catch (error) {
      setState(() {
        _isUpdating = false;
      });
      _showSnackBar('Lỗi khi cập nhật email: $error');
    }
  }

  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      _showSnackBar('Vui lòng nhập mật khẩu hiện tại');
      return;
    }

    if (newPassword.isEmpty) {
      _showSnackBar('Vui lòng nhập mật khẩu mới');
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Mật khẩu xác nhận không khớp');
      return;
    }

    try {
      setState(() {
        _isUpdating = true;
      });

      // Re-authenticate with Supabase
      final isValid = await _authService.reauthenticate(currentPassword);
      if (!isValid) {
        throw Exception('Mật khẩu hiện tại không đúng');
      }

      // Update password
      await _authService.updatePassword(newPassword);

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isUpdating = false;
      });

      _showSnackBar('Cập nhật mật khẩu thành công!', isError: false);
    } catch (error) {
      setState(() {
        _isUpdating = false;
      });

      if (error.toString().contains('Mật khẩu')) {
        _showSnackBar(error.toString().replaceAll('Exception: ', ''));
      } else {
        _showSnackBar('Lỗi khi cập nhật mật khẩu: $error');
      }
    }
  }

  Future<String?> _showPasswordDialog({
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        backgroundColor: const Color(0xFFF2ECF7),
        foregroundColor: const Color(0xFF2D2535),
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Không tìm thấy người dùng'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _photoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: _photoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.person, size: 60),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                        ),
                        if (_isLoading)
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: const Color(0xFF1877F2),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _isLoading ? null : _pickAndUploadAvatar,
                              customBorder: const CircleBorder(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Display Name section
                  _buildSectionTitle('Tên hiển thị'),
                  TextField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên của bạn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _isUpdating ? null : _updateDisplayName,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Email section
                  _buildSectionTitle('Email'),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Nhập email của bạn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _isUpdating ? null : _updateEmail,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 32),

                  // Change Password section
                  _buildSectionTitle('Đổi mật khẩu'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isUpdating ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Cập nhật mật khẩu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D2535),
        ),
      ),
    );
  }
}
