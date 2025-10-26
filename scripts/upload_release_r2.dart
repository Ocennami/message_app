/// Script để upload release lên Cloudflare R2 và update Supabase database
///
/// Usage:
///   dart scripts/upload_release_r2.dart <version> <platform> <file_path>
///
/// Example:
///   dart scripts/upload_release_r2.dart 1.0.1 android build/app/outputs/apk/release/app-release.apk
///   dart scripts/upload_release_r2.dart 1.0.1 windows build/windows/runner/Release/AllianceMessengerSetup.exe

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

// Import configs
import '../lib/config/r2_config.dart';
import '../lib/config/auto_update_config.dart';

/// Simple AWS Signature V4 implementation for R2
class SimpleAwsSigner {
  final String accessKey;
  final String secretKey;
  final String region;
  final String service;

  SimpleAwsSigner({
    required this.accessKey,
    required this.secretKey,
    this.region = 'auto',
    this.service = 's3',
  });

  Map<String, String> signRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    List<int>? body,
  }) {
    final dateTime = DateTime.now().toUtc();
    final dateStamp = _formatDate(dateTime);
    final amzDate = _formatDateTime(dateTime);

    // Add required headers
    final signedHeaders = Map<String, String>.from(headers);
    signedHeaders['host'] = uri.host;
    signedHeaders['x-amz-date'] = amzDate;
    signedHeaders['x-amz-content-sha256'] = body != null
        ? sha256.convert(body).toString()
        : 'UNSIGNED-PAYLOAD';

    // Create canonical request
    final headerKeys = signedHeaders.keys.toList()..sort();
    final canonicalHeaders = headerKeys
        .map((key) => '${key.toLowerCase()}:${signedHeaders[key]!.trim()}')
        .join('\n');
    final signedHeadersList = headerKeys.map((k) => k.toLowerCase()).join(';');

    final payloadHash = signedHeaders['x-amz-content-sha256']!;
    final canonicalRequest = [
      method,
      uri.path,
      uri.query,
      '$canonicalHeaders\n',
      signedHeadersList,
      payloadHash,
    ].join('\n');

    // Create string to sign
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    // Calculate signature
    final signature = _calculateSignature(dateStamp, stringToSign);

    // Create authorization header
    final authorization =
        'AWS4-HMAC-SHA256 '
        'Credential=$accessKey/$credentialScope, '
        'SignedHeaders=$signedHeadersList, '
        'Signature=$signature';

    signedHeaders['Authorization'] = authorization;
    return signedHeaders;
  }

  String _calculateSignature(String dateStamp, String stringToSign) {
    final kDate = _hmacSha256(
      utf8.encode('AWS4$secretKey'),
      utf8.encode(dateStamp),
    );
    final kRegion = _hmacSha256(kDate, utf8.encode(region));
    final kService = _hmacSha256(kRegion, utf8.encode(service));
    final kSigning = _hmacSha256(kService, utf8.encode('aws4_request'));
    final signature = _hmacSha256(kSigning, utf8.encode(stringToSign));
    return signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  List<int> _hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime dt) =>
      '${_formatDate(dt)}T${dt.hour.toString().padLeft(2, '0')}'
      '${dt.minute.toString().padLeft(2, '0')}'
      '${dt.second.toString().padLeft(2, '0')}Z';
}

void main(List<String> args) async {
  if (args.length < 3) {
    print(
      '❌ Usage: dart scripts/upload_release_r2.dart <version> <platform> <file_path>',
    );
    print('');
    print('Example:');
    print(
      '  dart scripts/upload_release_r2.dart 1.0.1 android build/app/outputs/apk/release/app-release.apk',
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

  // Check R2 config
  if (!R2Config.isConfigured) {
    print('❌ R2 is not configured!');
    print('Please update lib/config/r2_config.dart with your credentials');
    exit(1);
  }

  print('🚀 Starting release upload to Cloudflare R2...');
  print('📦 Version: $version');
  print('🖥️  Platform: $platform');
  print('📄 File: $filePath');
  print('');

  try {
    // 1. Calculate SHA256
    print('🔐 Calculating SHA256 checksum...');
    final bytes = await file.readAsBytes();
    final fileSize = bytes.length;
    final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
    final sha256Hash = sha256.convert(bytes).toString();
    print('✅ SHA256: $sha256Hash');
    print('📊 File size: $fileSizeMB MB');
    print('');

    // 2. Prepare R2 path
    final fileName = platform == 'android'
        ? 'android/v$version/app-release.apk'
        : 'windows/v$version/AllianceMessengerSetup.exe';

    print('☁️  Uploading to Cloudflare R2...');
    print('📁 Bucket: ${R2Config.releasesBucketName}');
    print('📍 Path: $fileName');

    // 3. Upload to R2 using S3-compatible API
    final endpoint = R2Config.endpoint;
    final bucketName = R2Config.releasesBucketName;

    // Create AWS signer with releases credentials (or default if not set)
    final signer = SimpleAwsSigner(
      accessKey: R2Config.getAccessKeyId(forReleases: true),
      secretKey: R2Config.getSecretAccessKey(forReleases: true),
      region: 'auto',
      service: 's3',
    );

    // Prepare request URL
    final path = '/$bucketName/$fileName';
    final uri = Uri.parse('$endpoint$path');

    // Sign the request
    final signedHeaders = signer.signRequest(
      method: 'PUT',
      uri: uri,
      headers: {'content-type': 'application/octet-stream'},
      body: bytes,
    );

    final response = await http.put(uri, headers: signedHeaders, body: bytes);

    if (response.statusCode != 200 && response.statusCode != 204) {
      print('❌ R2 upload failed: ${response.statusCode}');
      print('Response: ${response.body}');
      exit(1);
    }

    final publicUrl = R2Config.getReleasePublicUrl(fileName);
    print('✅ Uploaded to R2!');
    print('🔗 Public URL: $publicUrl');
    print('');

    // 4. Update Supabase database
    print('💾 Updating Supabase database...');

    // Check if version exists
    final checkUrl = Uri.parse(
      '${AutoUpdateConfig.supabaseUrl}/rest/v1/app_releases?version=eq.$version&select=id',
    );

    final checkResponse = await http.get(
      checkUrl,
      headers: {
        'apikey': AutoUpdateConfig.supabaseServiceKey,
        'Authorization': 'Bearer ${AutoUpdateConfig.supabaseServiceKey}',
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
      data['android_file_size'] = fileSize;
    } else {
      data['windows_download_url'] = publicUrl;
      data['windows_sha256'] = sha256Hash;
      data['windows_file_size'] = fileSize;
    }

    http.Response dbResponse;

    if (exists) {
      // Update existing record
      print('📝 Updating existing release record...');
      final updateUrl = Uri.parse(
        '${AutoUpdateConfig.supabaseUrl}/rest/v1/app_releases?version=eq.$version',
      );

      dbResponse = await http.patch(
        updateUrl,
        headers: {
          'apikey': AutoUpdateConfig.supabaseServiceKey,
          'Authorization': 'Bearer ${AutoUpdateConfig.supabaseServiceKey}',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(data),
      );
    } else {
      // Insert new record
      print('📝 Creating new release record...');
      data['release_notes'] =
          'Release $version for $platform\n\nFile size: $fileSizeMB MB';

      final insertUrl = Uri.parse(
        '${AutoUpdateConfig.supabaseUrl}/rest/v1/app_releases',
      );

      dbResponse = await http.post(
        insertUrl,
        headers: {
          'apikey': AutoUpdateConfig.supabaseServiceKey,
          'Authorization': 'Bearer ${AutoUpdateConfig.supabaseServiceKey}',
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
    print('   File size: $fileSizeMB MB');
    print('   Storage: Cloudflare R2');
    print('   Public URL: $publicUrl');
    print('   SHA256: $sha256Hash');
    print('');
    print('✅ Users will receive update notification on next app launch!');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
