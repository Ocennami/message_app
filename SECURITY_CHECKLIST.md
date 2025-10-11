# 🔒 Security Checklist - Files KHÔNG được push lên GitHub

## ✅ Đã bảo vệ trong `.gitignore`

### 1. **Configuration Files với Credentials**

```
lib/config/r2_config.dart          ✅ Ignored (Cloudflare R2)
lib/config/supabase_config.dart    ✅ Ignored (Supabase)
lib/config/giphy_config.dart       ✅ Ignored (Giphy API/SDK keys)
```

### 2. **Environment Files**

```
.env                               ✅ Ignored
.env.local                         ✅ Ignored
```

### 3. **Keys & Certificates**

```
*.key                              ✅ Ignored
*.pem                              ✅ Ignored
```

### 4. **Build Artifacts**

```
/build/                            ✅ Ignored
/coverage/                         ✅ Ignored
.dart_tool/                        ✅ Ignored
```

---

## 📋 Checklist trước khi commit

### Bước 1: Verify `.gitignore`

```bash
# Check file đã được ignore chưa
git check-ignore lib/config/r2_config.dart
git check-ignore lib/config/supabase_config.dart
git check-ignore lib/config/giphy_config.dart
```

**Kết quả mong đợi**: Tất cả đều hiển thị path (có nghĩa đã được ignore)

### Bước 2: Check staged files

```bash
# Xem file nào sẽ được commit
git status
```

**KHÔNG được có**:

- ❌ `lib/config/*_config.dart` (ngoại trừ `.template` files)
- ❌ `.env` files
- ❌ `*.key`, `*.pem` files

### Bước 3: Search for hardcoded secrets

```bash
# Check hardcoded keys trong code
git grep -i "api_key\|apikey\|secret\|password\|token"
```

**Phải đảm bảo**: Tất cả keys đều import từ config files, không hardcode!

---

## 🔑 Keys Management

### Desktop/Web API Key

- **File**: `lib/config/giphy_config.dart`
- **Variable**: `GiphyConfig.apiKey`
- **Type**: API
- **Used in**: `discord_style_picker.dart`

### Android SDK Key

- **File**: `lib/config/giphy_config.dart`
- **Variable**: `GiphyConfig.androidSdkKey`
- **Type**: Android SDK
- **Used in**: `home_screen.dart` (Platform.isAndroid)

### iOS SDK Key

- **File**: `lib/config/giphy_config.dart`
- **Variable**: `GiphyConfig.iosSdkKey`
- **Type**: iOS SDK
- **Used in**: `home_screen.dart` (Platform.isIOS)

### Cloudflare R2

- **File**: `lib/config/r2_config.dart`
- **Contains**: Account ID, Access Key, Secret Key, Endpoint, Bucket name

### Supabase

- **File**: `lib/config/supabase_config.dart`
- **Contains**: URL, Anon Key, Service Role Key

---

## 🚀 Setup cho Developer mới

### Nếu bạn clone project này:

1. **Copy template files**:

   ```bash
   cp lib/config/giphy_config.dart.template lib/config/giphy_config.dart
   cp lib/config/r2_config.dart.template lib/config/r2_config.dart
   cp lib/config/supabase_config.dart.template lib/config/supabase_config.dart
   ```

2. **Lấy API keys**:

   - Giphy: https://developers.giphy.com/dashboard/
   - Cloudflare R2: Cloudflare Dashboard → R2
   - Supabase: https://supabase.com/dashboard

3. **Update config files** với keys thật

4. **Verify không commit secrets**:
   ```bash
   git status
   # Không được thấy lib/config/*_config.dart (chỉ thấy *.template)
   ```

---

## ⚠️ Lỗi thường gặp

### ❌ "Import error: giphy_config.dart not found"

**Nguyên nhân**: Chưa tạo `giphy_config.dart` từ template

**Fix**:

```bash
cp lib/config/giphy_config.dart.template lib/config/giphy_config.dart
# Sau đó update keys trong file
```

### ❌ "Unauthorized" khi dùng GIF picker

**Nguyên nhân**: API key không đúng hoặc chưa update

**Fix**:

1. Check `lib/config/giphy_config.dart`
2. Verify keys từ Giphy Dashboard
3. Hot reload app

### ❌ Accidentally committed secrets

**Fix ngay**:

```bash
# Remove from staging
git reset lib/config/r2_config.dart

# Remove from history (nếu đã commit)
git filter-branch --index-filter \
  "git rm --cached --ignore-unmatch lib/config/r2_config.dart" HEAD

# Force push (NGUY HIỂM - chỉ dùng nếu chưa có người khác pull)
git push --force
```

**Sau đó**:

1. Revoke API keys cũ ngay lập tức!
2. Tạo keys mới
3. Update vào config files

---

## 📚 Best Practices

### ✅ DO

- ✅ Luôn dùng config files cho credentials
- ✅ Add config files vào `.gitignore` ngay từ đầu
- ✅ Tạo `.template` files để hướng dẫn
- ✅ Document rõ ràng trong README
- ✅ Review changes trước khi commit

### ❌ DON'T

- ❌ KHÔNG hardcode API keys trong code
- ❌ KHÔNG commit credentials lên GitHub
- ❌ KHÔNG share credentials qua chat/email
- ❌ KHÔNG dùng same key cho dev và production
- ❌ KHÔNG ignore errors từ git check-ignore

---

## 🔍 Audit Log

**Last security audit**: October 11, 2025

**Findings**:

- ✅ All credentials moved to config files
- ✅ All config files in `.gitignore`
- ✅ Template files created
- ✅ No hardcoded secrets in codebase

**Action items**:

- [ ] Revoke old hardcoded keys (if already pushed)
- [ ] Create new keys
- [ ] Update team about new setup

---

**Made with 🔒 by Oceanami**
