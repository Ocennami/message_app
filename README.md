# 💬 Message App - Group Chat Application

**MessageApp** by Oceanami - A real-time group chat application built with Flutter and **Supabase**.

> **⚡ Recently Migrated:** This project has been fully migrated from Firebase to Supabase (October 2025). See `MIGRATION_COMPLETE.md` for details.

## 📱 Overview

This is a **single-room group chat application** designed for teams, families, or any group that needs a dedicated communication space. All authenticated users share one common chatroom with full-featured messaging capabilities.

## ✨ Features

### 🎯 Core Features

- ✅ **Real-time Messaging** - Instant message delivery with Supabase PostgreSQL + Realtime
- ✅ **User Authentication** - Email/Password authentication via Supabase Auth
- ✅ **Beautiful Onboarding** - Smooth intro screens with animations
- ✅ **Responsive UI** - Works on mobile, tablet, and desktop

### 💬 Chat Features

1. **Text Messages** - Send and receive text messages instantly
2. **Image Sharing** - Pick from gallery with automatic compression (70% quality)
3. **File Attachments** - Share documents and files
4. **Voice Messages** - Record and send voice notes (mobile only)
5. **GIF Support** - Send animated GIFs
6. **Emoji Picker** - 176+ emojis with search and categories

### 🎨 Interactive Features

7. **Message Reactions** - React with 6 quick emojis (❤️ 😂 👍 👎 😮 😢)
8. **Reply/Quote** - Reply to specific messages with preview
9. **Forward Messages** - Forward messages with "Forwarded" badge
10. **Message Actions** - Copy, delete, reply to messages
11. **Search Messages** - Search with text highlighting
12. **Typing Indicator** - See when others are typing
13. **Read Status** - "Seen" indicators for messages
14. **Timestamps** - Smart timestamp formatting (Today, Yesterday, dates)

### 🎛️ Advanced Features

15. **Pagination** - Load 50 messages at a time for performance
16. **Theme Selector** - 12 accent color themes
17. **Push Notifications** - FCM integration (mobile/web only)
18. **Cross-Platform** - Android, iOS, Web, Windows, macOS, Linux

## 🏗️ Architecture

### Tech Stack

- **Frontend**: Flutter 3.9.0+ with Dart
- **Backend**: Supabase (Auth, PostgreSQL, Storage, Realtime)
- **State Management**: Provider pattern with StreamBuilder
- **Audio**: record ^6.1.2 (mobile), audioplayers ^6.1.0
- **Images**: image_picker, flutter_image_compress, cached_network_image

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── auth_screen.dart          # Authentication UI
├── home_screen.dart          # Main chat interface (~2600 lines)
├── profile_screen.dart       # User profile management
├── onboarding_screen.dart    # Intro screens
├── config/
│   └── supabase_config.dart  # Supabase configuration
├── services/
│   ├── supabase_auth_service.dart     # Authentication
│   ├── supabase_message_service.dart  # Messages & real-time
│   └── supabase_storage_service.dart  # File storage
└── themes/
    └── app_theme.dart        # Theme configuration
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.0 or higher
- Supabase account (free tier available)
- Android Studio / Xcode (for mobile development)
- Visual Studio 2022 (for Windows development)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Ocennami/message_app.git
   cd message_app
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Supabase** (IMPORTANT!)

   📖 **Hướng dẫn chi tiết**: See `SUPABASE_SETUP_GUIDE.md`

   Quick steps:

   - Create Supabase project at https://supabase.com
   - Run database migration: Execute `supabase_schema.sql` in SQL Editor
   - Update config: Edit `lib/config/supabase_config.dart` with your project URL and keys
   - **Enable Row Level Security (RLS)** on all tables (critical!)

4. **Run the app**

   ```bash
   # Android
   flutter run -d android

   # iOS
   flutter run -d ios

   # Windows
   flutter run -d windows

   # Web
   flutter run -d chrome
   ```

## 🔧 Configuration

### Supabase Setup

1. Create project at [supabase.com](https://supabase.com)
2. Get your project URL and anon key from Settings → API
3. Update `lib/config/supabase_config.dart`:
   ```dart
   const supabaseUrl = 'YOUR_PROJECT_URL';
   const supabaseAnonKey = 'YOUR_ANON_KEY';
   ```
4. Run database migration: `supabase_schema.sql` in SQL Editor
5. Enable RLS policies on all tables

### Known Limitations

- **Voice Messages**: Only work on Android/iOS (not supported on Windows/Web/Linux)
- **Push Notifications**: Only work on Android/iOS/Web (not Windows/macOS/Linux)

## 📦 Dependencies

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  firebase_storage: ^13.0.1
  firebase_messaging: ^16.0.1
  record: ^6.1.2
  audioplayers: ^6.1.0
  image_picker: ^1.2.0
  flutter_image_compress: ^2.3.0
  cached_network_image: ^3.4.1
  google_fonts: ^6.3.1
  # ... see pubspec.yaml for full list
```

## 🎨 Customization

### Theme Colors

Edit 12 available accent colors in `home_screen.dart`:

```dart
final _accentColors = [
  Color(0xFF1877F2), // Facebook Blue
  Color(0xFF0088CC), // Telegram Blue
  // ... customize colors
];
```

### Conversation ID

For multiple groups, change the conversation ID in `home_screen.dart`:

```dart
final _conversationId = 'your-group-id'; // Default: 'default'
```

## 🐛 Troubleshooting

### "Missing or insufficient permissions"

→ Deploy Firebase security rules (see `FIREBASE_RULES_SETUP.md`)

### "MissingPluginException for firebase_messaging"

→ Normal on Windows/Desktop, notifications only work on mobile/web

### Build fails on Windows

→ Ensure Visual Studio 2022 with "Desktop development with C++" is installed

## 📝 License

This project is created by Oceanami for educational purposes.

## 🙏 Credits

- **Developer**: Oceanami
- **Framework**: Flutter by Google
- **Backend**: Firebase by Google

## 📞 Support

For issues and feature requests, please contact the development team.

---

**Status**: ✅ Production Ready (after deploying Firebase rules)

**Version**: 1.0.0+1

**Last Updated**: October 10, 2025
