import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:giphy_get/giphy_get.dart';

/// Giphy SDK Picker - Only works on iOS/Android
/// Uses native Giphy SDK for better UI/UX
class GiphySdkPicker extends StatelessWidget {
  final String giphyApiKey;
  final Function(String gifUrl) onGifSelected;

  const GiphySdkPicker({
    super.key,
    required this.giphyApiKey,
    required this.onGifSelected,
  });

  /// Check if SDK is supported on current platform
  static bool get isSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isSupported) {
      return const Center(
        child: Text(
          'Giphy SDK only supported on iOS/Android\nUsing API fallback...',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gif_box, size: 64, color: Color(0xFF2D2535)),
          const SizedBox(height: 24),
          const Text(
            'Giphy SDK Picker',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2535),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Native UI for iOS/Android',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              // Use GiphyGet.getGif static method with API key
              final gif = await GiphyGet.getGif(
                context: context,
                apiKey: giphyApiKey,
                lang: GiphyLanguage.english,
              );

              if (gif != null && gif.images?.original?.url != null) {
                onGifSelected(gif.images!.original!.url);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2535),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.search),
            label: const Text(
              'Open Giphy Picker',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
