// lib/features/story/story_viewer_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../app/theme.dart';
import '../../shared/story_service.dart';

class StoryViewerArgs {
  final List<UserStories> userStoriesList;
  final int initialUserIndex;
  const StoryViewerArgs({
    required this.userStoriesList,
    required this.initialUserIndex,
  });
}

class StoryViewerPage extends StatefulWidget {
  static const route = '/story';

  /// Deep link parameter: user ID to view story
  final String? deepLinkUserId;

  const StoryViewerPage({super.key, this.deepLinkUserId});

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  static const _storyDuration = Duration(seconds: 6);

  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  Timer? _timer;

  final _storyService = StoryService.instance;
  
  List<UserStories> _userStoriesList = [];
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;

  DateTime? _startedAt;
  bool _paused = false;
  bool _initialized = false;
  bool _isReplying = false;
  
  // Video player
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;

  UserStories? get _currentUser => 
      _userStoriesList.isNotEmpty && _currentUserIndex < _userStoriesList.length
          ? _userStoriesList[_currentUserIndex]
          : null;

  Story? get _currentStory {
    final user = _currentUser;
    if (user == null || user.stories.isEmpty) return null;
    if (_currentStoryIndex >= user.stories.length) return null;
    return user.stories[_currentStoryIndex];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    // Priority: Deep link userId > Route arguments
    if (widget.deepLinkUserId != null) {
      _userStoriesList = _storyService.userStories;
      _currentUserIndex = _userStoriesList.indexWhere(
        (us) => us.userId == widget.deepLinkUserId,
      );
      if (_currentUserIndex == -1) _currentUserIndex = 0;
    } else {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is StoryViewerArgs) {
        _userStoriesList = arg.userStoriesList;
        _currentUserIndex = arg.initialUserIndex.clamp(
          0,
          _userStoriesList.isEmpty ? 0 : _userStoriesList.length - 1,
        );
      } else {
        _userStoriesList = _storyService.userStories;
      }
    }

    if (_userStoriesList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _safeGoBack();
      });
      return;
    }

    _markCurrentStoryAsViewed();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    _replyController.dispose();
    _videoController?.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _markCurrentStoryAsViewed() {
    final story = _currentStory;
    if (story != null) {
      _storyService.markStoryAsViewed(story.id);
    }
  }

  void _start() {
    _timer?.cancel();
    _progress.value = 0;
    _paused = false;
    _startedAt = DateTime.now();

    final story = _currentStory;
    
    // Video story'ler kendi progress'lerini yönetir
    if (story?.type == 'video') {
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted || _paused || _startedAt == null) return;
      final elapsed = DateTime.now().difference(_startedAt!);
      final currentStory = _currentStory;
      final duration = currentStory != null 
          ? Duration(seconds: currentStory.duration) 
          : _storyDuration;
      final p = elapsed.inMilliseconds / duration.inMilliseconds;
      final v = p.clamp(0.0, 1.0);
      _progress.value = v;
      if (v >= 1) _nextStory();
    });
  }

  void _pause() {
    if (!mounted) return;
    setState(() => _paused = true);
    
    // Video'yu da durdur
    if (_currentStory?.type == 'video') {
      _videoController?.pause();
    }
  }

  void _resume() {
    if (!mounted) return;
    if (!_paused) return;

    setState(() => _paused = false);
    
    // Video story
    if (_currentStory?.type == 'video') {
      _videoController?.play();
      return;
    }
    
    _startedAt = DateTime.now().subtract(
      Duration(
        milliseconds: (_progress.value * _storyDuration.inMilliseconds).round(),
      ),
    );
  }

  void _nextStory() {
    final user = _currentUser;
    if (user == null) return;

    // Video controller'ı temizle
    _disposeVideoController();

    // Aynı kullanıcının sonraki story'si
    if (_currentStoryIndex < user.stories.length - 1) {
      setState(() => _currentStoryIndex++);
      _markCurrentStoryAsViewed();
      _start();
      return;
    }

    // Sonraki kullanıcıya geç
    if (_currentUserIndex < _userStoriesList.length - 1) {
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
      });
      _markCurrentStoryAsViewed();
      _start();
      return;
    }

    // Tüm story'ler bitti
    _safeGoBack();
  }
  
  /// Güvenli geri dönüş - go_router stack kontrolü ile
  void _safeGoBack() {
    if (!mounted) return;
    
    // go_router ile güvenli geri dönüş
    if (context.canPop()) {
      context.pop();
    } else {
      // Stack boşsa ana sayfaya git
      context.go('/');
    }
  }

  void _disposeVideoController() {
    _videoController?.removeListener(_onVideoProgress);
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitializing = false;
  }

  // Alias for _nextStory
  void _next() {
    _nextStory();
  }

  void _prevStory() {
    // Video controller'ı temizle
    _disposeVideoController();

    // Aynı kullanıcının önceki story'si
    if (_currentStoryIndex > 0) {
      setState(() => _currentStoryIndex--);
      _start();
      return;
    }

    // Önceki kullanıcıya geç
    if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        final user = _currentUser;
        _currentStoryIndex = user != null ? user.stories.length - 1 : 0;
      });
      _start();
      return;
    }

    // İlk story'deyiz, başa dön
    _start();
  }

  void _showViewers() {
    final story = _currentStory;
    if (story == null) return;
    
    // Sadece kendi story'lerinde görüntüleyenleri göster
    if (story.userId != _storyService.currentUserId) return;

    _pause();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ViewersSheet(
        storyId: story.id,
        viewsCount: story.viewsCount,
        onClose: () {
          Navigator.pop(context);
          _resume();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final story = _currentStory;

    if (user == null || story == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onLongPressStart: (_) => _pause(),
          onLongPressEnd: (_) => _resume(),
          child: Stack(
            children: [
              // Background - Story content
              Positioned.fill(
                child: _buildStoryContent(story),
              ),

              // Tap zones (prev/next)
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _prevStory,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _nextStory,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),

              // Top: progress bars + header
              Positioned(
                left: 12,
                right: 12,
                top: 8,
                child: Column(
                  children: [
                    // Progress bars
                    Row(
                      children: List.generate(
                        user.stories.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index > 0 ? 2 : 0,
                              right: index < user.stories.length - 1 ? 2 : 0,
                            ),
                            child: index == _currentStoryIndex
                                ? ValueListenableBuilder<double>(
                                    valueListenable: _progress,
                                    builder: (_, v, __) => ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: v,
                                        minHeight: 3,
                                        backgroundColor: Colors.white.withAlpha(80),
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: index < _currentStoryIndex
                                          ? Colors.white
                                          : Colors.white.withAlpha(80),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: _safeGoBack,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Avatar
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          backgroundImage: user.userAvatar != null
                              ? NetworkImage(user.userAvatar!)
                              : null,
                          child: user.userAvatar == null
                              ? const Icon(Icons.person, color: Colors.white, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _formatTime(story.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _paused ? _resume() : _pause(),
                          icon: Icon(
                            _paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white,
                          ),
                        ),
                        if (story.userId == _storyService.currentUserId)
                          IconButton(
                            onPressed: _showViewers,
                            icon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.visibility_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${story.viewsCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Caption (if exists)
              if (story.caption != null && 
                  story.caption!.isNotEmpty && 
                  story.type == 'image')
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 100,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(120),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      story.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Bottom reply input (only for others' stories)
              if (story.userId != _storyService.currentUserId)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 18,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isReplying = true);
                      _pause();
                      _replyFocusNode.requestFocus();
                    },
                    child: _isReplying
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(180),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withAlpha(30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _replyController,
                                    focusNode: _replyFocusNode,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: '${user.userName} adlı kişiye yanıt ver...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withAlpha(150),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    onSubmitted: (_) => _sendReply(),
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: NearTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: _sendReply,
                                    icon: const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withAlpha(30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Mesaj gönder…',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(200),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryContent(Story story) {
    if (story.type == 'text') {
      return _buildTextStory(story);
    } else if (story.type == 'video') {
      return _buildVideoStory(story);
    } else {
      return _buildImageStory(story);
    }
  }

  Widget _buildVideoStory(Story story) {
    if (story.mediaUrl == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54, size: 64),
        ),
      );
    }

    // Video controller'ı başlat (eğer henüz yoksa veya farklı bir video ise)
    if (_videoController == null || 
        _videoController!.dataSource != story.mediaUrl) {
      _initVideoController(story);
    }

    if (_isVideoInitializing || _videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: NearTheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Video yükleniyor...',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  void _initVideoController(Story story) async {
    if (_isVideoInitializing) return;
    
    setState(() => _isVideoInitializing = true);
    
    // Önceki controller'ı dispose et
    _videoController?.dispose();
    
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl!));
      await _videoController!.initialize();
      
      // Trim başlangıç noktasına git (eğer varsa)
      final metadata = story.metadata;
      if (metadata != null && metadata['trimStart'] != null) {
        final trimStart = Duration(milliseconds: metadata['trimStart'] as int);
        await _videoController!.seekTo(trimStart);
      }
      
      _videoController!.setLooping(false);
      _videoController!.play();
      
      // Video bittiğinde sonraki story'e geç
      _videoController!.addListener(_onVideoProgress);
      
      if (mounted) {
        setState(() => _isVideoInitializing = false);
      }
    } catch (e) {
      debugPrint('StoryViewer: Error initializing video: $e');
      if (mounted) {
        setState(() => _isVideoInitializing = false);
      }
    }
  }

  void _onVideoProgress() {
    if (_videoController == null) return;
    
    final story = _currentStory;
    if (story == null || story.type != 'video') return;
    
    final metadata = story.metadata;
    final trimEnd = metadata != null && metadata['trimEnd'] != null
        ? Duration(milliseconds: metadata['trimEnd'] as int)
        : _videoController!.value.duration;
    
    final position = _videoController!.value.position;
    
    // Progress güncelle
    final trimStart = metadata != null && metadata['trimStart'] != null
        ? Duration(milliseconds: metadata['trimStart'] as int)
        : Duration.zero;
    final totalDuration = trimEnd - trimStart;
    if (totalDuration.inMilliseconds > 0) {
      _progress.value = (position - trimStart).inMilliseconds / totalDuration.inMilliseconds;
    }
    
    // Video bittiğinde
    if (position >= trimEnd || !_videoController!.value.isPlaying && _videoController!.value.position >= trimEnd - const Duration(milliseconds: 100)) {
      _videoController!.removeListener(_onVideoProgress);
      _next();
    }
  }

  Widget _buildImageStory(Story story) {
    if (story.mediaUrl == null) {
      return Container(
        color: NearTheme.primary,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
        ),
      );
    }

    return Image.network(
      story.mediaUrl!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        return Container(
          color: NearTheme.primary,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 64),
          ),
        );
      },
    );
  }

  Widget _buildTextStory(Story story) {
    final metadata = story.metadata ?? {};
    final useGradient = metadata['useGradient'] as bool? ?? true;
    final gradientIndex = metadata['gradientIndex'] as int? ?? 0;
    final bgColorValue = metadata['backgroundColor'] as int?;
    final fontSize = (metadata['fontSize'] as num?)?.toDouble() ?? 24.0;
    final textAlignStr = metadata['textAlign'] as String? ?? 'TextAlign.center';
    final isBold = metadata['isBold'] as bool? ?? false;

    final gradients = [
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

    TextAlign textAlign = TextAlign.center;
    if (textAlignStr.contains('left')) {
      textAlign = TextAlign.left;
    } else if (textAlignStr.contains('right')) {
      textAlign = TextAlign.right;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: useGradient && gradientIndex < gradients.length
            ? gradients[gradientIndex]
            : null,
        color: useGradient
            ? null
            : (bgColorValue != null ? Color(bgColorValue) : NearTheme.primary),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            story.caption ?? '',
            textAlign: textAlign,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    return 'Dün';
  }

  void _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final user = _currentUser;
    final story = _currentStory;
    if (user == null || story == null) return;

    _replyController.clear();
    _replyFocusNode.unfocus();
    setState(() => _isReplying = false);
    _resume();

    await _storyService.replyToStory(
      storyId: story.id,
      storyOwnerId: user.userId,
      message: text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.userName} adlı kişiye yanıt gönderildi'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Story görüntüleyenler sheet
class _ViewersSheet extends StatefulWidget {
  final String storyId;
  final int viewsCount;
  final VoidCallback onClose;

  const _ViewersSheet({
    required this.storyId,
    required this.viewsCount,
    required this.onClose,
  });

  @override
  State<_ViewersSheet> createState() => _ViewersSheetState();
}

class _ViewersSheetState extends State<_ViewersSheet> {
  final _storyService = StoryService.instance;
  List<StoryViewer> _viewers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadViewers();
  }

  Future<void> _loadViewers() async {
    final viewers = await _storyService.loadStoryViewers(widget.storyId);
    if (mounted) {
      setState(() {
        _viewers = viewers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
                const SizedBox(width: 8),
                Text(
                  'Görüntüleyenler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: NearTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 16,
                        color: NearTheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.viewsCount}',
                        style: TextStyle(
                          color: NearTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _viewers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 48,
                              color: isDark ? Colors.white38 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Henüz kimse görüntülemedi',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _viewers.length,
                        itemBuilder: (context, index) {
                          final viewer = _viewers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: NearTheme.primary.withAlpha(30),
                              backgroundImage: viewer.viewerAvatar != null
                                  ? NetworkImage(viewer.viewerAvatar!)
                                  : null,
                              child: viewer.viewerAvatar == null
                                  ? Icon(
                                      Icons.person,
                                      color: NearTheme.primary,
                                    )
                                  : null,
                            ),
                            title: Text(
                              viewer.viewerName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              _formatViewTime(viewer.viewedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatViewTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}
