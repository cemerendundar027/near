import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Mesaj Efekt Türleri - Premium animasyonlu mesaj efektleri
enum MessageEffect {
  none('none', 'Normal', Icons.send_rounded),
  confetti('confetti', 'Konfeti', Icons.celebration_rounded),
  hearts('hearts', 'Kalpler', Icons.favorite_rounded),
  fireworks('fireworks', 'Havai Fişek', Icons.auto_awesome_rounded),
  stars('stars', 'Yıldızlar', Icons.star_rounded),
  bubbles('bubbles', 'Baloncuklar', Icons.bubble_chart_rounded),
  snow('snow', 'Kar', Icons.ac_unit_rounded),
  laser('laser', 'Lazer', Icons.flash_on_rounded),
  shake('shake', 'Sarsıntı', Icons.vibration_rounded);

  final String value;
  final String label;
  final IconData icon;

  const MessageEffect(this.value, this.label, this.icon);

  static MessageEffect fromString(String? value) {
    if (value == null || value == 'none') return MessageEffect.none;
    return MessageEffect.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageEffect.none,
    );
  }

  /// Efekt renkleri
  List<Color> get colors {
    switch (this) {
      case MessageEffect.none:
        return [Colors.grey];
      case MessageEffect.confetti:
        return [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.purple,
          Colors.pink,
        ];
      case MessageEffect.hearts:
        return [
          const Color(0xFFE11D48),
          const Color(0xFFF43F5E),
          const Color(0xFFFB7185),
        ];
      case MessageEffect.fireworks:
        return [
          Colors.orange,
          Colors.yellow,
          Colors.red,
          Colors.amber,
        ];
      case MessageEffect.stars:
        return [
          Colors.amber,
          Colors.yellow,
          Colors.orange,
        ];
      case MessageEffect.bubbles:
        return [
          Colors.blue.shade300,
          Colors.cyan.shade200,
          Colors.lightBlue.shade100,
        ];
      case MessageEffect.snow:
        return [
          Colors.white,
          Colors.blue.shade50,
          Colors.cyan.shade50,
        ];
      case MessageEffect.laser:
        return [
          Colors.red,
          Colors.orange,
          Colors.yellow,
        ];
      case MessageEffect.shake:
        return [Colors.grey];
    }
  }
}

/// Mesaj Efekt Seçici Sheet
class MessageEffectPickerSheet extends StatelessWidget {
  final MessageEffect currentEffect;
  final Function(MessageEffect) onEffectSelected;

  const MessageEffectPickerSheet({
    super.key,
    required this.currentEffect,
    required this.onEffectSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '🎉 Mesaj Efekti',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mesajına özel bir efekt ekle',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Effects List
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: MessageEffect.values.length,
                itemBuilder: (context, index) {
                  final effect = MessageEffect.values[index];
                  final isSelected = effect == currentEffect;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onEffectSelected(effect);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 80,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (effect == MessageEffect.none
                                  ? Colors.grey.withAlpha(40)
                                  : effect.colors.first.withAlpha(40))
                              : (isDark
                                  ? Colors.white.withAlpha(10)
                                  : Colors.grey.withAlpha(20)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? (effect == MessageEffect.none
                                    ? Colors.grey
                                    : effect.colors.first)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _EffectPreview(effect: effect),
                            const SizedBox(height: 8),
                            Text(
                              effect.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _EffectPreview extends StatefulWidget {
  final MessageEffect effect;

  const _EffectPreview({required this.effect});

  @override
  State<_EffectPreview> createState() => _EffectPreviewState();
}

class _EffectPreviewState extends State<_EffectPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effect == MessageEffect.none) {
      return Icon(
        widget.effect.icon,
        size: 28,
        color: Colors.grey,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: widget.effect.colors,
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ).createShader(bounds);
          },
          child: Icon(
            widget.effect.icon,
            size: 28,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

/// Tam Ekran Mesaj Efekti Overlay
class MessageEffectOverlay extends StatefulWidget {
  final MessageEffect effect;
  final VoidCallback onComplete;

  const MessageEffectOverlay({
    super.key,
    required this.effect,
    required this.onComplete,
  });

  @override
  State<MessageEffectOverlay> createState() => _MessageEffectOverlayState();
}

class _MessageEffectOverlayState extends State<MessageEffectOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: _getEffectDuration(),
    );

    _generateParticles();
    _mainController.forward().then((_) => widget.onComplete());
  }

  Duration _getEffectDuration() {
    switch (widget.effect) {
      case MessageEffect.shake:
        return const Duration(milliseconds: 500);
      case MessageEffect.laser:
        return const Duration(milliseconds: 800);
      default:
        return const Duration(milliseconds: 2500);
    }
  }

  void _generateParticles() {
    final count = _getParticleCount();
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: -0.1 - (_random.nextDouble() * 0.3),
        size: 8 + _random.nextDouble() * 16,
        speed: 0.3 + _random.nextDouble() * 0.5,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        color: widget.effect.colors[_random.nextInt(widget.effect.colors.length)],
        delay: _random.nextDouble() * 0.3,
      ));
    }
  }

  int _getParticleCount() {
    switch (widget.effect) {
      case MessageEffect.confetti:
        return 80;
      case MessageEffect.hearts:
        return 40;
      case MessageEffect.fireworks:
        return 60;
      case MessageEffect.stars:
        return 50;
      case MessageEffect.bubbles:
        return 30;
      case MessageEffect.snow:
        return 100;
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effect == MessageEffect.shake) {
      return _buildShakeEffect();
    }

    if (widget.effect == MessageEffect.laser) {
      return _buildLaserEffect();
    }

    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
            particles: _particles,
            progress: _mainController.value,
            effect: widget.effect,
          ),
        );
      },
    );
  }

  Widget _buildShakeEffect() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final shake = math.sin(_mainController.value * math.pi * 10) * 10;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(color: Colors.transparent),
        );
      },
    );
  }

  Widget _buildLaserEffect() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _LaserPainter(progress: _mainController.value),
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  final double size;
  final double speed;
  double rotation;
  final double rotationSpeed;
  final Color color;
  final double delay;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.delay,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final MessageEffect effect;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.effect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final adjustedProgress = (progress - particle.delay).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final y = particle.y + (adjustedProgress * particle.speed * 1.5);
      if (y > 1.2) continue;

      final opacity = (1.0 - adjustedProgress).clamp(0.0, 1.0);
      final currentRotation = particle.rotation + (adjustedProgress * particle.rotationSpeed * 20);

      final paint = Paint()
        ..color = particle.color.withAlpha((opacity * 255).toInt())
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.x * size.width, y * size.height);
      canvas.rotate(currentRotation);

      _drawShape(canvas, particle.size * (0.5 + adjustedProgress * 0.5), paint);

      canvas.restore();
    }
  }

  void _drawShape(Canvas canvas, double size, Paint paint) {
    switch (effect) {
      case MessageEffect.confetti:
        // Rectangle confetti
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.6),
          paint,
        );
        break;
      case MessageEffect.hearts:
        _drawHeart(canvas, size, paint);
        break;
      case MessageEffect.stars:
        _drawStar(canvas, size, paint);
        break;
      case MessageEffect.bubbles:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawCircle(Offset.zero, size / 2, paint);
        break;
      case MessageEffect.snow:
        canvas.drawCircle(Offset.zero, size / 3, paint);
        break;
      case MessageEffect.fireworks:
        _drawSparkle(canvas, size, paint);
        break;
      default:
        canvas.drawCircle(Offset.zero, size / 2, paint);
    }
  }

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final s = size / 2;
    path.moveTo(0, s * 0.3);
    path.cubicTo(-s, -s * 0.5, -s, s * 0.5, 0, s);
    path.cubicTo(s, s * 0.5, s, -s * 0.5, 0, s * 0.3);
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = size / 4;
    const points = 5;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = radius * math.cos(angle);
      final y = radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, double size, Paint paint) {
    for (int i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 2, height: size),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _LaserPainter extends CustomPainter {
  final double progress;

  _LaserPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.red.withAlpha((255 * (1 - progress)).toInt()),
          Colors.orange.withAlpha((255 * (1 - progress)).toInt()),
          Colors.yellow.withAlpha((200 * (1 - progress)).toInt()),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4 - (progress * 3)
      ..style = PaintingStyle.stroke;

    // Multiple laser beams
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.3 + i * 0.2);
      final endX = size.width * progress;
      canvas.drawLine(Offset(0, y), Offset(endX, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LaserPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Inline Efekt Butonu (Mesaj input yanında)
class EffectButton extends StatelessWidget {
  final MessageEffect currentEffect;
  final VoidCallback onTap;

  const EffectButton({
    super.key,
    required this.currentEffect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasEffect = currentEffect != MessageEffect.none;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: hasEffect
              ? currentEffect.colors.first.withAlpha(40)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          hasEffect ? currentEffect.icon : Icons.auto_awesome_outlined,
          size: 22,
          color: hasEffect ? currentEffect.colors.first : Colors.grey,
        ),
      ),
    );
  }
}


