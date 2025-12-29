import 'package:flutter/material.dart';

/// Chat wallpaper picker page
class WallpaperPickerPage extends StatefulWidget {
  final String? currentWallpaper;
  final void Function(String? wallpaper)? onWallpaperSelected;

  const WallpaperPickerPage({
    super.key,
    this.currentWallpaper,
    this.onWallpaperSelected,
  });

  @override
  State<WallpaperPickerPage> createState() => _WallpaperPickerPageState();
}

class _WallpaperPickerPageState extends State<WallpaperPickerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedWallpaper;

  // Predefined solid colors
  static const _solidColors = [
    Color(0xFFFFFFFF),
    Color(0xFFF5F5F5),
    Color(0xFFE0E0E0),
    Color(0xFF1C1C1E),
    Color(0xFF2C2C2E),
    Color(0xFF000000),
    Color(0xFFE3F2FD),
    Color(0xFFBBDEFB),
    Color(0xFF90CAF9),
    Color(0xFFE8F5E9),
    Color(0xFFC8E6C9),
    Color(0xFFA5D6A7),
    Color(0xFFFFF3E0),
    Color(0xFFFFE0B2),
    Color(0xFFFFCC80),
    Color(0xFFFCE4EC),
    Color(0xFFF8BBD0),
    Color(0xFFF48FB1),
    Color(0xFFF3E5F5),
    Color(0xFFE1BEE7),
    Color(0xFFCE93D8),
    Color(0xFFE8EAF6),
    Color(0xFFC5CAE9),
    Color(0xFF9FA8DA),
    Color(0xFFE0F7FA),
    Color(0xFFB2EBF2),
    Color(0xFF80DEEA),
    Color(0xFFFFF8E1),
    Color(0xFFFFECB3),
    Color(0xFFFFE082),
  ];

  // Gradient presets
  static const _gradients = [
    [Color(0xFF7B3FF2), Color(0xFF5A22C8)],
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFFFA709A), Color(0xFFFEE140)],
    [Color(0xFF30CFD0), Color(0xFF330867)],
    [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
    [Color(0xFF5EE7DF), Color(0xFFB490CA)],
    [Color(0xFFD299C2), Color(0xFFFEF9D7)],
    [Color(0xFF89F7FE), Color(0xFF66A6FF)],
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedWallpaper = widget.currentWallpaper;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        title: Text(
          'Duvar Kağıdı',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onWallpaperSelected?.call(_selectedWallpaper);
              Navigator.pop(context);
            },
            child: const Text(
              'Kaydet',
              style: TextStyle(
                color: Color(0xFF7B3FF2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7B3FF2),
          labelColor: const Color(0xFF7B3FF2),
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          tabs: const [
            Tab(text: 'Düz Renk'),
            Tab(text: 'Gradyan'),
            Tab(text: 'Galeri'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Preview
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedWallpaper != null
                  ? _parseColor(_selectedWallpaper!)
                  : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
              gradient: _selectedWallpaper?.startsWith('gradient:') == true
                  ? _parseGradient(_selectedWallpaper!)
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Sample messages
                  Positioned(
                    left: 16,
                    bottom: 60,
                    child: _SampleMessage(text: 'Merhaba! 👋', isFromMe: false),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: _SampleMessage(
                      text: 'Selam, nasılsın?',
                      isFromMe: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Wallpaper options
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Solid colors
                _buildSolidColorGrid(),
                // Gradients
                _buildGradientGrid(),
                // Gallery
                _buildGalleryOption(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolidColorGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _solidColors.length + 1, // +1 for default
      itemBuilder: (context, index) {
        if (index == 0) {
          // Default option
          return _WallpaperOption(
            isSelected: _selectedWallpaper == null,
            onTap: () => setState(() => _selectedWallpaper = null),
            child: const Icon(Icons.block, color: Colors.grey),
          );
        }

        final color = _solidColors[index - 1];
        final colorString = 'solid:${color.toHex()}';

        return _WallpaperOption(
          isSelected: _selectedWallpaper == colorString,
          onTap: () => setState(() => _selectedWallpaper = colorString),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: color == const Color(0xFFFFFFFF)
                  ? Border.all(color: Colors.grey.shade300)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _gradients.length,
      itemBuilder: (context, index) {
        final gradient = _gradients[index];
        final gradientString =
            'gradient:${gradient[0].toHex()},${gradient[1].toHex()}';

        return _WallpaperOption(
          isSelected: _selectedWallpaper == gradientString,
          onTap: () => setState(() => _selectedWallpaper = gradientString),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGalleryOption() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF7B3FF2).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 40,
              color: Color(0xFF7B3FF2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Galeriden Seç',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kendi fotoğraflarınızı duvar kağıdı olarak kullanın',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Placeholder for image picker
            },
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Fotoğraf Seç'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B3FF2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String wallpaper) {
    if (wallpaper.startsWith('solid:')) {
      final hex = wallpaper.substring(6);
      return HexColor.fromHex(hex);
    }
    return null;
  }

  LinearGradient? _parseGradient(String wallpaper) {
    if (wallpaper.startsWith('gradient:')) {
      final colors = wallpaper.substring(9).split(',');
      if (colors.length == 2) {
        return LinearGradient(
          colors: [HexColor.fromHex(colors[0]), HexColor.fromHex(colors[1])],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    }
    return null;
  }
}

class _WallpaperOption extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget child;

  const _WallpaperOption({
    required this.isSelected,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF7B3FF2) : Colors.transparent,
            width: 3,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipRRect(borderRadius: BorderRadius.circular(6), child: child),
      ),
    );
  }
}

class _SampleMessage extends StatelessWidget {
  final String text;
  final bool isFromMe;

  const _SampleMessage({required this.text, required this.isFromMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isFromMe ? const Color(0xFF7B3FF2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isFromMe ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Extension to convert Color to hex string
extension HexColor on Color {
  String toHex() {
    return '${(a * 255).round().toRadixString(16).padLeft(2, '0')}'
        '${(r * 255).round().toRadixString(16).padLeft(2, '0')}'
        '${(g * 255).round().toRadixString(16).padLeft(2, '0')}'
        '${(b * 255).round().toRadixString(16).padLeft(2, '0')}';
  }

  static Color fromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
