import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/widgets/near_branding.dart';
import '../../shared/auth_service.dart';

class SplashPage extends StatefulWidget {
  static const route = '/splash';
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5)),
    );

    // Text animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Start animations
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // Navigate after splash
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      // Supabase auth durumunu kontrol et
      final auth = AuthService.instance;
      if (auth.isAuthenticated) {
        // Kullanıcı giriş yapmış, ana sayfaya git
        context.go('/');
      } else {
        // Kullanıcı giriş yapmamış, onboarding'e git
        context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NearTheme.primaryDark,
              NearTheme.primary,
              NearTheme.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              AnimatedBuilder(
                animation: Listenable.merge([
                  _logoController,
                  _pulseController,
                ]),
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        _logoScale.value * (1 + _pulseController.value * 0.05),
                    child: Opacity(opacity: _logoOpacity.value, child: child),
                  );
                },
                child: const NearIcon(
                  size: 120,
                  borderRadius: 32,
                  showShadow: true,
                ),
              ),

              const SizedBox(height: 32),

              // App name
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: Column(
                    children: [
                      Text(
                        'near',
                        style: GoogleFonts.nunito(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yakınlarınla bağlan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withAlpha(200),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Loading indicator
              FadeTransition(
                opacity: _textOpacity,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withAlpha(180),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Footer
              FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: Colors.white.withAlpha(150),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Uçtan uca şifreli',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'near inc.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(120),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
