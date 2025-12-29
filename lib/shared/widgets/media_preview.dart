import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen media preview widget for images and videos
class MediaPreviewPage extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;
  final String? senderName;
  final DateTime? sentTime;

  const MediaPreviewPage({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.senderName,
    this.sentTime,
  });

  @override
  State<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  bool _showControls = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeController);

    // Set system UI for immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _fadeController.reverse();
      } else {
        _fadeController.forward();
      }
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media viewer
          GestureDetector(
            onTap: _toggleControls,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return _MediaItemView(item: item, onDoubleTap: _toggleControls);
              },
            ),
          ),

          // Top bar
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: 1 - _fadeAnimation.value,
                child: IgnorePointer(ignoring: !_showControls, child: child),
              );
            },
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                right: 8,
                bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.senderName != null)
                          Text(
                            widget.senderName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (widget.sentTime != null)
                          Text(
                            _formatTime(widget.sentTime),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Share action placeholder
                    },
                    icon: const Icon(Icons.share, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () {
                      // More options
                      _showOptionsSheet(context);
                    },
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar with page indicator
          if (widget.items.length > 1)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(opacity: 1 - _fadeAnimation.value, child: child);
              },
              child: Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.items.length, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.white),
                title: const Text(
                  'Kaydet',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.star_outline, color: Colors.white),
                title: const Text(
                  'Yıldızla',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.forward, color: Colors.white),
                title: const Text(
                  'İlet',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Sil', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MediaItemView extends StatefulWidget {
  final MediaItem item;
  final VoidCallback? onDoubleTap;

  const _MediaItemView({required this.item, this.onDoubleTap});

  @override
  State<_MediaItemView> createState() => _MediaItemViewState();
}

class _MediaItemViewState extends State<_MediaItemView> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final position = details.localPosition;
    final Matrix4 matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();

    if (scale > 1.0) {
      // Zoom out
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom in to double tap position
      final newMatrix = Matrix4.identity();
      newMatrix.setEntry(0, 3, -position.dx);
      newMatrix.setEntry(1, 3, -position.dy);
      newMatrix.setEntry(0, 0, 2.5);
      newMatrix.setEntry(1, 1, 2.5);
      newMatrix.setEntry(0, 3, newMatrix.entry(0, 3) + position.dx / 2.5);
      newMatrix.setEntry(1, 3, newMatrix.entry(1, 3) + position.dy / 2.5);
      _transformationController.value = newMatrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.type == MediaType.video) {
      return _VideoItemView(item: widget.item);
    }

    return GestureDetector(
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: widget.onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: widget.item.url != null
              ? Image.network(
                  widget.item.url!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                            : null,
                        color: const Color(0xFF7B3FF2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stack) {
                    return _buildPlaceholder();
                  },
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.item.type == MediaType.video ? Icons.videocam : Icons.image,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'Medya yüklenemedi',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _VideoItemView extends StatefulWidget {
  final MediaItem item;

  const _VideoItemView({required this.item});

  @override
  State<_VideoItemView> createState() => _VideoItemViewState();
}

class _VideoItemViewState extends State<_VideoItemView> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    // Placeholder video player UI
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          color: Colors.grey.shade900,
          child: widget.item.thumbnailUrl != null
              ? Image.network(
                  widget.item.thumbnailUrl!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                )
              : const SizedBox.expand(),
        ),

        // Play button
        GestureDetector(
          onTap: () {
            setState(() => _isPlaying = !_isPlaying);
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),

        // Duration badge
        if (widget.item.duration != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(widget.item.duration!),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Media item model
class MediaItem {
  final String? url;
  final String? thumbnailUrl;
  final MediaType type;
  final Duration? duration;
  final String? caption;

  const MediaItem({
    this.url,
    this.thumbnailUrl,
    required this.type,
    this.duration,
    this.caption,
  });
}

enum MediaType { image, video }

/// Media thumbnail grid for chat media gallery
class MediaGalleryGrid extends StatelessWidget {
  final List<MediaItem> items;
  final void Function(int index)? onItemTap;
  final int crossAxisCount;

  const MediaGalleryGrid({
    super.key,
    required this.items,
    this.onItemTap,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => onItemTap?.call(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              Container(
                color: Colors.grey.shade800,
                child: item.thumbnailUrl != null
                    ? Image.network(item.thumbnailUrl!, fit: BoxFit.cover)
                    : item.url != null && item.type == MediaType.image
                    ? Image.network(item.url!, fit: BoxFit.cover)
                    : Icon(
                        item.type == MediaType.video
                            ? Icons.videocam
                            : Icons.image,
                        color: Colors.grey.shade600,
                      ),
              ),

              // Video indicator
              if (item.type == MediaType.video)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 14,
                        ),
                        if (item.duration != null) ...[
                          const SizedBox(width: 2),
                          Text(
                            _formatDuration(item.duration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
