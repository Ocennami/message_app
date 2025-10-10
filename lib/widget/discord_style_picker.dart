import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giphy GIF/Sticker model
class GiphyGif {
  final String id;
  final String title;
  final String url;
  final String previewUrl;

  GiphyGif({
    required this.id,
    required this.title,
    required this.url,
    required this.previewUrl,
  });

  factory GiphyGif.fromJson(Map<String, dynamic> json) {
    return GiphyGif(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      url: json['images']['original']['url'] as String,
      previewUrl: json['images']['fixed_width']['url'] as String,
    );
  }
}

/// Discord-style emoji/GIF/sticker picker
class DiscordStylePicker extends StatefulWidget {
  const DiscordStylePicker({
    super.key,
    required this.onEmojiSelected,
    required this.onGifSelected,
    required this.onStickerSelected,
  });

  final Function(String emoji) onEmojiSelected;
  final Function(String gifUrl) onGifSelected;
  final Function(String stickerUrl) onStickerSelected;

  @override
  State<DiscordStylePicker> createState() => _DiscordStylePickerState();
}

class _DiscordStylePickerState extends State<DiscordStylePicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _gifSearchController = TextEditingController();
  final _stickerSearchController = TextEditingController();

  // Giphy API - Get your free key at https://developers.giphy.com
  // Using public beta key for demo (get your own for production!)
  static const _giphyApiKey = 'o4Y38nznOmcsuDU1bAvr2SINfg9vQPhy';

  List<GiphyGif> _gifResults = [];
  List<GiphyGif> _stickerResults = [];
  bool _isLoadingGifs = false;
  bool _isLoadingStickers = false;

  // Custom emojis storage
  List<String> _customEmojis = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCustomContent();
    // Load trending on init
    _loadTrendingGifs();
    _loadTrendingStickers();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _gifSearchController.dispose();
    _stickerSearchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && _gifResults.isEmpty) {
      _loadTrendingGifs();
    } else if (_tabController.index == 2 && _stickerResults.isEmpty) {
      _loadTrendingStickers();
    }
  }

  Future<void> _loadCustomContent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _customEmojis = prefs.getStringList('custom_emojis') ?? [];
    });
  }

  Future<void> _saveCustomContent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('custom_emojis', _customEmojis);
  }

  Future<void> _loadTrendingGifs() async {
    setState(() {
      _isLoadingGifs = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.giphy.com/v1/gifs/trending?api_key=$_giphyApiKey&limit=50&rating=g',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data'] as List;
        setState(() {
          _gifResults = results.map((gif) => GiphyGif.fromJson(gif)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading trending GIFs: $e');
    } finally {
      setState(() {
        _isLoadingGifs = false;
      });
    }
  }

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty) {
      _loadTrendingGifs();
      return;
    }

    setState(() {
      _isLoadingGifs = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.giphy.com/v1/gifs/search?api_key=$_giphyApiKey&q=$query&limit=50&rating=g',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data'] as List;
        setState(() {
          _gifResults = results.map((gif) => GiphyGif.fromJson(gif)).toList();
        });
      }
    } catch (e) {
      debugPrint('GIF search error: $e');
    } finally {
      setState(() {
        _isLoadingGifs = false;
      });
    }
  }

  Future<void> _loadTrendingStickers() async {
    setState(() {
      _isLoadingStickers = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.giphy.com/v1/stickers/trending?api_key=$_giphyApiKey&limit=50&rating=g',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data'] as List;
        setState(() {
          _stickerResults = results
              .map((sticker) => GiphyGif.fromJson(sticker))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading trending stickers: $e');
    } finally {
      setState(() {
        _isLoadingStickers = false;
      });
    }
  }

  Future<void> _searchStickers(String query) async {
    if (query.trim().isEmpty) {
      _loadTrendingStickers();
      return;
    }

    setState(() {
      _isLoadingStickers = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.giphy.com/v1/stickers/search?api_key=$_giphyApiKey&q=$query&limit=50&rating=g',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['data'] as List;
        setState(() {
          _stickerResults = results
              .map((sticker) => GiphyGif.fromJson(sticker))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Sticker search error: $e');
    } finally {
      setState(() {
        _isLoadingStickers = false;
      });
    }
  }

  Future<void> _addCustomEmoji() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() {
        _customEmojis.add(base64Image);
      });
      await _saveCustomContent();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Custom emoji added!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2ECF7),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Tab bar
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2D2535),
                  unselectedLabelColor: const Color(0xFF7F7F88),
                  indicatorColor: const Color(0xFF2D2535),
                  tabs: const [
                    Tab(icon: Icon(Icons.emoji_emotions), text: 'Emoji'),
                    Tab(icon: Icon(Icons.gif_box), text: 'GIF'),
                    Tab(icon: Icon(Icons.sticky_note_2), text: 'Stickers'),
                    Tab(icon: Icon(Icons.star), text: 'Custom'),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmojiTab(),
                _buildGifTab(),
                _buildStickersTab(),
                _buildCustomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiTab() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        widget.onEmojiSelected(emoji.emoji);
      },
    );
  }

  Widget _buildGifTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _gifSearchController,
            decoration: InputDecoration(
              hintText: 'Search GIF...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _gifSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _gifSearchController.clear();
                        setState(() {
                          _gifResults = [];
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: _searchGifs,
          ),
        ),
        // GIF results
        Expanded(
          child: _isLoadingGifs
              ? const Center(child: CircularProgressIndicator())
              : _gifResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gif_box_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _gifSearchController.text.isEmpty
                            ? 'Loading trending GIFs...'
                            : 'No GIFs found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _gifResults.length,
                  itemBuilder: (context, index) {
                    final gif = _gifResults[index];
                    return GestureDetector(
                      onTap: () => widget.onGifSelected(gif.url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: gif.previewUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            ),
                            // GIF label
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'GIF',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStickersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _stickerSearchController,
            decoration: InputDecoration(
              hintText: 'Search animated stickers...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2D2535)),
              filled: true,
              fillColor: const Color(0xFFF2ECF7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _searchStickers(value);
              }
            },
          ),
        ),
        // Stickers grid
        Expanded(
          child: _isLoadingStickers
              ? const Center(child: CircularProgressIndicator())
              : _stickerResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sticky_note_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No stickers found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _stickerResults.length,
                  itemBuilder: (context, index) {
                    final sticker = _stickerResults[index];
                    return GestureDetector(
                      onTap: () {
                        widget.onStickerSelected('[GIF:${sticker.url}]');
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: sticker.previewUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFF2ECF7),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFF2ECF7),
                                child: const Icon(Icons.error),
                              ),
                            ),
                            // "STICKER" badge
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'STICKER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom Emojis section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Custom Emojis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2535),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addCustomEmoji,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2535),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _customEmojis.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2ECF7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_emotions_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No custom emojis yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _customEmojis.map((base64Image) {
                    final bytes = base64Decode(base64Image);
                    return GestureDetector(
                      onTap: () {
                        // Convert to data URL for sending
                        widget.onEmojiSelected('[CUSTOM_EMOJI:$base64Image]');
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(bytes, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
