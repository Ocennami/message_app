import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionCheckService {
  final String metadataUrl;

  VersionCheckService({required this.metadataUrl});

  Future<Map<String, dynamic>> _fetchMetadata() async {
    final resp = await http.get(Uri.parse(metadataUrl));
    if (resp.statusCode != 200) throw Exception('Failed to fetch metadata');
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  Future<String> _localVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version; // e.g. "1.0.0"
  }

  // Semver compare limited: returns true if remote > local (simple split)
  bool _isRemoteNewer(String local, String remote) {
    try {
      final l = local.split('.').map(int.parse).toList();
      final r = remote.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        final lv = (i < l.length) ? l[i] : 0;
        final rv = (i < r.length) ? r[i] : 0;
        if (rv > lv) return true;
        if (rv < lv) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkAndPrompt(BuildContext context) async {
    try {
      final metadata = await _fetchMetadata();
      final remoteVersion = metadata['latest_version'] as String? ?? '';
      final downloadUrl = metadata['url'] as String? ?? '';
      final sha256 = metadata['sha256'] as String? ?? '';
      final notes = metadata['notes'] as String? ?? '';

      final local = await _localVersion();
      if (!_isRemoteNewer(local, remoteVersion)) return;

      // Show dialog to user
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      final res = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Update available: $remoteVersion'),
          content: SingleChildScrollView(child: Text(notes)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Update'),
            ),
          ],
        ),
      );

      if (res == true) {
        await _downloadAndRun(downloadUrl, sha256);
      }
    } catch (e) {
      debugPrint('Version check failed: $e');
    }
  }

  Future<void> _downloadAndRun(String url, String expectedSha256) async {
    if (url.isEmpty) return;

    // On Android, open URL (let user download/install APK). On Windows, download and run.
    if (Platform.isAndroid) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (Platform.isWindows) {
      final tmpDir = await getTemporaryDirectory();
      final filePath =
          '${tmpDir.path}${Platform.pathSeparator}update_installer.exe';
      try {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode != 200) throw Exception('Download failed');
        final bytes = resp.bodyBytes;

        // Verify checksum if provided
        if (expectedSha256.isNotEmpty) {
          final digest = sha256.convert(bytes).toString();
          if (digest.toLowerCase() != expectedSha256.toLowerCase()) {
            throw Exception('Checksum mismatch');
          }
        }

        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);

        // Launch installer
        Process.start(file.path, [], mode: ProcessStartMode.detached);
      } catch (e) {
        debugPrint('Update download or run error: $e');
      }
    }
  }
}
