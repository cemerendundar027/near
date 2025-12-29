import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/settings_widgets.dart';

class AccountPage extends StatefulWidget {
  static const route = '/settings/account';
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
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

  void _showChangePhoneDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            Text(
              'Mevcut numara: +90 5XX XXX XX XX',
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
                labelText: 'Yeni Telefon Numarası',
                prefixText: '+90 ',
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
              'SMS ile doğrulama kodu gönderilecektir.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () {
              if (phoneController.text.isNotEmpty) {
                Navigator.pop(context);
                _showVerificationDialog('telefon');
              }
            },
            child: Text('Devam', style: TextStyle(color: NearTheme.primary)),
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
      builder: (context) => AlertDialog(
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
            Text(
              'Mevcut e-posta: cem@example.com',
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
              'E-posta ile doğrulama linki gönderilecektir.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty && emailController.text.contains('@')) {
                Navigator.pop(context);
                _showVerificationDialog('e-posta');
              }
            },
            child: Text('Devam', style: TextStyle(color: NearTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Doğrulama Kodu',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type == 'telefon' 
                  ? 'Yeni numaranıza gönderilen 6 haneli kodu girin.'
                  : 'Yeni e-postanıza gönderilen 6 haneli kodu girin.',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
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
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () {
              if (codeController.text.length == 6) {
                Navigator.pop(context);
                _toast(type == 'telefon' ? 'Telefon numarası güncellendi' : 'E-posta güncellendi');
              }
            },
            child: Text('Doğrula', style: TextStyle(color: NearTheme.primary)),
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
                  title: 'Change Number',
                  subtitle: '+90 5XX XXX XX XX',
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
                  title: 'Email',
                  subtitle: 'cem@example.com',
                  onTap: _showChangeEmailDialog,
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.devices_rounded,
                  iconBackgroundColor: SettingsColors.gray,
                  title: 'Active Sessions',
                  subtitle: '2 cihazda aktif',
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _toast('Şifre değiştirildi ✓');
            },
            child: const Text('Change'),
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w700, color: SettingsColors.red)),
        content: const Text('Bu işlem geri alınamaz. Tüm verileriniz silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SettingsColors.red),
            onPressed: () {
              Navigator.pop(context);
              _toast('Hesap silme isteği alındı');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
