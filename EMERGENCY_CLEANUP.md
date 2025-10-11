# 🚨 EMERGENCY: Leaked Credentials Cleanup Guide

## ⚠️ TÌNH HUỐNG

**Credentials đã bị leak lên GitHub trong commit cũ!**

- **Commit**: df8cb185dfab5b8607af77c9ebf0a746e6b5739d
- **Date**: Oct 7, 2025
- **File**: `lib/config/supabase_config.dart`
- **Có thể có thêm**: R2 config, Giphy keys trong commits khác

## 🔴 BƯỚC 1: REVOKE KEYS NGAY (QUAN TRỌNG NHẤT!)

### Supabase Keys

1. Truy cập: https://supabase.com/dashboard
2. Chọn project → Settings → API
3. Click **"Reset"** cho:
   - ❌ `anon/public` key
   - ❌ `service_role` key (nếu có)
4. Copy keys mới
5. Update vào `lib/config/supabase_config.dart` (local)

### Cloudflare R2 Keys

1. Truy cập: https://dash.cloudflare.com
2. R2 → Manage R2 API Tokens
3. Tìm token cũ → **Delete**
4. Create new token với quyền:
   - Object Read & Write
   - Scope: Specific bucket (message_app_bucket)
5. Copy Access Key + Secret Key
6. Update vào `lib/config/r2_config.dart` (local)

### Giphy Keys (ít nguy hiểm hơn nhưng nên reset)

1. Truy cập: https://developers.giphy.com/dashboard/
2. Your Apps → message_app
3. Click "Regenerate Key"
4. Copy keys mới (API + SDK)
5. Update vào `lib/config/giphy_config.dart` (local)

---

## 🧹 BƯỚC 2: XÓA CREDENTIALS KHỎI GIT HISTORY

### Option A: BFG Repo-Cleaner (KHUYẾN NGHỊ)

**Nhanh và an toàn nhất!**

1. **Download BFG**:

   ```bash
   # Tải từ: https://rtyley.github.io/bfg-repo-cleaner/
   # Hoặc dùng Chocolatey:
   choco install bfg-repo-cleaner
   ```

2. **Backup repository**:

   ```bash
   cd C:\Users\Admin\Desktop\Application
   cp -r message_app message_app_backup
   ```

3. **Clone bare repository**:

   ```bash
   git clone --mirror https://github.com/Ocennami/message_app.git message_app-bare.git
   cd message_app-bare.git
   ```

4. **Remove sensitive files**:

   ```bash
   bfg --delete-files "supabase_config.dart" --no-blob-protection
   bfg --delete-files "r2_config.dart" --no-blob-protection
   bfg --delete-files "giphy_config.dart" --no-blob-protection
   ```

5. **Clean up**:

   ```bash
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```

6. **Force push**:

   ```bash
   git push --force
   ```

7. **Update local repo**:
   ```bash
   cd ../message_app
   git fetch origin
   git reset --hard origin/master
   ```

### Option B: Git Filter-Repo (Nếu không có BFG)

1. **Install git-filter-repo**:

   ```bash
   pip install git-filter-repo
   ```

2. **Backup**:

   ```bash
   cd C:\Users\Admin\Desktop\Application
   cp -r message_app message_app_backup
   cd message_app
   ```

3. **Remove files from history**:

   ```bash
   git filter-repo --path lib/config/supabase_config.dart --invert-paths
   git filter-repo --path lib/config/r2_config.dart --invert-paths
   git filter-repo --path lib/config/giphy_config.dart --invert-paths
   ```

4. **Force push**:
   ```bash
   git remote add origin https://github.com/Ocennami/message_app.git
   git push --force --all
   git push --force --tags
   ```

### Option C: Manual (Không khuyến nghị - phức tạp)

```bash
# Tìm commits chứa sensitive files
git log --all --full-history -- "lib/config/*.dart"

# Rewrite từng commit
git filter-branch --index-filter \
  "git rm --cached --ignore-unmatch lib/config/supabase_config.dart lib/config/r2_config.dart lib/config/giphy_config.dart" \
  --prune-empty --tag-name-filter cat -- --all

# Force push
git push --force --all
git push --force --tags
```

---

## 🔒 BƯỚC 3: VERIFY XÓA THÀNH CÔNG

1. **Check GitHub history**:

   ```bash
   # Trên GitHub web
   https://github.com/Ocennami/message_app/commits/master
   # Tìm kiếm "config" trong commits
   ```

2. **Search trên GitHub**:

   - Vào repository → Code
   - Search: `supabase_config.dart`
   - Search: `r2_config.dart`
   - **Kết quả phải**: "We couldn't find any code matching..."

3. **Check local**:
   ```bash
   git log --all --full-history -- "lib/config/*.dart"
   # Phải không có kết quả nào!
   ```

---

## ✅ BƯỚC 4: SETUP LẠI AN TOÀN

1. **Recreate config files với keys MỚI**:

   ```bash
   cp lib/config/supabase_config.dart.template lib/config/supabase_config.dart
   cp lib/config/r2_config.dart.template lib/config/r2_config.dart
   cp lib/config/giphy_config.dart.template lib/config/giphy_config.dart
   ```

2. **Update keys mới** (đã reset ở BƯỚC 1)

3. **Verify .gitignore**:

   ```bash
   git check-ignore lib/config/supabase_config.dart
   git check-ignore lib/config/r2_config.dart
   git check-ignore lib/config/giphy_config.dart
   # Tất cả phải show path (= đã ignored)
   ```

4. **Test app** với keys mới:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 📢 BƯỚC 5: THÔNG BÁO TEAM (nếu có)

**Email template**:

```
Subject: URGENT: Security Incident - Credentials Leaked

Team,

We discovered that sensitive credentials were accidentally pushed to our
GitHub repository on Oct 7, 2025.

Actions taken:
✅ All affected API keys have been revoked and regenerated
✅ Git history has been cleaned
✅ .gitignore updated to prevent future incidents

Actions required:
🔹 Pull latest changes: git fetch origin && git reset --hard origin/master
🔹 Recreate local config files from .template files
🔹 Request new API keys from admin

Affected services:
- Supabase
- Cloudflare R2
- Giphy API

No user data was compromised. Only internal API keys were exposed.

Thanks,
[Your Name]
```

---

## 🛡️ BƯỚC 6: PREVENT FUTURE LEAKS

1. **Setup pre-commit hook**:

   ```bash
   # Tạo file .git/hooks/pre-commit
   #!/bin/sh

   # Check for sensitive files
   if git diff --cached --name-only | grep -E "lib/config/.*_config\.dart$" | grep -v "\.template$"; then
     echo "❌ ERROR: Attempting to commit sensitive config file!"
     echo "Only .template files are allowed."
     exit 1
   fi

   # Check for hardcoded secrets
   if git diff --cached | grep -iE "api_key|apikey|secret|password|token" | grep -v "template"; then
     echo "⚠️  WARNING: Potential secret detected in commit!"
     echo "Review your changes carefully."
   fi
   ```

2. **Make it executable**:

   ```bash
   chmod +x .git/hooks/pre-commit
   ```

3. **Use GitHub Secret Scanning**:

   - Repository → Settings → Security
   - Enable "Secret scanning"
   - Enable "Push protection"

4. **Regular audits**:
   ```bash
   # Monthly check
   git log --all --full-history --source --patch -- "lib/config/"
   ```

---

## ⏰ TIMELINE

| Priority    | Action                  | Time           |
| ----------- | ----------------------- | -------------- |
| 🔴 CRITICAL | Revoke all API keys     | **5 minutes**  |
| 🟠 HIGH     | Clean Git history (BFG) | **15 minutes** |
| 🟡 MEDIUM   | Verify cleanup          | **10 minutes** |
| 🟢 LOW      | Setup monitoring        | **30 minutes** |

**TOTAL**: ~1 hour để fix hoàn toàn

---

## 📞 SUPPORT

- **BFG Repo-Cleaner**: https://rtyley.github.io/bfg-repo-cleaner/
- **Git Filter-Repo**: https://github.com/newren/git-filter-repo
- **GitHub Support**: https://support.github.com/

---

## 🔍 CHECKLIST

- [ ] Revoked Supabase keys
- [ ] Revoked R2 keys
- [ ] Revoked Giphy keys
- [ ] Backed up repository
- [ ] Ran BFG/filter-repo
- [ ] Force pushed cleaned history
- [ ] Verified files removed from GitHub
- [ ] Updated local config with new keys
- [ ] Tested app with new keys
- [ ] Notified team (if applicable)
- [ ] Setup pre-commit hook
- [ ] Enabled GitHub secret scanning

---

**Created**: October 11, 2025
**Status**: 🚨 ACTIVE INCIDENT
