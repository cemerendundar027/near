import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/settings_widgets.dart';
import '../../shared/contact_service.dart';

class PrivacyPage extends StatefulWidget {
  static const route = '/settings/privacy';
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final _contactService = ContactService.instance;
  
  String _lastSeenOption = 'everyone';
  String _profilePhotoOption = 'everyone';
  String _aboutOption = 'everyone';
  String _groupAddOption = 'everyone';
  String _messageOption = 'everyone'; // Yeni: Kimler mesaj gönderebilir
  bool _readReceipts = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _contactService.loadPrivacySettings();
    
    final settings = _contactService.privacySettings;
    if (settings != null && mounted) {
      setState(() {
        _lastSeenOption = settings['privacy_last_seen'] ?? 'everyone';
        _profilePhotoOption = settings['privacy_profile_photo'] ?? 'everyone';
        _aboutOption = settings['privacy_about'] ?? 'everyone';
        _messageOption = settings['privacy_messages'] ?? 'everyone';
        _readReceipts = settings['privacy_read_receipts'] ?? true;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _go(BuildContext context, String route) {
    context.push(route);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ));
  }

  String _getDisplayLabel(String value) {
    switch (value) {
      case 'everyone':
        return 'Herkes';
      case 'contacts':
        return 'Kişilerim';
      case 'nobody':
        return 'Hiç kimse';
      default:
        return value;
    }
  }

  String _getMessageDisplayLabel(String value) {
    switch (value) {
      case 'everyone':
        return 'Herkes (kullanıcı adımı bulanlar dahil)';
      case 'contacts':
        return 'Sadece Kişilerim';
      default:
        return value;
    }
  }

  void _showMessagePrivacyPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                child: Text(
                  'Bana Mesaj Gönderebilir',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
              
              // Herkes seçeneği
              ListTile(
                leading: Icon(Icons.public, color: isDark ? Colors.white70 : Colors.black54),
                title: Text(
                  'Herkes',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  'Kullanıcı adınızı arayanlar da dahil',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                trailing: _messageOption == 'everyone'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _messageOption = 'everyone');
                  final success = await _contactService.updateMessagePrivacy('everyone');
                  if (success) {
                    _toast('Mesaj ayarı güncellendi');
                  } else {
                    _toast('Ayar güncellenemedi');
                  }
                },
              ),
              
              // Sadece Kişilerim seçeneği
              ListTile(
                leading: Icon(Icons.contacts, color: isDark ? Colors.white70 : Colors.black54),
                title: Text(
                  'Sadece Kişilerim',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  'Yalnızca rehberinizdeki kişiler mesaj gönderebilir',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                trailing: _messageOption == 'contacts'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _messageOption = 'contacts');
                  final success = await _contactService.updateMessagePrivacy('contacts');
                  if (success) {
                    _toast('Mesaj ayarı güncellendi');
                  } else {
                    _toast('Ayar güncellenemedi');
                  }
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        title: Text(
          'Gizlilik',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          const SettingsSectionHeader(title: 'Kişisel bilgilerimi kimler görebilir'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.access_time_rounded,
                  iconBackgroundColor: SettingsColors.blue,
                  title: 'Son Görülme',
                  subtitle: _getDisplayLabel(_lastSeenOption),
                  onTap: () => _showPrivacyPicker(
                    'Son Görülme', 
                    _lastSeenOption, 
                    (v) async {
                    setState(() => _lastSeenOption = v);
                      final success = await _contactService.updateLastSeenPrivacy(v);
                      if (success) {
                        _toast('Son görülme ayarı güncellendi');
                      } else {
                        _toast('Ayar güncellenemedi');
                      }
                    },
                  ),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.person_rounded,
                  iconBackgroundColor: SettingsColors.green,
                  title: 'Profil Fotoğrafı',
                  subtitle: _getDisplayLabel(_profilePhotoOption),
                  onTap: () => _showPrivacyPicker(
                    'Profil Fotoğrafı', 
                    _profilePhotoOption, 
                    (v) async {
                    setState(() => _profilePhotoOption = v);
                      final success = await _contactService.updateProfilePhotoPrivacy(v);
                      if (success) {
                        _toast('Profil fotoğrafı ayarı güncellendi');
                      } else {
                        _toast('Ayar güncellenemedi');
                      }
                    },
                  ),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.info_rounded,
                  iconBackgroundColor: SettingsColors.teal,
                  title: 'Hakkımda',
                  subtitle: _getDisplayLabel(_aboutOption),
                  onTap: () => _showPrivacyPicker(
                    'Hakkımda', 
                    _aboutOption, 
                    (v) async {
                    setState(() => _aboutOption = v);
                      final success = await _contactService.updateAboutPrivacy(v);
                      if (success) {
                        _toast('Hakkımda ayarı güncellendi');
                      } else {
                        _toast('Ayar güncellenemedi');
                      }
                    },
                  ),
                ),
                _divider(isDark),
                SettingsSwitchTile(
                  icon: Icons.done_all_rounded,
                  iconBackgroundColor: SettingsColors.purple,
                  title: 'Okundu Bilgisi',
                  subtitle: 'Mesajları okuduğunuzda bildirilsin',
                  value: _readReceipts,
                  onChanged: (v) async {
                    setState(() => _readReceipts = v);
                    final success = await _contactService.updateReadReceiptsPrivacy(v);
                    if (success) {
                    _toast(v ? 'Okundu bilgisi açık' : 'Okundu bilgisi kapalı');
                    } else {
                      _toast('Ayar güncellenemedi');
                      setState(() => _readReceipts = !v); // Geri al
                    }
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Son görülme ayarını "Hiç kimse" yaparsanız, başkalarının son görülme bilgisini de göremezsiniz.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),

          const SettingsSectionHeader(title: 'Mesajlar'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.message_rounded,
                  iconBackgroundColor: SettingsColors.blue,
                  title: 'Bana Mesaj Gönderebilir',
                  subtitle: _getMessageDisplayLabel(_messageOption),
                  onTap: () => _showMessagePrivacyPicker(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              '"Kişilerim" seçerseniz sadece rehberinizdeki kişiler size mesaj gönderebilir. Kullanıcı adınızı arayanlar size mesaj gönderemez.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),

          const SettingsSectionHeader(title: 'Engelleme'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: _contactService,
                  builder: (context, _) {
                    final blockedCount = _contactService.blockedUsers.length;
                    return SettingsTile(
                  icon: Icons.block_rounded,
                  iconBackgroundColor: SettingsColors.red,
                      title: 'Engellenen Kişiler',
                      subtitle: blockedCount > 0 
                          ? '$blockedCount kişi engellendi'
                          : 'Engellediğin kişileri yönet',
                  onTap: () => _go(context, '/settings/blocked'),
                    );
                  },
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.notifications_off_rounded,
                  iconBackgroundColor: SettingsColors.orange,
                  title: 'Sessize Alınanlar',
                  subtitle: 'Sessize aldığın kişileri yönet',
                  onTap: () => _go(context, '/settings/muted'),
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'Gruplar'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.group_add_rounded,
                  iconBackgroundColor: SettingsColors.indigo,
                  title: 'Gruplara Eklenme',
                  subtitle: _getDisplayLabel(_groupAddOption),
                  onTap: () => _showPrivacyPicker('Gruplara Eklenme', _groupAddOption, (v) {
                    setState(() => _groupAddOption = v);
                    _toast('Grup ayarı güncellendi');
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        indent: 70,
        color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
      );

  void _showPrivacyPicker(String title, String current, Function(String) onSelect) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      {'value': 'everyone', 'label': 'Herkes', 'desc': 'Tüm Near kullanıcıları'},
      {'value': 'contacts', 'label': 'Kişilerim', 'desc': 'Sadece kişi listendekilere'},
      {'value': 'nobody', 'label': 'Hiç kimse', 'desc': 'Kimse göremesin'},
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((opt) => ListTile(
                  title: Text(
                    opt['label']!, 
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    opt['desc']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  trailing: current == opt['value']
                      ? const Icon(Icons.check_circle, color: SettingsColors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(opt['value']!);
                  },
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
