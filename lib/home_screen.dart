import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
// Import record only on mobile platforms to avoid Windows build errors
import 'package:record/record.dart' if (dart.library.html) 'dart:core';
import 'package:message_app/onboarding_screen.dart';
import 'package:message_app/profile_screen.dart';
import 'package:message_app/settings_screen.dart';
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:message_app/services/supabase_message_service.dart';
import 'package:message_app/services/unified_storage_service.dart';
import 'package:message_app/widget/discord_style_picker.dart';
import 'package:message_app/widget/giphy_sdk_picker.dart';
import 'package:message_app/config/giphy_config.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const _AppDrawer(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isCompact = width < 480;
            final topSpacing = isCompact ? 12.0 : 24.0;
            final spacing = isCompact ? 8.0 : 16.0;

            return Column(
              children: [
                SizedBox(height: topSpacing),
                _HomeHeader(onSearchChanged: _handleSearchChanged),
                SizedBox(height: spacing),
                Expanded(child: _ChatSection(searchQuery: _searchQuery)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatefulWidget {
  const _HomeHeader({required this.onSearchChanged});

  final Function(String) onSearchChanged;

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _authService = SupabaseAuthService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        widget.onSearchChanged('');
      }
    });
  }

  Widget _buildUserAvatar(double size) {
    final user = _authService.currentUser;
    if (user == null) {
      // Fallback avatar if not logged in
      return Icon(
        Icons.person,
        size: size * 0.6,
        color: const Color(0xFF7F7F88),
      );
    }

    // Get avatar URL from user metadata or construct from Supabase storage
    final userId = user.id;
    final avatarUrl =
        'https://hqurumleoygxrhkuvahg.supabase.co/storage/v1/object/public/avatars/$userId/$userId.jpg';

    return CachedNetworkImage(
      imageUrl: avatarUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (context, url, error) {
        // Fallback to default avatar if image load fails
        return Image.asset('assets/images/OIP.jpg', fit: BoxFit.cover);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 480;
    final horizontalPadding = isCompact ? 12.0 : 24.0;
    final containerPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 16.0 : 20.0,
      vertical: isCompact ? 10.0 : 14.0,
    );
    final headerHeight = isCompact ? 44.0 : 48.0;
    final avatarSize = isCompact ? 36.0 : 40.0;
    final iconSize = isCompact ? 22.0 : 24.0;
    final splashRadius = isCompact ? 22.0 : 24.0;
    final titleStyle = TextStyle(
      color: const Color(0xFF2D2535),
      fontSize: isCompact ? 16.0 : 18.0,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2ECF7),
          borderRadius: BorderRadius.circular(isCompact ? 22 : 28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: containerPadding,
        child: SizedBox(
          height: headerHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Builder(
                  builder: (context) => IconButton(
                    onPressed: _isSearching
                        ? _toggleSearch
                        : () => Scaffold.of(context).openDrawer(),
                    iconSize: iconSize,
                    splashRadius: splashRadius,
                    icon: Icon(_isSearching ? Icons.arrow_back : Icons.menu),
                    color: const Color(0xFF2D2535),
                  ),
                ),
              ),
              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search for messages...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Color(0xFF7F7F88)),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF2D2535),
                      fontSize: 16,
                    ),
                    onChanged: widget.onSearchChanged,
                  ),
                )
              else
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Alliance Organization "v"',
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: _isSearching
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                        iconSize: iconSize,
                        splashRadius: splashRadius,
                        icon: const Icon(Icons.clear),
                        color: const Color(0xFF2D2535),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _toggleSearch,
                            iconSize: iconSize,
                            splashRadius: splashRadius,
                            icon: const Icon(Icons.search),
                            color: const Color(0xFF2D2535),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x11000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildUserAvatar(avatarSize),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFF2ECF7)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.chat_bubble, size: 64, color: Color(0xFF2D2535)),
                SizedBox(height: 16),
                Text(
                  'Channels',
                  style: TextStyle(
                    color: Color(0xFF2D2535),
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          // Channel 1: Alliance Organization "v" (Main Channel)
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2ECF7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.forum,
                color: Color(0xFF2D2535),
                size: 20,
              ),
            ),
            title: const Text(
              'Alliance Organization "v"',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Main chat channel',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2535),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            selected: true,
            selectedTileColor: const Color(0xFFF2ECF7).withOpacity(0.3),
            onTap: () {
              Navigator.pop(context);
              // Already in main channel, just close drawer
            },
          ),
          // Channel 2: Call/Video Call
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2ECF7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.video_call,
                color: Color(0xFF2D2535),
                size: 20,
              ),
            ),
            title: const Text(
              'Call & Video',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Voice and video calls',
              style: TextStyle(color: Color(0xFF7F7F88), fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Soon',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Call & Video feature coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF2D2535),
            ),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF7F7F88)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF2D2535)),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF7F7F88)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF2D2535)),
            title: const Text('About App'),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF7F7F88)),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationName: 'Alliance Message App',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                ),
                children: const [
                  Text('Messaging app for Alliance Organization'),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Confirm Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed != true) {
                return;
              }

              if (navigator.canPop()) {
                navigator.pop();
              }

              showDialog(
                context: navigator.context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                await SupabaseAuthService().signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('userLoggedIn', false);
                debugPrint('Signed out successfully');

                navigator.pop();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              } catch (e) {
                debugPrint('Sign out error: $e');
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Loi dang xuat: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

enum _AttachmentType { image, gif, file, voice }

// Use SupabaseAuth to get current user ID
String get _currentUserId {
  final authService = SupabaseAuthService();
  final user = authService.currentUser;
  debugPrint('Current user: ${user?.email} (id: ${user?.id})');
  return authService.currentUserId ?? 'anonymous';
}

class _ChatSection extends StatefulWidget {
  const _ChatSection({required this.searchQuery});

  final String searchQuery;

  @override
  State<_ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<_ChatSection> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _authService = SupabaseAuthService();
  final _messageService = SupabaseMessageService();
  final _storageService = UnifiedStorageService();
  AudioRecorder? _audioRecorder; // Nullable for platform compatibility

  final String _conversationId = 'common-channel';

  Color _accentColor = const Color(0xFF1877F2);
  bool _isSending = false;
  bool _isTyping = false;
  _ChatMessage? _replyingTo;
  bool _isRecording = false;
  int _recordDuration = 0;
  bool _isVoiceSupported = false; // Check if platform supports voice recording

  @override
  void initState() {
    super.initState();

    // Debug: Check current user
    final currentUser = _authService.currentUser;
    debugPrint(
      '🧑‍💻 Current user in HomeScreen: ${currentUser?.email} (id: ${currentUser?.id})',
    );

    if (currentUser == null) {
      debugPrint('⚠️ WARNING: No user logged in! Message stream may not work.');
    }

    // Initialize audio recorder only on supported platforms
    _isVoiceSupported = Platform.isAndroid || Platform.isIOS;
    if (_isVoiceSupported) {
      _audioRecorder = AudioRecorder();
    }

    // Listen to text changes to update typing status
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder?.dispose();
    // Clear typing status on dispose
    _updateTypingStatus(false);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      _isTyping = hasText;
      _updateTypingStatus(hasText);
    }
  }

  void _updateTypingStatus(bool isTyping) {
    _messageService
        .updateTypingStatus(conversationId: _conversationId, isTyping: isTyping)
        .catchError((error) {
          // Silently fail
          debugPrint('Typing status error: $error');
        });
  }

  void _markMessagesAsSeen(List<_ChatMessage> messages) {
    // Mark unread messages from others as seen
    for (final message in messages) {
      // Only mark others' messages that haven't been seen
      if (!message.isMe && !message.isSeen && message.id != null) {
        _messageService.markAsRead(message.id!).catchError((error) {
          debugPrint('❌ Mark as read error: $error');
        });
      }
    }
  }

  Future<void> _handleSend() async {
    if (_isSending) {
      return;
    }

    final text = _textController.text.trim();
    // If text is empty, send thumbs up as a quick reaction
    final messageToSend = text.isEmpty ? '[REACTION:THUMBS_UP]' : text;

    _textController.clear();
    _updateTypingStatus(false); // Clear typing status when sending
    FocusScope.of(context).unfocus();
    await _sendMessage(text: messageToSend);
  }

  Future<void> _handlePickFile() async {
    if (_isSending) return;
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showSnack('Không thể lấy dữ liệu tệp.');
        return;
      }

      await _sendMessage(
        attachmentType: _AttachmentType.file,
        attachmentBytes: bytes,
        fileName: file.name,
      );
    } catch (error) {
      _showSnack('Không thể chọn tệp: ');
    }
  }

  Future<void> _handlePickImage() async {
    if (_isSending) return;
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }

      // Compress image before sending
      Uint8List? compressedBytes;
      try {
        final result = await FlutterImageCompress.compressWithFile(
          image.path,
          quality: 70, // 70% quality
          minWidth: 1920, // Max width 1920px
          minHeight: 1080, // Max height 1080px
        );
        compressedBytes = result;
      } catch (e) {
        // If compression fails, use original
        compressedBytes = await image.readAsBytes();
      }

      if (!mounted || compressedBytes == null) {
        return;
      }

      await _sendMessage(
        attachmentType: _AttachmentType.image,
        attachmentBytes: compressedBytes,
        fileName: image.name,
      );
    } catch (error) {
      _showSnack('Không thể chọn ảnh: ');
    }
  }

  Future<void> _handlePickGif() async {
    if (_isSending) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['gif'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showSnack('Không thể lấy dữ liệu GIF.');
        return;
      }

      await _sendMessage(
        attachmentType: _AttachmentType.gif,
        attachmentBytes: bytes,
        fileName: file.name,
      );
    } catch (error) {
      _showSnack('Không thể chọn GIF: ');
    }
  }

  Future<void> _handleChangeAccent() async {
    final selected = await showModalBottomSheet<Color>(
      context: context,
      builder: (context) {
        final isCompact = MediaQuery.of(context).size.width < 480;
        const swatches = <Color>[
          Color(0xFF1877F2),
          Color(0xFFFF7A45),
          Color(0xFF2ABF88),
          Color(0xFF9A6BFF),
          Color(0xFFF5A623),
        ];
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16.0 : 24.0,
            vertical: isCompact ? 16.0 : 20.0,
          ),
          child: Wrap(
            spacing: isCompact ? 12.0 : 16.0,
            runSpacing: isCompact ? 12.0 : 16.0,
            children: swatches
                .map(
                  (color) => GestureDetector(
                    onTap: () => Navigator.of(context).pop(color),
                    child: Container(
                      width: isCompact ? 40.0 : 44.0,
                      height: isCompact ? 40.0 : 44.0,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _accentColor = selected;
      });
    }
  }

  Future<void> _handleStartRecording() async {
    if (_audioRecorder == null) return; // Exit if voice not supported

    try {
      if (await _audioRecorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder!.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        // Update duration every second
        while (_isRecording) {
          await Future.delayed(const Duration(seconds: 1));
          if (_isRecording && mounted) {
            setState(() {
              _recordDuration++;
            });
          }
        }
      } else {
        _showSnack('Không có quyền truy cập micro để ghi âm');
      }
    } catch (e) {
      _showSnack('Không thể ghi âm: $e');
    }
  }

  Future<void> _handleStopRecording() async {
    if (_audioRecorder == null) return; // Exit if voice not supported

    try {
      final path = await _audioRecorder!.stop();

      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });

      if (path != null) {
        final file = File(path);
        final bytes = await file.readAsBytes();
        await _sendMessage(
          attachmentType: _AttachmentType.voice,
          attachmentBytes: bytes,
          fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        // Delete temp file
        try {
          await file.delete();
        } catch (_) {}
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
      _showSnack('Không thể dừng ghi âm: $e');
    }
  }

  Future<void> _handleCancelRecording() async {
    if (_audioRecorder == null) return; // Exit if voice not supported

    try {
      await _audioRecorder!.stop();
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    } catch (e) {
      _showSnack('Không thể dừng ghi âm: $e');
    }
  }

  Future<void> _sendMessage({
    String? text,
    _AttachmentType? attachmentType,
    Uint8List? attachmentBytes,
    String? fileName,
  }) async {
    final trimmed = text?.trim();
    final hasText = trimmed != null && trimmed.isNotEmpty;
    final bytes = attachmentBytes;
    final type = attachmentType;
    final hasAttachment = bytes != null && type != null;

    if (!hasText && !hasAttachment) {
      return;
    }
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // If has attachment, upload first then send attachment message
      if (bytes != null && type != null) {
        final attachmentUrl = await _uploadAttachment(
          bytes: bytes,
          type: type,
          fileName: fileName,
        );

        await _messageService.sendAttachment(
          conversationId: _conversationId,
          attachmentUrl: attachmentUrl,
          attachmentType: type.name,
          attachmentName: fileName,
          text: hasText ? trimmed : null,
        );
      }
      // If only text, send text message
      else if (hasText) {
        await _messageService.sendMessage(
          conversationId: _conversationId,
          text: trimmed,
          replyToId: _replyingTo?.id,
        );
      }

      debugPrint('✅ Message sent successfully via Supabase!');

      // Clear reply state after sending
      if (_replyingTo != null && mounted) {
        setState(() {
          _replyingTo = null;
        });
      }

      // Manually fetch messages after sending (workaround for Windows)
      await _fetchMessagesManually();
    } catch (error) {
      debugPrint('❌ Failed to send message: $error');
      _showSnack('Gửi tin nhắn thất bại: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
      _scrollToBottom();
    }
  }

  Future<String> _uploadAttachment({
    required Uint8List bytes,
    required _AttachmentType type,
    String? fileName,
  }) async {
    final extension = _extensionFromFileName(fileName);
    final effectiveExtension = extension.isNotEmpty
        ? extension
        : _defaultExtensionFor(type);

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Sanitize filename: remove Vietnamese diacritics and special chars
    final baseName = fileName != null
        ? _sanitizeFileName(fileName.replaceAll('.$effectiveExtension', ''))
        : 'attachment_$timestamp';

    final finalFileName = '${baseName}_$timestamp.$effectiveExtension';

    // Upload to Supabase Storage
    if (type == _AttachmentType.image || type == _AttachmentType.gif) {
      return await _storageService.uploadImage(
        userId: _currentUserId,
        fileName: finalFileName,
        bytes: bytes,
      );
    } else {
      return await _storageService.uploadFile(
        userId: _currentUserId,
        fileName: finalFileName,
        bytes: bytes,
      );
    }
  }

  void _handleDeleteMessage(_ChatMessage message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tin nhắn'),
        content: const Text('Bạn có chắc chắn muốn xóa tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (message.id != null) {
                try {
                  await _messageService.deleteMessage(message.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa tin nhắn')),
                    );
                  }
                } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Không thể xóa: $error')),
                    );
                  }
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleForwardMessage(_ChatMessage message) async {
    try {
      if (message.attachmentUrl != null && message.attachmentType != null) {
        await _messageService.sendAttachment(
          conversationId: _conversationId,
          attachmentUrl: message.attachmentUrl!,
          attachmentType: message.attachmentType!.name,
          attachmentName: message.fileName,
          text: message.text,
        );
      } else {
        await _messageService.sendMessage(
          conversationId: _conversationId,
          text: message.text ?? '',
          isForwarded: true,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang chuyển tiếp tin nhắn')),
        );
      }
    } catch (error) {
      debugPrint('❌ Forward error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chuyển tiếp tin nhắn: $error')),
        );
      }
    }
  }

  void _toggleReaction(_ChatMessage message, String emoji) async {
    if (message.id == null) return;

    try {
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) return;

      final hasReacted = message.reactions[emoji] == currentUserId;

      if (hasReacted) {
        // Remove reaction
        await _messageService.removeReaction(
          messageId: message.id!,
          emoji: emoji,
        );
        debugPrint('✅ Removed reaction $emoji from message ${message.id}');
      } else {
        // Add reaction
        await _messageService.addReaction(messageId: message.id!, emoji: emoji);
        debugPrint('✅ Added reaction $emoji to message ${message.id}');
      }
    } catch (error) {
      debugPrint('❌ Reaction error: $error');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi reactions: $error')));
      }
    }
  }

  Future<void> _handleOpenAttachment(_ChatMessage message) async {
    if (message.attachmentUrl == null) return;

    try {
      // Determine attachment type
      final isImage =
          message.attachmentType == _AttachmentType.image ||
          message.attachmentType == _AttachmentType.gif;

      if (isImage) {
        // Open fullscreen image viewer
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullscreenImageViewer(
              imageUrl: message.attachmentUrl!,
              fileName: message.fileName,
            ),
          ),
        );
        debugPrint('✅ Opened image viewer: ${message.attachmentUrl}');
      } else if (message.attachmentType == _AttachmentType.file) {
        // Show file preview dialog
        await showDialog(
          context: context,
          builder: (context) => FilePreviewDialog(
            fileUrl: message.attachmentUrl!,
            fileName: message.fileName ?? 'File',
            fileType: message.attachmentType?.name ?? 'file',
          ),
        );
        debugPrint('✅ Opened file preview: ${message.attachmentUrl}');
      } else {
        // For voice messages or unknown types, open externally
        final uri = Uri.parse(message.attachmentUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint(
            '✅ Opened attachment externally: ${message.attachmentUrl}',
          );
        } else {
          throw 'Không thể mở file này';
        }
      }
    } catch (error) {
      debugPrint('❌ Open attachment error: $error');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể mở file: $error')));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchMessagesManually() async {
    // NOTE: Supabase real-time stream works better than Firebase on Windows
    // So we don't need manual fetch workaround anymore
    // Just trigger a state update to refresh the UI
    if (mounted) {
      setState(() {
        debugPrint('✅ Supabase stream will update messages automatically');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messageService.getMessagesStream(
              conversationId: _conversationId,
            ),
            builder: (context, snapshot) {
              // Debug logs
              debugPrint(
                'Supabase Stream connection state: ${snapshot.connectionState}',
              );
              debugPrint('Has error: ${snapshot.hasError}');
              debugPrint('Has data: ${snapshot.hasData}');
              debugPrint('Messages count: ${snapshot.data?.length ?? 0}');

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading messages:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                );
              }

              // Show loading spinner while waiting for initial data
              final bool showLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;

              if (showLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // Get messages from Supabase stream
              final messagesData = snapshot.data ?? [];
              var messages = messagesData
                  .map(
                    (data) => _ChatMessage.fromSupabaseData(
                      data,
                      currentUserId: _currentUserId,
                    ),
                  )
                  .toList();

              // Filter messages based on search query
              if (widget.searchQuery.isNotEmpty) {
                final query = widget.searchQuery.toLowerCase();
                messages = messages.where((message) {
                  final text = message.text?.toLowerCase() ?? '';
                  final fileName = message.fileName?.toLowerCase() ?? '';
                  return text.contains(query) || fileName.contains(query);
                }).toList();
              }

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.searchQuery.isEmpty
                            ? Icons.chat_bubble_outline
                            : Icons.search_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.searchQuery.isEmpty
                            ? 'No messages yet.\nStart a conversation!'
                            : 'No messages found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (widget.searchQuery.isEmpty) {
                  _scrollToBottom();
                  _markMessagesAsSeen(messages);
                }
              });

              return _MessagesList(
                controller: _scrollController,
                messages: messages,
                onReply: (message) {
                  setState(() {
                    _replyingTo = message;
                  });
                },
                onDelete: (message) => _handleDeleteMessage(message),
                onForward: (message) => _handleForwardMessage(message),
                onReaction: (message, emoji) => _toggleReaction(message, emoji),
                currentUserId: _authService.currentUser?.id ?? 'anonymous',
                searchQuery: widget.searchQuery,
                onOpenAttachment: _handleOpenAttachment,
              );
            },
          ),
        ),
        // Typing indicator (Supabase)
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _messageService.getTypingUsersStream(
            conversationId: _conversationId,
          ),
          builder: (context, snapshot) {
            final typingUsers = snapshot.data ?? [];

            // Filter out current user
            final othersTyping = typingUsers
                .where((user) => user['user_id'] != _currentUserId)
                .toList();

            if (othersTyping.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Đang nhập...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[600]!,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Reply preview banner
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2ECF7),
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 40,
                  color: const Color(0xFF1877F2),
                  margin: const EdgeInsets.only(right: 12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang trả lời ${_replyingTo!.isMe ? "chính mình" : "người khác"}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF1877F2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _replyingTo!.text ?? 'Attachment',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7F7F88),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _replyingTo = null;
                    });
                  },
                ),
              ],
            ),
          ),
        _MessageInputBar(
          controller: _textController,
          onSend: _handleSend,
          onAddFile: _handlePickFile,
          onPickImage: _handlePickImage,
          onPickGif: _handlePickGif,
          onChangeTheme: _handleChangeAccent,
          onStartRecording: _handleStartRecording,
          onStopRecording: _handleStopRecording,
          onCancelRecording: _handleCancelRecording,
          accentColor: _accentColor,
          isSending: _isSending,
          isRecording: _isRecording,
          recordDuration: _recordDuration,
          isVoiceSupported: _isVoiceSupported,
        ),
      ],
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.controller,
    required this.messages,
    required this.onReply,
    required this.onDelete,
    required this.onForward,
    required this.onReaction,
    required this.currentUserId,
    required this.onOpenAttachment,
    this.searchQuery = '',
  });

  final ScrollController controller;
  final List<_ChatMessage> messages;
  final void Function(_ChatMessage) onReply;
  final void Function(_ChatMessage) onDelete;
  final void Function(_ChatMessage) onForward;
  final void Function(_ChatMessage, String emoji) onReaction;
  final String currentUserId;
  final String searchQuery;
  final void Function(_ChatMessage message) onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 480;
    final horizontalPadding = isCompact ? 12.0 : 24.0;
    final verticalPadding = isCompact ? 8.0 : 12.0;
    final itemSpacing = isCompact ? 8.0 : 12.0;

    if (messages.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy tin nhắn',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: controller,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      itemCount: messages.length,
      separatorBuilder: (context, _) => SizedBox(height: itemSpacing),
      itemBuilder: (context, index) {
        final message = messages[index];
        return _ChatBubble(
          message: message,
          onReply: () => onReply(message),
          onDelete: () => onDelete(message),
          onForward: () => onForward(message),
          onReaction: (emoji) => onReaction(message, emoji),
          currentUserId: currentUserId,
          searchQuery: searchQuery,
          onOpenAttachment: onOpenAttachment,
        );
      },
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.onSend,
    required this.onAddFile,
    required this.onPickImage,
    required this.onPickGif,
    required this.onChangeTheme,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.accentColor,
    required this.isSending,
    required this.isRecording,
    required this.recordDuration,
    this.isVoiceSupported = true,
  });

  final TextEditingController controller;
  final Future<void> Function() onSend;
  final Future<void> Function() onAddFile;
  final Future<void> Function() onPickImage;
  final Future<void> Function() onPickGif;
  final Future<void> Function() onChangeTheme;
  final Future<void> Function() onStartRecording;
  final Future<void> Function() onStopRecording;
  final Future<void> Function() onCancelRecording;
  final Color accentColor;
  final bool isSending;
  final bool isRecording;
  final int recordDuration;
  final bool isVoiceSupported;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 480;
    final horizontalMargin = isCompact ? 12.0 : 20.0;
    final bottomMargin = isCompact ? 12.0 : 24.0;
    final containerPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 6.0 : 8.0,
      vertical: isCompact ? 8.0 : 10.0,
    );
    final gap = isCompact ? 6.0 : 8.0;
    final fieldHeight = isCompact ? 38.0 : 44.0;
    final fieldPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 12.0 : 16.0,
    );
    final textSize = isCompact ? 14.0 : 16.0;

    return Container(
      margin: EdgeInsets.fromLTRB(
        horizontalMargin,
        4,
        horizontalMargin,
        bottomMargin,
      ),
      padding: containerPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: isRecording
          ? Row(
              children: [
                // Cancel button
                _ActionIconButton(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: onCancelRecording,
                ),
                SizedBox(width: gap),
                // Recording indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: gap),
                // Duration
                Text(
                  _formatDuration(recordDuration),
                  style: TextStyle(
                    color: const Color(0xFF2D2535),
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Waveform animation placeholder
                Text(
                  '.....',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: textSize * 0.8,
                  ),
                ),
                SizedBox(width: gap),
                // Stop button
                _ActionIconButton(
                  icon: Icons.send,
                  color: accentColor,
                  onTap: onStopRecording,
                ),
              ],
            )
          : Row(
              children: [
                _ActionIconButton(
                  icon: Icons.add,
                  color: accentColor,
                  onTap: isSending ? null : onAddFile,
                ),
                _ActionIconButton(
                  icon: Icons.image_outlined,
                  color: accentColor,
                  onTap: isSending ? null : onPickImage,
                ),
                _ActionIconButton(
                  icon: Icons.palette_outlined,
                  color: accentColor,
                  onTap: isSending ? null : onChangeTheme,
                ),
                _ActionIconButton.text(
                  label: 'GIF',
                  color: accentColor,
                  onTap: isSending ? null : onPickGif,
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Container(
                    height: fieldHeight,
                    padding: fieldPadding,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(isCompact ? 19 : 22),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) {
                        if (!isSending) {
                          onSend();
                        }
                      },
                      style: TextStyle(
                        color: const Color(0xFF2D2535),
                        fontSize: textSize,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Aa',
                        hintStyle: TextStyle(
                          color: const Color(0xFF9E9E9E),
                          fontSize: textSize,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      cursorColor: accentColor,
                    ),
                  ),
                ),
                SizedBox(width: gap),
                _ActionIconButton(
                  icon: Icons.emoji_emotions_outlined,
                  color: accentColor,
                  onTap: isSending
                      ? null
                      : () async {
                          // Auto-detect platform: SDK for mobile, API for desktop
                          final bool useSdk = GiphySdkPicker.isSupported;

                          if (useSdk) {
                            // Mobile: Use Giphy SDK (native UI) - Direct call
                            // Keys stored in lib/config/giphy_config.dart (not committed to GitHub)
                            String sdkKey;
                            if (Platform.isAndroid) {
                              sdkKey = GiphyConfig.androidSdkKey;
                            } else if (Platform.isIOS) {
                              sdkKey = GiphyConfig.iosSdkKey;
                            } else {
                              sdkKey =
                                  GiphyConfig.apiKey; // Fallback to API key
                            }

                            // Open Giphy picker directly (no wrapper UI)
                            final gif = await GiphyGet.getGif(
                              context: context,
                              apiKey: sdkKey,
                              lang: GiphyLanguage.english,
                            );

                            // Handle selected GIF
                            if (gif != null &&
                                gif.images?.original?.url != null) {
                              controller.text =
                                  '[GIF:${gif.images!.original!.url}]';
                              onSend();
                            }
                          } else {
                            // Desktop/Web: Use API picker (current implementation)
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => DiscordStylePicker(
                                onEmojiSelected: (emoji) {
                                  // Insert emoji at cursor position
                                  final text = controller.text;
                                  final selection = controller.selection;
                                  final newText = text.replaceRange(
                                    selection.start,
                                    selection.end,
                                    emoji,
                                  );
                                  controller.value = controller.value.copyWith(
                                    text: newText,
                                    selection: TextSelection.collapsed(
                                      offset: selection.start + emoji.length,
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                                onGifSelected: (gifUrl) {
                                  // Send GIF as special message
                                  controller.text = '[GIF:$gifUrl]';
                                  Navigator.pop(context);
                                  onSend();
                                },
                                onStickerSelected: (sticker) {
                                  // Send sticker
                                  controller.text = sticker;
                                  Navigator.pop(context);
                                  onSend();
                                },
                              ),
                            );
                          }
                        },
                ),
                // Mic button or Send button (mic only on supported platforms)
                controller.text.trim().isEmpty
                    ? (isVoiceSupported
                          ? _ActionIconButton(
                              icon: Icons.mic,
                              color: accentColor,
                              onTap: isSending ? null : onStartRecording,
                            )
                          : _SendButton(
                              color: accentColor,
                              onSend: onSend,
                              isSending: isSending,
                            ))
                    : _SendButton(
                        color: accentColor,
                        onSend: onSend,
                        isSending: isSending,
                      ),
              ],
            ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.color,
    required this.onSend,
    required this.isSending,
  });

  final Color color;
  final Future<void> Function() onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 480;
    final sidePadding = isCompact ? 2.0 : 4.0;
    final buttonWidth = isCompact ? 36.0 : 40.0;
    final buttonHeight = isCompact ? 32.0 : 36.0;
    final borderRadius = BorderRadius.circular(isCompact ? 16 : 18);
    final indicatorSize = isCompact ? 16.0 : 18.0;
    final indicatorStroke = isCompact ? 1.8 : 2.0;
    final iconSize = isCompact ? 18.0 : 20.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      child: InkWell(
        onTap: isSending
            ? null
            : () async {
                // Send thumbs up when clicked
                await onSend();
              },
        borderRadius: borderRadius,
        child: Ink(
          width: buttonWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: borderRadius,
          ),
          child: Center(
            child: isSending
                ? SizedBox(
                    width: indicatorSize,
                    height: indicatorSize,
                    child: CircularProgressIndicator(
                      strokeWidth: indicatorStroke,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(Icons.thumb_up, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  }) : label = null;

  const _ActionIconButton.text({
    required this.label,
    required this.color,
    required this.onTap,
  }) : icon = null;

  final IconData? icon;
  final String? label;
  final Color color;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 480;
    final sidePadding = isCompact ? 2.0 : 4.0;
    final buttonHeight = isCompact ? 32.0 : 36.0;
    final buttonWidth = label != null
        ? (isCompact ? 44.0 : 48.0)
        : (isCompact ? 32.0 : 36.0);
    final borderRadius = BorderRadius.circular(isCompact ? 16 : 18);
    final iconSize = isCompact ? 18.0 : 20.0;
    final textStyle = TextStyle(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: isCompact ? 12.0 : 14.0,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                onTap!();
              },
        borderRadius: borderRadius,
        child: Ink(
          width: buttonWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: borderRadius,
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: color, size: iconSize)
                : Text(label!, style: textStyle),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  const _ChatBubble({
    required this.message,
    required this.onReply,
    required this.onDelete,
    required this.onForward,
    required this.onReaction,
    required this.onOpenAttachment,
    required this.currentUserId,
    this.searchQuery = '',
  });

  final _ChatMessage message;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onForward;
  final Function(String emoji) onReaction;
  final Function(_ChatMessage message) onOpenAttachment;
  final String currentUserId;
  final String searchQuery;

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = message.isMe;
    final searchQuery = widget.searchQuery;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor = isMe
        ? const Color(0xFFF6E8C9)
        : const Color(0xFFF1F0F6);
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 6),
      bottomRight: Radius.circular(isMe ? 6 : 18),
    );
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 480;
    final bubbleMaxWidth = isCompact ? width * 0.78 : 320.0;
    final bubblePadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 12.0 : 16.0,
      vertical: isCompact ? 10.0 : 12.0,
    );
    final attachmentHeight = isCompact ? 140.0 : 160.0;
    final textSpacing = isCompact ? 6.0 : 8.0;

    final content = <Widget>[];

    // Show reply preview if this message is replying to another
    if (message.replyToText != null) {
      content.add(
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: const Color(0xFF1877F2), width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.replyToSender ?? 'Someone',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF1877F2),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message.replyToText!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 11.0 : 12.0,
                  color: const Color(0xFF7F7F88),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (message.hasVisualAttachment) {
      content.add(
        GestureDetector(
          onTap: () => widget.onOpenAttachment(message),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: message.attachmentUrl!,
              fit: BoxFit.cover,
              placeholder: (context, _) => Container(
                height: attachmentHeight,
                color: Colors.black.withValues(alpha: 0.05),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, error, _) => Container(
                height: attachmentHeight,
                color: Colors.black.withValues(alpha: 0.05),
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      );
    } else if (message.attachmentType == _AttachmentType.voice) {
      content.add(
        _VoiceMessagePlayer(
          audioUrl: message.attachmentUrl!,
          isMe: message.isMe,
          accentColor: isMe ? const Color(0xFF1877F2) : const Color(0xFF7F7F88),
        ),
      );
    } else if (message.attachmentType == _AttachmentType.file) {
      content.add(
        GestureDetector(
          onTap: () => widget.onOpenAttachment(message),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 20,
                color: Color(0xFF2D2535),
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Flexible(
                child: Text(
                  message.fileName ?? message.text ?? 'Tên tệp không xác định',
                  style: TextStyle(
                    color: const Color(0xFF2D2535),
                    fontSize: isCompact ? 13.0 : 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Icon(Icons.download, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      );
    }

    // Show forwarded badge
    if (message.isForwarded) {
      if (content.isNotEmpty) {
        content.add(SizedBox(height: textSpacing));
      }
      content.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forward, size: 14, color: const Color(0xFF7F7F88)),
            const SizedBox(width: 4),
            Text(
              'Đang chuyển tin nhắn',
              style: TextStyle(
                color: const Color(0xFF7F7F88),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (message.text != null && message.text!.isNotEmpty) {
      if (content.isNotEmpty) {
        content.add(SizedBox(height: textSpacing));
      }

      // Check if it's a GIF
      if (message.text!.startsWith('[GIF:')) {
        final gifUrl = message.text!.substring(5, message.text!.length - 1);
        content.add(
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: gifUrl,
              width: isCompact ? 180 : 220,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: isCompact ? 180 : 220,
                height: 150,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: isCompact ? 180 : 220,
                height: 150,
                color: Colors.grey[200],
                child: const Icon(Icons.error),
              ),
            ),
          ),
        );
      }
      // Check if it's a custom emoji
      else if (message.text!.startsWith('[CUSTOM_EMOJI:')) {
        final base64Data = message.text!.substring(
          14,
          message.text!.length - 1,
        );
        try {
          final bytes = base64Decode(base64Data);
          content.add(
            Image.memory(
              bytes,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.emoji_emotions, size: 32),
            ),
          );
        } catch (e) {
          content.add(const Icon(Icons.emoji_emotions, size: 32));
        }
      }
      // Check if it's a custom sticker
      else if (message.text!.startsWith('[CUSTOM_STICKER:')) {
        final base64Data = message.text!.substring(
          16,
          message.text!.length - 1,
        );
        try {
          final bytes = base64Decode(base64Data);
          content.add(
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                width: isCompact ? 100 : 120,
                height: isCompact ? 100 : 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: isCompact ? 100 : 120,
                  height: isCompact ? 100 : 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sticky_note_2),
                ),
              ),
            ),
          );
        } catch (e) {
          content.add(
            Container(
              width: isCompact ? 100 : 120,
              height: isCompact ? 100 : 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sticky_note_2),
            ),
          );
        }
      }
      // Check if it's a quick reaction
      else if (message.text!.startsWith('[REACTION:')) {
        final reactionType = message.text!
            .replaceAll('[REACTION:', '')
            .replaceAll(']', '');

        // Display large icon for reaction
        IconData reactionIcon;
        Color reactionColor;

        switch (reactionType) {
          case 'THUMBS_UP':
            reactionIcon = Icons.thumb_up;
            reactionColor = const Color(0xFF2196F3);
            break;
          case 'HEART':
            reactionIcon = Icons.favorite;
            reactionColor = Colors.red;
            break;
          case 'LAUGH':
            reactionIcon = Icons.mood;
            reactionColor = Colors.orange;
            break;
          default:
            reactionIcon = Icons.thumb_up;
            reactionColor = const Color(0xFF2196F3);
        }

        content.add(
          Icon(
            reactionIcon,
            size: isCompact ? 48.0 : 64.0,
            color: reactionColor,
          ),
        );
      }
      // Highlight search query in text
      else if (searchQuery.isNotEmpty &&
          message.text!.toLowerCase().contains(searchQuery.toLowerCase())) {
        content.add(
          _HighlightedText(
            text: message.text!,
            query: searchQuery,
            textStyle: TextStyle(
              color: const Color(0xFF2D2535),
              fontSize: isCompact ? 13.0 : 14.0,
              height: 1.4,
            ),
            highlightColor: const Color(0xFFFFEB3B),
          ),
        );
      } else {
        content.add(
          Text(
            message.text!,
            style: TextStyle(
              color: const Color(0xFF2D2535),
              fontSize: isCompact ? 13.0 : 14.0,
              height: 1.4,
            ),
          ),
        );
      }
    }

    // Add timestamp display with seen status
    if (message.timestamp != null || (message.isMe && message.isSeen)) {
      if (content.isNotEmpty) {
        content.add(SizedBox(height: 4));
      }
      content.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.timestamp != null)
              Text(
                _formatTimestamp(message.timestamp!),
                style: TextStyle(
                  color: const Color(0xFF7F7F88),
                  fontSize: isCompact ? 10.0 : 11.0,
                ),
              ),
            if (message.isMe && message.isSeen) ...[
              const SizedBox(width: 4),
              Icon(Icons.done_all, size: 14, color: Colors.blue[600]),
            ],
          ],
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (left side for others, right side for me)
          if (!isMe) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE4E6EB),
                backgroundImage:
                    message.senderAvatar != null &&
                        message.senderAvatar!.isNotEmpty
                    ? CachedNetworkImageProvider(message.senderAvatar!)
                    : null,
                child:
                    message.senderAvatar == null ||
                        message.senderAvatar!.isEmpty
                    ? Text(
                        (message.senderName?.isNotEmpty == true
                                ? message.senderName!.substring(0, 1)
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF65676B),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Chat bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          _showMessageActions(context, message);
                        },
                        child: Container(
                          constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                          padding: bubblePadding,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: borderRadius,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: content,
                          ),
                        ),
                      ),
                      // Hover actions
                      if (_isHovered)
                        Positioned(
                          top: -8,
                          right: isMe ? 8 : null,
                          left: isMe ? null : 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _HoverActionButton(
                                  icon: Icons.reply,
                                  tooltip: 'Reply',
                                  onPressed: widget.onReply,
                                ),
                                _HoverActionButton(
                                  icon: Icons.forward,
                                  tooltip: 'Forward',
                                  onPressed: widget.onForward,
                                ),
                                _HoverActionButton(
                                  icon: Icons.emoji_emotions_outlined,
                                  tooltip: 'React',
                                  onPressed: () =>
                                      _showMessageActions(context, message),
                                ),
                                if (message.isMe)
                                  _HoverActionButton(
                                    icon: Icons.delete_outline,
                                    tooltip: 'Delete',
                                    onPressed: widget.onDelete,
                                    color: Colors.red,
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Reaction display
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                    child: _ReactionDisplay(
                      reactions: message.reactions,
                      onTap: () => _showMessageActions(context, message),
                    ),
                  ),
              ],
            ),
          ),
          // Avatar for my messages (right side)
          if (isMe) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE4E6EB),
                backgroundImage:
                    message.senderAvatar != null &&
                        message.senderAvatar!.isNotEmpty
                    ? CachedNetworkImageProvider(message.senderAvatar!)
                    : null,
                child:
                    message.senderAvatar == null ||
                        message.senderAvatar!.isEmpty
                    ? Text(
                        (message.senderName?.isNotEmpty == true
                                ? message.senderName!.substring(0, 1)
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF65676B),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMessageActions(BuildContext context, _ChatMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reactions row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['❤️', '😂', '👍', '👎', '😮', '😢'].map((emoji) {
                  final hasReacted =
                      message.reactions[emoji] == widget.currentUserId;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onReaction(emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasReacted
                            ? const Color(0xFFF6E8C9)
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: hasReacted
                            ? Border.all(
                                color: const Color(0xFF1877F2),
                                width: 2,
                              )
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            if (message.text != null && message.text!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () async {
                  Navigator.pop(context);
                  // Copy to clipboard
                  await Clipboard.setData(ClipboardData(text: message.text!));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message copied to clipboard'),
                      ),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                widget.onReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                widget.onForward();
              },
            ),
            if (message.isMe)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
              ),
          ],
        ),
      ),
    );
  }
}

// Reaction display widget
class _ReactionDisplay extends StatelessWidget {
  const _ReactionDisplay({required this.reactions, required this.onTap});

  final Map<String, String> reactions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Count each emoji
    final emojiCounts = <String, int>{};
    for (final emoji in reactions.keys) {
      emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: emojiCounts.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 16)),
                  if (entry.value > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F7F88),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Highlighted text widget for search results
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.textStyle,
    required this.highlightColor,
  });

  final String text;
  final String query;
  final TextStyle textStyle;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: textStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        // No more matches, add the rest
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            backgroundColor: highlightColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(style: textStyle, children: spans),
    );
  }
}

// Voice message player widget
class _VoiceMessagePlayer extends StatefulWidget {
  const _VoiceMessagePlayer({
    required this.audioUrl,
    required this.isMe,
    required this.accentColor,
  });

  final String audioUrl;
  final bool isMe;
  final Color accentColor;

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.accentColor,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Waveform/Progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Simple progress bar
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(1.5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _duration.inMilliseconds > 0
                      ? _position.inMilliseconds / _duration.inMilliseconds
                      : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Duration
              Text(
                _isPlaying || _position.inSeconds > 0
                    ? _formatDuration(_position)
                    : _formatDuration(_duration),
                style: TextStyle(color: const Color(0xFF7F7F88), fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    this.id,
    this.text,
    required this.isMe,
    this.attachmentType,
    this.attachmentUrl,
    this.fileName,
    this.timestamp,
    this.isSeen = false,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.reactions = const {},
    this.isForwarded = false,
    this.senderName,
    this.senderAvatar,
  });

  final String? id;
  final String? text;
  final bool isMe;
  final _AttachmentType? attachmentType;
  final String? attachmentUrl;
  final String? fileName;
  final DateTime? timestamp;
  final bool isSeen;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final Map<String, String> reactions; // emoji -> userId mapping
  final bool isForwarded;
  final String? senderName;
  final String? senderAvatar;

  bool get hasVisualAttachment =>
      attachmentUrl != null &&
      (attachmentType == _AttachmentType.image ||
          attachmentType == _AttachmentType.gif);

  /// Create from Supabase data (messages_enriched view)
  static _ChatMessage fromSupabaseData(
    Map<String, dynamic> data, {
    required String currentUserId,
  }) {
    // Parse attachment type
    final typeName = data['attachment_type'] as String?;
    _AttachmentType? type;
    if (typeName != null) {
      for (final candidate in _AttachmentType.values) {
        if (candidate.name == typeName) {
          type = candidate;
          break;
        }
      }
    }

    // Parse timestamp and convert to local time
    DateTime? timestamp;
    final createdAt = data['created_at'];
    if (createdAt != null) {
      // Supabase returns UTC time, convert to local
      timestamp = DateTime.parse(createdAt as String).toLocal();
    }

    // Parse seen status (from message_seen table join)
    final seenCount = data['seen_count'] as int? ?? 0;
    final isSeen = seenCount > 0;

    // Parse reactions (from message_reactions table join)
    final reactionsData = data['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = <String, String>{};
    reactionsData.forEach((emoji, userId) {
      reactions[emoji] = userId.toString();
    });

    final senderName = data['sender_name'] as String?;
    final senderAvatar = data['sender_photo'] as String?;

    // Debug log
    debugPrint('📦 Message from: $senderName, avatar: $senderAvatar');

    return _ChatMessage(
      id: data['id'] as String?,
      text: (data['text'] as String?)?.trim(),
      isMe: data['user_id'] == currentUserId,
      attachmentType: type,
      attachmentUrl: data['attachment_url'] as String?,
      fileName: data['attachment_name'] as String?,
      timestamp: timestamp,
      isSeen: isSeen,
      replyToId: data['reply_to_id'] as String?,
      replyToText: data['reply_to_text'] as String?,
      replyToSender: data['reply_to_sender'] as String?,
      reactions: reactions,
      isForwarded: data['is_forwarded'] as bool? ?? false,
      senderName: senderName ?? 'Unknown',
      senderAvatar: senderAvatar,
    );
  }
}

String _extensionFromFileName(String? fileName) {
  if (fileName == null) {
    return '';
  }
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == fileName.length - 1) {
    return '';
  }
  return fileName.substring(dotIndex + 1);
}

/// Sanitize filename: remove Vietnamese diacritics and special characters
/// Keep only: a-z, A-Z, 0-9, dash, underscore
String _sanitizeFileName(String fileName) {
  // Remove Vietnamese diacritics
  const vietnameseMap = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'đ': 'd',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    // Uppercase
    'À': 'A', 'Á': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
    'Ă': 'A', 'Ằ': 'A', 'Ắ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
    'Â': 'A', 'Ầ': 'A', 'Ấ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A',
    'Đ': 'D',
    'È': 'E', 'É': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
    'Ê': 'E', 'Ề': 'E', 'Ế': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',
    'Ì': 'I', 'Í': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
    'Ò': 'O', 'Ó': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
    'Ô': 'O', 'Ồ': 'O', 'Ố': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O',
    'Ơ': 'O', 'Ờ': 'O', 'Ớ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',
    'Ù': 'U', 'Ú': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
    'Ư': 'U', 'Ừ': 'U', 'Ứ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',
    'Ỳ': 'Y', 'Ý': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
  };

  var result = fileName;
  vietnameseMap.forEach((key, value) {
    result = result.replaceAll(key, value);
  });

  // Replace spaces with underscores and remove special characters
  result = result
      .replaceAll(' ', '_')
      .replaceAll(
        RegExp(r'[^\w\-.]'),
        '',
      ); // Keep only alphanumeric, dash, underscore, dot

  // Remove multiple underscores/dashes
  result = result.replaceAll(RegExp(r'[_\-]{2,}'), '_');

  // Limit length to 100 characters
  if (result.length > 100) {
    result = result.substring(0, 100);
  }

  return result.isEmpty ? 'file' : result;
}

String _defaultExtensionFor(_AttachmentType type) {
  switch (type) {
    case _AttachmentType.image:
      return 'jpg';
    case _AttachmentType.gif:
      return 'gif';
    case _AttachmentType.file:
      return 'bin';
    case _AttachmentType.voice:
      return 'm4a';
  }
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  // Normalize dates to midnight for accurate day comparison
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final daysDifference = today.difference(messageDate).inDays;

  // Just now (< 1 minute)
  if (difference.inSeconds < 60) {
    return 'Just now';
  }

  // X minutes ago (< 1 hour)
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }

  // Today - show hours ago or time
  if (daysDifference == 0) {
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Yesterday
  if (daysDifference == 1) {
    return 'Yesterday ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // This week (2-6 days ago) - show day name
  if (daysDifference < 7) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[timestamp.weekday - 1];
    return '$dayName ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // This year - show date without year
  if (timestamp.year == now.year) {
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Old messages - show full date with year
  return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
}

// ============================================================================
// Fullscreen Image Viewer (like Messenger)
// ============================================================================

class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? fileName;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.fileName,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // Reset zoom
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom to 2x at tap position
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx, -position.dy)
        ..scale(2.0);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image with pinch-to-zoom
          GestureDetector(
            onDoubleTapDown: _handleDoubleTapDown,
            onDoubleTap: _handleDoubleTap,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 16,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.fileName ?? 'Image',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () async {
                      try {
                        await launchUrl(
                          Uri.parse(widget.imageUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Không thể tải xuống: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// File Preview Dialog
// ============================================================================

class FilePreviewDialog extends StatelessWidget {
  final String fileUrl;
  final String fileName;
  final String fileType;

  const FilePreviewDialog({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
  });

  IconData _getFileIcon() {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.purple;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Colors.pink;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getFileColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getFileIcon(), size: 48, color: _getFileColor()),
            ),
            const SizedBox(height: 16),

            // File name
            Text(
              fileName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // File type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                fileName.split('.').last.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Đóng'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await launchUrl(
                          Uri.parse(fileUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Không thể mở: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Mở'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getFileColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Hover Action Button (for chat bubble hover menu)
// ============================================================================

class _HoverActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _HoverActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color ?? Colors.grey[700],
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        splashRadius: 16,
      ),
    );
  }
}
