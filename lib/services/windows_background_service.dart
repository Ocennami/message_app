import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:message_app/services/supabase_message_service.dart';
import 'package:message_app/services/windows_notification_helper.dart';
import 'package:message_app/services/supabase_auth_service.dart';

/// Windows Background Service
/// Giữ app chạy ẩn trong system tray để nhận thông báo ngay cả khi đóng cửa sổ
class WindowsBackgroundService with TrayListener, WindowListener {
  static final WindowsBackgroundService _instance =
      WindowsBackgroundService._internal();
  factory WindowsBackgroundService() => _instance;
  WindowsBackgroundService._internal();

  final _messageService = SupabaseMessageService();
  final _windowsNotifier = WindowsNotificationHelper();
  final _authService = SupabaseAuthService();

  StreamSubscription? _messageSubscription;
  bool _isInitialized = false;
  bool _isMinimizedToTray = false;

  /// Khởi tạo background service cho Windows
  Future<void> initialize() async {
    if (!Platform.isWindows || _isInitialized) return;

    try {
      // 1. Cấu hình window manager
      await windowManager.ensureInitialized();

      // Cho phép minimize to tray thay vì close
      await windowManager.setPreventClose(true);

      // Listen to window events
      windowManager.addListener(this);

      // 2. Cấu hình system tray
      await trayManager.setIcon(
        Platform.isWindows
            ? 'assets/images/app_icon.ico' // Cần thêm file .ico
            : 'assets/images/app_icon.png',
      );

      await trayManager.setToolTip('Alliance Message App');

      // Tạo context menu cho tray icon
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: 'show', label: 'Show Window'),
            MenuItem.separator(),
            MenuItem(key: 'exit', label: 'Exit'),
          ],
        ),
      );

      trayManager.addListener(this);

      // 3. Khởi động message listener
      await _startMessageListener();

      _isInitialized = true;
      debugPrint('✅ Windows Background Service initialized');
    } catch (e) {
      debugPrint('❌ Windows Background Service error: $e');
    }
  }

  /// Lắng nghe tin nhắn mới
  Future<void> _startMessageListener() async {
    final currentUserId = _authService.currentUserId;
    if (currentUserId == null) {
      debugPrint('⚠️ Cannot start message listener: No user logged in');
      return;
    }

    _messageSubscription = _messageService
        .getMessagesStream(conversationId: 'common-channel')
        .listen((messages) {
          if (messages.isEmpty) return;

          final latestMessage = messages.last;

          // Không thông báo tin nhắn của chính mình
          if (latestMessage['user_id'] == currentUserId) return;

          // Không thông báo tin nhắn cũ (> 5 giây)
          final createdAt = DateTime.parse(
            latestMessage['created_at'] as String,
          );
          final now = DateTime.now();
          if (now.difference(createdAt).inSeconds > 5) return;

          // Hiển thị notification LUÔN trên Windows
          _showNotification(
            senderEmail: latestMessage['user_email'] as String? ?? 'Someone',
            message: latestMessage['text'] as String? ?? 'Sent an attachment',
            hasAttachment: latestMessage['attachment_url'] != null,
          );
        });

    debugPrint('✅ Windows message listener started');
  }

  /// Hiển thị Windows notification
  Future<void> _showNotification({
    required String senderEmail,
    required String message,
    bool hasAttachment = false,
  }) async {
    final senderName = senderEmail.split('@').first;
    final displayMessage = hasAttachment && message.isEmpty
        ? '📎 Sent an attachment'
        : message;

    await _windowsNotifier.showNotification(
      title: senderName,
      body: displayMessage.length > 100
          ? '${displayMessage.substring(0, 100)}...'
          : displayMessage,
    );

    // Nếu app đang minimize to tray, flash tray icon
    if (_isMinimizedToTray) {
      await _flashTrayIcon();
    }

    debugPrint('✅ Windows notification shown: $senderName - $displayMessage');
  }

  /// Nhấp nháy tray icon để thu hút sự chú ý
  Future<void> _flashTrayIcon() async {
    try {
      // Có thể implement animation cho tray icon ở đây
      // Tạm thời chỉ log
      debugPrint('💫 Flashing tray icon...');
    } catch (e) {
      debugPrint('❌ Flash tray icon error: $e');
    }
  }

  /// Dừng background service
  void dispose() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    debugPrint('✅ Windows Background Service disposed');
  }

  // ============================================
  // TRAY LISTENER
  // ============================================

  @override
  void onTrayIconMouseDown() {
    // Click vào tray icon → show window
    windowManager.show();
    windowManager.focus();
    _isMinimizedToTray = false;
  }

  @override
  void onTrayIconRightMouseDown() {
    // Right click → show context menu
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        windowManager.show();
        windowManager.focus();
        _isMinimizedToTray = false;
        break;
      case 'exit':
        // Thực sự thoát app
        windowManager.destroy();
        exit(0);
    }
  }

  // ============================================
  // WINDOW MANAGER LISTENER (moved from extension)
  // ============================================

  @override
  void onWindowClose() async {
    // Thay vì đóng, minimize to tray
    await windowManager.hide();
    _isMinimizedToTray = true;
    debugPrint('🔽 Window minimized to tray');
  }

  @override
  void onWindowMinimize() {
    // Có thể minimize to tray luôn hoặc giữ trong taskbar
    debugPrint('🔽 Window minimized');
  }

  @override
  void onWindowRestore() {
    _isMinimizedToTray = false;
    debugPrint('🔼 Window restored');
  }
}
