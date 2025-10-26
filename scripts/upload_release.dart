/// Script để upload release lên Supabase Storage và update database
///
/// Usage:
///   dart scripts/upload_release.dart <version> <platform> <file_path>
///
/// Example:
///   dart scripts/upload_release.dart 1.0.1 android build/app/outputs/apk/release/app-release.apk
///   dart scripts/upload_release.dart 1.0.1 windows build/windows/runner/Release/AllianceMessengerSetup.exe

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

// Import config
import '../lib/config/auto_update_config.dart';

// Alias for easier access
typedef Config = AutoUpdateConfig;

void main(List<String> args) async {
  if (args.length < 3) {
    print(
      '❌ Usage: dart scripts/upload_release.dart <version> <platform> <file_path>',
    );
    print('');
    print('Example:');
    print(
      '  dart scripts/upload_release.dart 1.0.1 android build/app/outputs/apk/release/app-release.apk',
    );
    exit(1);
  }

  final version = args[0];
  final platform = args[1].toLowerCase();
  final filePath = args[2];

  if (platform != 'android' && platform != 'windows') {
    print('❌ Platform must be "android" or "windows"');
    exit(1);
  }

  final file = File(filePath);
  if (!await file.exists()) {
    print('❌ File not found: $filePath');
    exit(1);
  }

  print('🚀 Starting release upload...');
  print('📦 Version: $version');
  print('🖥️  Platform: $platform');
  print('📄 File: $filePath');
  print('');

  try {
    // 1. Calculate SHA256
    print('🔐 Calculating SHA256 checksum...');
    final bytes = await file.readAsBytes();
    final sha256Hash = sha256.convert(bytes).toString();
    print('✅ SHA256: $sha256Hash');
    print('');

    // 2. Upload to Supabase Storage
    print('☁️  Uploading to Supabase Storage...');
    final storagePath = platform == 'android'
        ? Config.androidPath(version)
        : Config.windowsPath(version);

    final uploadUrl = Uri.parse(
      '${Config.supabaseUrl}/storage/v1/object/${Config.storageBucket}/$storagePath',
    );

    final uploadResponse = await http.post(
      uploadUrl,
      headers: {
        'Authorization': 'Bearer ${Config.supabaseServiceKey}',
        'Content-Type': 'application/octet-stream',
      },
      body: bytes,
    );

    if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 201) {
      print('❌ Upload failed: ${uploadResponse.statusCode}');
      print('Response: ${uploadResponse.body}');
      exit(1);
    }

    final publicUrl =
        '${Config.supabaseUrl}/storage/v1/object/public/${Config.storageBucket}/$storagePath';
    print('✅ Uploaded to: $publicUrl');
    print('');

    // 3. Insert/Update database record
    print('💾 Updating database...');

    // Check if version exists
    final checkUrl = Uri.parse(
      '${Config.supabaseUrl}/rest/v1/app_releases?version=eq.$version&select=id',
    );

    final checkResponse = await http.get(
      checkUrl,
      headers: {
        'apikey': Config.supabaseServiceKey,
        'Authorization': 'Bearer ${Config.supabaseServiceKey}',
      },
    );

    final exists =
        jsonDecode(checkResponse.body) is List &&
        (jsonDecode(checkResponse.body) as List).isNotEmpty;

    Map<String, dynamic> data = {
      'version': version,
      'is_active': true,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (platform == 'android') {
      data['android_download_url'] = publicUrl;
      data['android_sha256'] = sha256Hash;
    } else {
      data['windows_download_url'] = publicUrl;
      data['windows_sha256'] = sha256Hash;
    }

    http.Response dbResponse;

    if (exists) {
      // Update existing record
      print('📝 Updating existing release record...');
      final updateUrl = Uri.parse(
        '${Config.supabaseUrl}/rest/v1/app_releases?version=eq.$version',
      );

      dbResponse = await http.patch(
        updateUrl,
        headers: {
          'apikey': Config.supabaseServiceKey,
          'Authorization': 'Bearer ${Config.supabaseServiceKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(data),
      );
    } else {
      // Insert new record
      print('📝 Creating new release record...');
      data['release_notes'] = 'Release $version for $platform';

      final insertUrl = Uri.parse('${Config.supabaseUrl}/rest/v1/app_releases');

      dbResponse = await http.post(
        insertUrl,
        headers: {
          'apikey': Config.supabaseServiceKey,
          'Authorization': 'Bearer ${Config.supabaseServiceKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(data),
      );
    }

    if (dbResponse.statusCode != 200 && dbResponse.statusCode != 201) {
      print('❌ Database update failed: ${dbResponse.statusCode}');
      print('Response: ${dbResponse.body}');
      exit(1);
    }

    print('✅ Database updated successfully!');
    print('');
    print('🎉 Release uploaded successfully!');
    print('');
    print('📋 Summary:');
    print('   Version: $version');
    print('   Platform: $platform');
    print('   URL: $publicUrl');
    print('   SHA256: $sha256Hash');
    print('');
    print('✅ Users will receive update notification on next app launch!');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
