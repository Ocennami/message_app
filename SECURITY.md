# 🔐 Security Configuration Guide

## ⚠️ QUAN TRỌNG: Các file KHÔNG được commit vào Git

Các file sau chứa thông tin nhạy cảm và **KHÔNG BAO GIỜ** được push lên GitHub:

### 📁 Files cần bảo mật:

1. **`lib/config/auto_update_config.dart`**

   - Chứa: Supabase Service Role Key
   - Template: `lib/config/auto_update_config.dart.template`

2. **`android/app/google-services.json`**

   - Chứa: Firebase API keys
   - Template: `android/app/google-services.json.template`

3. **`website/.env.local`**

   - Chứa: Environment variables cho Next.js
   - Template: Xem `website/.env.example`

4. **`lib/config/supabase_config.dart`**

   - Template: `lib/config/supabase_config.dart.template`

5. **`lib/config/giphy_config.dart`**
   - Template: `lib/config/giphy_config.dart.template`

---

## 🛠️ Setup cho Developer mới

### Bước 1: Copy template files

```bash
# Auto-update config
cp lib/config/auto_update_config.dart.template lib/config/auto_update_config.dart

# Firebase config
cp android/app/google-services.json.template android/app/google-services.json

# Supabase config (nếu có)
cp lib/config/supabase_config.dart.template lib/config/supabase_config.dart

# Giphy config (nếu có)
cp lib/config/giphy_config.dart.template lib/config/giphy_config.dart
```

### Bước 2: Chạy setup script

```bash
# Windows PowerShell
.\scripts\easy_setup.ps1

# Linux/Mac
bash scripts/setup_auto_update.sh
```

### Bước 3: Nhập thông tin

Script sẽ hướng dẫn bạn nhập:

- Supabase URL
- Supabase Anon Key
- Supabase Service Role Key
- Website URL (optional)

---

## 🔍 Kiểm tra trước khi commit

### Trước mỗi lần commit, chạy:

```bash
# Kiểm tra xem có file nhạy cảm nào sắp được commit không
git status

# Nếu thấy các file sau, ĐỪNG commit:
# - lib/config/auto_update_config.dart
# - android/app/google-services.json
# - website/.env.local
# - *.key, *.pem
```

### Nếu đã commit nhầm:

```bash
# Xóa file khỏi git (giữ lại local)
git rm --cached <file-path>

# Commit việc xóa
git commit -m "Remove sensitive file from git"

# Push
git push
```

---

## 🚨 Nếu SECRET KEY đã bị lộ

### 1. Đối với Supabase Service Role Key:

1. Vào **Supabase Dashboard** → **Settings** → **API**
2. Bấm **Reset Service Role Key**
3. Cập nhật key mới vào `auto_update_config.dart`
4. Chạy lại setup script

### 2. Đối với Firebase:

1. Vào **Firebase Console** → **Project Settings**
2. Xóa và tạo lại Firebase app
3. Download `google-services.json` mới
4. Replace file cũ

### 3. Đối với GitHub:

1. Xóa repository và tạo lại (nếu cần)
2. Hoặc dùng `git filter-branch` để xóa history

---

## ✅ Best Practices

1. **KHÔNG BAO GIỜ** commit trực tiếp các file config
2. **LUÔN** dùng template files
3. **KIỂM TRA** `.gitignore` thường xuyên
4. **SỬ DỤNG** setup scripts để tự động hóa
5. **ROTATE** keys định kỳ (3-6 tháng/lần)

---

## 📝 File `.gitignore` hiện tại

Đảm bảo `.gitignore` có các dòng sau:

```gitignore
# Security - DO NOT COMMIT credentials
lib/config/r2_config.dart
lib/config/supabase_config.dart
lib/config/giphy_config.dart
lib/config/auto_update_config.dart
website/.env.local
.env
.env.local
*.key
*.pem
google-services.json
android/app/google-services.json
```

---

## 🆘 Support

Nếu có vấn đề về security, liên hệ:

- Email: security@yourcompany.com
- Tạo issue riêng tư trên GitHub

**LƯU Ý:** KHÔNG bao giờ post sensitive keys/tokens trong GitHub Issues!
