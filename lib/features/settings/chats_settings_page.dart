import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../app/theme.dart';
import '../../app/app_settings.dart';
import '../../shared/settings_widgets.dart';
import '../../shared/settings_service.dart';
import '../../shared/chat_service.dart';

class ChatsSettingsPage extends StatefulWidget {
  static const route = '/settings/chats';
  const ChatsSettingsPage({super.key});

  @override
  State<ChatsSettingsPage> createState() => _ChatsSettingsPageState();
}

class _ChatsSettingsPageState extends State<ChatsSettingsPage> {
  final _settingsService = SettingsService.instance;
  final _chatService = ChatService.instance;

  String _modeLabel(NearThemeMode m) {
    switch (m) {
      case NearThemeMode.system:
        return 'System Default';
      case NearThemeMode.light:
        return 'Light';
      case NearThemeMode.dark:
        return 'Dark';
    }
  }

  String _wallpaperLabel(NearWallpaper w) {
    switch (w) {
      case NearWallpaper.none:
        return 'Default';
      case NearWallpaper.softPurple:
        return 'Soft Purple';
      case NearWallpaper.graphite:
        return 'Graphite';
    }
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

  void _showExportChatDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Gerçek sohbet listesini al
    final chats = _chatService.chats;
    
    if (chats.isEmpty) {
      _toast('Dışa aktarılacak sohbet bulunamadı');
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
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
                  'Sohbet Seç',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (ctx, index) {
                    final chat = chats[index];
                    final isGroup = chat['is_group'] == true;
                    final chatName = _chatService.getChatName(chat);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: NearTheme.primary.withAlpha(30),
                        child: Icon(
                          isGroup ? Icons.group_rounded : Icons.person_rounded,
                          color: NearTheme.primary,
                        ),
                      ),
                      title: Text(
                        chatName,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                      subtitle: Text(
                        isGroup ? 'Grup sohbeti' : 'Bireysel sohbet',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _exportChat(chatName);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _exportChat(String chatName) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Dışa Aktar',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$chatName sohbetini nasıl dışa aktarmak istersiniz?',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.text_snippet, color: NearTheme.primary),
              title: Text(
                'Metin olarak',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                SharePlus.instance.share(
                  ShareParams(
                    text: '$chatName sohbet geçmişi\n\n[Örnek mesajlar...]\n\nNear uygulaması ile dışa aktarıldı.',
                    subject: '$chatName - Sohbet Geçmişi',
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.attach_file, color: NearTheme.primary),
              title: Text(
                'Medya ile birlikte',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              onTap: () {
                Navigator.pop(context);
                _toast('$chatName sohbeti dışa aktarılıyor...');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([settings, _settingsService]),
      builder: (_, _) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            title: Text(
              'Chats',
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
          body: ListView(
            children: [
              const SettingsSectionHeader(title: 'Display'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.brightness_6_rounded,
                      iconBackgroundColor: SettingsColors.indigo,
                      title: 'Theme',
                      subtitle: _modeLabel(settings.themeMode),
                      onTap: () => _showThemePicker(settings),
                    ),
                    _divider(isDark),
                    SettingsTile(
                      icon: Icons.wallpaper_rounded,
                      iconBackgroundColor: SettingsColors.teal,
                      title: 'Wallpaper',
                      subtitle: _wallpaperLabel(settings.wallpaper),
                      onTap: () => _showWallpaperPicker(settings),
                    ),
                  ],
                ),
              ),

              const SettingsSectionHeader(title: 'Font Size'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: SettingsColors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Font Size',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(settings.fontScale * 100).round()}%',
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('A', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                          Expanded(
                            child: Slider(
                              value: settings.fontScale,
                              min: 0.90,
                              max: 1.20,
                              divisions: 6,
                              activeColor: NearTheme.primary,
                              onChanged: (v) => settings.setFontScale(v),
                            ),
                          ),
                          Text('A', style: TextStyle(fontSize: 20, color: isDark ? Colors.white54 : Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SettingsSectionHeader(title: 'Chat Settings'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.keyboard_return_rounded,
                      iconBackgroundColor: SettingsColors.green,
                      title: 'Enter is Send',
                      subtitle: 'Enter tuşu mesaj gönderir',
                      value: _settingsService.enterToSend,
                      onChanged: (v) {
                        _settingsService.setEnterToSend(v);
                        _toast(v ? 'Enter ile gönder: Açık' : 'Enter ile gönder: Kapalı');
                      },
                    ),
                    _divider(isDark),
                    SettingsSwitchTile(
                      icon: Icons.photo_library_rounded,
                      iconBackgroundColor: SettingsColors.blue,
                      title: 'Media Visibility',
                      subtitle: 'Medyaları galeriye kaydet',
                      value: _settingsService.mediaVisibility,
                      onChanged: (v) {
                        _settingsService.setMediaVisibility(v);
                        _toast(v ? 'Galeri kayıt: Açık' : 'Galeri kayıt: Kapalı');
                      },
                    ),
                  ],
                ),
              ),

              const SettingsSectionHeader(title: 'Chat History'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.cloud_upload_rounded,
                      iconBackgroundColor: SettingsColors.green,
                      title: 'Chat Backup',
                      subtitle: 'Sohbetleri yedekle',
                      onTap: () => _showBackupDialog(),
                    ),
                    _divider(isDark),
                    SettingsTile(
                      icon: Icons.history_rounded,
                      iconBackgroundColor: SettingsColors.purple,
                      title: 'Export Chat',
                      subtitle: 'Sohbet geçmişini dışa aktar',
                      onTap: _showExportChatDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        indent: 70,
        color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
      );

  void _showThemePicker(AppSettings settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            _themeOption('System Default', NearThemeMode.system, settings),
            _themeOption('Light', NearThemeMode.light, settings),
            _themeOption('Dark', NearThemeMode.dark, settings),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(String label, NearThemeMode mode, AppSettings settings) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: settings.themeMode == mode
          ? const Icon(Icons.check_circle, color: SettingsColors.green)
          : null,
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        settings.setThemeMode(mode);
        _toast('Tema: $label');
      },
    );
  }

  void _showWallpaperPicker(AppSettings settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Wallpaper', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            _wallpaperOption('Default', NearWallpaper.none, settings),
            _wallpaperOption('Soft Purple', NearWallpaper.softPurple, settings),
            _wallpaperOption('Graphite', NearWallpaper.graphite, settings),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _wallpaperOption(String label, NearWallpaper wp, AppSettings settings) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: settings.wallpaper == wp
          ? const Icon(Icons.check_circle, color: SettingsColors.green)
          : null,
      onTap: () {
        Navigator.pop(context);
        settings.setWallpaper(wp);
        _toast('Duvar kağıdı: $label');
      },
    );
  }

  void _showBackupDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Backup Chats', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Tüm sohbetlerin iCloud\'a yedeklenecek. Bu işlem birkaç dakika sürebilir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _toast('Yedekleme başladı...');
            },
            child: const Text('Backup Now'),
          ),
        ],
      ),
    );
  }
}
