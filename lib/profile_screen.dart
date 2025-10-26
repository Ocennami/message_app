import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
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
  final _storageService = UnifiedStorageService();
  final _imagePicker = ImagePicker();

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isUpdating = false;
  String? _photoUrl;
  bool _showPasswordSection = false;

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

      setState(() => _isLoading = true);

      final bytes = await image.readAsBytes();
      final fileName = '${_authService.currentUserId}.jpg';
      final downloadUrl = await _storageService.uploadAvatar(
        userId: _authService.currentUserId!,
        fileName: fileName,
        bytes: bytes,
      );

      await _authService.updatePhotoUrl(downloadUrl);

      setState(() {
        _photoUrl = downloadUrl;
        _isLoading = false;
      });

      _showSnackBar('Cập nhật avatar thành công!', isError: false);
    } catch (error) {
      setState(() => _isLoading = false);
      _showSnackBar('Lỗi: $error');
    }
  }

  Future<void> _updateDisplayName() async {
    final newName = _displayNameController.text.trim();
    if (newName.isEmpty) {
      _showSnackBar('Tên hiển thị không được để trống');
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await _authService.updateDisplayName(newName);
      _showSnackBar('Cập nhật tên thành công!', isError: false);
    } catch (error) {
      _showSnackBar('Lỗi: $error');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updatePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnackBar('Vui lòng điền đầy đủ thông tin');
      return;
    }

    if (newPass != confirm) {
      _showSnackBar('Mật khẩu xác nhận không khớp');
      return;
    }

    if (newPass.length < 6) {
      _showSnackBar('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await _authService.updatePassword(newPass);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordSection = false);
      _showSnackBar('Đổi mật khẩu thành công!', isError: false);
    } catch (error) {
      _showSnackBar('Lỗi: $error');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2535)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hồ sơ',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D2535),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar Section với design đẹp
            _buildAvatarSection(),
            const SizedBox(height: 24),

            // Info Cards
            _buildInfoCard(),
            const SizedBox(height: 16),

            // Password Section
            _buildPasswordCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF7494EC).withOpacity(0.3),
                      const Color(0xFF9CB4F5).withOpacity(0.3),
                    ],
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : ClipOval(
                        child: _photoUrl != null && _photoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _photoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7494EC),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7494EC).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Boxicons.bx_camera,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _displayNameController.text.isNotEmpty
                ? _displayNameController.text
                : 'Người dùng',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D2535),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _emailController.text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cá nhân',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2535),
            ),
          ),
          const SizedBox(height: 20),

          // Display Name
          _buildTextField(
            label: 'Tên hiển thị',
            controller: _displayNameController,
            icon: Boxicons.bx_user,
            suffixIcon: IconButton(
              icon: const Icon(Boxicons.bx_check, color: Color(0xFF7494EC)),
              onPressed: _isUpdating ? null : _updateDisplayName,
            ),
          ),
          const SizedBox(height: 16),

          // Email (read-only)
          _buildTextField(
            label: 'Email',
            controller: _emailController,
            icon: Boxicons.bx_envelope,
            readOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bảo mật',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D2535),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _showPasswordSection = !_showPasswordSection);
                },
                icon: Icon(
                  _showPasswordSection ? Boxicons.bx_minus : Boxicons.bx_plus,
                  size: 18,
                ),
                label: Text(
                  _showPasswordSection ? 'Ẩn' : 'Đổi mật khẩu',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          
          if (_showPasswordSection) ...[
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Mật khẩu hiện tại',
              controller: _currentPasswordController,
              icon: Boxicons.bx_lock_alt,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Mật khẩu mới',
              controller: _newPasswordController,
              icon: Boxicons.bx_lock_open_alt,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Xác nhận mật khẩu mới',
              controller: _confirmPasswordController,
              icon: Boxicons.bx_check_shield,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7494EC),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Cập nhật mật khẩu',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: const Color(0xFF2D2535),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF7494EC), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7494EC), width: 2),
        ),
      ),
    );
  }
}
