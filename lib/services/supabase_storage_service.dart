import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase Storage Service
/// Handles file uploads to Supabase Storage (alternative to Firebase Storage)
class SupabaseStorageService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Bucket names
  static const String chatAttachmentsBucket = 'chat_attachments';
  static const String avatarsBucket = 'avatars';

  /// Upload image attachment
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final path = '$userId/$fileName';

    await _client.storage
        .from(chatAttachmentsBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return _client.storage.from(chatAttachmentsBucket).getPublicUrl(path);
  }

  /// Upload file attachment
  Future<String> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final path = '$userId/$fileName';

    await _client.storage
        .from(chatAttachmentsBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return _client.storage.from(chatAttachmentsBucket).getPublicUrl(path);
  }

  /// Upload voice message
  Future<String> uploadVoiceMessage({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final path = '$userId/voice/$fileName';

    await _client.storage
        .from(chatAttachmentsBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: 'audio/m4a',
          ),
        );

    return _client.storage.from(chatAttachmentsBucket).getPublicUrl(path);
  }

  /// Upload avatar
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    final path = '$userId/$fileName';

    await _client.storage
        .from(avatarsBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true, // Allow overwriting
            contentType: 'image/jpeg',
          ),
        );

    return _client.storage.from(avatarsBucket).getPublicUrl(path);
  }

  /// Delete file
  Future<void> deleteFile({required String path, bool isAvatar = false}) async {
    final bucket = isAvatar ? avatarsBucket : chatAttachmentsBucket;

    await _client.storage.from(bucket).remove([path]);
  }

  /// Get file URL
  String getFileUrl(String path, {bool isAvatar = false}) {
    final bucket = isAvatar ? avatarsBucket : chatAttachmentsBucket;
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Download file as bytes
  Future<Uint8List> downloadFile(String path, {bool isAvatar = false}) async {
    final bucket = isAvatar ? avatarsBucket : chatAttachmentsBucket;

    final bytes = await _client.storage.from(bucket).download(path);

    return bytes;
  }

  /// Create storage buckets (run once during setup)
  Future<void> createBucketsIfNeeded() async {
    try {
      // Check if buckets exist
      final buckets = await _client.storage.listBuckets();
      final bucketNames = buckets.map((b) => b.name).toList();

      // Create chat_attachments bucket
      if (!bucketNames.contains(chatAttachmentsBucket)) {
        await _client.storage.createBucket(
          chatAttachmentsBucket,
          BucketOptions(
            public: true,
            fileSizeLimit: '52428800', // 50MB
            allowedMimeTypes: const [
              'image/jpeg',
              'image/png',
              'image/gif',
              'audio/m4a',
              'audio/mpeg',
              'application/pdf',
              'application/msword',
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            ],
          ),
        );
      }

      // Create avatars bucket
      if (!bucketNames.contains(avatarsBucket)) {
        await _client.storage.createBucket(
          avatarsBucket,
          BucketOptions(
            public: true,
            fileSizeLimit: '5242880', // 5MB
            allowedMimeTypes: const ['image/jpeg', 'image/png'],
          ),
        );
      }
    } catch (e) {
      print('Error creating buckets: $e');
      // Buckets might already exist
    }
  }
}
