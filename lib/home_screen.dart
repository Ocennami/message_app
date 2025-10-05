import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const Drawer(),
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
                const _HomeHeader(),
                SizedBox(height: spacing),
                const Expanded(child: _ChatSection()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

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
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    iconSize: iconSize,
                    splashRadius: splashRadius,
                    icon: const Icon(Icons.menu),
                    color: const Color(0xFF2D2535),
                  ),
                ),
              ),
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
                  child: Image.asset(
                    'assets/images/OIP.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AttachmentType { image, gif, file }

const _currentUserId = 'demo-user';
const _conversationId = 'default';

class _ChatSection extends StatefulWidget {
  const _ChatSection();

  @override
  State<_ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<_ChatSection> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  late final CollectionReference<Map<String, dynamic>> _messagesRef;

  Color _accentColor = const Color(0xFF1877F2);
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messagesRef = _firestore
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages');
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    _textController.clear();
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
        _showSnack('Không thể đọc dữ liệu tệp.');
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

      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }

      await _sendMessage(
        attachmentType: _AttachmentType.image,
        attachmentBytes: bytes,
        fileName: image.name,
      );
    } catch (error) {
      _showSnack('Không thể lấy ảnh: ');
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
        _showSnack('Không thể đọc dữ liệu GIF.');
        return;
      }

      await _sendMessage(
        attachmentType: _AttachmentType.gif,
        attachmentBytes: bytes,
        fileName: file.name,
      );
    } catch (error) {
      _showSnack('Không thể lấy GIF: ');
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

    final docRef = _messagesRef.doc();

    try {
      String? attachmentUrl;
      if (bytes != null && type != null) {
        attachmentUrl = await _uploadAttachment(
          messageId: docRef.id,
          bytes: bytes,
          type: type,
          fileName: fileName,
        );
      }

      await docRef.set({
        'text': hasText ? trimmed : null,
        'senderId': _currentUserId,
        'attachmentType': type?.name,
        'attachmentUrl': attachmentUrl,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      _showSnack('Gửi tin nhắn thất bại: ');
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
    required String messageId,
    required Uint8List bytes,
    required _AttachmentType type,
    String? fileName,
  }) async {
    final extension = _extensionFromFileName(fileName);
    final effectiveExtension = extension.isNotEmpty
        ? extension
        : _defaultExtensionFor(type);
    final storageRef = _storage.ref('conversations//.');

    final metadata = SettableMetadata(
      contentType: _contentTypeFor(type, effectiveExtension),
    );

    await storageRef.putData(bytes, metadata);
    return storageRef.getDownloadURL();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _messagesRef
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Không thể tải tin nhắn: '));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return _MessagesList(
                  controller: _scrollController,
                  messages: _initialMessages,
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final messages = docs
                  .map(
                    (doc) => _ChatMessage.fromDocument(
                      doc,
                      currentUserId: _currentUserId,
                    ),
                  )
                  .toList();

              if (messages.isEmpty) {
                return _MessagesList(
                  controller: _scrollController,
                  messages: _initialMessages,
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });

              return _MessagesList(
                controller: _scrollController,
                messages: messages,
              );
            },
          ),
        ),
        _MessageInputBar(
          controller: _textController,
          onSend: _handleSend,
          onAddFile: _handlePickFile,
          onPickImage: _handlePickImage,
          onPickGif: _handlePickGif,
          onChangeTheme: _handleChangeAccent,
          accentColor: _accentColor,
          isSending: _isSending,
        ),
      ],
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({required this.controller, required this.messages});

  final ScrollController controller;
  final List<_ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 480;
    final horizontalPadding = isCompact ? 12.0 : 24.0;
    final verticalPadding = isCompact ? 8.0 : 12.0;
    final itemSpacing = isCompact ? 8.0 : 12.0;

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
        return _ChatBubble(message: message);
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
    required this.accentColor,
    required this.isSending,
  });

  final TextEditingController controller;
  final Future<void> Function() onSend;
  final Future<void> Function() onAddFile;
  final Future<void> Function() onPickImage;
  final Future<void> Function() onPickGif;
  final Future<void> Function() onChangeTheme;
  final Color accentColor;
  final bool isSending;

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
      child: Row(
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
            onTap: isSending ? null : () async {},
          ),
          _SendButton(color: accentColor, onSend: onSend, isSending: isSending),
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
  const _ChatBubble({required this.message});

  final _ChatMessage message;

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
                message.fileName ?? message.text ?? 'T???p ?`A-nh kA"m',
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

    if (message.text != null && message.text!.isNotEmpty) {
      if (content.isNotEmpty) {
        content.add(SizedBox(height: textSpacing));
      }
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

    return Align(
      alignment: alignment,
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
  });

  final String? id;
  final String? text;
  final bool isMe;
  final _AttachmentType? attachmentType;
  final String? attachmentUrl;
  final String? fileName;

  bool get hasVisualAttachment =>
      attachmentUrl != null &&
      (attachmentType == _AttachmentType.image ||
          attachmentType == _AttachmentType.gif);

  static _ChatMessage fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data();
    final typeName = data['attachmentType'] as String?;
    _AttachmentType? type;
    if (typeName != null) {
      for (final candidate in _AttachmentType.values) {
        if (candidate.name == typeName) {
          type = candidate;
          break;
        }
      }
    }

    return _ChatMessage(
      id: doc.id,
      text: (data['text'] as String?)?.trim(),
      isMe: data['senderId'] == currentUserId,
      attachmentType: type,
      attachmentUrl: data['attachmentUrl'] as String?,
      fileName: data['fileName'] as String?,
    );
  }
}

final _initialMessages = <_ChatMessage>[
  const _ChatMessage(
    text: 'Xin chào, mình k67 sv Hust, bạn khóa nhiu thế',
    isMe: true,
  ),
  const _ChatMessage(text: 'Xin chào, mình k70 cũng sv Hust', isMe: false),
  const _ChatMessage(text: 'Cuối tuần này rảnh không?', isMe: true),
  const _ChatMessage(text: 'Tớ rảnh chủ nhật nhé!', isMe: false),
  const _ChatMessage(text: 'Đi giải tích nhé', isMe: true),
  const _ChatMessage(text: 'Okie, hẹn cậu 5h sáng.', isMe: false),
];

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
  }
}

String _contentTypeFor(_AttachmentType type, String? extension) {
  final lowerExt = extension?.toLowerCase();
  switch (type) {
    case _AttachmentType.image:
      if (lowerExt == 'png') return 'image/png';
      if (lowerExt == 'gif') return 'image/gif';
      if (lowerExt == 'heic') return 'image/heic';
      return 'image/jpeg';
    case _AttachmentType.gif:
      return 'image/gif';
    case _AttachmentType.file:
      if (lowerExt == 'pdf') return 'application/pdf';
      if (lowerExt == 'txt') return 'text/plain';
      if (lowerExt == 'doc' || lowerExt == 'docx') {
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      }
      return 'application/octet-stream';
  }
}
