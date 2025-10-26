import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:message_app/config/supabase_config.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? displayName;
  final String? photoUrl;
  final String? email;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.email,
  });

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  final _authService = SupabaseAuthService();
  bool _isLoading = true;
  String? _displayName;
  String? _photoUrl;
  String? _email;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      // Use provided data first
      _displayName = widget.displayName;
      _photoUrl = widget.photoUrl;
      _email = widget.email;

      // Fetch additional data from Supabase
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('display_name, avatar_url, email, created_at')
          .eq('id', widget.userId)
          .single();

      setState(() {
        _displayName = response['display_name'] ?? _displayName;
        _photoUrl = response['avatar_url'] ?? _photoUrl;
        _email = response['email'] ?? _email;
        if (response['created_at'] != null) {
          _createdAt = DateTime.parse(response['created_at']);
        }
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool get _isCurrentUser => widget.userId == _authService.currentUserId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF8F9FD),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Personal page',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF7494EC).withOpacity(0.3),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFFE4E6EB),
                              backgroundImage:
                                  _photoUrl != null && _photoUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(_photoUrl!)
                                  : null,
                              child: _photoUrl == null || _photoUrl!.isEmpty
                                  ? Text(
                                      (_displayName?.isNotEmpty == true
                                              ? _displayName!.substring(0, 1)
                                              : '?')
                                          .toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF7494EC),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Display Name
                          Text(
                            _displayName ?? 'Người dùng',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (_email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _email!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // User Info Card
                          _buildInfoCard(
                            context,
                            isDark,
                            icon: Boxicons.bx_user,
                            title: 'Thông tin',
                            children: [
                              _buildInfoRow(
                                context,
                                isDark,
                                icon: Boxicons.bx_id_card,
                                label: 'User ID',
                                value: widget.userId,
                              ),
                              if (_createdAt != null)
                                _buildInfoRow(
                                  context,
                                  isDark,
                                  icon: Boxicons.bx_calendar,
                                  label: 'Tham gia',
                                  value: _formatDate(_createdAt!),
                                ),
                            ],
                          ),

                          // Action button (if not current user)
                          if (!_isCurrentUser) ...[
                            const SizedBox(height: 20),
                            _buildMessageButton(context, isDark),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7494EC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF7494EC), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Navigate to chat with this user
          Navigator.pop(context);
        },
        icon: const Icon(Boxicons.bx_message_rounded_dots, size: 20),
        label: Text(
          'Gửi tin nhắn',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7494EC),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else {
      return '${(difference.inDays / 365).floor()} năm trước';
    }
  }
}
