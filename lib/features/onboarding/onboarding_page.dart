import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_settings.dart';
import '../../app/theme.dart';

class OnboardingPage extends StatefulWidget {
  static const route = '/onboarding';
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.chat_bubble_rounded,
      title: 'Mesajlaşma',
      subtitle:
          'Arkadaşlarınla anında mesajlaş.\nUçtan uca şifrelenmiş, güvenli.',
      color: Color(0xFF7B3FF2),
    ),
    _OnboardingData(
      icon: Icons.videocam_rounded,
      title: 'Görüntülü Arama',
      subtitle:
          'Yüksek kalitede sesli ve görüntülü aramalar.\nHer yerden bağlan.',
      color: Color(0xFF5A22C8),
    ),
    _OnboardingData(
      icon: Icons.group_rounded,
      title: 'Gruplar & Hikayeler',
      subtitle: 'Grup sohbetleri oluştur.\nAnlarını hikayelerle paylaş.',
      color: Color(0xFF8B5CF6),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    // Onboarding tamamlandı olarak kaydet
    AppSettings.instance.setOnboardingCompleted(true);
    context.go('/auth');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Atla',
                  style: TextStyle(
                    color: NearTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPageContent(data: page, isDark: isDark);
                },
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? NearTheme.primary
                        : (isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Next/Start button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NearTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Başla' : 'Devam',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _OnboardingPageContent extends StatelessWidget {
  final _OnboardingData data;
  final bool isDark;

  const _OnboardingPageContent({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: data.color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: data.color.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, size: 60, color: data.color),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
