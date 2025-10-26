# 🚀 Auto-Update Release Guide

Hướng dẫn deploy phiên bản mới và sử dụng hệ thống auto-update với **Cloudflare R2**.

## 📋 Prerequisites

1. ✅ Đã setup Cloudflare R2 (bucket `releases`) - [Xem hướng dẫn](R2_SETUP.md)
2. ✅ Đã setup Supabase (table `app_releases`)
3. ✅ File `lib/config/r2_config.dart` đã có API credentials
4. ✅ File `lib/config/auto_update_config.dart` đã có Service Role Key
5. ✅ Flutter và Dart đã cài đặt

## 🌩️ Why Cloudflare R2?

- ✅ **FREE egress bandwidth** (Supabase Storage chỉ 50MB)
- ✅ No storage limits
- ✅ $0.015/GB/month storage cost
- ✅ Global CDN
- ✅ S3-compatible API

## 🎯 Quick Start - Deploy Release

### Option 1: Tự động (Khuyến nghị)

```batch
# Build và upload cả Android + Windows lên R2
scripts\build_and_upload.bat 1.0.1
```

### Option 2: Thủ công từng bước

#### 1. Build App

**Android:**

```bash
flutter build apk --release
```

➡️ Output: `build/app/outputs/flutter-apk/app-release.apk`

**Windows:**

```bash
flutter build windows --release
```

➡️ Output: `build/windows/x64/runner/Release/message_app.exe`

#### 2. Upload Release to R2

**Android:**

```bash
dart scripts/upload_release_r2.dart 1.0.1 android build/app/outputs/flutter-apk/app-release.apk
```

**Windows:**

```bash
dart scripts/upload_release_r2.dart 1.0.1 windows build/windows/x64/runner/Release/message_app.exe
dart scripts/upload_release.dart 1.0.1 windows build/windows/x64/runner/Release/message_app.exe
```

## 🔄 How It Works

### Upload Script Flow

```
1. ✅ Calculate SHA256 checksum
2. ☁️  Upload file to Supabase Storage
   └─ Bucket: releases
   └─ Path: android/v1.0.1/app-release.apk
3. 💾 Insert/Update database record
   └─ Table: app_releases
   └─ Fields: version, download_url, sha256, etc.
4. 🎉 Done!
```

### User Update Flow

```
1. 📱 User opens app
2. 🔍 App checks version via Supabase Edge Function
   └─ GET /functions/v1/releases?platform=android
3. 📊 Compare versions (local vs remote)
4. 🔔 Show update dialog if new version available
5. ⬇️  User downloads & installs
   └─ Android: Opens browser to download APK
   └─ Windows: Downloads EXE and auto-runs installer
```

## 📝 Script Usage

### upload_release.dart

```bash
dart scripts/upload_release.dart <version> <platform> <file_path>
```

**Parameters:**

- `version`: Version number (e.g., 1.0.1)
- `platform`: `android` or `windows`
- `file_path`: Path to built file

**Example:**

```bash
dart scripts/upload_release.dart 1.0.1 android build/app/outputs/flutter-apk/app-release.apk
```

### build_and_upload.bat

```batch
build_and_upload.bat <version>
```

**Example:**

```batch
build_and_upload.bat 1.0.1
```

Builds both Android and Windows, then uploads both to Supabase.

## 🗄️ Database Structure

Table: `app_releases`

```sql
- version (TEXT UNIQUE)          - e.g., "1.0.1"
- release_notes (TEXT)           - What's new
- android_download_url (TEXT)    - Public URL to APK
- windows_download_url (TEXT)    - Public URL to EXE
- android_sha256 (TEXT)          - Checksum for Android
- windows_sha256 (TEXT)          - Checksum for Windows
- is_active (BOOLEAN)            - Enable/disable version
- created_at (TIMESTAMPTZ)
- updated_at (TIMESTAMPTZ)
```

## 🔐 Security

### Service Role Key

- ⚠️ **NEVER commit** `auto_update_config.dart` to Git!
- ✅ File is already in `.gitignore`
- 🔑 Service Role Key has admin access to Supabase

### SHA256 Verification

- ✅ Checksums calculated on upload
- ✅ Verified on download (Windows only)
- ✅ Prevents tampering

## 🛠️ Troubleshooting

### "Database update failed"

➡️ Check Service Role Key in `auto_update_config.dart`

### "Upload failed"

➡️ Ensure bucket `releases` exists in Supabase Storage

### "File not found"

➡️ Verify build path matches your Flutter version

- Android: `build/app/outputs/flutter-apk/app-release.apk`
- Windows: `build/windows/x64/runner/Release/message_app.exe`

### Users don't see update

1. Check `is_active = true` in database
2. Verify Edge Function is deployed: `/functions/v1/releases`
3. Test API manually: `https://your-project.supabase.co/functions/v1/releases?platform=android`

## 📚 Additional Resources

- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Flutter Build Docs](https://docs.flutter.dev/deployment)

## 🎉 Complete Workflow Example

```batch
# 1. Update version in pubspec.yaml
# version: 1.0.1+1

# 2. Build and upload
scripts\build_and_upload.bat 1.0.1

# 3. (Optional) Update release notes in Supabase Dashboard
# Go to: Table Editor > app_releases > Edit row

# 4. Test
# Open app -> Should see update dialog

# 5. Done! 🎊
```

## 💡 Tips

- **Version format**: Use semantic versioning (major.minor.patch)
- **Testing**: Test on old version app before announcing
- **Release notes**: Add helpful info for users in database
- **Backup**: Keep previous versions in storage for rollback

---

**Need help?** Check main README.md or create an issue.
