import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../../app/theme.dart';

/// Sesli mesaj kayıt widget'ı - Profesyonel eflatun temalı
class VoiceMessageRecorder extends StatefulWidget {
  final Function(Duration duration) onRecordingComplete;
  final VoidCallback? onCancel;

  const VoiceMessageRecorder({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isLocked = false;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;
  double _slideOffset = 0;
  double _lockOffset = 0;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  // Waveform verileri
  final List<double> _waveform = List.generate(50, (_) => 0.3);
  final math.Random _random = math.Random();
  Offset _lastOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _startRecording() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
      _slideOffset = 0;
      _lockOffset = 0;
      _lastOffset = Offset.zero;
    });

    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _recordDuration += const Duration(milliseconds: 100);
        // Gerçekçi waveform simülasyonu
        _waveform.removeAt(0);
        _waveform.add(0.25 + _random.nextDouble() * 0.65);
      });
    });
  }

  void _stopRecording({bool send = true}) {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    if (send && _recordDuration.inSeconds >= 1) {
      HapticFeedback.mediumImpact();
      widget.onRecordingComplete(_recordDuration);
    } else {
      HapticFeedback.lightImpact();
      widget.onCancel?.call();
    }

    setState(() {
      _isRecording = false;
      _isLocked = false;
      _slideOffset = 0;
      _lockOffset = 0;
      _recordDuration = Duration.zero;
      // Waveform'u sıfırla
      for (int i = 0; i < _waveform.length; i++) {
        _waveform[i] = 0.3;
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isRecording || _isLocked) return;

    setState(() {
      // Sola kaydırma (iptal)
      _slideOffset = (_slideOffset + details.delta.dx).clamp(-120.0, 0.0);
      // Yukarı kaydırma (kilitle)
      _lockOffset = (_lockOffset - details.delta.dy).clamp(0.0, 80.0);
    });

    // İptal eşiği
    if (_slideOffset <= -100) {
      HapticFeedback.heavyImpact();
      _stopRecording(send: false);
    }

    // Kilitleme eşiği
    if (_lockOffset >= 60 && !_isLocked) {
      HapticFeedback.heavyImpact();
      setState(() => _isLocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecording) {
      return _buildMicButton();
    }
    return _isLocked ? _buildLockedUI() : _buildRecordingUI();
  }

  /// Mikrofon butonu - başlangıç durumu
  Widget _buildMicButton() {
    return GestureDetector(
      // Tek tıklama: Kilitli modda kayıt başlat (eller serbest)
      onTap: () {
        _startRecording();
        setState(() => _isLocked = true);
      },
      // Uzun basış: Basılı tutarak kayıt (WhatsApp tarzı)
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) {
        if (!_isLocked) {
          _stopRecording(send: true);
        }
      },
      onLongPressMoveUpdate: (details) {
        // Uzun basışta kaydırma desteği
        if (!_isLocked) {
          _onPanUpdate(DragUpdateDetails(
            globalPosition: details.globalPosition,
            localPosition: details.localPosition,
            delta: details.offsetFromOrigin - _lastOffset,
          ));
          _lastOffset = details.offsetFromOrigin;
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [NearTheme.primary, NearTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: NearTheme.primary.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  /// Kayıt sırasında UI - kaydırılabilir
  Widget _buildRecordingUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final cancelProgress = (_slideOffset.abs() / 100).clamp(0.0, 1.0);
    final lockProgress = (_lockOffset / 60).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _stopRecording(send: true),
      child: SizedBox(
        height: 100,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            // Ana kayıt paneli
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: 56,
              margin: EdgeInsets.only(right: _lockOffset > 20 ? 60 : 0),
              padding: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Kayıt göstergesi (yanıp sönen)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(
                            NearTheme.primary,
                            NearTheme.primary.withAlpha(100),
                            _pulseController.value,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: NearTheme.primary.withAlpha(
                                (80 * (1 - _pulseController.value)).round(),
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 12),

                  // Süre
                  Text(
                    _formatDuration(_recordDuration),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Waveform
                  SizedBox(
                    width: 80,
                    height: 32,
                    child: CustomPaint(
                      painter: _VoiceWaveformPainter(
                        waveform: _waveform,
                        color: NearTheme.primary,
                        animationValue: _pulseController.value,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // İptal için sola kaydır göstergesi
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: cancelProgress > 0.3 ? 0 : 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_left_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 18,
                        ),
                        Text(
                          'İptal',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Kayıt butonu
                  Transform.translate(
                    offset: Offset(_slideOffset * 0.5, 0),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: cancelProgress > 0.5
                                    ? [Colors.red.shade400, Colors.red.shade600]
                                    : [
                                        NearTheme.primary,
                                        NearTheme.primaryDark,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (cancelProgress > 0.5
                                              ? Colors.red
                                              : NearTheme.primary)
                                          .withAlpha(60),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              cancelProgress > 0.5
                                  ? Icons.delete_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Kilitleme göstergesi (yukarı kaydırınca)
            if (lockProgress > 0.1)
              Positioned(
                right: 0,
                bottom: 56 + (_lockOffset * 0.5),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: lockProgress,
                  child: Container(
                    width: 44,
                    height: 44 + (_lockOffset * 0.3),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          lockProgress > 0.8
                              ? Icons.lock_rounded
                              : Icons.lock_open_rounded,
                          color: lockProgress > 0.8
                              ? NearTheme.primary
                              : (isDark ? Colors.white54 : Colors.black38),
                          size: 20,
                        ),
                        if (lockProgress < 0.8) ...[
                          const SizedBox(height: 4),
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: isDark ? Colors.white38 : Colors.black26,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Kilitli mod UI - kayıt devam eder, butonlarla kontrol
  Widget _buildLockedUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // İptal butonu
          _buildCircleButton(
            icon: Icons.delete_outline_rounded,
            color: Colors.red.shade400,
            onTap: () => _stopRecording(send: false),
          ),

          const SizedBox(width: 12),

          // Kayıt göstergesi
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NearTheme.primary.withAlpha(
                    (255 * (0.4 + _pulseController.value * 0.6)).round(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          // Süre
          Text(
            _formatDuration(_recordDuration),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(width: 12),

          // Waveform
          Expanded(
            child: SizedBox(
              height: 32,
              child: CustomPaint(
                painter: _VoiceWaveformPainter(
                  waveform: _waveform,
                  color: NearTheme.primary,
                  animationValue: _pulseController.value,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Gönder butonu
          _buildCircleButton(
            icon: Icons.send_rounded,
            gradient: const LinearGradient(
              colors: [NearTheme.primary, NearTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => _stopRecording(send: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    Color? color,
    Gradient? gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? NearTheme.primary) : null,
          gradient: gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (color ?? NearTheme.primary).withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Sesli mesaj oynatıcı widget'ı - Profesyonel eflatun temalı
class VoiceMessagePlayer extends StatefulWidget {
  final Duration duration;
  final String? audioUrl;
  final bool isFromMe;
  final List<double>? waveformData;

  const VoiceMessagePlayer({
    super.key,
    required this.duration,
    this.audioUrl,
    this.isFromMe = false,
    this.waveformData,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _progress = 0;
  Duration _currentPosition = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isLoading = false;

  // Gerçek ses oynatıcı (just_audio)
  AudioPlayer? _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  late AnimationController _playButtonController;
  late Animation<double> _playButtonAnimation;

  // Varsayılan waveform (gerçek ses verisi olmadığında)
  late List<double> _waveform;

  @override
  void initState() {
    super.initState();
    _waveform =
        widget.waveformData ??
        List.generate(35, (i) {
          // Doğal görünümlü varsayılan waveform
          final base = 0.3 + (math.sin(i * 0.5) * 0.2).abs();
          return base + (i % 3 == 0 ? 0.2 : 0);
        });

    _playButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _playButtonAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _playButtonController, curve: Curves.easeInOut),
    );

    // Gerçek ses URL'si varsa player'ı hazırla
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      _initAudioPlayer();
    }
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();

    // Pozisyon değişikliklerini dinle
    _positionSubscription = _audioPlayer!.positionStream.listen((position) {
      if (!mounted) return;
      final totalDuration = _audioPlayer!.duration ?? widget.duration;
      setState(() {
        _currentPosition = position;
        _progress = totalDuration.inMilliseconds > 0
            ? position.inMilliseconds / totalDuration.inMilliseconds
            : 0;
      });
    });

    // Oynatma durumunu dinle
    _stateSubscription = _audioPlayer!.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _progress = 0;
          _currentPosition = Duration.zero;
          _audioPlayer?.seek(Duration.zero);
          _audioPlayer?.pause();
        }
      });
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _audioPlayer?.dispose();
    _playButtonController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    HapticFeedback.lightImpact();
    _playButtonController.forward().then((_) {
      _playButtonController.reverse();
    });

    // Gerçek ses URL'si varsa gerçek oynatma
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty && _audioPlayer != null) {
      try {
    if (_isPlaying) {
          await _audioPlayer!.pause();
        } else {
          // İlk kez oynatılıyorsa URL'yi yükle
          if (_audioPlayer!.audioSource == null) {
            setState(() => _isLoading = true);
            await _audioPlayer!.setUrl(widget.audioUrl!);
            await _audioPlayer!.setSpeed(_playbackSpeed);
            setState(() => _isLoading = false);
          }
          await _audioPlayer!.play();
        }
      } catch (e) {
        debugPrint('VoiceMessagePlayer: Oynatma hatası: $e');
        setState(() => _isLoading = false);
      }
    } else {
      // Simülasyon modu (gerçek URL yoksa)
      _simulatePlayback();
    }
  }

  // URL yoksa simülasyon modu
  Timer? _simTimer;
  void _simulatePlayback() {
    if (_isPlaying) {
      _simTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);

      final totalMs = widget.duration.inMilliseconds;
      final intervalMs = (50 / _playbackSpeed).round();

      _simTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
        if (!mounted) return;
        setState(() {
          _currentPosition += Duration(milliseconds: 50);
          _progress = _currentPosition.inMilliseconds / totalMs;

          if (_progress >= 1) {
            _simTimer?.cancel();
            _isPlaying = false;
            _progress = 0;
            _currentPosition = Duration.zero;
          }
        });
      });
    }
  }

  Future<void> _seekTo(double progress) async {
    HapticFeedback.selectionClick();
    final newPosition = Duration(
      milliseconds: (widget.duration.inMilliseconds * progress.clamp(0.0, 1.0)).round(),
    );

    if (_audioPlayer != null && widget.audioUrl != null) {
      await _audioPlayer!.seek(newPosition);
    }
    
    setState(() {
      _progress = progress.clamp(0.0, 1.0);
      _currentPosition = newPosition;
    });
  }

  Future<void> _changeSpeed() async {
    HapticFeedback.selectionClick();
    double newSpeed;
      if (_playbackSpeed == 1.0) {
      newSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
      newSpeed = 2.0;
      } else {
      newSpeed = 1.0;
    }

    if (_audioPlayer != null) {
      await _audioPlayer!.setSpeed(newSpeed);
    }

    setState(() {
      _playbackSpeed = newSpeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Renk şeması
    final bubbleColor = widget.isFromMe
        ? NearTheme.myBubble
        : (isDark ? const Color(0xFF2C2C2E) : NearTheme.theirBubble);
    final textColor = widget.isFromMe
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final secondaryColor = widget.isFromMe
        ? Colors.white70
        : (isDark ? Colors.white60 : Colors.black54);
    final waveActiveColor = widget.isFromMe ? Colors.white : NearTheme.primary;
    final waveInactiveColor = widget.isFromMe
        ? Colors.white.withAlpha(80)
        : NearTheme.primary.withAlpha(60);
    final playBtnColor = widget.isFromMe
        ? Colors.white.withAlpha(50)
        : NearTheme.primary;
    const playIconColor = Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280, minWidth: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause butonu
          GestureDetector(
            onTap: _togglePlayback,
            child: AnimatedBuilder(
              animation: _playButtonAnimation,
              builder: (context, _) {
                return Transform.scale(
                  scale: _playButtonAnimation.value,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: playBtnColor,
                      shape: BoxShape.circle,
                      boxShadow: widget.isFromMe
                          ? null
                          : [
                              BoxShadow(
                                color: NearTheme.primary.withAlpha(40),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(_isPlaying),
                        color: playIconColor,
                        size: 26,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          // Waveform + bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tıklanabilir Waveform
                GestureDetector(
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox?;
                    if (box == null) return;
                    final localPosition = details.localPosition;
                    final waveformWidth =
                        box.size.width - 64; // buton + padding
                    final progress = (localPosition.dx / waveformWidth).clamp(
                      0.0,
                      1.0,
                    );
                    _seekTo(progress);
                  },
                  child: SizedBox(
                    height: 32,
                    child: CustomPaint(
                      painter: _VoiceWaveformPainter(
                        waveform: _waveform,
                        color: waveActiveColor,
                        progress: _progress,
                        progressColor: waveActiveColor,
                        inactiveColor: waveInactiveColor,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Süre ve hız
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isPlaying
                          ? _formatDuration(_currentPosition)
                          : _formatDuration(widget.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    GestureDetector(
                      onTap: _changeSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isFromMe
                              ? Colors.white.withAlpha(40)
                              : NearTheme.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_playbackSpeed.toStringAsFixed(_playbackSpeed == 1.0 || _playbackSpeed == 2.0 ? 0 : 1)}x',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Profesyonel waveform painter
class _VoiceWaveformPainter extends CustomPainter {
  final List<double> waveform;
  final Color color;
  final double progress;
  final Color? progressColor;
  final Color? inactiveColor;
  final double animationValue;

  _VoiceWaveformPainter({
    required this.waveform,
    required this.color,
    this.progress = 0,
    this.progressColor,
    this.inactiveColor,
    this.animationValue = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final barCount = waveform.length;
    final totalGapWidth = (barCount - 1) * 2.0; // 2px gap between bars
    final barWidth = (size.width - totalGapWidth) / barCount;
    final maxHeight = size.height * 0.85;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + 2) + barWidth / 2;
      var amplitude = waveform[i].clamp(0.15, 1.0);

      // Animasyon efekti (kayıt sırasında)
      if (animationValue > 0 && i > barCount - 5) {
        amplitude *= (0.8 + animationValue * 0.4);
      }

      final barHeight = amplitude * maxHeight;
      final halfHeight = barHeight / 2;

      final isPlayed = progress > 0 && (i / barCount) <= progress;

      final paint = Paint()
        ..color = isPlayed
            ? (progressColor ?? color)
            : (inactiveColor ?? color.withAlpha(60))
        ..strokeWidth = barWidth.clamp(2.0, 4.0)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, centerY - halfHeight),
        Offset(x, centerY + halfHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.waveform != waveform;
  }
}

/// Kayıt göstergesi - AppBar veya status için
class RecordingIndicator extends StatefulWidget {
  final Duration duration;

  const RecordingIndicator({super.key, required this.duration});

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NearTheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _blinkController,
            builder: (context, _) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NearTheme.primary.withAlpha(
                    (255 * (0.3 + _blinkController.value * 0.7)).round(),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NearTheme.primary.withAlpha(
                        (100 * _blinkController.value).round(),
                      ),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(widget.duration),
            style: const TextStyle(
              color: NearTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sesli mesaj ön izleme widget'ı (gönderilmeden önce)
class VoiceMessagePreview extends StatelessWidget {
  final Duration duration;
  final VoidCallback onSend;
  final VoidCallback onDelete;

  const VoiceMessagePreview({
    super.key,
    required this.duration,
    required this.onSend,
    required this.onDelete,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sil butonu
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Önizleme bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.mic_rounded,
                      color: NearTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sesli Mesaj',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Gönder butonu
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NearTheme.primary, NearTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NearTheme.primary.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
