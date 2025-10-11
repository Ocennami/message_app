# ☀️ MORNING ACTION PLAN - Cleanup Leaked Credentials

**Ngày mai**: October 12, 2025
**Thời gian dự kiến**: 30 phút
**Mức độ**: ⚠️ Quan trọng nhưng không cần vội

---

## 📋 CHECKLIST SÁNG MAI

### ✅ Bước 1: Reset API Keys (10 phút)

#### Supabase (QUAN TRỌNG NHẤT)

**⚠️ Supabase KHÔNG có nút Reset trực tiếp!**

**Option A: Regenerate Keys** (nếu có trong UI mới)

- [ ] Mở https://supabase.com/dashboard
- [ ] Click vào project "MessageApp" / "Oceanami's Project"
- [ ] Settings → API Keys (menu bên trái)
- [ ] Scroll xuống phần "Project API keys"
- [ ] Tìm nút **"Generate new anon key"** hoặc **"Rotate"** (nếu có)
- [ ] Click để tạo key mới
- [ ] Copy `anon` key mới
- [ ] Click "Reveal" ở `service_role` → Copy
- [ ] Paste 2 keys vào `lib/config/supabase_config.dart`
- [ ] Save file

**Option B: Tạo Project Mới** (KHUYẾN NGHỊ - nhanh nhất!)

- [ ] Dashboard → **"New Project"**
- [ ] Name: MessageApp_v2
- [ ] Database Password: [tạo password mới]
- [ ] Region: Southeast Asia (Singapore) - gần Việt Nam nhất
- [ ] Click "Create new project" → Chờ ~2 phút
- [ ] Settings → API → Copy `URL`, `anon key`, `service_role key`
- [ ] Paste vào `lib/config/supabase_config.dart`
- [ ] Settings → Database → Query Editor
- [ ] Copy nội dung file `supabase_schema.sql` (trong project)
- [ ] Paste vào Query Editor → Run để tạo lại tables
- [ ] Save file

**Option C: Nếu repo là Private** (có thể skip tạm!)

- [ ] Nếu GitHub repo là **Private** → keys ít rủi ro hơn
- [ ] Có thể để nguyên keys cũ tạm thời
- [ ] Focus vào việc đảm bảo `.gitignore` đã protect config files

#### Cloudflare R2 (10 phút)

- [ ] Mở https://dash.cloudflare.com
- [ ] R2 → Manage R2 API Tokens
- [ ] Tìm token cũ → Click "Delete"
- [ ] Click "Create API Token"
- [ ] Chọn quyền: Object Read & Write
- [ ] Scope: Specific bucket → chọn `message_app_bucket`
- [ ] Click "Create"
- [ ] Copy Access Key ID và Secret Access Key
- [ ] Paste vào `lib/config/r2_config.dart` (file local)
- [ ] Save file

#### Giphy (5 phút - ít quan trọng)

- [ ] Mở https://developers.giphy.com/dashboard/
- [ ] Click vào app "message_app"
- [ ] Click "Regenerate Key" cho API Key
- [ ] Click "Regenerate Key" cho Android SDK
- [ ] Click "Regenerate Key" cho iOS SDK
- [ ] Copy 3 keys mới
- [ ] Paste vào `lib/config/giphy_config.dart`
- [ ] Save file

---

### ✅ Bước 2: Test App (5 phút)

```powershell
# Trong terminal PowerShell
cd C:\Users\Admin\Desktop\Application\message_app

# Clean build cũ
flutter clean

# Get dependencies
flutter pub get

# Run app
flutter run
```

**Test các chức năng**:

- [ ] Login/Register (Supabase)
- [ ] Upload ảnh (R2 Storage)
- [ ] Chọn GIF/Emoji (Giphy)

Nếu OK → Keys mới đang hoạt động! ✅

---

### ✅ Bước 3: Xóa Keys Cũ Khỏi Git History (15 phút)

**Option A: Dùng Git Filter-Repo (KHUYẾN NGHỊ cho Windows)**

```powershell
# 1. Install (nếu chưa có Python)
pip install git-filter-repo

# 2. Backup repo
cd C:\Users\Admin\Desktop\Application
Copy-Item -Recurse message_app message_app_backup

# 3. Clean history
cd message_app
git filter-repo --path lib/config/supabase_config.dart --invert-paths --force
git filter-repo --path lib/config/r2_config.dart --invert-paths --force

# 4. Add remote lại (filter-repo sẽ xóa remote)
git remote add origin https://github.com/Ocennami/message_app.git

# 5. Force push
git push origin --force --all
git push origin --force --tags
```

**Option B: Nếu không muốn cài thêm tool**

Có thể skip bước này nếu:

- Keys đã được reset → keys cũ không dùng được nữa
- Repo là private → ít rủi ro hơn
- Chỉ bạn một mình dùng project

**Lưu ý**: Vẫn nên clean history để đảm bảo 100% an toàn!

---

## 🆘 NẾU GẶP VẤN ĐỀ

### "pip: command not found"

**Fix**:

```powershell
# Install Python từ Microsoft Store
# Hoặc tải từ: https://www.python.org/downloads/
```

### "git-filter-repo: command not found"

**Fix**:

```powershell
# Sau khi install, thêm vào PATH:
$env:Path += ";C:\Users\Admin\AppData\Local\Programs\Python\Python3X\Scripts"
```

### "Cannot force push"

**Fix**:

```powershell
# Disable branch protection trên GitHub:
# Settings → Branches → master → Edit → Tắt "Require pull request reviews"
# Sau đó push lại
git push origin --force --all
```

### "App bị lỗi sau khi đổi keys"

**Nguyên nhân**: Keys mới chưa update đúng

**Fix**:

1. Double-check keys trong 3 config files
2. Chắc chắn không có space thừa
3. Keys phải nằm trong dấu quotes `'...'`
4. Run lại `flutter clean && flutter pub get`

---

## 📝 NOTES CHO BẠN

### Tại sao phải làm?

- Keys cũ đã public trên GitHub → ai cũng có thể dùng
- Có thể bị tấn công: spam database, upload file lạ, abuse API quota
- Reset keys = làm keys cũ vô hiệu → bảo vệ app

### Có gấp không?

- **Supabase/R2**: Nên làm sớm (có thể bị truy cập database/storage)
- **Giphy**: Ít gấp hơn (chỉ mất quota API miễn phí)
- **Clean Git**: Có thể làm sau (keys đã reset thì keys cũ vô dụng)

### Tôi có thể delay được không?

Được! Nhưng:

- Nếu repo là **public** → nên làm sáng mai
- Nếu repo là **private** → có thể delay 1-2 ngày (nhưng không nên)

---

## ⏰ TIMELINE SÁNG MAI

| Giờ  | Việc                         | Time   |
| ---- | ---------------------------- | ------ |
| 8:00 | ☕ Uống cà phê, tỉnh táo     | 5 min  |
| 8:05 | Reset Supabase keys          | 5 min  |
| 8:10 | Reset R2 keys                | 5 min  |
| 8:15 | Reset Giphy keys             | 3 min  |
| 8:18 | Update local config files    | 2 min  |
| 8:20 | Test app                     | 5 min  |
| 8:25 | Clean Git history (optional) | 15 min |
| 8:40 | ✅ **XONG!**                 | -      |

---

## 📞 CẦN TRỢ GIÚP?

Sáng mai nếu bạn gặp vấn đề:

1. Đọc lại file `EMERGENCY_CLEANUP.md` (chi tiết đầy đủ)
2. Check phần "🆘 NẾU GẶP VẤN ĐỀ" ở trên
3. Hỏi tôi tiếp (tôi luôn sẵn sàng!)

---

## 🎯 MỤC TIÊU

**Sau khi làm xong**:

- ✅ Keys cũ không dùng được nữa (revoked)
- ✅ App chạy bình thường với keys mới
- ✅ Git history sạch (nếu clean)
- ✅ Yên tâm push code lên GitHub

---

**Good night! Ngủ ngon nhé!** 😴🌙

Tomorrow you got this! 💪
