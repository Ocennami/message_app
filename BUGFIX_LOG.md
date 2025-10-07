# 🔧 Bug Fixes Log - October 7, 2025

## ✅ Fixed Bugs:

### 1. **Missing 'is_online' Column Error** ❌→✅

**Error:** `PostgrestException: Could not find the 'is_online' column of 'users'`

**Root Cause:** Database schema thiếu columns `is_online` và `last_seen`

**Fix:**

- Created `fix_users_table.sql` migration script
- Adds missing columns with proper indexes
- Safe to run multiple times

**Status:** ✅ **FIXED** - Run `fix_users_table.sql` in Supabase SQL Editor

---

### 2. **PGRST116 - Single JSON Object Error** ❌→✅

**Error:** `Cannot coerce the result to a single JSON object, code: PGRST116, details: The result contains 0 rows`

**Root Cause:**

- Code looked for user with non-existent `firebase_uid` column
- SignIn didn't create user profile if not exists

**Fixes Applied:**

1. ✅ **Fixed `supabase_message_service.dart`**:

   - Changed `_getCurrentUserId()` to use Supabase Auth user.id directly
   - Removed lookup by `firebase_uid` (Firebase remnant)

2. ✅ **Fixed `supabase_auth_service.dart`**:
   - Added `_ensureUserProfile()` method with UPSERT
   - SignIn now creates user profile if not exists
   - Uses `onConflict: 'id'` for safe upsert

**Code Changes:**

```dart
// Before (BROKEN):
final response = await _client
    .from('users')
    .select('id')
    .eq('firebase_uid', user.id)  // ❌ Column doesn't exist
    .single();

// After (FIXED):
return user.id;  // ✅ Use Supabase Auth ID directly
```

**Status:** ✅ **FIXED** - Already applied in code

---

## 📊 Summary:

| Issue                      | Status     | Action Required           |
| -------------------------- | ---------- | ------------------------- |
| Missing `is_online` column | ✅ Fixed   | Run `fix_users_table.sql` |
| PGRST116 error             | ✅ Fixed   | Code already updated      |
| Firebase remnants          | ✅ Cleaned | No action needed          |

---

## 🚀 Next Steps:

1. **Run SQL Fix:**

   ```
   - Open Supabase Dashboard
   - Go to SQL Editor
   - Run fix_users_table.sql
   ```

2. **Restart App:**

   ```bash
   # Stop current app (Ctrl+C)
   flutter clean
   flutter run -d windows
   ```

3. **Test Login:**
   - Try login with existing account
   - User profile should auto-create
   - No more PGRST116 errors

---

## 🔍 Verification:

After fixes, check:

- ✅ App starts without errors
- ✅ Login works successfully
- ✅ User profile auto-created in `users` table
- ✅ Messages can be sent
- ✅ Real-time updates work

---

---

### 3. **Foreign Key Constraint Violation (23503)** ❌→⏳

**Error:** `insert or update on table "messages" violates foreign key constraint "messages_user_id_fkey"`

**Root Cause:**

- User authenticated in Supabase Auth
- But user profile NOT created in `users` table
- RLS policies too restrictive OR silent failures

**Fixes To Apply:**

1. ⏳ **Run `fix_user_rls_policies.sql`**:

   - Drops old restrictive policies
   - Creates new policies allowing authenticated users to insert/update profiles
   - Allows SELECT for all users (needed for chat)

2. ✅ **Code Updated**:
   - Added error logging in `_ensureUserProfile()`
   - Will show if profile creation fails

**Files Created:**

- `fix_user_rls_policies.sql` - Fix RLS policies
- `debug_user_creation.sql` - Diagnostic queries

**Status:** ⏳ **ACTION REQUIRED** - Run `fix_user_rls_policies.sql` first!

---

## 🚨 CRITICAL: Run SQL Fixes in Order!

```
1. ✅ fix_users_table.sql      (adds columns)
2. ⏳ fix_user_rls_policies.sql (fixes policies) ← RUN THIS NOW!
3. 🔍 debug_user_creation.sql  (optional - for debugging)
```

**After running SQL, restart app!** 🔄
