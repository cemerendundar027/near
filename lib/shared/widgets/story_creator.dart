import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Hikaye oluşturma sayfası
class StoryCreatorPage extends StatefulWidget {
  final VoidCallback? onStoryCreated;

  const StoryCreatorPage({super.key, this.onStoryCreated});

  @override
  State<StoryCreatorPage> createState() => _StoryCreatorPageState();
}

class _StoryCreatorPageState extends State<StoryCreatorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();

  // Text story options
  Color _backgroundColor = NearTheme.primary;
  String _fontFamily = 'Default';
  TextAlign _textAlign = TextAlign.center;

  // Media
  String? _selectedMedia;

  // Drawing
  final List<_DrawingPath> _paths = [];
  Color _drawColor = Colors.white;
  double _strokeWidth = 4.0;
  bool _isDrawing = false;

  final List<Color> _colorOptions = [
    NearTheme.primary,
    NearTheme.primaryDark,
    const Color(0xFF1DA1F2),
    const Color(0xFF25D366),
    const Color(0xFFFF6B6B),
    const Color(0xFFFFA726),
    const Color(0xFF9C27B0),
    const Color(0xFF2C2C2E),
  ];

  final List<String> _fontOptions = ['Default', 'Bold', 'Serif', 'Mono'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  // Mode selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeButton(0, Icons.text_fields_rounded, 'Metin'),
                        _buildModeButton(1, Icons.photo_rounded, 'Fotoğraf'),
                        _buildModeButton(2, Icons.videocam_rounded, 'Video'),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                    onPressed: _showSettings,
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTextStory(),
                  _buildMediaStory(false),
                  _buildMediaStory(true),
                ],
              ),
            ),

            // Bottom toolbar
            _buildBottomToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(int index, IconData icon, String label) {
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.black : Colors.white70,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextStory() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Text input
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: TextField(
                  controller: _textController,
                  textAlign: _textAlign,
                  maxLines: null,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: _fontFamily == 'Bold'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontFamily: _fontFamily == 'Serif'
                        ? 'Georgia'
                        : (_fontFamily == 'Mono' ? 'Courier' : null),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Bir şeyler yaz...',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha(100),
                      fontSize: 28,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Color picker
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _colorOptions.map((color) {
                    final isSelected = _backgroundColor == color;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _backgroundColor = color;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        width: isSelected ? 32 : 24,
                        height: isSelected ? 32 : 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Font & alignment options
            Positioned(
              left: 16,
              bottom: 16,
              right: 60,
              child: Row(
                children: [
                  // Font selector
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButton<String>(
                      value: _fontFamily,
                      dropdownColor: Colors.black87,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      style: const TextStyle(color: Colors.white),
                      items: _fontOptions.map((font) {
                        return DropdownMenuItem(
                          value: font,
                          child: Text(font),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _fontFamily = value ?? 'Default';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Alignment buttons
                  _buildAlignButton(Icons.format_align_left, TextAlign.left),
                  _buildAlignButton(Icons.format_align_center, TextAlign.center),
                  _buildAlignButton(Icons.format_align_right, TextAlign.right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignButton(IconData icon, TextAlign align) {
    final isSelected = _textAlign == align;

    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white54,
        size: 22,
      ),
      onPressed: () {
        setState(() {
          _textAlign = align;
        });
      },
    );
  }

  Widget _buildMediaStory(bool isVideo) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _selectedMedia == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVideo ? Icons.videocam_rounded : Icons.photo_rounded,
                      size: 40,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isVideo ? 'Video Seç' : 'Fotoğraf Seç',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMediaSourceButton(
                        Icons.photo_library_rounded,
                        'Galeri',
                        () => _pickMedia(isVideo, fromCamera: false),
                      ),
                      const SizedBox(width: 16),
                      _buildMediaSourceButton(
                        isVideo ? Icons.videocam_rounded : Icons.camera_alt_rounded,
                        isVideo ? 'Kaydet' : 'Çek',
                        () => _pickMedia(isVideo, fromCamera: true),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Media preview
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.image_rounded,
                        size: 100,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),

                // Drawing canvas
                if (_isDrawing)
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _paths.add(_DrawingPath(
                          color: _drawColor,
                          strokeWidth: _strokeWidth,
                          points: [details.localPosition],
                        ));
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _paths.last.points.add(details.localPosition);
                      });
                    },
                    child: CustomPaint(
                      painter: _DrawingPainter(_paths),
                      size: Size.infinite,
                    ),
                  ),

                // Edit tools
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      _buildEditButton(
                        Icons.draw_rounded,
                        _isDrawing,
                        () {
                          setState(() {
                            _isDrawing = !_isDrawing;
                          });
                        },
                      ),
                      _buildEditButton(
                        Icons.text_fields_rounded,
                        false,
                        _addTextOverlay,
                      ),
                      _buildEditButton(
                        Icons.emoji_emotions_rounded,
                        false,
                        _addSticker,
                      ),
                      _buildEditButton(
                        Icons.crop_rounded,
                        false,
                        _cropMedia,
                      ),
                    ],
                  ),
                ),

                // Drawing tools
                if (_isDrawing)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...[
                            Colors.white,
                            Colors.black,
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.blue,
                          ].map((color) {
                            final isSelected = _drawColor == color;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _drawColor = color;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                width: isSelected ? 28 : 20,
                                height: isSelected ? 28 : 20,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          // Stroke width slider
                          RotatedBox(
                            quarterTurns: 3,
                            child: SizedBox(
                              width: 100,
                              child: Slider(
                                value: _strokeWidth,
                                min: 2,
                                max: 20,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white30,
                                onChanged: (value) {
                                  setState(() {
                                    _strokeWidth = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Clear drawing
                if (_paths.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _paths.clear();
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.white),
                      label: const Text(
                        'Temizle',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildMediaSourceButton(
      IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(IconData icon, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.black.withAlpha(100),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.black : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Privacy selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Kişilerim',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
          const Spacer(),
          // Post button
          ElevatedButton(
            onPressed: _createStory,
            style: ElevatedButton.styleFrom(
              backgroundColor: NearTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Paylaş',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickMedia(bool isVideo, {required bool fromCamera}) {
    // Simüle - gerçekte image_picker kullanılır
    setState(() {
      _selectedMedia = 'selected_media';
    });
  }

  void _addTextOverlay() {
    // Text overlay ekleme
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metin ekleme özelliği')),
    );
  }

  void _addSticker() {
    // Sticker ekleme
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sticker ekleme özelliği')),
    );
  }

  void _cropMedia() {
    // Kırpma
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kırpma özelliği')),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.white),
                title: const Text('Süre', style: TextStyle(color: Colors.white)),
                subtitle: const Text('24 saat',
                    style: TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              ),
              ListTile(
                leading:
                    const Icon(Icons.visibility_outlined, color: Colors.white),
                title: const Text('Gizlilik',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Kişilerim',
                    style: TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              ),
              ListTile(
                leading:
                    const Icon(Icons.reply_outlined, color: Colors.white),
                title: const Text('Yanıtlar',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Herkes yanıtlayabilir',
                    style: TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _createStory() {
    HapticFeedback.mediumImpact();

    if (_tabController.index == 0 && _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir şeyler yazın')),
      );
      return;
    }

    if (_tabController.index != 0 && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir medya seçin')),
      );
      return;
    }

    // Story paylaşıldı
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hikaye paylaşıldı!'),
        backgroundColor: NearTheme.primary,
      ),
    );

    widget.onStoryCreated?.call();
    Navigator.pop(context);
  }
}

/// Drawing path model
class _DrawingPath {
  final Color color;
  final double strokeWidth;
  final List<Offset> points;

  _DrawingPath({
    required this.color,
    required this.strokeWidth,
    required this.points,
  });
}

/// Drawing painter
class _DrawingPainter extends CustomPainter {
  final List<_DrawingPath> paths;

  _DrawingPainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      if (path.points.length < 2) continue;

      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final drawPath = Path();
      drawPath.moveTo(path.points.first.dx, path.points.first.dy);

      for (int i = 1; i < path.points.length; i++) {
        drawPath.lineTo(path.points[i].dx, path.points[i].dy);
      }

      canvas.drawPath(drawPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
