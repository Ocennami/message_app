# 📱 Hướng Dẫn Sử Dụng Auto-Update

Hướng dẫn deploy và quản lý phiên bản app với hệ thống auto-update.

## 🎯 Tổng Quan

Hệ thống auto-update tự động thông báo cho users khi có phiên bản mới và cho phép tải xuống ngay lập tức.

**Flow hoạt động:**

1. Admin build và upload phiên bản mới
2. Files được lưu trên Cloudflare R2
3. Metadata được lưu trong Supabase
4. Users mở app → tự động kiểm tra phiên bản mới
5. Hiển thị dialog update với release notes
6. Users download và cài đặt

---

## 🚀 Deploy Phiên Bản Mới

### Bước 1: Cập nhật Version Number

Mở file `pubspec.yaml` và tăng version:

```yaml
# Trước
version: 1.0.0+1

# Sau
version: 1.0.1+2
```

**Format:** `major.minor.patch+buildNumber`

- `1.0.1`: Version hiển thị cho users
- `+2`: Build number (phải tăng mỗi lần build)

### Bước 2: Build và Upload

**Option A: Tự động (Khuyến nghị)**

```batch
scripts\build_and_upload.bat 1.0.1
```

Script sẽ:

- ✅ Build Android APK
- ✅ Build Windows EXE
- ✅ Upload cả 2 lên R2
- ✅ Cập nhật database

**Option B: Thủ công từng bước**

```batch
# Build Android
flutter build apk --release

# Upload Android
dart scripts/upload_release_r2.dart 1.0.1 android build/app/outputs/flutter-apk/app-release.apk

# Build Windows
flutter build windows --release

# Upload Windows
dart scripts/upload_release_r2.dart 1.0.1 windows build/windows/x64/runner/Release/message_app.exe
```

### Bước 3: Kiểm tra Upload

Sau khi upload thành công, bạn sẽ thấy:

```
🚀 Starting release upload to Cloudflare R2...
📦 Version: 1.0.1
🖥️  Platform: android
📄 File: build/app/outputs/flutter-apk/app-release.apk

🔐 Calculating SHA256 checksum...
✅ SHA256: abc123...
📊 File size: 45.23 MB

☁️  Uploading to Cloudflare R2...
📁 Bucket: releases
📍 Path: android/v1.0.1/app-release.apk
✅ Uploaded to R2!
🔗 Public URL: https://pub-xxx.r2.dev/android/v1.0.1/app-release.apk

💾 Updating Supabase database...
📝 Creating new release record...
✅ Database updated successfully!

🎉 Release uploaded successfully!
```

---

## 📝 Cập Nhật Release Notes

### Option 1: Qua Supabase Dashboard (Khuyến nghị)

1. Vào [Supabase Dashboard](https://supabase.com/dashboard)
2. Chọn project → **Table Editor**
3. Mở table `app_releases`
4. Tìm row với `version = "1.0.1"`
5. Click **Edit** → Sửa field `release_notes`
6. Nhập nội dung theo format:

```
🎉 Phiên bản 1.0.1

✨ Tính năng mới:
- Thêm chức năng gửi stickers
- Cải thiện emoji picker
- Thêm dark mode

🐛 Sửa lỗi:
- Fix crash khi upload ảnh lớn
- Fix notification không hiển thị
- Cải thiện performance

🔧 Cải tiến:
- Tăng tốc độ load tin nhắn
- Giảm dung lượng cache
```

### Option 2: Qua SQL

```sql
UPDATE app_releases
SET release_notes = '🎉 Phiên bản 1.0.1

✨ Tính năng mới:
- Thêm chức năng gửi stickers
- Cải thiện emoji picker
...
'
WHERE version = '1.0.1';
```

---

## 👥 User Experience

### Khi Users Mở App

**Nếu có phiên bản mới:**

1. Dialog xuất hiện:

   ```
   ┌─────────────────────────────────┐
   │  Update available: 1.0.1        │
   ├─────────────────────────────────┤
   │                                 │
   │  🎉 Phiên bản 1.0.1             │
   │                                 │
   │  ✨ Tính năng mới:              │
   │  - Thêm stickers                │
   │  - Dark mode                    │
   │  ...                            │
   │                                 │
   ├─────────────────────────────────┤
   │  [Later]          [Update]      │
   └─────────────────────────────────┘
   ```

2. User click **Update**:

   - **Android**: Mở browser → Download APK → Cài đặt thủ công
   - **Windows**: Download EXE → Tự động chạy installer

3. User click **Later**: Đóng dialog, hỏi lại lần sau

**Nếu đã cập nhật:**

- Không hiển thị gì, vào app bình thường

---

## 🔍 Kiểm Tra và Debug

### 1. Kiểm tra Files trên R2

1. Vào [Cloudflare Dashboard](https://dash.cloudflare.com) → R2
2. Click bucket `releases`
3. Verify files tồn tại:
   ```
   releases/
   ├── android/
   │   └── v1.0.1/
   │       └── app-release.apk (✅ 45 MB)
   └── windows/
       └── v1.0.1/
           └── message_app.exe (✅ 78 MB)
   ```

### 2. Kiểm tra Database

```sql
-- Xem tất cả releases
SELECT version, is_active, created_at
FROM app_releases
ORDER BY created_at DESC;

-- Xem chi tiết 1 version
SELECT * FROM app_releases WHERE version = '1.0.1';
```

Expected output:

```
version | is_active | android_download_url | windows_download_url
1.0.1   | true      | https://pub-xxx...   | https://pub-xxx...
```

### 3. Test Public URLs

Mở browser và test download URLs:

```
https://pub-xxx.r2.dev/android/v1.0.1/app-release.apk
https://pub-xxx.r2.dev/windows/v1.0.1/message_app.exe
```

**Kết quả mong đợi:** File tải xuống thành công

### 4. Test Auto-Update Flow

**Cách 1: Giảm version trong app**

1. Sửa `pubspec.yaml`: `version: 0.9.0+1` (thấp hơn version đã upload)
2. Build và chạy app
3. Mở app → Dialog update sẽ xuất hiện

**Cách 2: Test với app production**

- Mở app version cũ
- Đợi vài giây
- Dialog update sẽ hiển thị

---

## 🛠️ Quản Lý Versions

### Vô hiệu hóa một version

```sql
UPDATE app_releases
SET is_active = false
WHERE version = '1.0.0';
```

Users sẽ không được thông báo update lên version này nữa.

### Kích hoạt lại version

```sql
UPDATE app_releases
SET is_active = true
WHERE version = '1.0.0';
```

### Xóa version (không khuyến nghị)

```sql
DELETE FROM app_releases WHERE version = '1.0.0';
```

**Lưu ý:** File vẫn còn trên R2, chỉ xóa metadata.

### Xem lịch sử versions

```sql
SELECT
  version,
  is_active,
  TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI') as uploaded_at,
  ROUND(android_file_size / 1024.0 / 1024.0, 2) as android_mb,
  ROUND(windows_file_size / 1024.0 / 1024.0, 2) as windows_mb
FROM app_releases
ORDER BY created_at DESC;
```

---

## 📊 Thống Kê và Monitoring

### Download Statistics (Cloudflare R2)

1. Vào R2 Dashboard → Bucket `releases`
2. Tab **Metrics**
3. Xem:
   - Number of requests
   - Data transfer
   - Popular files

### User Update Rate (Tự implement)

Có thể track bằng cách thêm analytics vào app:

```dart
// Khi user update thành công
await analytics.logEvent(
  name: 'app_updated',
  parameters: {
    'from_version': oldVersion,
    'to_version': newVersion,
    'platform': Platform.isAndroid ? 'android' : 'windows',
  },
);
```

---

## ⚠️ Lưu Ý Quan Trọng

### Version Numbering

✅ **Đúng:** `1.0.0` → `1.0.1` → `1.1.0` → `2.0.0`

❌ **Sai:** `1.0.0` → `1.0.0` (trùng), `1.5` (thiếu patch), `2.0.0` → `1.9.0` (giảm)

### File Size

- Android APK: Thường 30-60 MB
- Windows EXE: Thường 50-100 MB
- R2 không giới hạn, nhưng users cần download → giữ file nhỏ gọn

### Testing

- ✅ **LUÔN test** trên thiết bị thật trước khi announce
- ✅ Build cả Debug và Release để test
- ✅ Verify SHA256 checksum khớp

### Rollback

Nếu version mới có bug nghiêm trọng:

1. **Nhanh:** Disable version mới

   ```sql
   UPDATE app_releases SET is_active = false WHERE version = '1.0.1';
   ```

2. **Chính thức:** Upload hotfix version
   ```batch
   scripts\build_and_upload.bat 1.0.2
   ```

---

## 🎯 Best Practices

### 1. Version Strategy

**Semantic Versioning:**

- **Major (1.x.x):** Breaking changes
- **Minor (x.1.x):** New features, backward compatible
- **Patch (x.x.1):** Bug fixes only

**Example:**

- `1.0.0` → Initial release
- `1.0.1` → Bug fixes
- `1.1.0` → New features
- `2.0.0` → Major redesign

### 2. Release Notes Format

```markdown
🎉 Version X.Y.Z

✨ Tính năng mới:

- [Feature 1]
- [Feature 2]

🐛 Sửa lỗi:

- [Bug fix 1]
- [Bug fix 2]

🔧 Cải tiến:

- [Improvement 1]
- [Improvement 2]

⚠️ Lưu ý:

- [Important note if any]
```

### 3. Release Frequency

- 🟢 **Bug fixes:** Ngay khi cần (hotfix)
- 🟡 **Minor updates:** 1-2 tuần một lần
- 🔴 **Major updates:** 1-3 tháng một lần

### 4. Communication

Thông báo cho users qua:

- ✅ In-app update dialog (tự động)
- ✅ Email newsletter (optional)
- ✅ Social media posts
- ✅ Website changelog

---

## 🆘 Troubleshooting

### Users không thấy update

**Kiểm tra:**

1. Version trong database có `is_active = true`?
2. Edge Function `/functions/v1/releases` có hoạt động?
3. User có internet connection?
4. App version hiện tại thấp hơn version mới?

**Test:**

```bash
# Test Edge Function
curl "https://your-project.supabase.co/functions/v1/releases?platform=android"
```

### Download fails

**Kiểm tra:**

1. Public URL có accessible?
2. R2 bucket có public access?
3. File tồn tại trên R2?

**Test:** Mở URL trong browser

### SHA256 mismatch (Windows only)

**Nguyên nhân:** File corrupt trong quá trình upload/download

**Giải pháp:**

1. Upload lại file
2. Clear browser cache và download lại

---

## 📞 Support

Nếu gặp vấn đề:

1. Check logs trong app (Debug console)
2. Verify database records
3. Test public URLs manually
4. Check R2 bucket permissions
5. Review Edge Function logs in Supabase

---

## ✅ Checklist Deploy

Trước mỗi lần release:

- [ ] Đã test app thoroughly
- [ ] Đã update version trong `pubspec.yaml`
- [ ] Đã build cả Android và Windows
- [ ] Đã upload thành công lên R2
- [ ] Đã verify files trên R2 dashboard
- [ ] Đã verify database records
- [ ] Đã test download URLs
- [ ] Đã viết release notes
- [ ] Đã test update dialog trên app
- [ ] Đã thông báo cho users (nếu major update)

---

**Happy Releasing! 🚀**
