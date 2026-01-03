import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../app/theme.dart';
import '../../shared/settings_widgets.dart';
import '../../shared/widgets/qr_code.dart';
import '../../shared/widgets/near_branding.dart';
import '../../shared/accessibility.dart';
import '../../shared/supabase_service.dart';
import '../../shared/mood_aura.dart';
import '../profile/profile_edit_page.dart';
import '../chats/chat_extras_pages.dart';
import 'account_page.dart';
import 'privacy_page.dart';
import 'chats_settings_page.dart';
import 'notifications_page.dart';
import 'storage_page.dart';
import 'help_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _supabase = SupabaseService.instance;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.currentUser?.id;
      debugPrint('SettingsPage: Loading profile for user: $userId');
      
      if (userId != null) {
        final profile = await _supabase.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        
        debugPrint('SettingsPage: Loaded profile: $profile');
        
        if (mounted) {
          setState(() {
            _profile = profile;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('SettingsPage: No user logged in');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('SettingsPage: Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _go(BuildContext context, String route) {
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName = _profile?['full_name'] ?? _profile?['username'] ?? 'Kullanıcı';
    final username = _profile?['username'] as String?;
    final email = _supabase.currentUser?.email;
    final about = _profile?['bio'] ?? 'Hey there! I\'m using near.';
    final avatarUrl = _profile?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF000000)
            : const Color(0xFFF2F2F7),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 34,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
        children: [
          const SizedBox(height: 8),

          // Profile card - WhatsApp style
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: _isLoading
                      ? Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : _buildProfileAvatarWithAura(isDark, avatarUrl),
                  title: Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (username != null && username.isNotEmpty) ...[
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (email != null && email.isNotEmpty) ...[
                        Text(
                          email!,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        about,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.qr_code_rounded,
                          color: NearTheme.primary,
                          size: 24,
                        ),
                        onPressed: () => _showQRCodeBottomSheet(context),
                        tooltip: 'QR Kodum',
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ],
                  ),
                  onTap: () async {
                    await context.push(ProfileEditPage.route);
                    // Profil düzenleme sonrası yenile
                    _loadProfile();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ✨ Mood Aura - Premium Feature
          _buildMoodAuraSection(isDark, cs),

          const SizedBox(height: 24),

          // Main settings group
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.star_rounded,
                  iconBackgroundColor: SettingsColors.yellow,
                  title: 'Starred Messages',
                  subtitle: 'Yıldızlı mesajlarını gör',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StarredMessagesPage()),
                  ),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.laptop_mac_rounded,
                  iconBackgroundColor: SettingsColors.green,
                  title: 'Linked Devices',
                  subtitle: 'Bağlı cihazları yönet',
                  onTap: () => _go(context, '/settings/devices'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Settings categories
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.key_rounded,
                  iconBackgroundColor: SettingsColors.blue,
                  title: 'Account',
                  subtitle: 'Güvenlik, şifre, 2FA',
                  onTap: () => _go(context, AccountPage.route),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.lock_rounded,
                  iconBackgroundColor: SettingsColors.teal,
                  title: 'Privacy',
                  subtitle: 'Son görülme, profil fotoğrafı, engelleme',
                  onTap: () => _go(context, PrivacyPage.route),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  iconBackgroundColor: SettingsColors.blue,
                  title: 'Uygulama Kilidi',
                  subtitle: 'PIN, Face ID, Touch ID',
                  onTap: () => _go(context, '/settings/app-lock'),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.chat_bubble_rounded,
                  iconBackgroundColor: SettingsColors.green,
                  title: 'Chats',
                  subtitle: 'Tema, duvar kağıdı, chat geçmişi',
                  onTap: () => _go(context, ChatsSettingsPage.route),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.notifications_rounded,
                  iconBackgroundColor: SettingsColors.red,
                  title: 'Notifications',
                  subtitle: 'Mesaj, grup bildirimleri',
                  onTap: () => _go(context, NotificationsPage.route),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.data_usage_rounded,
                  iconBackgroundColor: SettingsColors.green,
                  title: 'Storage and Data',
                  subtitle: 'Ağ kullanımı, otomatik indirme',
                  onTap: () => _go(context, StoragePage.route),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.accessibility_new_rounded,
                  iconBackgroundColor: SettingsColors.purple,
                  title: 'Accessibility',
                  subtitle: 'Erişilebilirlik, renk körü modu, RTL',
                  onTap: () => _openAccessibilitySettings(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Help section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.help_rounded,
                  iconBackgroundColor: SettingsColors.blue,
                  title: 'Help',
                  subtitle: 'SSS, iletişim, gizlilik politikası',
                  onTap: () => _go(context, HelpPage.route),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.favorite_rounded,
                  iconBackgroundColor: SettingsColors.pink,
                  title: 'Tell a Friend',
                  subtitle: 'Near\'ı arkadaşlarınla paylaş',
                  onTap: () => _shareApp(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // App version
          const Center(
            child: NearVersionText(),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
    height: 1,
    indent: 70,
    color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
  );

  /// Profil avatarını Mood Aura ile göster
  Widget _buildProfileAvatarWithAura(bool isDark, String? avatarUrl) {
    final currentMood = MoodAura.fromString(_profile?['mood_aura']);
    
    final avatarWidget = CircleAvatar(
      radius: 30,
      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      onBackgroundImageError: avatarUrl != null ? (_, __) {
        debugPrint('Avatar load error: $avatarUrl');
      } : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Icon(
              Icons.person,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              size: 36,
            )
          : null,
    );
    
    // Mood Aura aktifse sarmalayıcı ile göster
    if (currentMood != MoodAura.none) {
      return MoodAuraWidget(
        mood: currentMood,
        size: 60,
        child: avatarWidget,
      );
    }
    
    return avatarWidget;
  }

  /// Mood Aura Premium Section
  Widget _buildMoodAuraSection(bool isDark, ColorScheme cs) {
    final currentMood = MoodAura.fromString(_profile?['mood_aura']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF1C1C1E) : Colors.white,
            isDark 
                ? (currentMood.primaryColor?.withAlpha(30) ?? const Color(0xFF1C1C1E))
                : (currentMood.primaryColor?.withAlpha(20) ?? Colors.white),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentMood.primaryColor?.withAlpha(50) ?? Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: currentMood != MoodAura.none
                ? MoodAuraWidget(
                    mood: currentMood,
                    size: 44,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            currentMood.primaryColor!,
                            currentMood.secondaryColor!,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          currentMood.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
            title: Row(
              children: [
                Text(
                  '✨ Mood Aura',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              currentMood != MoodAura.none
                  ? '${currentMood.emoji} ${currentMood.label} - ${currentMood.description}'
                  : 'Ruh halini profil fotoğrafınla göster',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            onTap: () => _showMoodAuraPicker(isDark),
          ),
        ],
      ),
    );
  }

  void _showMoodAuraPicker(bool isDark) {
    final currentMood = MoodAura.fromString(_profile?['mood_aura']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MoodAuraPickerSheet(
        currentMood: currentMood,
        onMoodSelected: (mood) async {
          final success = await MoodAuraService.instance.setMood(mood);
          if (success) {
            setState(() {
              _profile?['mood_aura'] = mood.value;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    mood == MoodAura.none
                        ? 'Mood Aura kapatıldı'
                        : '${mood.emoji} ${mood.label} aurası aktif!',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: mood.primaryColor ?? Colors.grey,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Near - Modern mesajlaşma uygulaması! 📱✨\n\nHızlı, güvenli ve şık. Hemen dene!\n\nhttps://near.app',
        subject: 'Near - Mesajlaşma Uygulaması',
      ),
    );
  }

  void _openAccessibilitySettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AccessibilitySettingsScreen(),
      ),
    );
  }

  void _showQRCodeBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            // Tab bar
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        padding: const EdgeInsets.all(4),
                        indicator: BoxDecoration(
                          color: NearTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark
                            ? Colors.white60
                            : Colors.black54,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'QR Kodum'),
                          Tab(text: 'Kodu Tara'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // My QR Code tab
                          _buildMyQRCodeTab(context, isDark),
                          // Scan QR tab
                          _buildScanQRTab(context, isDark),
                        ],
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

  Widget _buildMyQRCodeTab(BuildContext context, bool isDark) {
    final displayName = _profile?['full_name'] ?? _profile?['username'] ?? 'Kullanıcı';
    final username = _profile?['username'] as String?;
    final avatarUrl = _profile?['avatar_url'] as String?;
    final userId = _supabase.currentUser?.id ?? '';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // User info
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 48,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 48,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          if (username != null && username.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@$username',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // QR Code
          QRCodeDisplay(
            data: 'near://user/$userId',
            size: 220,
            foregroundColor: NearTheme.primary,
            backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          ),

          const SizedBox(height: 24),

          Text(
            'Kişi eklemek için QR kodunuzu taratın',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),

          const SizedBox(height: 24),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR kod paylaşılıyor...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('QR Kodu Paylaş'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NearTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanQRTab(BuildContext context, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Scanner preview
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Placeholder camera view
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kamera önizlemesi',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Corner decorations
              ..._buildScannerCorners(),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'QR kodu çerçevenin içine yerleştirin',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),

        const Spacer(),

        // Full scanner button
        Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScannerPage(
                      onScanned: (data) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Taranan: $data'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.fullscreen),
              label: const Text('Tam Ekran Tarayıcı'),
              style: OutlinedButton.styleFrom(
                foregroundColor: NearTheme.primary,
                side: BorderSide(color: NearTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildScannerCorners() {
    const cornerSize = 24.0;
    const strokeWidth = 3.0;
    const color = Color(0xFF7B3FF2);
    const margin = 20.0;

    return [
      // Top-left
      Positioned(
        top: margin,
        left: margin,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: strokeWidth),
              left: BorderSide(color: color, width: strokeWidth),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: margin,
        right: margin,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: strokeWidth),
              right: BorderSide(color: color, width: strokeWidth),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: margin,
        left: margin,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: strokeWidth),
              left: BorderSide(color: color, width: strokeWidth),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: margin,
        right: margin,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: strokeWidth),
              right: BorderSide(color: color, width: strokeWidth),
            ),
          ),
        ),
      ),
    ];
  }
}
