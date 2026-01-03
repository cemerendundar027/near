import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme.dart';
import '../../shared/settings_widgets.dart';
import '../../shared/auth_service.dart';

class AccountPage extends StatefulWidget {
  static const route = '/settings/account';
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _supabase = Supabase.instance.client;
  final _auth = AuthService.instance;
  
  bool _twoStepEnabled = false;
  bool _fingerprintEnabled = true;
  bool _isLoading = true;
  
  String _email = '';
  String _phone = '';
  
  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }
  
  Future<void> _loadAccountInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Profil bilgilerini al
        final profile = await _supabase
            .from('profiles')
            .select('phone')
            .eq('id', user.id)
            .maybeSingle();
        
        if (mounted) {
          setState(() {
            _email = user.email ?? '';
            _phone = profile?['phone'] ?? '';
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading account info: $e');
      setState(() => _isLoading = false);
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

  void _showChangePhoneDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Telefon Numarası Değiştir',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_phone.isNotEmpty)
              Text(
                'Mevcut numara: $_phone',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefon Numarası',
                hintText: '+90 5XX XXX XX XX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: NearTheme.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) {
                _toast('Lütfen telefon numarası girin');
                return;
              }
              
              Navigator.pop(ctx);
              
              try {
                final userId = _supabase.auth.currentUser?.id;
                if (userId != null) {
                  await _supabase.from('profiles').update({
                    'phone': phone,
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', userId);
                  
                  setState(() => _phone = phone);
                  _toast('Telefon numarası güncellendi ✓');
                }
              } catch (e) {
                _toast('Güncelleme başarısız: ${e.toString()}');
              }
            },
            child: Text('Kaydet', style: TextStyle(color: NearTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'E-posta Değiştir',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_email.isNotEmpty)
              Text(
                'Mevcut e-posta: $_email',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Yeni E-posta Adresi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: NearTheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'E-posta değişikliği için doğrulama maili gönderilecektir.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () async {
              final newEmail = emailController.text.trim();
              if (newEmail.isEmpty || !newEmail.contains('@')) {
                _toast('Lütfen geçerli bir e-posta girin');
                return;
              }
              
              Navigator.pop(ctx);
              
              try {
                await _supabase.auth.updateUser(
                  UserAttributes(email: newEmail),
                );
                _toast('Doğrulama e-postası gönderildi. Lütfen kontrol edin.');
              } catch (e) {
                _toast('E-posta değiştirilemedi: ${e.toString()}');
              }
            },
            child: Text('Gönder', style: TextStyle(color: NearTheme.primary)),
          ),
        ],
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

          const SettingsSectionHeader(title: 'Phone Number'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.phone_iphone_rounded,
                  iconBackgroundColor: SettingsColors.teal,
                  title: 'Telefon Numarası',
                  subtitle: _phone.isNotEmpty ? _phone : 'Telefon numarası eklenmemiş',
                  onTap: _showChangePhoneDialog,
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'Account Info'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.email_rounded,
                  iconBackgroundColor: SettingsColors.purple,
                  title: 'E-posta',
                  subtitle: _email.isNotEmpty ? _email : 'E-posta bulunamadı',
                  onTap: _showChangeEmailDialog,
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.devices_rounded,
                  iconBackgroundColor: SettingsColors.gray,
                  title: 'Aktif Oturumlar',
                  subtitle: 'Bu cihazda aktif',
                  onTap: () => _showActiveSessions(),
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

  void _showActiveSessions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _sessionTile('iPhone 14 Pro', 'Şu an • İstanbul', true),
              const SizedBox(height: 12),
              _sessionTile('MacBook Pro', '2 saat önce • Ankara', false),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _toast('Diğer oturumlar kapatıldı');
                  },
                  icon: const Icon(Icons.logout, color: SettingsColors.red),
                  label: const Text('Log Out All Other Sessions', style: TextStyle(color: SettingsColors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionTile(String device, String info, bool current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            device.contains('iPhone') ? Icons.phone_iphone : Icons.laptop_mac,
            color: current ? SettingsColors.green : (isDark ? Colors.white54 : Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(info, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
          if (current)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SettingsColors.green.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Current', style: TextStyle(fontSize: 11, color: SettingsColors.green, fontWeight: FontWeight.w600)),
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
