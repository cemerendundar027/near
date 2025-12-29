import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Video kırpma sayfası
/// - Başlangıç/bitiş noktası seçimi
/// - Video önizleme
/// - Kırpma aralığı göstergesi
class VideoTrimmerPage extends StatefulWidget {
  final File videoFile;
  final Duration? maxDuration;

  const VideoTrimmerPage({
    super.key,
    required this.videoFile,
    this.maxDuration,
  });

  /// Navigator ile açıp kırpılmış video dosyasını döndürür
  static Future<VideoTrimResult?> open(
    BuildContext context,
    File videoFile, {
    Duration? maxDuration,
  }) async {
    return Navigator.push<VideoTrimResult?>(
      context,
      MaterialPageRoute(
        builder: (context) => VideoTrimmerPage(
          videoFile: videoFile,
          maxDuration: maxDuration,
        ),
      ),
    );
  }

  @override
  State<VideoTrimmerPage> createState() => _VideoTrimmerPageState();
}

class _VideoTrimmerPageState extends State<VideoTrimmerPage> {
  // Video state
  Duration _videoDuration = const Duration(seconds: 30);
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;

  // Trim state
  Duration _trimStart = Duration.zero;
  Duration _trimEnd = const Duration(seconds: 30);

  // UI state placeholder for future thumbnail generation

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  void _loadVideo() {
    // Gerçek uygulamada video_player kullanılır
    // Mock duration
    setState(() {
      _videoDuration = const Duration(seconds: 30);
      _trimEnd = _videoDuration;
    });
  }

  void _togglePlayback() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seekTo(Duration position) {
    setState(() {
      if (position < Duration.zero) {
        _currentPosition = Duration.zero;
      } else if (position > _videoDuration) {
        _currentPosition = _videoDuration;
      } else {
        _currentPosition = position;
      }
    });
  }

  void _onTrimStartChanged(double value) {
    final newStart = Duration(
      milliseconds: (value * _videoDuration.inMilliseconds).round(),
    );

    if (newStart < _trimEnd - const Duration(seconds: 1)) {
      setState(() {
        _trimStart = newStart;
        if (_currentPosition < _trimStart) {
          _currentPosition = _trimStart;
        }
      });
    }
  }

  void _onTrimEndChanged(double value) {
    final newEnd = Duration(
      milliseconds: (value * _videoDuration.inMilliseconds).round(),
    );

    if (newEnd > _trimStart + const Duration(seconds: 1)) {
      // Check max duration constraint
      if (widget.maxDuration != null) {
        final trimmedDuration = newEnd - _trimStart;
        if (trimmedDuration > widget.maxDuration!) {
          return;
        }
      }

      setState(() {
        _trimEnd = newEnd;
        if (_currentPosition > _trimEnd) {
          _currentPosition = _trimEnd;
        }
      });
    }
  }

  void _applyTrim() {
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      VideoTrimResult(
        originalFile: widget.videoFile,
        startTime: _trimStart,
        endTime: _trimEnd,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final millis = (duration.inMilliseconds.remainder(1000) / 100).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$millis';
  }

  @override
  Widget build(BuildContext context) {
    final trimmedDuration = _trimEnd - _trimStart;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Videoyu Kırp'),
        actions: [
          TextButton(
            onPressed: _applyTrim,
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
          // Video preview
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video placeholder (gerçek uygulamada VideoPlayer)
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.movie_rounded,
                          size: 80,
                          color: NearTheme.primary.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Video Önizleme',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDuration(_currentPosition),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Play button
                Positioned(
                  child: GestureDetector(
                    onTap: _togglePlayback,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Trim info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seçilen Süre',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(trimmedDuration),
                      style: TextStyle(
                        color: NearTheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                if (widget.maxDuration != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Maksimum',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        _formatDuration(widget.maxDuration!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Timeline with trimmer
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Time markers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_trimStart),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      _formatDuration(_trimEnd),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Thumbnail timeline with trim handles
                Expanded(
                  child: _VideoTimeline(
                    duration: _videoDuration,
                    trimStart: _trimStart,
                    trimEnd: _trimEnd,
                    currentPosition: _currentPosition,
                    onTrimStartChanged: _onTrimStartChanged,
                    onTrimEndChanged: _onTrimEndChanged,
                    onSeek: _seekTo,
                  ),
                ),
              ],
            ),
          ),

          // Quick trim presets
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TrimPresetChip(
                    label: 'Baştan',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _trimStart = Duration.zero;
                        _currentPosition = Duration.zero;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _TrimPresetChip(
                    label: 'Sondan',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _trimEnd = _videoDuration;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _TrimPresetChip(
                    label: 'İlk 15s',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _trimStart = Duration.zero;
                        _trimEnd = Duration(
                          milliseconds: 15000.clamp(0, _videoDuration.inMilliseconds),
                        );
                        _currentPosition = Duration.zero;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _TrimPresetChip(
                    label: 'Son 15s',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final start = _videoDuration - const Duration(seconds: 15);
                      setState(() {
                        _trimStart = start.isNegative ? Duration.zero : start;
                        _trimEnd = _videoDuration;
                        _currentPosition = _trimStart;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _TrimPresetChip(
                    label: 'Ortadan',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final center = _videoDuration ~/ 2;
                      final halfTrim = const Duration(seconds: 7);
                      setState(() {
                        _trimStart = (center - halfTrim).isNegative
                            ? Duration.zero
                            : center - halfTrim;
                        _trimEnd = center + halfTrim > _videoDuration
                            ? _videoDuration
                            : center + halfTrim;
                        _currentPosition = _trimStart;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _VideoTimeline extends StatefulWidget {
  final Duration duration;
  final Duration trimStart;
  final Duration trimEnd;
  final Duration currentPosition;
  final ValueChanged<double> onTrimStartChanged;
  final ValueChanged<double> onTrimEndChanged;
  final ValueChanged<Duration> onSeek;

  const _VideoTimeline({
    required this.duration,
    required this.trimStart,
    required this.trimEnd,
    required this.currentPosition,
    required this.onTrimStartChanged,
    required this.onTrimEndChanged,
    required this.onSeek,
  });

  @override
  State<_VideoTimeline> createState() => _VideoTimelineState();
}

class _VideoTimelineState extends State<_VideoTimeline> {
  @override
  Widget build(BuildContext context) {
    final startRatio =
        widget.trimStart.inMilliseconds / widget.duration.inMilliseconds;
    final endRatio =
        widget.trimEnd.inMilliseconds / widget.duration.inMilliseconds;
    final positionRatio =
        widget.currentPosition.inMilliseconds / widget.duration.inMilliseconds;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Stack(
          children: [
            // Thumbnail strip (placeholder)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: List.generate(
                  10,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          NearTheme.primary.withAlpha(30),
                          NearTheme.primaryDark.withAlpha(30),
                          index / 10,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.movie_rounded,
                          size: 16,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Dim overlay - left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: startRatio * width,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
              ),
            ),

            // Dim overlay - right
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: (1 - endRatio) * width,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                ),
              ),
            ),

            // Trim selection border
            Positioned(
              left: startRatio * width,
              right: (1 - endRatio) * width,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: NearTheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // Start handle
            Positioned(
              left: startRatio * width - 12,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final newRatio =
                      (startRatio + details.delta.dx / width).clamp(0.0, 1.0);
                  widget.onTrimStartChanged(newRatio);
                },
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: NearTheme.primary,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // End handle
            Positioned(
              right: (1 - endRatio) * width - 12,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final newRatio =
                      (endRatio + details.delta.dx / width).clamp(0.0, 1.0);
                  widget.onTrimEndChanged(newRatio);
                },
                child: Container(
                  width: 24,
                  decoration: BoxDecoration(
                    color: NearTheme.primary,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Playhead
            Positioned(
              left: positionRatio * width - 1,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: Colors.white,
              ),
            ),

            // Seek gesture detector
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  final ratio = details.localPosition.dx / width;
                  final position = Duration(
                    milliseconds:
                        (ratio * widget.duration.inMilliseconds).round(),
                  );
                  widget.onSeek(position);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrimPresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TrimPresetChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Video kırpma sonucu
class VideoTrimResult {
  final File originalFile;
  final Duration startTime;
  final Duration endTime;

  const VideoTrimResult({
    required this.originalFile,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime - startTime;
}
