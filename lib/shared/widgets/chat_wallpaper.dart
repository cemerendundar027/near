import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../app/theme.dart';

/// Duvar kağıdı ayarlarını yönetir
class WallpaperService {
  static final WallpaperService instance = WallpaperService._();
  WallpaperService._();

  /// Belirli bir chat için duvar kağıdını kaydet
  Future<void> saveWallpaper(String chatId, String? wallpaperId) async {
    final prefs = await SharedPreferences.getInstance();
    if (wallpaperId == null) {
      await prefs.remove('wallpaper_$chatId');
    } else {
      await prefs.setString('wallpaper_$chatId', wallpaperId);
    }
  }

  /// Belirli bir chat için duvar kağıdını getir
  Future<String?> getWallpaper(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('wallpaper_$chatId');
  }

  /// Custom resmi kaydet
  Future<String> saveCustomImage(String chatId, File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'wallpaper_${chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await imageFile.copy('${dir.path}/$fileName');
    return savedFile.path;
  }
}

/// Sohbet duvar kağıdı seçenekleri
class ChatWallpaperPicker extends StatefulWidget {
  final String chatId;
  final String? currentWallpaper;
  final Function(String? wallpaper) onWallpaperChanged;

  const ChatWallpaperPicker({
    super.key,
    required this.chatId,
    this.currentWallpaper,
    required this.onWallpaperChanged,
  });

  @override
  State<ChatWallpaperPicker> createState() => _ChatWallpaperPickerState();
}

class _ChatWallpaperPickerState extends State<ChatWallpaperPicker> {
  late String? _selectedWallpaper;

  // Önceden tanımlı duvar kağıtları
  final List<WallpaperOption> _wallpapers = [
    WallpaperOption(id: null, name: 'Varsayılan', isDefault: true),
    WallpaperOption(
      id: 'gradient_purple',
      name: 'Mor Gradyan',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7B3FF2), Color(0xFF5A22C8)],
      ),
    ),
    WallpaperOption(
      id: 'gradient_blue',
      name: 'Mavi Gradyan',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1DA1F2), Color(0xFF0D47A1)],
      ),
    ),
    WallpaperOption(
      id: 'gradient_green',
      name: 'Yeşil Gradyan',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF25D366), Color(0xFF128C7E)],
      ),
    ),
    WallpaperOption(
      id: 'gradient_orange',
      name: 'Turuncu Gradyan',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
      ),
    ),
    WallpaperOption(
      id: 'gradient_dark',
      name: 'Koyu',
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
      ),
    ),
    WallpaperOption(
      id: 'pattern_dots',
      name: 'Noktalar',
      patternType: PatternType.dots,
    ),
    WallpaperOption(
      id: 'pattern_lines',
      name: 'Çizgiler',
      patternType: PatternType.lines,
    ),
    WallpaperOption(
      id: 'pattern_grid',
      name: 'Izgara',
      patternType: PatternType.grid,
    ),
    WallpaperOption(
      id: 'solid_light',
      name: 'Açık Gri',
      solidColor: const Color(0xFFF2F2F7),
    ),
    WallpaperOption(
      id: 'solid_dark',
      name: 'Koyu Gri',
      solidColor: const Color(0xFF2C2C2E),
    ),
    WallpaperOption(
      id: 'custom',
      name: 'Galeriden Seç',
      isCustom: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedWallpaper = widget.currentWallpaper;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        title: Text(
          'Sohbet Arka Planı',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onWallpaperChanged(_selectedWallpaper);
              Navigator.pop(context);
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildPreview(),
              ),
            ),
          ),

          // Wallpaper options
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
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
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _wallpapers.length,
                      itemBuilder: (context, index) {
                        return _buildWallpaperOption(_wallpapers[index], isDark);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final option = _wallpapers.firstWhere(
      (w) => w.id == _selectedWallpaper,
      orElse: () => _wallpapers.first,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        _buildWallpaperBackground(option),

        // Sample messages
        Positioned(
          left: 16,
          right: 80,
          top: 32,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Merhaba! Nasılsın?',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        Positioned(
          left: 80,
          right: 16,
          top: 100,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NearTheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'İyiyim, sen nasılsın? 😊',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWallpaperBackground(WallpaperOption option) {
    if (option.isDefault) {
      return Container(
        color: const Color(0xFFECE5DD),
      );
    }

    if (option.gradient != null) {
      return Container(
        decoration: BoxDecoration(gradient: option.gradient),
      );
    }

    if (option.solidColor != null) {
      return Container(color: option.solidColor);
    }

    if (option.patternType != null) {
      return _buildPattern(option.patternType!);
    }

    if (option.imageUrl != null) {
      return Image.network(
        option.imageUrl!,
        fit: BoxFit.cover,
      );
    }

    return Container(color: Colors.grey.shade200);
  }

  Widget _buildPattern(PatternType type) {
    return CustomPaint(
      painter: _PatternPainter(type),
      size: Size.infinite,
    );
  }

  Widget _buildWallpaperOption(WallpaperOption option, bool isDark) {
    final isSelected = _selectedWallpaper == option.id;

    return GestureDetector(
      onTap: () {
        if (option.isCustom) {
          _pickCustomWallpaper();
        } else {
          setState(() {
            _selectedWallpaper = option.id;
          });
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: NearTheme.primary, width: 3)
                    : Border.all(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildOptionPreview(option, isDark),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.name,
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? NearTheme.primary
                  : (isDark ? Colors.white60 : Colors.black54),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionPreview(WallpaperOption option, bool isDark) {
    if (option.isDefault) {
      return Container(
        color: const Color(0xFFECE5DD),
        child: const Center(
          child: Icon(Icons.format_color_reset, color: Colors.grey),
        ),
      );
    }

    if (option.isCustom) {
      return Container(
        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
        child: Center(
          child: Icon(
            Icons.add_photo_alternate_rounded,
            color: isDark ? Colors.white60 : Colors.grey,
          ),
        ),
      );
    }

    if (option.gradient != null) {
      return Container(
        decoration: BoxDecoration(gradient: option.gradient),
      );
    }

    if (option.solidColor != null) {
      return Container(color: option.solidColor);
    }

    if (option.patternType != null) {
      return _buildPattern(option.patternType!);
    }

    return Container(color: Colors.grey);
  }

  Future<void> _pickCustomWallpaper() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Dosyayı kalıcı olarak kaydet
      final savedPath = await WallpaperService.instance.saveCustomImage(
        widget.chatId,
        File(pickedFile.path),
      );

      setState(() {
        // Custom wallpaper ID'yi dosya yolu olarak kullan
        _selectedWallpaper = 'custom:$savedPath';
        
        // Listeye ekle veya güncelle
        final existingCustomIndex = _wallpapers.indexWhere((w) => w.id?.startsWith('custom:') == true);
        if (existingCustomIndex != -1) {
          _wallpapers[existingCustomIndex] = WallpaperOption(
            id: 'custom:$savedPath',
            name: 'Özel',
            imageUrl: savedPath,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resim seçildi'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}

/// Duvar kağıdı seçeneği
class WallpaperOption {
  final String? id;
  final String name;
  final LinearGradient? gradient;
  final Color? solidColor;
  final PatternType? patternType;
  final String? imageUrl;
  final bool isDefault;
  final bool isCustom;

  WallpaperOption({
    this.id,
    required this.name,
    this.gradient,
    this.solidColor,
    this.patternType,
    this.imageUrl,
    this.isDefault = false,
    this.isCustom = false,
  });
}

/// Desen türleri
enum PatternType { dots, lines, grid }

/// Desen painter
class _PatternPainter extends CustomPainter {
  final PatternType type;

  _PatternPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(30)
      ..strokeWidth = 1;

    switch (type) {
      case PatternType.dots:
        for (double x = 0; x < size.width; x += 20) {
          for (double y = 0; y < size.height; y += 20) {
            canvas.drawCircle(Offset(x, y), 2, paint);
          }
        }
        break;
      case PatternType.lines:
        for (double y = 0; y < size.height; y += 15) {
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y),
            paint,
          );
        }
        break;
      case PatternType.grid:
        for (double x = 0; x < size.width; x += 20) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x, size.height),
            paint,
          );
        }
        for (double y = 0; y < size.height; y += 20) {
          canvas.drawLine(
            Offset(0, y),
            Offset(size.width, y),
            paint,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chat için duvar kağıdı container widget'ı
class ChatWallpaper extends StatelessWidget {
  final String? wallpaperId;
  final Widget child;

  const ChatWallpaper({
    super.key,
    this.wallpaperId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(),
        child,
      ],
    );
  }

  Widget _buildBackground() {
    if (wallpaperId == null) {
      // Varsayılan
      return Container(
        color: const Color(0xFFECE5DD),
      );
    }

    switch (wallpaperId) {
      case 'gradient_purple':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7B3FF2), Color(0xFF5A22C8)],
            ),
          ),
        );
      case 'gradient_blue':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1DA1F2), Color(0xFF0D47A1)],
            ),
          ),
        );
      case 'gradient_green':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF25D366), Color(0xFF128C7E)],
            ),
          ),
        );
      case 'gradient_orange':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
            ),
          ),
        );
      case 'gradient_dark':
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
            ),
          ),
        );
      case 'pattern_dots':
        return CustomPaint(
          painter: _PatternPainter(PatternType.dots),
          child: Container(color: const Color(0xFFECE5DD)),
        );
      case 'pattern_lines':
        return CustomPaint(
          painter: _PatternPainter(PatternType.lines),
          child: Container(color: const Color(0xFFECE5DD)),
        );
      case 'pattern_grid':
        return CustomPaint(
          painter: _PatternPainter(PatternType.grid),
          child: Container(color: const Color(0xFFECE5DD)),
        );
      case 'solid_light':
        return Container(color: const Color(0xFFF2F2F7));
      case 'solid_dark':
        return Container(color: const Color(0xFF2C2C2E));
      default:
        // Custom wallpaper (dosya yolu)
        if (wallpaperId!.startsWith('custom:')) {
          final path = wallpaperId!.substring(7);
          return Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: const Color(0xFFECE5DD));
            },
          );
        }
        return Container(color: const Color(0xFFECE5DD));
    }
  }
}
