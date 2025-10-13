import 'package:flutter/material.dart';

/// Configuration cho các loại thông báo trong app
/// File này giúp dễ dàng custom thông báo, thêm icon, gif, image,...

// ============================================
// 1. DATA MODELS
// ============================================

/// Model cho notification data
class NotificationData {
  final String message;
  final String? icon; // emoji or icon path
  final String? imagePath; // path to image/gif
  final String? soundPath; // path to sound file
  final DateTime? date; // ngày cụ thể (cho ngày lễ, sinh nhật)
  final VoidCallback? onTap; // action khi tap vào notification
  final String? actionText; // text cho action button
  final bool isRecurring; // lặp lại hàng năm hay không

  const NotificationData({
    required this.message,
    this.icon,
    this.imagePath,
    this.soundPath,
    this.date,
    this.onTap,
    this.actionText,
    this.isRecurring = false,
  });

  NotificationData copyWith({
    String? message,
    String? icon,
    String? imagePath,
    String? soundPath,
    DateTime? date,
    VoidCallback? onTap,
    String? actionText,
    bool? isRecurring,
  }) {
    return NotificationData(
      message: message ?? this.message,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
      soundPath: soundPath ?? this.soundPath,
      date: date ?? this.date,
      onTap: onTap ?? this.onTap,
      actionText: actionText ?? this.actionText,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}

/// Model cho birthday notification
class BirthdayNotification {
  final String userId;
  final String userName;
  final DateTime birthday;
  final NotificationData notificationData;

  const BirthdayNotification({
    required this.userId,
    required this.userName,
    required this.birthday,
    required this.notificationData,
  });
}

// ============================================
// 2. NOTIFICATION CONFIG CLASS
// ============================================

class NotificationConfig {
  // ============================================
  // NGÀY LỄ - DỄ DÀNG THÊM MỚI VÀ CUSTOM
  // ============================================

  /// Danh sách các ngày lễ và thông báo tương ứng
  /// Dễ dàng thêm mới bằng cách add vào map này
  static final Map<String, NotificationData> holidays = {
    // Tết Nguyên Đán
    'tet': NotificationData(
      message:
          '🎊 Chúc mừng năm mới! Năm mới an khang thịnh vượng, vạn sự như ý! 🎊',
      icon: '🎊',
      imagePath: 'assets/images/tet.gif',
      soundPath: 'sounds/tet.mp3',
      date: DateTime(2025, 1, 29), // Tết 2025
      isRecurring: true,
      actionText: 'Gửi lời chúc',
    ),

    // Ngày Quốc tế Phụ nữ
    'womens_day': NotificationData(
      message:
          '🌹 Chúc mừng ngày Quốc tế Phụ nữ 8/3! Chúc các chị em luôn xinh đẹp, hạnh phúc và thành công! 🌹',
      icon: '🌹',
      imagePath: 'assets/images/womens_day.gif',
      soundPath: 'sounds/womens_day.mp3',
      date: DateTime(DateTime.now().year, 3, 8),
      isRecurring: true,
      actionText: 'Gửi hoa hồng',
    ),

    // Giỗ Tổ Hùng Vương
    'hung_king': NotificationData(
      message: '🙏 Ngày Giỗ Tổ Hùng Vương 10/3 - Tưởng nhớ công ơn cha ông 🙏',
      icon: '🙏',
      imagePath: 'assets/images/hung_king.png',
      date: DateTime(DateTime.now().year, 3, 10),
      isRecurring: true,
    ),

    // Ngày Giải phóng miền Nam
    'liberation_day': NotificationData(
      message:
          '🇻🇳 Kỷ niệm ngày Giải phóng miền Nam 30/4 - Thống nhất đất nước! 🇻🇳',
      icon: '🇻🇳',
      imagePath: 'assets/images/liberation.png',
      date: DateTime(DateTime.now().year, 4, 30),
      isRecurring: true,
    ),

    // Ngày Quốc tế Lao động
    'labor_day': NotificationData(
      message:
          '⚒️ Chúc mừng ngày Quốc tế Lao động 1/5! Chúc một ngày nghỉ thoải mái! ⚒️',
      icon: '⚒️',
      imagePath: 'assets/images/labor_day.gif',
      date: DateTime(DateTime.now().year, 5, 1),
      isRecurring: true,
      actionText: 'Nghỉ ngơi thôi!',
    ),

    // Ngày Quốc tế Thiếu nhi
    'childrens_day': NotificationData(
      message:
          '🎈 Chúc mừng ngày Quốc tế Thiếu nhi 1/6! Chúc các bé luôn vui vẻ, khỏe mạnh! 🎈',
      icon: '🎈',
      imagePath: 'assets/images/childrens_day.gif',
      date: DateTime(DateTime.now().year, 6, 1),
      isRecurring: true,
    ),

    // Ngày Quốc Khánh
    'national_day': NotificationData(
      message: '🎆 Chúc mừng Quốc Khánh 2/9! Tự hào Việt Nam! 🇻🇳',
      icon: '🎆',
      imagePath: 'assets/images/national_day.gif',
      date: DateTime(DateTime.now().year, 9, 2),
      isRecurring: true,
    ),

    // Ngày Phụ nữ Việt Nam
    'vietnamese_womens_day': NotificationData(
      message:
          '💐 Chúc mừng ngày Phụ nữ Việt Nam 20/10! Chúc các chị em luôn hạnh phúc! 💐',
      icon: '💐',
      imagePath: 'assets/images/vn_womens_day.gif',
      date: DateTime(DateTime.now().year, 10, 20),
      isRecurring: true,
      actionText: 'Tặng quà',
    ),

    // Halloween
    'halloween': NotificationData(
      message: '🎃 Happy Halloween! Trick or Treat! 👻',
      icon: '🎃',
      imagePath: 'assets/images/halloween.gif',
      soundPath: 'sounds/halloween.mp3',
      date: DateTime(DateTime.now().year, 10, 31),
      isRecurring: true,
      actionText: 'Boo!',
    ),

    // Ngày Nhà giáo Việt Nam
    'teachers_day': NotificationData(
      message:
          '👨‍🏫 Chúc mừng ngày Nhà giáo Việt Nam 20/11! Chúc thầy cô dồi dào sức khỏe! 👩‍🏫',
      icon: '👨‍🏫',
      imagePath: 'assets/images/teachers_day.png',
      date: DateTime(DateTime.now().year, 11, 20),
      isRecurring: true,
      actionText: 'Gửi lời cảm ơn',
    ),

    // Giáng sinh
    'christmas': NotificationData(
      message:
          '🎄 Merry Christmas! Chúc Giáng sinh an lành, hạnh phúc bên gia đình! 🎅',
      icon: '🎄',
      imagePath: 'assets/images/christmas.gif',
      soundPath: 'sounds/christmas.mp3',
      date: DateTime(DateTime.now().year, 12, 25),
      isRecurring: true,
      actionText: 'Mở quà',
    ),

    // Năm mới Dương lịch
    'new_year': NotificationData(
      message:
          '🎉 Happy New Year! Chúc năm mới tràn đầy niềm vui và thành công! 🎊',
      icon: '🎉',
      imagePath: 'assets/images/new_year.gif',
      soundPath: 'sounds/new_year.mp3',
      date: DateTime(DateTime.now().year + 1, 1, 1),
      isRecurring: true,
      actionText: 'Chúc mừng',
    ),

    // Thêm ngày lễ mới tại đây...
    // Ví dụ:
    // 'valentines_day': NotificationData(
    //   message: '💝 Happy Valentine\'s Day! Love is in the air! 💕',
    //   icon: '💝',
    //   imagePath: 'assets/images/valentine.gif',
    //   date: DateTime(DateTime.now().year, 2, 14),
    //   isRecurring: true,
    // ),
  };

  // ============================================
  // SINH NHẬT - CUSTOM MESSAGE
  // ============================================

  /// Template thông báo sinh nhật
  /// Có thể custom và thêm nhiều template khác nhau
  static List<NotificationData> birthdayTemplates = [
    // Template 1: Classic
    const NotificationData(
      message:
          '🎂 Chúc mừng sinh nhật {name}! Tuổi mới vui vẻ, hạnh phúc, thành công! 🎉',
      icon: '🎂',
      imagePath: 'assets/images/birthday_1.gif',
      soundPath: 'sounds/birthday.mp3',
      actionText: 'Gửi lời chúc',
    ),

    // Template 2: Fun
    const NotificationData(
      message:
          '🎈 Hôm nay là sinh nhật {name} đó! Chúc bạn một ngày tuyệt vời nhất! 🎊',
      icon: '🎈',
      imagePath: 'assets/images/birthday_2.gif',
      soundPath: 'sounds/birthday.mp3',
      actionText: 'Tham gia party',
    ),

    // Template 3: Heartfelt
    const NotificationData(
      message:
          '💖 {name} ơi, chúc mừng sinh nhật! Chúc bạn luôn khỏe mạnh và gặp nhiều may mắn! 🌟',
      icon: '💖',
      imagePath: 'assets/images/birthday_3.gif',
      actionText: 'Tặng quà',
    ),

    // Thêm template mới tại đây...
  ];

  /// Lấy thông báo sinh nhật (random hoặc theo index)
  static NotificationData getBirthdayNotification(
    String userName, {
    int? templateIndex,
  }) {
    final index =
        templateIndex ?? DateTime.now().millisecond % birthdayTemplates.length;
    final template = birthdayTemplates[index];

    return template.copyWith(
      message: template.message.replaceAll('{name}', userName),
    );
  }

  // ============================================
  // TIN NHẮN MỚI
  // ============================================

  /// Thông báo tin nhắn mới (có thể custom theo từng người hoặc nhóm)
  static NotificationData getNewMessageNotification({
    required String senderName,
    required String messagePreview,
    String? senderAvatar,
    bool isGroup = false,
  }) {
    return NotificationData(
      message: isGroup
          ? '💬 $senderName sent a message in group: $messagePreview'
          : '💬 New message from $senderName: $messagePreview',
      icon: isGroup ? '👥' : '💬',
      imagePath: senderAvatar,
      soundPath: 'sounds/message.mp3',
      actionText: 'Reply',
    );
  }

  // ============================================
  // HELPER FUNCTIONS
  // ============================================

  /// Kiểm tra xem hôm nay có phải ngày lễ không
  static List<NotificationData> getTodayHolidays() {
    final today = DateTime.now();
    final results = <NotificationData>[];

    for (final holiday in holidays.values) {
      if (holiday.date != null &&
          holiday.date!.month == today.month &&
          holiday.date!.day == today.day) {
        results.add(holiday);
      }
    }

    return results;
  }

  /// Lấy tất cả ngày lễ trong tháng
  static List<MapEntry<String, NotificationData>> getHolidaysInMonth(
    int month,
  ) {
    return holidays.entries
        .where((entry) => entry.value.date?.month == month)
        .toList();
  }

  /// Lấy ngày lễ theo key
  static NotificationData? getHoliday(String key) {
    return holidays[key];
  }

  /// Thêm ngày lễ mới (runtime)
  static void addHoliday(String key, NotificationData notification) {
    holidays[key] = notification;
  }

  /// Cập nhật ngày lễ
  static void updateHoliday(String key, NotificationData notification) {
    if (holidays.containsKey(key)) {
      holidays[key] = notification;
    }
  }

  /// Xóa ngày lễ
  static void removeHoliday(String key) {
    holidays.remove(key);
  }
}

// ============================================
// 3. BACKGROUND CONFIG
// ============================================

class BackgroundConfig {
  /// Danh sách background cho các ngày lễ
  static final Map<String, String> holidayBackgrounds = {
    'tet': 'assets/images/bg_tet.jpg',
    'womens_day': 'assets/images/bg_womens_day.jpg',
    'christmas': 'assets/images/bg_christmas.jpg',
    'new_year': 'assets/images/bg_new_year.jpg',
    'halloween': 'assets/images/bg_halloween.jpg',
    'valentines_day': 'assets/images/bg_valentine.jpg',
    // Thêm background cho ngày lễ mới...
  };

  /// Background cho sinh nhật
  static const String birthdayBackground = 'assets/images/bg_birthday.jpg';

  /// Background mặc định
  static const String defaultBackground = 'assets/images/bg_default.jpg';

  /// Lấy background cho hôm nay
  static String getTodayBackground() {
    // Kiểm tra sinh nhật user
    // (sẽ được implement trong service)

    // Kiểm tra ngày lễ
    final holidays = NotificationConfig.getTodayHolidays();
    if (holidays.isNotEmpty) {
      // Tìm background tương ứng
      for (final entry in NotificationConfig.holidays.entries) {
        if (entry.value == holidays.first &&
            holidayBackgrounds.containsKey(entry.key)) {
          return holidayBackgrounds[entry.key]!;
        }
      }
    }

    return defaultBackground;
  }

  /// Lấy background theo key
  static String? getBackgroundByKey(String key) {
    return holidayBackgrounds[key];
  }

  /// Thêm background mới
  static void addBackground(String key, String path) {
    holidayBackgrounds[key] = path;
  }
}
