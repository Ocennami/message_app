import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:minio/minio.dart';
import 'package:message_app/config/r2_config.dart';

/// Cloudflare R2 Storage Service
///
/// Handles file uploads and downloads using Cloudflare R2 (S3-compatible storage).
/// Benefits:
/// - Zero egress fees (unlimited free bandwidth)
/// - Global CDN via Cloudflare
/// - Cheaper than AWS S3
/// - Perfect for chat attachments
class R2StorageService {
  late final Minio _client;
  final String _bucketName;

  R2StorageService() : _bucketName = R2Config.bucketName {
    // Validate configuration
    R2Config.validateConfig();

    // Initialize Minio client (S3-compatible)
    _client = Minio(
      endPoint: R2Config.endpoint.replaceAll('https://', ''),
      accessKey: R2Config.accessKeyId,
      secretKey: R2Config.secretAccessKey,
      useSSL: true,
      enableTrace: kDebugMode, // Enable logs in debug mode
    );

    debugPrint('✅ R2StorageService initialized');
    debugPrint('   Endpoint: ${R2Config.endpoint}');
    debugPrint('   Bucket: $_bucketName');
  }

  // ========================================
  // Upload Methods
  // ========================================

  /// Upload file to R2 and return public URL
  ///
  /// [fileName] - Name of file in bucket (should be unique)
  /// [bytes] - File content as bytes
  /// [contentType] - MIME type (e.g., 'image/jpeg', 'audio/mp4')
  ///
  /// Returns public URL to access the file
  Future<String> uploadFile({
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      debugPrint('📤 Uploading to R2: $fileName (${bytes.length} bytes)');

      // Prepare metadata with proper headers
      final metadata = <String, String>{};

      // Set Content-Type
      if (contentType != null) {
        metadata['Content-Type'] = contentType;
      }

      // Add cache control for better performance
      metadata['Cache-Control'] = 'public, max-age=31536000'; // 1 year

      // Upload to R2
      await _client.putObject(
        _bucketName,
        fileName,
        Stream.value(bytes),
        size: bytes.length,
        metadata: metadata.isNotEmpty ? metadata : null,
      );

      // Generate public URL
      final publicUrl = R2Config.getPublicUrl(fileName);

      debugPrint('✅ Upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ R2 upload failed: $e');
      rethrow;
    }
  }

  /// Upload image with automatic content type detection
  Future<String> uploadImage({
    required String fileName,
    required Uint8List bytes,
  }) async {
    // Detect image type from extension
    String contentType = 'image/jpeg';
    final ext = fileName.toLowerCase().split('.').last;

    switch (ext) {
      case 'png':
        contentType = 'image/png';
        break;
      case 'gif':
        contentType = 'image/gif';
        break;
      case 'webp':
        contentType = 'image/webp';
        break;
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
    }

    return uploadFile(
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
    );
  }

  /// Upload voice message
  Future<String> uploadVoice({
    required String fileName,
    required Uint8List bytes,
  }) async {
    return uploadFile(
      fileName: fileName,
      bytes: bytes,
      contentType: 'audio/mp4',
    );
  }

  /// Upload generic file
  Future<String> uploadDocument({
    required String fileName,
    required Uint8List bytes,
  }) async {
    return uploadFile(
      fileName: fileName,
      bytes: bytes,
      contentType: 'application/octet-stream',
    );
  }

  // ========================================
  // Download Methods
  // ========================================

  /// Download file from R2
  /// Returns file content as bytes
  Future<Uint8List> downloadFile(String fileName) async {
    try {
      debugPrint('📥 Downloading from R2: $fileName');

      final stream = await _client.getObject(_bucketName, fileName);
      final bytes = await stream.expand((chunk) => chunk).toList();

      debugPrint('✅ Download successful: ${bytes.length} bytes');
      return Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('❌ R2 download failed: $e');
      rethrow;
    }
  }

  // ========================================
  // Utility Methods
  // ========================================

  /// Delete file from R2
  Future<void> deleteFile(String fileName) async {
    try {
      debugPrint('🗑️ Deleting from R2: $fileName');
      await _client.removeObject(_bucketName, fileName);
      debugPrint('✅ Delete successful');
    } catch (e) {
      debugPrint('❌ R2 delete failed: $e');
      rethrow;
    }
  }

  /// Check if file exists in R2
  Future<bool> fileExists(String fileName) async {
    try {
      await _client.statObject(_bucketName, fileName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// List all files in bucket (use with caution - can be slow)
  Future<List<String>> listFiles({String? prefix}) async {
    try {
      final stream = _client.listObjects(_bucketName, prefix: prefix ?? '');

      final fileNames = <String>[];
      await for (final item in stream) {
        // item is ListObjectsResult which contains objects list
        for (final obj in item.objects) {
          if (obj.key != null) {
            fileNames.add(obj.key!);
          }
        }
      }

      return fileNames;
    } catch (e) {
      debugPrint('❌ R2 list failed: $e');
      rethrow;
    }
  }

  /// Generate unique filename with timestamp
  String generateFileName({required String originalName, String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitized = originalName
        .replaceAll(RegExp(r'[^\w\-\.]'), '_')
        .toLowerCase();

    if (prefix != null) {
      return '$prefix/$timestamp-$sanitized';
    }
    return '$timestamp-$sanitized';
  }

  // ========================================
  // Batch Operations
  // ========================================

  /// Upload multiple files in parallel
  Future<List<String>> uploadMultiple({
    required List<MapEntry<String, Uint8List>> files,
    String? contentType,
  }) async {
    final futures = files.map(
      (entry) => uploadFile(
        fileName: entry.key,
        bytes: entry.value,
        contentType: contentType,
      ),
    );

    return await Future.wait(futures);
  }

  /// Delete multiple files in parallel
  Future<void> deleteMultiple(List<String> fileNames) async {
    final futures = fileNames.map((name) => deleteFile(name));
    await Future.wait(futures);
  }
}
