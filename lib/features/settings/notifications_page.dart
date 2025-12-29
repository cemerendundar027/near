import 'package:flutter/material.dart';
import '../../shared/settings_widgets.dart';
import '../../shared/settings_service.dart';

class NotificationsPage extends StatefulWidget {
  static const route = '/settings/notifications';
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _settings = SettingsService.instance;

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        title: Text(
          'Notifications',
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
          const SettingsSectionHeader(title: 'Message Notifications'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.chat_bubble_rounded,
                  iconBackgroundColor: SettingsColors.blue,
                  title: 'Message Notifications',
                  subtitle: 'Mesaj bildirimleri',
                  value: _settings.messageNotifications,
                  onChanged: (v) {
                    _settings.setMessageNotifications(v);
                    _toast(v ? 'Mesaj bildirimleri açık' : 'Mesaj bildirimleri kapalı');
                  },
                ),
                if (_settings.messageNotifications) ...[
                  _divider(isDark),
                  SettingsSwitchTile(
                    icon: Icons.visibility_rounded,
                    iconBackgroundColor: SettingsColors.teal,
                    title: 'Show Preview',
                    subtitle: 'Bildirimde mesaj önizlemesi',
                    value: _settings.showPreview,
                    onChanged: (v) {
                      _settings.setShowPreview(v);
                      _toast(v ? 'Önizleme açık' : 'Önizleme kapalı');
                    },
                  ),
                  _divider(isDark),
                  SettingsSwitchTile(
                    icon: Icons.volume_up_rounded,
                    iconBackgroundColor: SettingsColors.green,
                    title: 'Sound',
                    subtitle: 'Bildirim sesi',
                    value: _settings.sound,
                    onChanged: (v) {
                      _settings.setSound(v);
                      _toast(v ? 'Ses açık' : 'Ses kapalı');
                    },
                  ),
                  _divider(isDark),
                  SettingsSwitchTile(
                    icon: Icons.vibration_rounded,
                    iconBackgroundColor: SettingsColors.orange,
                    title: 'Vibrate',
                    subtitle: 'Titreşim',
                    value: _settings.vibrate,
                    onChanged: (v) {
                      _settings.setVibrate(v);
                      _toast(v ? 'Titreşim açık' : 'Titreşim kapalı');
                    },
                  ),
                ],
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'Group Notifications'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.group_rounded,
                  iconBackgroundColor: SettingsColors.purple,
                  title: 'Group Notifications',
                  subtitle: 'Grup bildirimleri',
                  value: _settings.groupNotifications,
                  onChanged: (v) {
                    _settings.setGroupNotifications(v);
                    _toast(v ? 'Grup bildirimleri açık' : 'Grup bildirimleri kapalı');
                  },
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'In-App Notifications'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.music_note_rounded,
                  iconBackgroundColor: SettingsColors.pink,
                  title: 'In-App Sounds',
                  subtitle: 'Uygulama içi sesler',
                  value: _settings.inAppSounds,
                  onChanged: (v) {
                    _settings.setInAppSounds(v);
                    _toast(v ? 'Uygulama içi sesler açık' : 'Uygulama içi sesler kapalı');
                  },
                ),
                _divider(isDark),
                SettingsSwitchTile(
                  icon: Icons.smartphone_rounded,
                  iconBackgroundColor: SettingsColors.gray,
                  title: 'In-App Vibrate',
                  subtitle: 'Uygulama içi titreşim',
                  value: _settings.inAppVibrate,
                  onChanged: (v) {
                    _settings.setInAppVibrate(v);
                    _toast(v ? 'Uygulama içi titreşim açık' : 'Uygulama içi titreşim kapalı');
                  },
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'Reset'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.restart_alt_rounded,
                  iconBackgroundColor: SettingsColors.red,
                  title: 'Reset Notification Settings',
                  subtitle: 'Tüm ayarları sıfırla',
                  showChevron: false,
                  onTap: () => _showResetDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    ));
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        indent: 70,
        color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
      );

  void _showResetDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Reset Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Tüm bildirim ayarları varsayılan değerlere döndürülecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SettingsColors.red),
            onPressed: () {
              Navigator.pop(context);
              _settings.resetNotificationSettings();
              _toast('Ayarlar sıfırlandı');
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
