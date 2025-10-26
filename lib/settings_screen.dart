import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'auth_screen.dart';
import 'providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _cacheSize = 'Đang tính...';

  final user = Supabase.instance.client.auth.currentUser;
  String _displayName = '';
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserData();
    _calculateCacheSize();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select('display_name, photo_url')
          .eq('id', user!.id)
          .single();

      if (mounted) {
        setState(() {
          _displayName = response['display_name'] ?? '';
          _photoUrl = response['photo_url'] ?? '';
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _soundEnabled = prefs.getBool('sound') ?? true;
      _vibrationEnabled = prefs.getBool('vibration') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;

      if (await tempDir.exists()) {
        await for (var entity in tempDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      setState(() {
        _cacheSize = '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
      });
    } catch (e) {
      setState(() {
        _cacheSize = 'Không xác định';
      });
    }
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await _calculateCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ Đã xóa bộ nhớ đệm thành công',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF7494EC),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Lỗi khi xóa bộ nhớ đệm: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Đăng xuất',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C2C2E),
          ),
        ),
        content: Text(
          'Bạn có chắc muốn đăng xuất?',
          style: GoogleFonts.poppins(color: const Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: const Color(0xFF666666)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7494EC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar với Gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7494EC), Color(0xFF9CB4F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                title: Text(
                  'Cài đặt',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // User Info Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7494EC), Color(0xFF9CB4F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7494EC).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _photoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _photoUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: Colors.white,
                                          child: const Icon(
                                            Icons.person,
                                            color: Color(0xFF7494EC),
                                            size: 35,
                                          ),
                                        ),
                                  )
                                : Container(
                                    color: Colors.white,
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF7494EC),
                                      size: 35,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName.isNotEmpty ? _displayName : 'User',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Giao diện
                _buildSectionTitle('🎨 Giao diện'),
                _buildSettingsCard([
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildSettingTile(
                        icon: Icons.dark_mode_rounded,
                        iconColor: const Color(0xFF6C63FF),
                        title: 'Chế độ tối',
                        subtitle: themeProvider.isDarkMode
                            ? 'Đang bật'
                            : 'Đang tắt',
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.setTheme(value);
                          },
                          activeColor: const Color(0xFF7494EC),
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                // Thông báo
                _buildSectionTitle('🔔 Thông báo'),
                _buildSettingsCard([
                  _buildSettingTile(
                    icon: Icons.notifications_rounded,
                    iconColor: const Color(0xFFFF6B6B),
                    title: 'Thông báo đẩy',
                    subtitle: _notificationsEnabled ? 'Đang bật' : 'Đang tắt',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _saveSetting('notifications', value);
                      },
                      activeColor: const Color(0xFF7494EC),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.volume_up_rounded,
                    iconColor: const Color(0xFFFFD93D),
                    title: 'Âm thanh',
                    subtitle: _soundEnabled ? 'Đang bật' : 'Đang tắt',
                    trailing: Switch(
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() => _soundEnabled = value);
                        _saveSetting('sound', value);
                      },
                      activeColor: const Color(0xFF7494EC),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.vibration_rounded,
                    iconColor: const Color(0xFF4ECDC4),
                    title: 'Rung',
                    subtitle: _vibrationEnabled ? 'Đang bật' : 'Đang tắt',
                    trailing: Switch(
                      value: _vibrationEnabled,
                      onChanged: (value) {
                        setState(() => _vibrationEnabled = value);
                        _saveSetting('vibration', value);
                      },
                      activeColor: const Color(0xFF7494EC),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // Bảo mật & Quyền riêng tư
                _buildSectionTitle('🔒 Bảo mật & Quyền riêng tư'),
                _buildSettingsCard([
                  _buildSettingTile(
                    icon: Icons.security_rounded,
                    iconColor: const Color(0xFF95E1D3),
                    title: 'Bảo mật tài khoản',
                    subtitle: 'Mật khẩu và xác thực',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF999999),
                    ),
                    onTap: () {
                      // TODO: Navigate to security settings
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.lock_rounded,
                    iconColor: const Color(0xFFFF8FB1),
                    title: 'Quyền riêng tư',
                    subtitle: 'Quản lý quyền riêng tư',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF999999),
                    ),
                    onTap: () {
                      // TODO: Navigate to privacy settings
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                // Bộ nhớ
                _buildSectionTitle('💾 Bộ nhớ'),
                _buildSettingsCard([
                  _buildSettingTile(
                    icon: Icons.storage_rounded,
                    iconColor: const Color(0xFFB983FF),
                    title: 'Bộ nhớ đệm',
                    subtitle: _cacheSize,
                    trailing: TextButton(
                      onPressed: () => _showClearCacheDialog(),
                      child: Text(
                        'Xóa',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // Về ứng dụng
                _buildSectionTitle('ℹ️ Về ứng dụng'),
                _buildSettingsCard([
                  _buildSettingTile(
                    icon: Icons.info_rounded,
                    iconColor: const Color(0xFF7494EC),
                    title: 'Phiên bản',
                    subtitle: '1.0.0',
                    trailing: const SizedBox.shrink(),
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.description_rounded,
                    iconColor: const Color(0xFFFFA726),
                    title: 'Điều khoản dịch vụ',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF999999),
                    ),
                    onTap: () {
                      // TODO: Show terms
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    icon: Icons.privacy_tip_rounded,
                    iconColor: const Color(0xFF66BB6A),
                    title: 'Chính sách bảo mật',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF999999),
                    ),
                    onTap: () {
                      // TODO: Show privacy policy
                    },
                  ),
                ]),

                const SizedBox(height: 30),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Đăng xuất',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2C2C2E),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF2C2C2E),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF999999),
              ),
            )
          : null,
      trailing: trailing,
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Xóa bộ nhớ đệm',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C2C2E),
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa tất cả bộ nhớ đệm không? Thao tác này không thể hoàn tác.',
          style: GoogleFonts.poppins(color: const Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: GoogleFonts.poppins(color: const Color(0xFF666666)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text('Xóa', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
