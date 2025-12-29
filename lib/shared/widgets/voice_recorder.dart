import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Voice message recorder widget with animated waveform
class VoiceRecorderWidget extends StatefulWidget {
  final VoidCallback? onCancel;
  final void Function(Duration duration)? onSend;
  final void Function(bool isLocked)? onLockChanged;

  const VoiceRecorderWidget({
    super.key,
    this.onCancel,
    this.onSend,
    this.onLockChanged,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  bool _isLocked = false;
  final List<double> _waveformData = [];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    _startRecording();
  }

  void _startRecording() {
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      setState(() {
        _recordingDuration += const Duration(milliseconds: 100);
        // Add random waveform data for visualization
        _waveformData.add(math.Random().nextDouble() * 0.8 + 0.2);
        if (_waveformData.length > 50) {
          _waveformData.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
    widget.onLockChanged?.call(_isLocked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          // Cancel button or slide hint
          if (_isLocked)
            IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            )
          else
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.chevron_left, color: Colors.grey, size: 20),
                  Text(
                    'İptal için kaydır',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Recording indicator and timer
          if (_isLocked) ...[
            const Spacer(),
            // Waveform visualization
            SizedBox(
              width: 120,
              height: 32,
              child: CustomPaint(
                painter: _WaveformPainter(
                  data: _waveformData,
                  color: const Color(0xFF7B3FF2),
                ),
              ),
            ),
            const Spacer(),
          ],

          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value * 0.7 + 0.3,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_recordingDuration),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          // Lock button (when not locked)
          if (!_isLocked) ...[
            GestureDetector(
              onTap: _toggleLock,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Send button (when locked)
          if (_isLocked)
            GestureDetector(
              onTap: () => widget.onSend?.call(_recordingDuration),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF7B3FF2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, size: 20, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _WaveformPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / math.max(data.length, 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final barHeight = data[i] * size.height * 0.8;
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.data.length != data.length;
  }
}

/// Voice message playback widget
class VoiceMessagePlayer extends StatefulWidget {
  final Duration duration;
  final bool isPlaying;
  final double progress;
  final bool isFromMe;
  final VoidCallback? onPlayPause;
  final void Function(double)? onSeek;

  const VoiceMessagePlayer({
    super.key,
    required this.duration,
    this.isPlaying = false,
    this.progress = 0.0,
    this.isFromMe = true,
    this.onPlayPause,
    this.onSeek,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  // Generate static waveform for display
  late List<double> _waveform;

  @override
  void initState() {
    super.initState();
    _waveform = List.generate(
      30,
      (i) => math.Random(i * 42).nextDouble() * 0.7 + 0.3,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isFromMe
        ? Colors.white.withValues(alpha: 0.9)
        : const Color(0xFF7B3FF2);
    final secondaryColor = widget.isFromMe
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF7B3FF2).withValues(alpha: 0.4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button
        GestureDetector(
          onTap: widget.onPlayPause,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.isFromMe
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFF7B3FF2).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isPlaying ? Icons.pause : Icons.play_arrow,
              color: primaryColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Waveform
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final localX = details.localPosition.dx;
                    final progress = (localX / box.size.width).clamp(0.0, 1.0);
                    widget.onSeek?.call(progress);
                  }
                },
                child: SizedBox(
                  height: 24,
                  child: CustomPaint(
                    size: const Size(double.infinity, 24),
                    painter: _StaticWaveformPainter(
                      data: _waveform,
                      progress: widget.progress,
                      activeColor: primaryColor,
                      inactiveColor: secondaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(widget.duration * (1 - widget.progress)),
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StaticWaveformPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _StaticWaveformPainter({
    required this.data,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / data.length;
    final progressX = size.width * progress;

    for (int i = 0; i < data.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final barHeight = data[i] * size.height * 0.8;
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        x <= progressX ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StaticWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
