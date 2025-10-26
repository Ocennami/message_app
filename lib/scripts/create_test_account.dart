// Script để tạo tài khoản test với email chứa 'username' và mật khẩu '11111111'
// Chạy script này để tạo tài khoản demo

import '../config/supabase_config.dart';

// Thông tin tài khoản test
const String testEmail = 'username@example.com';
const String testPassword = '11111111';
const String testDisplayName = 'username';

Future<void> createTestAccount() async {
  try {
    // Initialize Supabase
    await SupabaseConfig.initialize();
    final client = SupabaseConfig.client;

    print('🔄 Đang tạo tài khoản test...');
    print('Email: $testEmail');
    print('Password: $testPassword');

    // Tạo tài khoản
    final response = await client.auth.signUp(
      email: testEmail,
      password: testPassword,
      data: {'display_name': testDisplayName},
    );

    if (response.user != null) {
      print('✅ Tạo tài khoản thành công!');
      print('User ID: ${response.user!.id}');
      print('Email: ${response.user!.email}');

      // Tạo user profile trong database
      await client.from('users').upsert({
        'id': response.user!.id,
        'email': testEmail,
        'display_name': testDisplayName,
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      print('✅ Tạo user profile thành công!');
      print('');
      print('🎯 Bây giờ bạn có thể đăng nhập với:');
      print('   Email: $testEmail');
      print('   Password: $testPassword');
      print('');
      print('📱 App sẽ tự động chuyển đến màn hình cập nhật thông tin');
      print('   khi đăng nhập với tài khoản này.');
    } else {
      print('❌ Không thể tạo tài khoản');
      if (response.session == null) {
        print('Session null - có thể email đã tồn tại');
      }
    }
  } catch (e) {
    print('❌ Lỗi khi tạo tài khoản: $e');

    // Nếu lỗi là email đã tồn tại, thông báo cho user
    if (e.toString().contains('User already registered')) {
      print('');
      print('ℹ️  Tài khoản đã tồn tại. Bạn có thể đăng nhập với:');
      print('   Email: $testEmail');
      print('   Password: $testPassword');
    }
  }
}

// Hàm để xóa tài khoản test (nếu cần)
Future<void> deleteTestAccount() async {
  try {
    await SupabaseConfig.initialize();
    final client = SupabaseConfig.client;

    print('🔄 Đang đăng nhập để xóa tài khoản...');

    // Đăng nhập trước
    final signInResponse = await client.auth.signInWithPassword(
      email: testEmail,
      password: testPassword,
    );

    if (signInResponse.user != null) {
      final userId = signInResponse.user!.id;

      // Xóa user profile từ database
      await client.from('users').delete().eq('id', userId);
      print('✅ Đã xóa user profile');

      // Đăng xuất
      await client.auth.signOut();
      print('✅ Đã đăng xuất');

      print('⚠️  Lưu ý: Tài khoản auth vẫn tồn tại trong Supabase Auth');
      print('   Cần xóa thủ công từ Supabase Dashboard nếu muốn xóa hoàn toàn');
    } else {
      print('❌ Không thể đăng nhập để xóa tài khoản');
    }
  } catch (e) {
    print('❌ Lỗi khi xóa tài khoản: $e');
  }
}

// Main function để chạy script
void main() async {
  print('=== SCRIPT TẠO TÀI KHOẢN TEST ===');
  print('');

  // Uncomment dòng bạn muốn chạy:
  await createTestAccount();

  // Để xóa tài khoản test, uncomment dòng dưới:
  // await deleteTestAccount();
}
