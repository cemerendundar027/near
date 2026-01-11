import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mood Aura türleri - Premium animasyonlu profil efektleri
enum MoodAura {
  none('none', 'Kapalı', null, null),
  happy('happy', 'Mutlu', Color(0xFF4ADE80), Color(0xFF22C55E)),
  calm('calm', 'Sakin', Color(0xFFA78BFA), Color(0xFF8B5CF6)),
  excited('excited', 'Heyecanlı', Color(0xFFFB923C), Color(0xFFF97316)),
  focused('focused', 'Odaklanmış', Color(0xFF60A5FA), Color(0xFF3B82F6)),
  creative('creative', 'Yaratıcı', Color(0xFFF472B6), Color(0xFFEC4899)),
  love('love', 'Aşık', Color(0xFFFB7185), Color(0xFFE11D48)),
  mysterious('mysterious', 'Gizemli', Color(0xFF818CF8), Color(0xFF6366F1));

  final String value;
  final String label;
  final Color? primaryColor;
  final Color? secondaryColor;

  const MoodAura(this.value, this.label, this.primaryColor, this.secondaryColor);

  static MoodAura fromString(String? value) {
    if (value == null) return MoodAura.none;
    return MoodAura.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MoodAura.none,
    );
  }

  /// Aura için emoji
  String get emoji {
    switch (this) {
      case MoodAura.none:
        return '⚪';
      case MoodAura.happy:
        return '😊';
      case MoodAura.calm:
        return '😌';
      case MoodAura.excited:
        return '🔥';
      case MoodAura.focused:
        return '💪';
      case MoodAura.creative:
        return '✨';
      case MoodAura.love:
        return '💕';
      case MoodAura.mysterious:
        return '🌙';
    }
  }

  /// Aura için açıklama
  String get description {
    switch (this) {
      case MoodAura.none:
        return 'Aura efekti kapalı';
      case MoodAura.happy:
        return 'Yeşil parıltı ile mutluluğunu yansıt';
      case MoodAura.calm:
        return 'Mor dalga ile sakinliğini göster';
      case MoodAura.excited:
        return 'Turuncu alev ile enerjini paylaş';
      case MoodAura.focused:
        return 'Mavi nabız ile odaklanmışlığını belirt';
      case MoodAura.creative:
        return 'Pembe ışıltı ile yaratıcılığını ifade et';
      case MoodAura.love:
        return 'Kırmızı kalpler ile sevgini göster';
      case MoodAura.mysterious:
        return 'Mor girdap ile gizemini koru';
    }
  }
}

/// Mood Aura Service - Veritabanı işlemleri
class MoodAuraService extends ChangeNotifier {
  MoodAuraService._();
  static final instance = MoodAuraService._();

  final _supabase = Supabase.instance.client;
  MoodAura _currentMood = MoodAura.none;
  final Map<String, MoodAura> _userMoods = {};

  MoodAura get currentMood => _currentMood;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Mevcut kullanıcının mood'unu yükle
  Future<void> loadCurrentMood() async {
    if (currentUserId == null) return;

    try {
      final result = await _supabase
          .from('profiles')
          .select('mood_aura')
          .eq('id', currentUserId!)
          .maybeSingle();

      if (result != null) {
        _currentMood = MoodAura.fromString(result['mood_aura']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('MoodAuraService: Error loading mood: $e');
    }
  }

  /// Mood'u güncelle
  Future<bool> setMood(MoodAura mood) async {
    if (currentUserId == null) return false;

    try {
      await _supabase.from('profiles').update({
        'mood_aura': mood.value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUserId!);

      _currentMood = mood;
      _userMoods[currentUserId!] = mood;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('MoodAuraService: Error setting mood: $e');
      return false;
    }
  }

  /// Belirli bir kullanıcının mood'unu al (cache'den veya DB'den)
  MoodAura getMoodForUser(String? userId) {
    if (userId == null) return MoodAura.none;
    return _userMoods[userId] ?? MoodAura.none;
  }

  /// Kullanıcı mood'unu cache'e ekle (chat yüklenirken kullanılır)
  void cacheUserMood(String userId, String? moodValue) {
    _userMoods[userId] = MoodAura.fromString(moodValue);
  }
}

/// Animasyonlu Mood Aura Widget - Avatar etrafında gösterilir
class MoodAuraWidget extends StatefulWidget {
  final Widget child;
  final MoodAura mood;
  final double size;
  final bool showLabel;

  const MoodAuraWidget({
    super.key,
    required this.child,
    required this.mood,
    this.size = 50,
    this.showLabel = false,
  });

  @override
  State<MoodAuraWidget> createState() => _MoodAuraWidgetState();
}

class _MoodAuraWidgetState extends State<MoodAuraWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mood == MoodAura.none) {
      return widget.child;
    }

    // Label gösterilmeyecekse sadece Stack döndür (overflow önlenir)
    if (!widget.showLabel) {
      return SizedBox(
        width: widget.size + 16,
        height: widget.size + 16,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            _buildOuterGlow(),
            // Rotating particles
            _buildParticles(),
            // Inner pulse ring
            _buildPulseRing(),
            // Avatar
            widget.child,
          ],
        ),
      );
    }

    // Label gösterilecekse Column kullan
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size + 16,
          height: widget.size + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              _buildOuterGlow(),
              // Rotating particles
              _buildParticles(),
              // Inner pulse ring
              _buildPulseRing(),
              // Avatar
              widget.child,
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.mood.primaryColor?.withAlpha(40),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.mood.emoji,
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 4),
              Text(
                widget.mood.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: widget.mood.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOuterGlow() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowOpacity = 0.3 + (_glowController.value * 0.4);
        return Container(
          width: widget.size + 14,
          height: widget.size + 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.mood.primaryColor!.withAlpha((glowOpacity * 255).toInt()),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: widget.mood.secondaryColor!.withAlpha((glowOpacity * 200).toInt()),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPulseRing() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.08);
        final opacity = 0.6 - (_pulseController.value * 0.3);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size + 8,
            height: widget.size + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.mood.primaryColor!.withAlpha((opacity * 255).toInt()),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    if (widget.mood == MoodAura.love) {
      return _buildHeartParticles();
    }
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotateController.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size + 16, widget.size + 16),
            painter: _AuraParticlePainter(
              mood: widget.mood,
              animation: _pulseController.value,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeartParticles() {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(6, (index) {
            final angle = (index / 6) * 2 * math.pi + (_rotateController.value * math.pi);
            final radius = (widget.size / 2) + 6;
            final x = math.cos(angle) * radius;
            final y = math.sin(angle) * radius;
            final scale = 0.6 + (_pulseController.value * 0.4);

            return Transform.translate(
              offset: Offset(x, y),
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.favorite,
                  size: 8,
                  color: widget.mood.primaryColor!.withAlpha(200),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _AuraParticlePainter extends CustomPainter {
  final MoodAura mood;
  final double animation;

  _AuraParticlePainter({required this.mood, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // 8 particles around the avatar
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final particleRadius = 2.0 + (animation * 1.5);
      final distance = radius - 1;

      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;

      // Gradient color between primary and secondary
      final t = (i / 8);
      paint.color = Color.lerp(
        mood.primaryColor!.withAlpha(200),
        mood.secondaryColor!.withAlpha(150),
        t,
      )!;

      canvas.drawCircle(Offset(x, y), particleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuraParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Mood Seçim Dialog'u
class MoodAuraPickerSheet extends StatelessWidget {
  final MoodAura currentMood;
  final Function(MoodAura) onMoodSelected;

  const MoodAuraPickerSheet({
    super.key,
    required this.currentMood,
    required this.onMoodSelected,
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
                    '✨ Mood Aura',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ruh halini profil fotoğrafınla göster',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Mood Grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: MoodAura.values.length,
                itemBuilder: (context, index) {
                  final mood = MoodAura.values[index];
                  final isSelected = mood == currentMood;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onMoodSelected(mood);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (mood.primaryColor ?? Colors.grey).withAlpha(40)
                            : (isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (mood.primaryColor ?? Colors.grey)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Preview aura
                          if (mood != MoodAura.none)
                            _MiniAuraPreview(mood: mood, size: 36)
                          else
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                              ),
                              child: Icon(
                                Icons.visibility_off,
                                size: 18,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

class _MiniAuraPreview extends StatefulWidget {
  final MoodAura mood;
  final double size;

  const _MiniAuraPreview({required this.mood, required this.size});

  @override
  State<_MiniAuraPreview> createState() => _MiniAuraPreviewState();
}

class _MiniAuraPreviewState extends State<_MiniAuraPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowIntensity = 0.4 + (_controller.value * 0.4);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.mood.primaryColor!,
                widget.mood.secondaryColor!.withAlpha(150),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.mood.primaryColor!.withAlpha((glowIntensity * 255).toInt()),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}


