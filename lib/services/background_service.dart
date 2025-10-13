import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:message_app/config/notification_config.dart';

/// Service quản lý background và system tray (cho desktop)
class BackgroundService extends ChangeNotifier
    with TrayListener, WindowListener {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  String _currentBackground = BackgroundConfig.defaultBackground;
  bool _autoChangeBackground = true;
  bool _isInitialized = false;

  String get currentBackground => _currentBackground;
  bool get autoChangeBackground => _autoChangeBackground;

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadSettings();
    await _updateBackground();

    // Initialize desktop features
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await _initializeDesktop();
    }

    _isInitialized = true;
    debugPrint('✅ BackgroundService initialized');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoChangeBackground = prefs.getBool('autoChangeBackground') ?? true;
    _currentBackground =
        prefs.getString('customBackground') ??
        BackgroundConfig.defaultBackground;
  }

  // ============================================
  // DESKTOP FEATURES (System Tray)
  // ============================================

  Future<void> _initializeDesktop() async {
    try {
      // Must be called in main or here
      await windowManager.ensureInitialized();

      // Add window listener
      windowManager.addListener(this);

      // Window settings
      const windowOptions = WindowOptions(
        size: Size(1200, 800),
        minimumSize: Size(800, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'Message App',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      // Initialize system tray
      await _initializeSystemTray();

      debugPrint('✅ Desktop features initialized');
    } catch (e) {
      debugPrint('❌ Error initializing desktop features: $e');
    }
  }

  Future<void> _initializeSystemTray() async {
    try {
      trayManager.addListener(this);

      // Set tray icon
      await trayManager.setIcon(
        Platform.isWindows
            ? 'assets/images/app_icon.ico'
            : 'assets/images/app_icon.png',
      );

      // Set tray menu
      await _updateTrayMenu();

      // Set tooltip
      await trayManager.setToolTip('Message App');

      debugPrint('✅ System tray initialized');
    } catch (e) {
      debugPrint('❌ Error initializing system tray: $e');
    }
  }

  Future<void> _updateTrayMenu() async {
    final menu = Menu(
      items: [
        MenuItem(key: 'show', label: 'Show Window'),
        MenuItem.separator(),
        MenuItem(key: 'online', label: 'Set Online'),
        MenuItem(key: 'offline', label: 'Set Offline'),
        MenuItem.separator(),
        MenuItem(key: 'settings', label: 'Settings'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ],
    );

    await trayManager.setContextMenu(menu);
  }

  // ============================================
  // WINDOW LISTENER (Handle close button)
  // ============================================

  @override
  void onWindowClose() async {
    debugPrint('Window close requested - hiding to tray');

    // Don't close, just hide to system tray
    await windowManager.hide();

    // Show notification
    // You can use NotificationService here to show a toast
    debugPrint('App minimized to system tray');
  }

  @override
  void onWindowFocus() {
    debugPrint('Window focused');
  }

  @override
  void onWindowBlur() {
    debugPrint('Window blurred');
  }

  @override
  void onWindowMinimize() {
    debugPrint('Window minimized');
  }

  @override
  void onWindowRestore() {
    debugPrint('Window restored');
  }

  // ============================================
  // TRAY LISTENER (Handle tray clicks)
  // ============================================

  @override
  void onTrayIconMouseDown() {
    debugPrint('Tray icon clicked');
    _showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    debugPrint('Tray icon right clicked');
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    debugPrint('Tray menu item clicked: ${menuItem.key}');

    switch (menuItem.key) {
      case 'show':
        await _showWindow();
        break;
      case 'online':
        // Set online status
        debugPrint('Setting online status...');
        break;
      case 'offline':
        // Set offline status
        debugPrint('Setting offline status...');
        break;
      case 'settings':
        await _showWindow();
        // Navigate to settings
        break;
      case 'quit':
        await _quitApp();
        break;
    }
  }

  Future<void> _showWindow() async {
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('Error showing window: $e');
    }
  }

  Future<void> _quitApp() async {
    try {
      await windowManager.destroy();
      exit(0);
    } catch (e) {
      debugPrint('Error quitting app: $e');
    }
  }

  // ============================================
  // BACKGROUND MANAGEMENT
  // ============================================

  Future<void> _updateBackground() async {
    if (!_autoChangeBackground) {
      final prefs = await SharedPreferences.getInstance();
      _currentBackground =
          prefs.getString('customBackground') ??
          BackgroundConfig.defaultBackground;
      notifyListeners();
      return;
    }

    // Auto update based on holidays and birthdays
    _currentBackground = BackgroundConfig.getTodayBackground();
    notifyListeners();

    debugPrint('Background updated: $_currentBackground');
  }

  /// Set custom background
  Future<void> setCustomBackground(String backgroundPath) async {
    _currentBackground = backgroundPath;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customBackground', backgroundPath);

    notifyListeners();
    debugPrint('Custom background set: $backgroundPath');
  }

  /// Toggle auto change background
  Future<void> setAutoChangeBackground(bool value) async {
    _autoChangeBackground = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoChangeBackground', value);

    if (value) {
      await _updateBackground();
    }

    notifyListeners();
    debugPrint('Auto change background: $value');
  }

  /// Force update background (check for today's holiday/birthday)
  Future<void> refreshBackground() async {
    await _updateBackground();
  }

  /// Get available backgrounds
  List<BackgroundOption> getAvailableBackgrounds() {
    return [
      BackgroundOption(
        name: 'Default',
        path: BackgroundConfig.defaultBackground,
        isDefault: true,
      ),
      BackgroundOption(
        name: 'Birthday',
        path: BackgroundConfig.birthdayBackground,
        isDefault: false,
      ),
      ...BackgroundConfig.holidayBackgrounds.entries.map(
        (entry) => BackgroundOption(
          name: _formatHolidayName(entry.key),
          path: entry.value,
          isDefault: false,
        ),
      ),
    ];
  }

  String _formatHolidayName(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // ============================================
  // AUTO START (Desktop)
  // ============================================

  Future<void> setAutoStart(bool enable) async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('autoStart', enable);

        // TODO: Implement actual auto-start registration
        // For Windows: Add to registry or startup folder
        // For macOS: Use LaunchAgents
        // For Linux: Use autostart desktop file

        debugPrint('Auto start ${enable ? 'enabled' : 'disabled'}');
      } catch (e) {
        debugPrint('Error setting auto start: $e');
      }
    }
  }

  Future<bool> isAutoStartEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('autoStart') ?? false;
  }

  // ============================================
  // CLEANUP
  // ============================================

  Future<void> dispose() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
    super.dispose();
  }
}

// ============================================
// DATA MODELS
// ============================================

class BackgroundOption {
  final String name;
  final String path;
  final bool isDefault;

  const BackgroundOption({
    required this.name,
    required this.path,
    required this.isDefault,
  });
}
