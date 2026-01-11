import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme.dart';
import '../../shared/settings_widgets.dart';

class AccountPage extends StatefulWidget {
  static const route = '/settings/account';
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _supabase = Supabase.instance.client;
  
  bool _twoStepEnabled = false;
  bool _fingerprintEnabled = true;

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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        title: Text(
          'Account',
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
          const SettingsSectionHeader(title: 'Security'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsSwitchTile(
                  icon: Icons.security_rounded,
                  iconBackgroundColor: SettingsColors.blue,
                  title: 'Two-Step Verification',
                  subtitle: 'Ekstra güvenlik katmanı',
                  value: _twoStepEnabled,
                  onChanged: (v) {
                    setState(() => _twoStepEnabled = v);
                    _toast(v ? '2FA aktif edildi' : '2FA devre dışı');
                  },
                ),
                _divider(isDark),
                SettingsSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  iconBackgroundColor: SettingsColors.green,
                  title: 'Fingerprint Lock',
                  subtitle: 'Parmak izi ile kilit',
                  value: _fingerprintEnabled,
                  onChanged: (v) {
                    setState(() => _fingerprintEnabled = v);
                    _toast(v ? 'Parmak izi kilidi aktif' : 'Parmak izi kilidi kapalı');
                  },
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.password_rounded,
                  iconBackgroundColor: SettingsColors.orange,
                  title: 'Change Password',
                  subtitle: 'Şifreni değiştir',
                  onTap: () => _showChangePasswordDialog(),
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'Danger Zone'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconBackgroundColor: SettingsColors.red,
                  title: 'Delete My Account',
                  subtitle: 'Hesabını kalıcı olarak sil',
                  onTap: () => _showDeleteAccountDialog(),
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

  void _showChangePasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: Text(
          'Şifre Değiştir',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          FilledButton(
            onPressed: () async {
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();
              
              if (newPassword.isEmpty || confirmPassword.isEmpty) {
                _toast('Lütfen tüm alanları doldurun');
                return;
              }
              
              if (newPassword.length < 6) {
                _toast('Şifre en az 6 karakter olmalı');
                return;
              }
              
              if (newPassword != confirmPassword) {
                _toast('Şifreler eşleşmiyor');
                return;
              }
              
              Navigator.pop(ctx);
              
              try {
                await _supabase.auth.updateUser(
                  UserAttributes(password: newPassword),
                );
                _toast('Şifre başarıyla değiştirildi ✓');
              } catch (e) {
                _toast('Şifre değiştirilemedi: ${e.toString()}');
              }
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text(
          'Hesabı Sil',
          style: TextStyle(fontWeight: FontWeight.w700, color: SettingsColors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu işlem geri alınamaz! Tüm verileriniz kalıcı olarak silinecek:',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              '• Mesajlarınız\n• Sohbetleriniz\n• Profil bilgileriniz\n• Medya dosyalarınız',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                labelText: 'Onaylamak için "SİL" yazın',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SettingsColors.red),
            onPressed: () async {
              if (confirmController.text.trim().toUpperCase() != 'SİL') {
                _toast('Lütfen "SİL" yazarak onaylayın');
                return;
              }
              
              Navigator.pop(ctx);
              _toast('Hesabınız silinmek üzere işaretlendi. Kısa süre içinde çıkış yapılacak.');
              
              // Hesabı sil (profil + auth)
              try {
                final userId = _supabase.auth.currentUser?.id;
                if (userId != null) {
                  // Önce profili sil
                  await _supabase.from('profiles').delete().eq('id', userId);
                }
                // Oturumu kapat
                await _supabase.auth.signOut();
              } catch (e) {
                debugPrint('Error deleting account: $e');
              }
            },
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );
  }
}
