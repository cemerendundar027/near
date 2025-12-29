import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Görsel düzenleme sayfası
/// - Kırpma (Crop)
/// - Döndürme (Rotate)
/// - Filtreler
/// - Metin ekleme
/// - Çizim
class ImageEditorPage extends StatefulWidget {
  final File imageFile;
  final bool showCropOnly;

  const ImageEditorPage({
    super.key,
    required this.imageFile,
    this.showCropOnly = false,
  });

  /// Navigator ile açıp düzenlenmiş dosyayı döndürür
  static Future<File?> open(BuildContext context, File imageFile,
      {bool cropOnly = false}) async {
    return Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageEditorPage(imageFile: imageFile, showCropOnly: cropOnly),
      ),
    );
  }

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Crop state
  Rect _cropRect = Rect.zero;
  Size _imageSize = Size.zero;
  final GlobalKey _imageKey = GlobalKey();

  // Rotation state
  double _rotation = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;

  // Filter state
  int _selectedFilterIndex = 0;
  final List<_ImageFilter> _filters = [
    _ImageFilter(name: 'Orijinal', matrix: null),
    _ImageFilter(name: 'Canlı', matrix: _vivid),
    _ImageFilter(name: 'Sıcak', matrix: _warm),
    _ImageFilter(name: 'Soğuk', matrix: _cool),
    _ImageFilter(name: 'Siyah-Beyaz', matrix: _grayscale),
    _ImageFilter(name: 'Sepya', matrix: _sepia),
    _ImageFilter(name: 'Kontrast', matrix: _highContrast),
    _ImageFilter(name: 'Soluk', matrix: _fade),
  ];

  // Text overlay state
  final List<_TextOverlay> _textOverlays = [];
  int? _selectedTextIndex;

  // Drawing state
  final List<_DrawingPath> _drawings = [];
  List<Offset> _currentDrawing = [];
  Color _drawingColor = Colors.red;
  double _drawingStrokeWidth = 4;
  bool _isDrawingMode = false;

  // Aspect ratio presets
  final List<_AspectRatio> _aspectRatios = [
    _AspectRatio(name: 'Serbest', ratio: null),
    _AspectRatio(name: '1:1', ratio: 1.0),
    _AspectRatio(name: '4:3', ratio: 4 / 3),
    _AspectRatio(name: '3:4', ratio: 3 / 4),
    _AspectRatio(name: '16:9', ratio: 16 / 9),
    _AspectRatio(name: '9:16', ratio: 9 / 16),
  ];
  int _selectedAspectRatioIndex = 0;

  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showCropOnly ? 1 : 4,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index;
        _isDrawingMode = _currentTab == 3;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCropRect();
    });
  }

  void _initializeCropRect() {
    final renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _imageSize = renderBox.size;
        _cropRect = Rect.fromLTWH(
          _imageSize.width * 0.1,
          _imageSize.height * 0.1,
          _imageSize.width * 0.8,
          _imageSize.height * 0.8,
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _rotate90() {
    HapticFeedback.lightImpact();
    setState(() {
      _rotation = (_rotation + 90) % 360;
    });
  }

  void _flip(bool horizontal) {
    HapticFeedback.lightImpact();
    setState(() {
      if (horizontal) {
        _flipHorizontal = !_flipHorizontal;
      } else {
        _flipVertical = !_flipVertical;
      }
    });
  }

  void _addText() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metin Ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Metninizi yazın...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _textOverlays.add(_TextOverlay(
                    text: controller.text.trim(),
                    position: Offset(
                      _imageSize.width / 2,
                      _imageSize.height / 2,
                    ),
                    color: Colors.white,
                    fontSize: 24,
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showTextOptions(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: NearTheme.primary),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(context);
                  _editText(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Sil'),
                onTap: () {
                  setState(() {
                    _textOverlays.removeAt(index);
                    _selectedTextIndex = null;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editText(int index) {
    final overlay = _textOverlays[index];
    final controller = TextEditingController(text: overlay.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Metni Düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _textOverlays[index] = overlay.copyWith(
                    text: controller.text.trim(),
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _undoDrawing() {
    if (_drawings.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _drawings.removeLast();
      });
    }
  }

  void _clearDrawings() {
    if (_drawings.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() {
        _drawings.clear();
      });
    }
  }

  void _applyChanges() {
    // Gerçek uygulamada burada image processing yapılır
    // Şimdilik orijinal dosyayı döndürüyoruz
    HapticFeedback.mediumImpact();
    Navigator.pop(context, widget.imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Düzenle'),
        actions: [
          TextButton(
            onPressed: _applyChanges,
            child: Text(
              'Tamam',
              style: TextStyle(
                color: NearTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            child: GestureDetector(
              onPanStart: _isDrawingMode
                  ? (details) {
                      setState(() {
                        _currentDrawing = [details.localPosition];
                      });
                    }
                  : null,
              onPanUpdate: _isDrawingMode
                  ? (details) {
                      setState(() {
                        _currentDrawing.add(details.localPosition);
                      });
                    }
                  : null,
              onPanEnd: _isDrawingMode
                  ? (details) {
                      if (_currentDrawing.isNotEmpty) {
                        setState(() {
                          _drawings.add(_DrawingPath(
                            points: List.from(_currentDrawing),
                            color: _drawingColor,
                            strokeWidth: _drawingStrokeWidth,
                          ));
                          _currentDrawing = [];
                        });
                      }
                    }
                  : null,
              child: Center(
                child: Stack(
                  children: [
                    // Image with transformations
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateZ(_rotation * math.pi / 180)
                        ..setEntry(0, 0, _flipHorizontal ? -1.0 : 1.0)
                        ..setEntry(1, 1, _flipVertical ? -1.0 : 1.0),
                      child: ColorFiltered(
                        colorFilter: _filters[_selectedFilterIndex].matrix !=
                                null
                            ? ColorFilter.matrix(
                                _filters[_selectedFilterIndex].matrix!)
                            : const ColorFilter.mode(
                                Colors.transparent, BlendMode.multiply),
                        child: Image.file(
                          widget.imageFile,
                          key: _imageKey,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Crop overlay
                    if (_currentTab == 0 && _imageSize != Size.zero)
                      _CropOverlay(
                        imageSize: _imageSize,
                        cropRect: _cropRect,
                        onCropRectChanged: (rect) {
                          setState(() => _cropRect = rect);
                        },
                        aspectRatio: _aspectRatios[_selectedAspectRatioIndex].ratio,
                      ),

                    // Text overlays
                    ..._textOverlays.asMap().entries.map((entry) {
                      final index = entry.key;
                      final overlay = entry.value;
                      return Positioned(
                        left: overlay.position.dx - 50,
                        top: overlay.position.dy - 20,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTextIndex = index;
                            });
                          },
                          onLongPress: () => _showTextOptions(index),
                          onPanUpdate: (details) {
                            setState(() {
                              _textOverlays[index] = overlay.copyWith(
                                position: overlay.position + details.delta,
                              );
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: _selectedTextIndex == index
                                ? BoxDecoration(
                                    border: Border.all(
                                      color: NearTheme.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                : null,
                            child: Text(
                              overlay.text,
                              style: TextStyle(
                                fontSize: overlay.fontSize,
                                color: overlay.color,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // Drawings
                    CustomPaint(
                      size: Size.infinite,
                      painter: _DrawingPainter(
                        drawings: _drawings,
                        currentDrawing: _currentDrawing,
                        currentColor: _drawingColor,
                        currentStrokeWidth: _drawingStrokeWidth,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          if (!widget.showCropOnly)
            TabBar(
              controller: _tabController,
              indicatorColor: NearTheme.primary,
              labelColor: NearTheme.primary,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.crop), text: 'Kırp'),
                Tab(icon: Icon(Icons.rotate_right), text: 'Döndür'),
                Tab(icon: Icon(Icons.filter), text: 'Filtre'),
                Tab(icon: Icon(Icons.draw), text: 'Çiz'),
              ],
            ),

          // Tab content
          Container(
            height: widget.showCropOnly ? 100 : 120,
            color: const Color(0xFF1C1C1E),
            child: widget.showCropOnly
                ? _buildCropControls()
                : IndexedStack(
                    index: _currentTab,
                    children: [
                      _buildCropControls(),
                      _buildRotateControls(),
                      _buildFilterControls(),
                      _buildDrawControls(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropControls() {
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _aspectRatios.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final ratio = _aspectRatios[index];
              final isSelected = index == _selectedAspectRatioIndex;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedAspectRatioIndex = index;
                    if (ratio.ratio != null && _imageSize != Size.zero) {
                      // Adjust crop rect to match aspect ratio
                      final newWidth = _imageSize.width * 0.8;
                      final newHeight = newWidth / ratio.ratio!;
                      _cropRect = Rect.fromCenter(
                        center: Offset(
                          _imageSize.width / 2,
                          _imageSize.height / 2,
                        ),
                        width: newWidth,
                        height: newHeight.clamp(0, _imageSize.height * 0.9),
                      );
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? NearTheme.primary
                        : Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      ratio.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRotateControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RotateButton(
          icon: Icons.rotate_left,
          label: 'Sola',
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _rotation = (_rotation - 90) % 360);
          },
        ),
        _RotateButton(
          icon: Icons.rotate_right,
          label: 'Sağa',
          onTap: _rotate90,
        ),
        _RotateButton(
          icon: Icons.flip,
          label: 'Yatay',
          onTap: () => _flip(true),
        ),
        _RotateButton(
          icon: Icons.flip,
          label: 'Dikey',
          isVertical: true,
          onTap: () => _flip(false),
        ),
      ],
    );
  }

  Widget _buildFilterControls() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = index == _selectedFilterIndex;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilterIndex = index);
            },
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: NearTheme.primary, width: 2)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ColorFiltered(
                      colorFilter: filter.matrix != null
                          ? ColorFilter.matrix(filter.matrix!)
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply),
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  filter.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? NearTheme.primary : Colors.white60,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawControls() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Color picker
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final color in [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.purple,
                Colors.pink,
                Colors.white,
                Colors.black,
              ])
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _drawingColor = color);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _drawingColor == color
                          ? Border.all(color: NearTheme.primary, width: 3)
                          : Border.all(color: Colors.white30),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Stroke width + actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.brush, color: Colors.white60, size: 20),
              Expanded(
                child: Slider(
                  value: _drawingStrokeWidth,
                  min: 2,
                  max: 20,
                  activeColor: NearTheme.primary,
                  onChanged: (v) => setState(() => _drawingStrokeWidth = v),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.white60),
                onPressed: _undoDrawing,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white60),
                onPressed: _clearDrawings,
              ),
              IconButton(
                icon: const Icon(Icons.text_fields, color: Colors.white60),
                onPressed: _addText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RotateButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isVertical;

  const _RotateButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Transform.rotate(
            angle: isVertical ? math.pi / 2 : 0,
            child: Icon(icon, color: Colors.white70, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CropOverlay extends StatefulWidget {
  final Size imageSize;
  final Rect cropRect;
  final ValueChanged<Rect> onCropRectChanged;
  final double? aspectRatio;

  const _CropOverlay({
    required this.imageSize,
    required this.cropRect,
    required this.onCropRectChanged,
    this.aspectRatio,
  });

  @override
  State<_CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<_CropOverlay> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.imageSize.width,
      height: widget.imageSize.height,
      child: CustomPaint(
        painter: _CropPainter(cropRect: widget.cropRect),
        child: Stack(
          children: [
            // Corner handles
            _buildHandle(Alignment.topLeft),
            _buildHandle(Alignment.topRight),
            _buildHandle(Alignment.bottomLeft),
            _buildHandle(Alignment.bottomRight),
            // Edge handles
            _buildHandle(Alignment.topCenter),
            _buildHandle(Alignment.bottomCenter),
            _buildHandle(Alignment.centerLeft),
            _buildHandle(Alignment.centerRight),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(Alignment alignment) {
    double left = 0, top = 0;

    if (alignment == Alignment.topLeft) {
      left = widget.cropRect.left - 10;
      top = widget.cropRect.top - 10;
    } else if (alignment == Alignment.topRight) {
      left = widget.cropRect.right - 10;
      top = widget.cropRect.top - 10;
    } else if (alignment == Alignment.bottomLeft) {
      left = widget.cropRect.left - 10;
      top = widget.cropRect.bottom - 10;
    } else if (alignment == Alignment.bottomRight) {
      left = widget.cropRect.right - 10;
      top = widget.cropRect.bottom - 10;
    } else if (alignment == Alignment.topCenter) {
      left = widget.cropRect.center.dx - 10;
      top = widget.cropRect.top - 10;
    } else if (alignment == Alignment.bottomCenter) {
      left = widget.cropRect.center.dx - 10;
      top = widget.cropRect.bottom - 10;
    } else if (alignment == Alignment.centerLeft) {
      left = widget.cropRect.left - 10;
      top = widget.cropRect.center.dy - 10;
    } else if (alignment == Alignment.centerRight) {
      left = widget.cropRect.right - 10;
      top = widget.cropRect.center.dy - 10;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) => _onHandleDrag(alignment, details.delta),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onHandleDrag(Alignment alignment, Offset delta) {
    Rect newRect = widget.cropRect;
    const minSize = 50.0;

    if (alignment == Alignment.topLeft) {
      newRect = Rect.fromLTRB(
        (newRect.left + delta.dx).clamp(0, newRect.right - minSize),
        (newRect.top + delta.dy).clamp(0, newRect.bottom - minSize),
        newRect.right,
        newRect.bottom,
      );
    } else if (alignment == Alignment.topRight) {
      newRect = Rect.fromLTRB(
        newRect.left,
        (newRect.top + delta.dy).clamp(0, newRect.bottom - minSize),
        (newRect.right + delta.dx).clamp(newRect.left + minSize, widget.imageSize.width),
        newRect.bottom,
      );
    } else if (alignment == Alignment.bottomLeft) {
      newRect = Rect.fromLTRB(
        (newRect.left + delta.dx).clamp(0, newRect.right - minSize),
        newRect.top,
        newRect.right,
        (newRect.bottom + delta.dy).clamp(newRect.top + minSize, widget.imageSize.height),
      );
    } else if (alignment == Alignment.bottomRight) {
      newRect = Rect.fromLTRB(
        newRect.left,
        newRect.top,
        (newRect.right + delta.dx).clamp(newRect.left + minSize, widget.imageSize.width),
        (newRect.bottom + delta.dy).clamp(newRect.top + minSize, widget.imageSize.height),
      );
    } else if (alignment == Alignment.topCenter) {
      newRect = Rect.fromLTRB(
        newRect.left,
        (newRect.top + delta.dy).clamp(0, newRect.bottom - minSize),
        newRect.right,
        newRect.bottom,
      );
    } else if (alignment == Alignment.bottomCenter) {
      newRect = Rect.fromLTRB(
        newRect.left,
        newRect.top,
        newRect.right,
        (newRect.bottom + delta.dy).clamp(newRect.top + minSize, widget.imageSize.height),
      );
    } else if (alignment == Alignment.centerLeft) {
      newRect = Rect.fromLTRB(
        (newRect.left + delta.dx).clamp(0, newRect.right - minSize),
        newRect.top,
        newRect.right,
        newRect.bottom,
      );
    } else if (alignment == Alignment.centerRight) {
      newRect = Rect.fromLTRB(
        newRect.left,
        newRect.top,
        (newRect.right + delta.dx).clamp(newRect.left + minSize, widget.imageSize.width),
        newRect.bottom,
      );
    }

    widget.onCropRectChanged(newRect);
  }
}

class _CropPainter extends CustomPainter {
  final Rect cropRect;

  _CropPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    // Dim outside area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = Colors.black54,
    );

    // Crop border
    canvas.drawRect(
      cropRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Grid lines (rule of thirds)
    final thirdWidth = cropRect.width / 3;
    final thirdHeight = cropRect.height / 3;
    final gridPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 0.5;

    // Vertical lines
    canvas.drawLine(
      Offset(cropRect.left + thirdWidth, cropRect.top),
      Offset(cropRect.left + thirdWidth, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + thirdWidth * 2, cropRect.top),
      Offset(cropRect.left + thirdWidth * 2, cropRect.bottom),
      gridPaint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + thirdHeight),
      Offset(cropRect.right, cropRect.top + thirdHeight),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + thirdHeight * 2),
      Offset(cropRect.right, cropRect.top + thirdHeight * 2),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}

class _DrawingPainter extends CustomPainter {
  final List<_DrawingPath> drawings;
  final List<Offset> currentDrawing;
  final Color currentColor;
  final double currentStrokeWidth;

  _DrawingPainter({
    required this.drawings,
    required this.currentDrawing,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw saved paths
    for (final drawing in drawings) {
      if (drawing.points.length < 2) continue;

      final paint = Paint()
        ..color = drawing.color
        ..strokeWidth = drawing.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(drawing.points.first.dx, drawing.points.first.dy);
      for (int i = 1; i < drawing.points.length; i++) {
        path.lineTo(drawing.points[i].dx, drawing.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current path
    if (currentDrawing.length >= 2) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(currentDrawing.first.dx, currentDrawing.first.dy);
      for (int i = 1; i < currentDrawing.length; i++) {
        path.lineTo(currentDrawing[i].dx, currentDrawing[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return true;
  }
}

// Data classes
class _ImageFilter {
  final String name;
  final List<double>? matrix;

  const _ImageFilter({required this.name, this.matrix});
}

class _AspectRatio {
  final String name;
  final double? ratio;

  const _AspectRatio({required this.name, this.ratio});
}

class _TextOverlay {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;

  const _TextOverlay({
    required this.text,
    required this.position,
    required this.color,
    required this.fontSize,
  });

  _TextOverlay copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? fontSize,
  }) {
    return _TextOverlay(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class _DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const _DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

// Filter matrices
const List<double> _vivid = [
  1.2, 0, 0, 0, 0,
  0, 1.2, 0, 0, 0,
  0, 0, 1.2, 0, 0,
  0, 0, 0, 1, 0,
];

const List<double> _warm = [
  1.2, 0, 0, 0, 20,
  0, 1.1, 0, 0, 10,
  0, 0, 0.9, 0, 0,
  0, 0, 0, 1, 0,
];

const List<double> _cool = [
  0.9, 0, 0, 0, 0,
  0, 1.0, 0, 0, 0,
  0, 0, 1.2, 0, 20,
  0, 0, 0, 1, 0,
];

const List<double> _grayscale = [
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

const List<double> _sepia = [
  0.393, 0.769, 0.189, 0, 0,
  0.349, 0.686, 0.168, 0, 0,
  0.272, 0.534, 0.131, 0, 0,
  0, 0, 0, 1, 0,
];

const List<double> _highContrast = [
  1.5, 0, 0, 0, -30,
  0, 1.5, 0, 0, -30,
  0, 0, 1.5, 0, -30,
  0, 0, 0, 1, 0,
];

const List<double> _fade = [
  1, 0, 0, 0, 30,
  0, 1, 0, 0, 30,
  0, 0, 1, 0, 30,
  0, 0, 0, 0.9, 0,
];
