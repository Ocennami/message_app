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
import 'package:message_app/services/supabase_auth_service.dart';
import 'package:message_app/services/supabase_message_service.dart';
import 'package:message_app/services/supabase_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                          Container(
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
                            child: Image.asset(
                              'assets/images/OIP.jpg',
                              fit: BoxFit.cover,
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
    final authService = SupabaseAuthService();
    final user = authService.currentUser;
    final userEmail = user?.email ?? 'Guest';
    final userName = authService.displayName;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFF2ECF7)),
            accountName: Text(
              userName,
              style: const TextStyle(
                color: Color(0xFF2D2535),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              userEmail,
              style: const TextStyle(color: Color(0xFF7F7F88), fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: authService.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        authService.photoUrl!,
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                      ),
                    )
                  : Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Color(0xFF2D2535),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Color(0xFF2D2535)),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF2D2535),
            ),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.dark_mode_outlined,
              color: Color(0xFF2D2535),
            ),
            title: const Text('Dark mode'),
            trailing: Switch(
              value: false,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Function under development')),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF2D2535)),
            title: const Text('Help & Support'),
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
  final _storageService = SupabaseStorageService();
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
    // Mark unread messages from others as seen (TODO: Implement in Supabase)
    // For now, skip this functionality
    // Will implement message_seen table later
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    _textController.clear();
    _updateTypingStatus(false); // Clear typing status when sending
    FocusScope.of(context).unfocus();
    await _sendMessage(text: text);
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
    final finalFileName =
        fileName ?? 'attachment_$timestamp.$effectiveExtension';

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

  void _toggleReaction(_ChatMessage message, String emoji) {
    // TODO: Implement reactions with Supabase message_reactions table
    debugPrint('❌ Reactions not yet implemented for Supabase');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reactions chưa được implement')),
      );
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
                      color: const Color(0xFF2B2B33),
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
                      style: TextStyle(color: Colors.white, fontSize: textSize),
                      decoration: InputDecoration(
                        hintText: 'Aa',
                        hintStyle: TextStyle(
                          color: const Color(0xFF7F7F88),
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
                          // Show emoji picker
                          final emoji = await showDialog<String>(
                            context: context,
                            builder: (context) => const _EmojiPickerDialog(),
                          );
                          if (emoji != null) {
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
        onTap: isSending ? null : onSend,
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

class _EmojiPickerDialog extends StatelessWidget {
  const _EmojiPickerDialog();

  static const _emojis = [
    '😀',
    '😁',
    '😂',
    '🤣',
    '😊',
    '😍',
    '😘',
    '😎',
    '🤔',
    '😢',
    '😭',
    '😡',
    '👍',
    '👎',
    '👏',
    '🙏',
    '🔥',
    '❤️',
    '💯',
    '🎉',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn emoji',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _emojis.length,
                itemBuilder: (context, index) {
                  final emoji = _emojis[index];
                  return InkWell(
                    onTap: () => Navigator.pop(context, emoji),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
          ],
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

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.onReply,
    required this.onDelete,
    required this.onForward,
    required this.onReaction,
    required this.currentUserId,
    this.searchQuery = '',
  });

  final _ChatMessage message;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onForward;
  final Function(String emoji) onReaction;
  final String currentUserId;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
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
        ClipRRect(
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
        Row(
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
          ],
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

      // Highlight search query in text
      if (searchQuery.isNotEmpty &&
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
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
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
                  final hasReacted = message.reactions[emoji] == currentUserId;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onReaction(emoji);
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
                onReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () {
                Navigator.pop(context);
                onForward();
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
                  onDelete();
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
    final isSeen = data['is_seen'] == true;

    // Parse reactions (TODO: join with message_reactions table)
    final reactions = <String, String>{};

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
      replyToText: null, // TODO: join with replied message
      replyToSender: null,
      reactions: reactions,
      isForwarded: data['is_forwarded'] as bool? ?? false,
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

  if (difference.inDays > 0) {
    if (difference.inDays == 1) {
      return 'Yesterday ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  } else if (difference.inHours > 0) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} min ago';
  } else {
    return 'Just now';
  }
}
