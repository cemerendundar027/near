import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../app/theme.dart';

/// Tenor API key (Google Cloud Console'dan alınmalı)
/// https://console.cloud.google.com/apis/credentials
/// Tenor API'yi etkinleştirin ve API key oluşturun
const _tenorApiKey = 'AIzaSyAyimkuYQYF_FXVvIQUdHxWpErCd7Xbel0';

/// GIF Picker Widget
/// - Trend GIF'ler
/// - Kategori seçimi
/// - Arama
/// - Grid görünüm
class GifPicker extends StatefulWidget {
  final Function(GifItem gif) onGifSelected;
  final VoidCallback? onClose;

  const GifPicker({
    super.key,
    required this.onGifSelected,
    this.onClose,
  });

  /// Bottom sheet olarak göster
  static Future<GifItem?> show(BuildContext context) {
    return showModalBottomSheet<GifItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _GifPickerSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends State<GifPicker> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategory = 0;
  List<GifItem> _gifs = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _categories = [
    '🔥 Trend',
    '😂 Komik',
    '❤️ Aşk',
    '🎉 Kutlama',
    '👋 Selam',
    '😢 Üzgün',
    '😮 Şaşkın',
    '💪 Güç',
    '🐱 Hayvanlar',
    '🎬 Film',
  ];

  // Kategori arama terimleri
  final List<String> _categorySearchTerms = [
    'trending',
    'funny',
    'love',
    'celebration',
    'hello',
    'sad',
    'surprised',
    'strong',
    'cats',
    'movie',
  ];

  @override
  void initState() {
    super.initState();
    _loadGifs();
  }

  /// Tenor API'den GIF'leri yükle
  Future<void> _loadGifs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final searchTerm = _searchQuery.isNotEmpty 
          ? _searchQuery 
          : _categorySearchTerms[_selectedCategory];
      
      final endpoint = _searchQuery.isNotEmpty || _selectedCategory > 0
          ? 'search'
          : 'featured';
      
      final uri = Uri.parse(
        'https://tenor.googleapis.com/v2/$endpoint'
        '?key=$_tenorApiKey'
        '&client_key=near_app'
        '&q=$searchTerm'
        '&limit=24'
        '&media_filter=tinygif,gif'
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        debugPrint('Tenor API: ${results.length} GIF found');

        setState(() {
          _gifs = results.map((r) {
            final mediaFormats = r['media_formats'] as Map<String, dynamic>? ?? {};
            
            // Tenor API v2 formatları - öncelik sırası
            final gifMedium = mediaFormats['mediumgif'] as Map<String, dynamic>?;
            final gif = mediaFormats['gif'] as Map<String, dynamic>?;
            final tinygif = mediaFormats['tinygif'] as Map<String, dynamic>?;
            final nanogif = mediaFormats['nanogif'] as Map<String, dynamic>?;
            
            // En iyi URL'yi seç
            final mainUrl = gifMedium?['url'] ?? gif?['url'] ?? tinygif?['url'] ?? '';
            final previewUrl = nanogif?['url'] ?? tinygif?['url'] ?? mainUrl;
            
            // Boyutları al
            final dims = tinygif?['dims'] as List<dynamic>? ?? 
                         nanogif?['dims'] as List<dynamic>? ?? 
                         [200, 150];
            
            debugPrint('GIF URL: $mainUrl');
            
            return GifItem(
              id: r['id']?.toString() ?? '',
              url: mainUrl,
              previewUrl: previewUrl,
              width: (dims.isNotEmpty ? dims[0] : 200) as int,
              height: (dims.length > 1 ? dims[1] : 150) as int,
              title: r['content_description'] ?? 'GIF',
              color: Colors.grey,
            );
          }).where((g) => g.url.isNotEmpty).toList();
          _isLoading = false;
    });
      } else {
        debugPrint('Tenor API error: ${response.statusCode} - ${response.body}');
        _loadFallbackGifs();
      }
    } catch (e) {
      debugPrint('Tenor API error: $e');
      _loadFallbackGifs();
    }
  }

  /// API başarısız olduğunda popüler GIF'leri göster
  void _loadFallbackGifs() {
    final fallbackUrls = [
      'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif',
      'https://media.giphy.com/media/3o7TKSjRrfIPjeiVyM/giphy.gif',
      'https://media.giphy.com/media/l41lGvinEgARjB2HC/giphy.gif',
      'https://media.giphy.com/media/xT9IgG50Fb7Mi0prBC/giphy.gif',
      'https://media.giphy.com/media/3oz8xIsloV7zOmt81G/giphy.gif',
      'https://media.giphy.com/media/l0HlvtIPzPdt2usKs/giphy.gif',
      'https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif',
      'https://media.giphy.com/media/l0MYC0LajbaPoEADu/giphy.gif',
      'https://media.giphy.com/media/xT9DPBMumj2Q0hlI3K/giphy.gif',
      'https://media.giphy.com/media/26u4cqiYI30juCOGY/giphy.gif',
      'https://media.giphy.com/media/l3q2K5jinAlChoCLS/giphy.gif',
      'https://media.giphy.com/media/3ohzdIuqJoo8QdKlnW/giphy.gif',
    ];
    
    setState(() {
      _gifs = fallbackUrls.asMap().entries.map((e) => GifItem(
        id: 'fallback_${e.key}',
        url: e.value,
        previewUrl: e.value,
        width: 200,
        height: 150,
        title: 'GIF',
        color: Colors.grey,
      )).toList();
      _isLoading = false;
      _error = null;
    });
  }

  /// Arama yap
  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _loadGifs();
  }

  /// Kategori değiştir
  void _onCategoryChanged(int index) {
    setState(() {
      _selectedCategory = index;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadGifs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'GIF',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                // GIPHY attribution
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'GIPHY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'GIF ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Categories
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? NearTheme.primary
                          : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // GIF Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: Colors.grey)))
                    : _GifGrid(
                        gifs: _gifs,
              onGifSelected: widget.onGifSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _GifPickerSheet extends StatefulWidget {
  final ScrollController scrollController;

  const _GifPickerSheet({required this.scrollController});

  @override
  State<_GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<_GifPickerSheet> {
  final _searchController = TextEditingController();
  int _selectedCategory = 0;
  List<GifItem> _gifs = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _categories = [
    '🔥 Trend',
    '😂 Komik',
    '❤️ Aşk',
    '🎉 Kutlama',
    '👋 Selam',
    '😢 Üzgün',
    '😮 Şaşkın',
    '💪 Güç',
  ];

  final List<String> _categoryTerms = [
    'trending',
    'funny',
    'love',
    'celebration',
    'hello',
    'sad',
    'surprised',
    'strong',
  ];

  @override
  void initState() {
    super.initState();
    _loadGifs();
  }

  Future<void> _loadGifs({String? searchQuery}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final query = searchQuery ?? _categoryTerms[_selectedCategory];
      final endpoint = searchQuery != null ? 'search' : 'featured';
      
      final uri = Uri.parse(
        'https://tenor.googleapis.com/v2/$endpoint'
        '?key=$_tenorApiKey'
        '&client_key=near_app'
        '&q=$query'
        '&limit=24'
        '&media_filter=tinygif,gif'
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];

        setState(() {
          _gifs = results.map((r) {
            final media = r['media_formats'] as Map<String, dynamic>? ?? {};
            
            // Tenor API v2 formatları
            final gifMedium = media['mediumgif'] as Map<String, dynamic>?;
            final gif = media['gif'] as Map<String, dynamic>?;
            final tiny = media['tinygif'] as Map<String, dynamic>?;
            final nano = media['nanogif'] as Map<String, dynamic>?;
            
            final mainUrl = gifMedium?['url'] ?? gif?['url'] ?? tiny?['url'] ?? '';
            final previewUrl = nano?['url'] ?? tiny?['url'] ?? mainUrl;
            
            final dims = tiny?['dims'] as List<dynamic>? ?? 
                         nano?['dims'] as List<dynamic>? ?? 
                         [200, 150];
            
            return GifItem(
              id: r['id']?.toString() ?? '',
              url: mainUrl,
              previewUrl: previewUrl,
              width: (dims.isNotEmpty ? dims[0] : 200) as int,
              height: (dims.length > 1 ? dims[1] : 150) as int,
              title: r['content_description'] ?? 'GIF',
              color: Colors.grey,
            );
          }).where((g) => g.url.isNotEmpty).toList();
          _isLoading = false;
        });
      } else {
        debugPrint('Tenor API error in sheet: ${response.statusCode}');
        _loadSheetFallbackGifs();
      }
    } catch (e) {
      debugPrint('Tenor API error in sheet: $e');
      _loadSheetFallbackGifs();
    }
  }

  void _loadSheetFallbackGifs() {
    final fallbackUrls = [
      'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif',
      'https://media.giphy.com/media/3o7TKSjRrfIPjeiVyM/giphy.gif',
      'https://media.giphy.com/media/l41lGvinEgARjB2HC/giphy.gif',
      'https://media.giphy.com/media/xT9IgG50Fb7Mi0prBC/giphy.gif',
      'https://media.giphy.com/media/3oz8xIsloV7zOmt81G/giphy.gif',
      'https://media.giphy.com/media/l0HlvtIPzPdt2usKs/giphy.gif',
      'https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif',
      'https://media.giphy.com/media/l0MYC0LajbaPoEADu/giphy.gif',
      'https://media.giphy.com/media/xT9DPBMumj2Q0hlI3K/giphy.gif',
      'https://media.giphy.com/media/26u4cqiYI30juCOGY/giphy.gif',
      'https://media.giphy.com/media/l3q2K5jinAlChoCLS/giphy.gif',
      'https://media.giphy.com/media/3ohzdIuqJoo8QdKlnW/giphy.gif',
    ];
    
    setState(() {
      _gifs = fallbackUrls.asMap().entries.map((e) => GifItem(
        id: 'fallback_${e.key}',
        url: e.value,
        previewUrl: e.value,
        width: 200,
        height: 150,
        title: 'GIF',
        color: Colors.grey,
      )).toList();
      _isLoading = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'GIF',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: NearTheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TENOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onSubmitted: (query) => _loadGifs(searchQuery: query),
              decoration: InputDecoration(
                hintText: 'GIF ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadGifs();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Categories
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = index);
                    _loadGifs();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? NearTheme.primary
                          : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // GIF Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(_error!, style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadGifs,
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : _GifGrid(
              gifs: _gifs,
              scrollController: widget.scrollController,
              onGifSelected: (gif) {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, gif);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GifGrid extends StatelessWidget {
  final List<GifItem> gifs;
  final ScrollController? scrollController;
  final Function(GifItem gif) onGifSelected;

  const _GifGrid({
    required this.gifs,
    this.scrollController,
    required this.onGifSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: gifs.length,
      itemBuilder: (context, index) {
        final gif = gifs[index];
        return GestureDetector(
          onTap: () => onGifSelected(gif),
          child: Container(
            decoration: BoxDecoration(
              color: gif.color.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Placeholder animated gradient
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _AnimatedGifPlaceholder(color: gif.color),
                ),
                // GIF icon overlay
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.gif_box_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedGifPlaceholder extends StatefulWidget {
  final Color color;

  const _AnimatedGifPlaceholder({required this.color});

  @override
  State<_AnimatedGifPlaceholder> createState() => _AnimatedGifPlaceholderState();
}

class _AnimatedGifPlaceholderState extends State<_AnimatedGifPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * _controller.value, 0),
              end: Alignment(1.0 + 2 * _controller.value, 0),
              colors: [
                widget.color.withAlpha(60),
                widget.color.withAlpha(120),
                widget.color.withAlpha(60),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// GIF data model
class GifItem {
  final String id;
  final String url;
  final String previewUrl;
  final int width;
  final int height;
  final String title;
  final Color color;

  const GifItem({
    required this.id,
    required this.url,
    required this.previewUrl,
    required this.width,
    required this.height,
    required this.title,
    this.color = Colors.grey,
  });
}
