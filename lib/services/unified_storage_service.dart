/// 📦 Unified Storage Service
///
/// Provides a single interface to upload/download files
/// Can switch between Supabase Storage and Cloudflare R2
///
/// Default: Uses R2 for attachments (free bandwidth!)
/// Fallback: Uses Supabase Storage if R2 fails

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'r2_storage_service.dart';
import 'supabase_storage_service.dart';
import '../config/r2_config.dart';

enum StorageProvider {
  r2, // Cloudflare R2 (recommended for attachments)
  supabase, // Supabase Storage (backup/avatars)
}

class UnifiedStorageService {
  final _r2Service = R2StorageService();
  final _supabaseService = SupabaseStorageService();

  /// Primary storage provider
  /// Use R2 for attachments (free bandwidth)
  /// Use Supabase for avatars (integrated with RLS)
  StorageProvider _primaryProvider = StorageProvider.r2;

  /// Enable fallback to Supabase if R2 fails
  bool enableFallback = true;

  UnifiedStorageService({
    StorageProvider? primaryProvider,
    this.enableFallback = true,
  }) {
    if (primaryProvider != null) {
      _primaryProvider = primaryProvider;
    }

    // Check R2 configuration
    if (_primaryProvider == StorageProvider.r2) {
      try {
        R2Config.validateConfig();
      } catch (e) {
        debugPrint('⚠️ R2 not configured, falling back to Supabase Storage');
        debugPrint('See R2_SETUP_GUIDE.md for setup instructions');
        _primaryProvider = StorageProvider.supabase;
      }
    }
  }

  /// Upload image file
  Future<String> uploadImage({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    return await _uploadWithFallback(
      primary: () => _r2Service.uploadImage(fileName: fileName, bytes: bytes),
      fallback: () => _supabaseService.uploadImage(
        userId: userId,
        fileName: fileName,
        bytes: bytes,
      ),
      fileType: 'image',
    );
  }

  /// Upload generic file (PDF, DOCX, etc.)
  Future<String> uploadFile({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    return await _uploadWithFallback(
      primary: () => _r2Service.uploadFile(fileName: fileName, bytes: bytes),
      fallback: () => _supabaseService.uploadFile(
        userId: userId,
        fileName: fileName,
        bytes: bytes,
      ),
      fileType: 'file',
    );
  }

  /// Upload voice message
  Future<String> uploadVoice({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    return await _uploadWithFallback(
      primary: () => _r2Service.uploadVoice(fileName: fileName, bytes: bytes),
      fallback: () => _supabaseService.uploadFile(
        userId: userId,
        fileName: fileName,
        bytes: bytes,
      ),
      fileType: 'voice',
    );
  }

  /// Upload document (specialized for docs)
  Future<String> uploadDocument({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    return await _uploadWithFallback(
      primary: () =>
          _r2Service.uploadDocument(fileName: fileName, bytes: bytes),
      fallback: () => _supabaseService.uploadFile(
        userId: userId,
        fileName: fileName,
        bytes: bytes,
      ),
      fileType: 'document',
    );
  }

  /// Upload avatar (profile picture)
  /// Avatars benefit from R2's free bandwidth since they're loaded frequently
  Future<String> uploadAvatar({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    return await _uploadWithFallback(
      primary: () => _r2Service.uploadImage(fileName: fileName, bytes: bytes),
      fallback: () => _supabaseService.uploadAvatar(
        userId: userId,
        fileName: fileName,
        bytes: bytes,
      ),
      fileType: 'avatar',
    );
  }

  /// Internal: Upload with fallback strategy
  Future<String> _uploadWithFallback({
    required Future<String> Function() primary,
    required Future<String> Function() fallback,
    required String fileType,
  }) async {
    try {
      // Try primary provider (R2)
      if (_primaryProvider == StorageProvider.r2) {
        debugPrint('📤 Uploading $fileType to R2...');
        final url = await primary();
        debugPrint('✅ R2 upload success: $url');
        return url;
      } else {
        // Use Supabase as primary
        debugPrint('📤 Uploading $fileType to Supabase...');
        final url = await fallback();
        debugPrint('✅ Supabase upload success: $url');
        return url;
      }
    } catch (e) {
      // Fallback if enabled
      if (enableFallback && _primaryProvider == StorageProvider.r2) {
        debugPrint('⚠️ R2 upload failed: $e');
        debugPrint('🔄 Falling back to Supabase Storage...');
        try {
          final url = await fallback();
          debugPrint('✅ Supabase fallback success: $url');
          return url;
        } catch (fallbackError) {
          debugPrint('❌ Supabase fallback also failed: $fallbackError');
          rethrow;
        }
      } else {
        debugPrint('❌ Upload failed: $e');
        rethrow;
      }
    }
  }

  /// Download file
  Future<Uint8List> downloadFile(String url) async {
    // Detect provider from URL
    if (url.contains('r2.dev') || url.contains('r2.cloudflarestorage.com')) {
      // R2 URL - extract filename
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;
      return await _r2Service.downloadFile(fileName);
    } else {
      // Supabase URL
      return await _supabaseService.downloadFile(url);
    }
  }

  /// Delete file
  Future<void> deleteFile(String url) async {
    // Detect provider from URL
    if (url.contains('r2.dev') || url.contains('r2.cloudflarestorage.com')) {
      // R2 URL - extract filename
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;
      await _r2Service.deleteFile(fileName);
    } else {
      // Supabase URL - extract path
      final uri = Uri.parse(url);
      final path = uri.pathSegments.skip(1).join('/');
      await _supabaseService.deleteFile(path: path);
    }
  }

  /// Get current provider
  String get currentProvider => _primaryProvider == StorageProvider.r2
      ? 'Cloudflare R2 (Free Bandwidth)'
      : 'Supabase Storage';

  /// Switch provider manually
  void setProvider(StorageProvider provider) {
    _primaryProvider = provider;
    debugPrint('🔄 Storage provider changed to: $currentProvider');
  }

  /// Check if R2 is configured
  bool get isR2Configured => R2Config.isConfigured;

  /// Get storage stats (for debugging)
  Map<String, dynamic> getStats() {
    return {
      'primary_provider': currentProvider,
      'fallback_enabled': enableFallback,
      'r2_configured': isR2Configured,
    };
  }
}
