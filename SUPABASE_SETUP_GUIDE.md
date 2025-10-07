# 🚀 Hướng dẫn Setup Supabase Database

## ⚡ QUICK FIX - Nếu gặp lỗi "is_online column not found"

### Cách 1: Fix nhanh (5 phút)

1. **Mở Supabase Dashboard**: https://app.supabase.com
2. **Chọn project của bạn**
3. **Vào SQL Editor** (icon database bên trái)
4. **Click "New query"**
5. **Copy toàn bộ file `fix_users_table.sql`** và paste vào
6. **Click "Run"** (hoặc nhấn Ctrl+Enter)
7. **Khởi động lại app Flutter**

✅ **Done!** Lỗi sẽ mất ngay!

---

## 🏗️ FULL SETUP - Lần đầu tiên setup database

### Bước 1: Tạo Database Tables

1. **Mở Supabase Dashboard**: https://app.supabase.com
2. **Chọn project** → **SQL Editor** → **New query**
3. **Copy toàn bộ file `supabase_schema.sql`** (330 lines)
4. **Paste vào SQL Editor**
5. **Click "Run"**

Kết quả:

- ✅ Tạo 4 tables: `users`, `conversations`, `messages`, `typing_indicators`
- ✅ Tạo indexes cho performance
- ✅ Enable Row Level Security (RLS)
- ✅ Tạo functions và triggers

### Bước 2: Tạo Storage Buckets

**Option A - Qua Dashboard (Recommended):**

1. **Vào Storage** (icon folder bên trái)
2. **Click "New bucket"**
3. Tạo 2 buckets:
   - `chat_attachments` (Public: ✅)
   - `avatars` (Public: ✅)
4. **Click "Create"**

**Option B - Qua Script:**

```bash
cd lib/scripts
flutter run storage_setup.dart
```

### Bước 3: Configure RLS Policies

RLS policies đã được tạo tự động khi chạy `supabase_schema.sql`.

Verify bằng cách:

1. **Vào Authentication** → **Policies**
2. **Check các tables có policies:**
   - ✅ `users`: SELECT, INSERT, UPDATE
   - ✅ `messages`: SELECT, INSERT, DELETE
   - ✅ `typing_indicators`: SELECT, INSERT, DELETE

### Bước 4: Update Config trong Flutter

Edit file `lib/config/supabase_config.dart`:

```dart
const supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
const supabaseAnonKey = 'YOUR_ANON_KEY';
```

Lấy URL và key từ:
**Supabase Dashboard** → **Settings** → **API**

---

## 🔍 Verify Setup thành công

### Check Database:

```sql
-- Check tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Check users table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Check RLS enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

Expected result:

- ✅ 4 tables: `conversations`, `messages`, `typing_indicators`, `users`
- ✅ users table có columns: `id`, `email`, `display_name`, `photo_url`, `is_online`, `last_seen`
- ✅ All tables có `rowsecurity = true`

### Check Storage:

1. Vào **Storage** → **Buckets**
2. Should see:
   - ✅ `chat_attachments` (Public)
   - ✅ `avatars` (Public)

---

## 🐛 Troubleshooting

### Lỗi: "relation 'users' does not exist"

**Fix:** Chạy `supabase_schema.sql` trong SQL Editor

### Lỗi: "column 'is_online' does not exist"

**Fix:** Chạy `fix_users_table.sql` trong SQL Editor

### Lỗi: "row-level security policy violation"

**Fix:**

1. Check RLS enabled: `ALTER TABLE users ENABLE ROW LEVEL SECURITY;`
2. Recreate policies trong `supabase_schema.sql`

### Lỗi: "bucket does not exist"

**Fix:** Tạo buckets qua Dashboard hoặc chạy `storage_setup.dart`

### Lỗi: "Invalid JWT"

**Fix:**

1. Check `supabase_config.dart` có đúng URL và key
2. Check key là **anon key** (NOT service_role key)

### Lỗi: "Cannot coerce the result to a single JSON object" (PGRST116)

**Nguyên nhân:** Query không trả về data (0 rows) khi code expect 1 row

**Fix:**

1. ✅ **Đã tự động fix trong code** - Service sẽ tự tạo user profile khi login
2. Run `fix_users_table.sql` để verify table structure
3. Restart app sau khi run SQL

**Nếu vẫn lỗi:** Check RLS policies có cho phép INSERT/SELECT không

---

## 📚 Tài nguyên

- **Supabase Docs**: https://supabase.com/docs
- **SQL Schema**: `supabase_schema.sql`
- **Quick Fix**: `fix_users_table.sql`
- **Storage Setup**: `lib/scripts/storage_setup.dart`
- **Migration Guide**: `MIGRATION_COMPLETE.md`

---

## ✅ Checklist

Trước khi chạy app, đảm bảo:

- [ ] Supabase project đã tạo
- [ ] `supabase_schema.sql` đã chạy xong (hoặc `fix_users_table.sql`)
- [ ] Storage buckets đã tạo: `chat_attachments`, `avatars`
- [ ] `supabase_config.dart` đã update URL và key
- [ ] RLS policies đã enable
- [ ] Test login: Tạo user mới và login thành công

---

**Need help?** Check `MIGRATION_COMPLETE.md` for detailed migration info.
