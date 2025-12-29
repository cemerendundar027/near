import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../app/theme.dart';
import '../../shared/widgets/image_editor.dart';
import '../../shared/widgets/video_trimmer.dart';
import '../../shared/story_service.dart';

/// Story oluşturma sayfası
/// - Kamera/Galeri seçimi (fotoğraf ve video)
/// - Metin story oluşturma
/// - Video kırpma (max 60 saniye)
/// - Düzenleme araçları
/// - Paylaş butonu
class StoryCreatePage extends StatefulWidget {
  static const route = '/create-story';
  const StoryCreatePage({super.key});

  @override
  State<StoryCreatePage> createState() => _StoryCreatePageState();
}

class _StoryCreatePageState extends State<StoryCreatePage>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  File? _selectedImage;
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  VideoTrimResult? _videoTrimResult;
  bool _isVideoStory = false;
  bool _isTextStory = false;
  Color _backgroundColor = NearTheme.primary;
  TextAlign _textAlign = TextAlign.center;
  double _fontSize = 24;
  bool _isBold = false;

  final List<Color> _backgroundColors = [
    NearTheme.primary,
    NearTheme.primaryDark,
    const Color(0xFF25D366),
    const Color(0xFF128C7E),
    const Color(0xFFE91E63),
    const Color(0xFFFF5722),
    const Color(0xFF2196F3),
    const Color(0xFF9C27B0),
    const Color(0xFF607D8B),
    const Color(0xFF000000),
  ];

  final List<LinearGradient> _gradients = [
    const LinearGradient(
      colors: [Color(0xFF7B3FF2), Color(0xFF5A22C8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    const LinearGradient(
      colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  int _selectedGradientIndex = 0;
  bool _useGradient = true;

  @override
  void dispose() {
    _textController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isTextStory = false;
        });
      }
    } catch (e) {
      _showSnackBar('Fotoğraf seçilemedi');
    }
  }

  Future<void> _openImageEditor() async {
    if (_selectedImage == null) return;
    
    final editedFile = await ImageEditorPage.open(context, _selectedImage!);
    if (editedFile != null && mounted) {
      setState(() {
        _selectedImage = editedFile;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5), // 5 dakikaya kadar seçebilir
      );

      if (video != null) {
        final videoFile = File(video.path);
        
        // Video süresini kontrol et
        final tempController = VideoPlayerController.file(videoFile);
        await tempController.initialize();
        final duration = tempController.value.duration;
        await tempController.dispose();

        if (duration.inSeconds > 60) {
          // 60 saniyeden uzunsa, trimmer aç
          if (!mounted) return;
          
          final trimResult = await VideoTrimmerPage.open(
            context,
            videoFile,
            maxDuration: const Duration(seconds: 60),
          );

          if (trimResult != null && mounted) {
            _initVideoWithTrim(trimResult);
          }
        } else {
          // 60 saniye veya daha kısa, doğrudan kullan
          _initVideo(videoFile);
        }
      }
    } catch (e) {
      _showSnackBar('Video seçilemedi: $e');
    }
  }

  void _initVideo(File videoFile) async {
    setState(() {
      _selectedVideo = videoFile;
      _videoTrimResult = null;
      _isVideoStory = true;
      _isTextStory = false;
      _selectedImage = null;
    });

    _videoController?.dispose();
    _videoController = VideoPlayerController.file(videoFile);
    await _videoController!.initialize();
    _videoController!.setLooping(true);
    _videoController!.play();
    setState(() {});
  }

  void _initVideoWithTrim(VideoTrimResult trimResult) async {
    setState(() {
      _selectedVideo = trimResult.originalFile;
      _videoTrimResult = trimResult;
      _isVideoStory = true;
      _isTextStory = false;
      _selectedImage = null;
    });

    _videoController?.dispose();
    _videoController = VideoPlayerController.file(trimResult.originalFile);
    await _videoController!.initialize();
    
    // Kırpılmış başlangıç noktasına git
    await _videoController!.seekTo(trimResult.startTime);
    _videoController!.play();
    
    // Kırpılmış süre içinde loop yap
    _videoController!.addListener(_videoLoopListener);
    
    setState(() {});
  }

  void _videoLoopListener() {
    if (_videoController == null || _videoTrimResult == null) return;
    
    final position = _videoController!.value.position;
    if (position >= _videoTrimResult!.endTime) {
      _videoController!.seekTo(_videoTrimResult!.startTime);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  String _formatVideoDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _createTextStory() {
    setState(() {
      _isTextStory = true;
      _isVideoStory = false;
      _selectedImage = null;
      _selectedVideo = null;
    });
  }

  void _showPhotoSourceOptions() {
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
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoSourceOptions() {
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Video (maks. 60 saniye)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_rounded),
                title: const Text('Kamera'),
                subtitle: const Text('Video çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_rounded),
                title: const Text('Galeri'),
                subtitle: const Text('Video seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaOptions() {
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
              const SizedBox(height: 24),
              Text(
                'Story Oluştur',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MediaOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Fotoğraf',
                    color: NearTheme.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _showPhotoSourceOptions();
                    },
                  ),
                  _MediaOption(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    color: const Color(0xFFE91E63),
                    onTap: () {
                      Navigator.pop(context);
                      _showVideoSourceOptions();
                    },
                  ),
                  _MediaOption(
                    icon: Icons.text_fields_rounded,
                    label: 'Metin',
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      Navigator.pop(context);
                      _createTextStory();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareStory() async {
    if (_isTextStory && _textController.text.trim().isEmpty) {
      _showSnackBar('Lütfen bir metin girin');
      return;
    }

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: NearTheme.primary),
            const SizedBox(width: 16),
            Text(_isVideoStory ? 'Video yükleniyor...' : 'Paylaşılıyor...'),
          ],
        ),
      ),
    );

    final storyService = StoryService.instance;
    Story? result;

    if (_isTextStory) {
      // Metin story oluştur
      result = await storyService.createTextStory(
        text: _textController.text.trim(),
        metadata: {
          'useGradient': _useGradient,
          'gradientIndex': _selectedGradientIndex,
          'backgroundColor': _backgroundColor.value,
          'fontSize': _fontSize,
          'textAlign': _textAlign.toString(),
          'isBold': _isBold,
        },
      );
    } else if (_isVideoStory && _selectedVideo != null) {
      // Video story oluştur
      result = await storyService.createVideoStory(
        videoFile: _selectedVideo!,
        caption: _textController.text.trim().isEmpty 
            ? null 
            : _textController.text.trim(),
        trimStart: _videoTrimResult?.startTime,
        trimEnd: _videoTrimResult?.endTime,
      );
    } else if (_selectedImage != null) {
      // Fotoğraf story oluştur
      result = await storyService.createImageStory(
        imageFile: _selectedImage!,
        caption: _textController.text.trim().isEmpty 
            ? null 
            : _textController.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.pop(context); // Dialog kapat

    if (result != null) {
      Navigator.pop(context); // Page kapat
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Durumunuz paylaşıldı!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      debugPrint('StoryCreatePage: Story creation failed');
      _showSnackBar('Durum paylaşılamadı. Supabase bağlantısını kontrol edin.');
    }
  }

  void _showEmojiPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<String> emojiList = [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
      '🙂', '😉', '😊', '😇', '🥰', '😍', '🤩', '😘',
      '😗', '😚', '😋', '😛', '😜', '🤪', '😝', '🤑',
      '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑',
      '😶', '😏', '😒', '🙄', '😬', '🤥', '😌', '😔',
      '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮',
      '🤧', '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳',
      '🥸', '😎', '🤓', '🧐', '😕', '😟', '🙁', '😮',
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘',
      '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️',
      '🤟', '🤘', '👌', '🤌', '🤏', '👈', '👉', '👆',
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Emoji Ekle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1,
                ),
                itemCount: emojiList.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _textController.text += emojiList[index];
                      });
                      Navigator.pop(context);
                    },
                    child: Center(
                      child: Text(
                        emojiList[index],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStickerPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<IconData> stickerIcons = [
      Icons.favorite,
      Icons.star,
      Icons.thumb_up,
      Icons.celebration,
      Icons.mood,
      Icons.sentiment_very_satisfied,
      Icons.pets,
      Icons.local_fire_department,
      Icons.flash_on,
      Icons.auto_awesome,
      Icons.emoji_events,
      Icons.cake,
      Icons.sports_esports,
      Icons.music_note,
      Icons.beach_access,
      Icons.flight,
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sticker Ekle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: stickerIcons.length,
                itemBuilder: (context, index) {
                  final colors = [
                    NearTheme.primary,
                    Colors.pink,
                    Colors.orange,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                    Colors.teal,
                  ];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Sticker eklendi');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        stickerIcons[index],
                        size: 40,
                        color: colors[index % colors.length],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTextOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                const SizedBox(height: 16),
                // Font size slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 16,
                          max: 48,
                          activeColor: NearTheme.primary,
                          onChanged: (v) {
                            setModalState(() => _fontSize = v);
                            setState(() => _fontSize = v);
                          },
                        ),
                      ),
                      Text(
                        '${_fontSize.round()}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Text align options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TextAlignOption(
                        icon: Icons.format_align_left,
                        isSelected: _textAlign == TextAlign.left,
                        onTap: () {
                          setModalState(() => _textAlign = TextAlign.left);
                          setState(() => _textAlign = TextAlign.left);
                        },
                      ),
                      _TextAlignOption(
                        icon: Icons.format_align_center,
                        isSelected: _textAlign == TextAlign.center,
                        onTap: () {
                          setModalState(() => _textAlign = TextAlign.center);
                          setState(() => _textAlign = TextAlign.center);
                        },
                      ),
                      _TextAlignOption(
                        icon: Icons.format_align_right,
                        isSelected: _textAlign == TextAlign.right,
                        onTap: () {
                          setModalState(() => _textAlign = TextAlign.right);
                          setState(() => _textAlign = TextAlign.right);
                        },
                      ),
                      _TextAlignOption(
                        icon: Icons.format_bold,
                        isSelected: _isBold,
                        onTap: () {
                          setModalState(() => _isBold = !_isBold);
                          setState(() => _isBold = !_isBold);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Boş durum - henüz içerik seçilmemiş
    if (_selectedImage == null && !_isTextStory && !_isVideoStory) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Yeni Durum',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: NearTheme.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 60,
                  color: NearTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Durum Oluştur',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fotoğraf veya metin paylaşın',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showMediaOptions,
                icon: const Icon(Icons.add_rounded),
                label: const Text('İçerik Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NearTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Metin story düzenleme
    if (_isTextStory) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: _useGradient ? _gradients[_selectedGradientIndex] : null,
            color: _useGradient ? null : _backgroundColor,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Metin girişi
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: TextField(
                      controller: _textController,
                      textAlign: _textAlign,
                      cursorColor: Colors.white,
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: _isBold ? FontWeight.bold : FontWeight.w500,
                        color: Colors.white,
                        height: 1.4,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      decoration: InputDecoration(
                        hintText: 'Bir şeyler yaz...',
                        hintStyle: TextStyle(
                          fontSize: _fontSize,
                          color: Colors.white70,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),

                // Üst bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.text_format,
                                color: Colors.white,
                              ),
                              onPressed: _showTextOptions,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.emoji_emotions_outlined,
                                color: Colors.white,
                              ),
                              onPressed: _showEmojiPicker,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Alt bar - renk seçici
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Gradient toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ToggleChip(
                              label: 'Gradient',
                              isSelected: _useGradient,
                              onTap: () => setState(() => _useGradient = true),
                            ),
                            const SizedBox(width: 12),
                            _ToggleChip(
                              label: 'Düz Renk',
                              isSelected: !_useGradient,
                              onTap: () => setState(() => _useGradient = false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Renk/Gradient listesi
                        SizedBox(
                          height: 50,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _useGradient
                                ? _gradients.length
                                : _backgroundColors.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final isSelected = _useGradient
                                  ? index == _selectedGradientIndex
                                  : _backgroundColors[index] ==
                                        _backgroundColor;

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_useGradient) {
                                      _selectedGradientIndex = index;
                                    } else {
                                      _backgroundColor =
                                          _backgroundColors[index];
                                    }
                                  });
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: _useGradient
                                        ? _gradients[index]
                                        : null,
                                    color: _useGradient
                                        ? null
                                        : _backgroundColors[index],
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Paylaş butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _shareStory,
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('Paylaş'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: NearTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Video story düzenleme
    if (_isVideoStory && _selectedVideo != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player
              if (_videoController != null && _videoController!.value.isInitialized)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                )
              else
                Center(
                  child: CircularProgressIndicator(color: NearTheme.primary),
                ),

              // Play/Pause overlay
              if (_videoController != null && !_videoController!.value.isPlaying)
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Video duration indicator
              if (_videoController != null && _videoController!.value.isInitialized)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _videoTrimResult != null
                            ? '${_formatVideoDuration(_videoTrimResult!.duration)}'
                            : '${_formatVideoDuration(_videoController!.value.duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

              // Üst bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.content_cut_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          final result = await VideoTrimmerPage.open(
                            context,
                            _selectedVideo!,
                            maxDuration: const Duration(seconds: 60),
                          );
                          if (result != null && mounted) {
                            _initVideoWithTrim(result);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Alt bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Caption input
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Açıklama ekle...',
                              hintStyle: TextStyle(color: Colors.white60),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Send button
                      GestureDetector(
                        onTap: _shareStory,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: NearTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fotoğraf story düzenleme
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fotoğraf
            if (_selectedImage != null)
              InteractiveViewer(
                child: Image.file(_selectedImage!, fit: BoxFit.contain),
              ),

            // Üst bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.crop_rotate,
                            color: Colors.white,
                          ),
                          onPressed: () => _openImageEditor(),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.white,
                          ),
                          onPressed: _showStickerPicker,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.text_fields,
                            color: Colors.white,
                          ),
                          onPressed: () => _openImageEditor(),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.draw_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => _openImageEditor(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Alt bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Caption input
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Açıklama ekle...',
                            hintStyle: TextStyle(color: Colors.white60),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send button
                    GestureDetector(
                      onTap: _shareStory,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: NearTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAlignOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TextAlignOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: isSelected ? NearTheme.primary : Colors.grey),
      onPressed: onTap,
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? NearTheme.primary : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
