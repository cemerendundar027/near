import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import '../../app/theme.dart';
import '../../shared/settings_widgets.dart';
import '../../shared/widgets/near_branding.dart';

class HelpPage extends StatelessWidget {
  static const route = '/settings/help';
  const HelpPage({super.key});

  void _toast(BuildContext context, String msg) {
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
          'Help',
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
          const SettingsSectionHeader(title: 'Support'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.help_center_rounded,
                  iconBackgroundColor: SettingsColors.blue,
                  title: 'Help Center',
                  subtitle: 'Sık sorulan sorular ve yardım',
                  onTap: () => _showHelpCenterSheet(context),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconBackgroundColor: SettingsColors.green,
                  title: 'Contact Us',
                  subtitle: 'Destek ekibimize ulaşın',
                  onTap: () => _showContactSheet(context),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.bug_report_rounded,
                  iconBackgroundColor: SettingsColors.orange,
                  title: 'Report a Problem',
                  subtitle: 'Hata veya sorun bildir',
                  onTap: () => _showReportDialog(context),
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'Legal'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.description_rounded,
                  iconBackgroundColor: SettingsColors.gray,
                  title: 'Terms of Service',
                  subtitle: 'Kullanım koşulları',
                  onTap: () => _showTermsSheet(context),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  iconBackgroundColor: SettingsColors.teal,
                  title: 'Privacy Policy',
                  subtitle: 'Gizlilik politikası',
                  onTap: () => _showPrivacySheet(context),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.copyright_rounded,
                  iconBackgroundColor: SettingsColors.purple,
                  title: 'Licenses',
                  subtitle: 'Açık kaynak lisansları',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'near',
                    applicationVersion: '1.0.0',
                    applicationIcon: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: NearTheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SettingsSectionHeader(title: 'About'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.info_rounded,
                  iconBackgroundColor: NearTheme.primary,
                  title: 'App Info',
                  subtitle: 'near v1.0.0 (Build 1)',
                  showChevron: false,
                  onTap: () {},
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.share_rounded,
                  iconBackgroundColor: SettingsColors.pink,
                  title: 'Share near',
                  subtitle: 'Arkadaşlarınla paylaş',
                  onTap: () => SharePlus.instance.share(
                    ShareParams(
                      text: 'Near - Modern mesajlaşma uygulaması! 📱✨\n\nHızlı, güvenli ve şık. Hemen dene!\n\nhttps://near.app',
                      subject: 'Near - Mesajlaşma Uygulaması',
                    ),
                  ),
                ),
                _divider(isDark),
                SettingsTile(
                  icon: Icons.star_rounded,
                  iconBackgroundColor: SettingsColors.yellow,
                  title: 'Rate near',
                  subtitle: 'App Store\'da değerlendir',
                  onTap: () => _showRatingDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Column(
              children: [
                const NearIcon(size: 70, borderRadius: 16),
                const SizedBox(height: 12),
                const NearLogo(fontSize: 22),
                const SizedBox(height: 4),
                Text(
                  'Made with ❤️ in Limassol',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
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

  void _showContactSheet(BuildContext context) {
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
            children: [
              const Text('Contact Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SettingsColors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.email_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('support@near.app'),
                onTap: () {
                  Navigator.pop(context);
                  _toast(context, 'E-posta açılıyor...');
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SettingsColors.teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Website', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('www.near.app'),
                onTap: () {
                  Navigator.pop(context);
                  _toast(context, 'Website açılıyor...');
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DA1F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alternate_email_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Twitter', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('@nearapp'),
                onTap: () {
                  Navigator.pop(context);
                  _toast(context, 'Twitter açılıyor...');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        title: const Text('Report a Problem', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yaşadığınız sorunu kısaca açıklayın:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Sorununuzu buraya yazın...',
                border: OutlineInputBorder(),
              ),
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
              _toast(context, 'Raporunuz gönderildi. Teşekkürler!');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Yardım Merkezi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _faqItem('Nasıl mesaj gönderebilirim?', 'Sohbet listesinden bir kişi seçin veya yeni sohbet başlatmak için sağ üstteki + butonuna tıklayın.'),
            _faqItem('Profil fotoğrafımı nasıl değiştirebilirim?', 'Ayarlar > Profil düzenle bölümünden profil fotoğrafınıza tıklayarak değiştirebilirsiniz.'),
            _faqItem('Mesajlarımı nasıl yedekleyebilirim?', 'Ayarlar > Sohbetler > Sohbet Yedeği bölümünden yedekleme ayarlarını yapabilirsiniz.'),
            _faqItem('Birini nasıl engelleyebilirim?', 'Kişinin profilini açın ve "Engelle" seçeneğine tıklayın.'),
            _faqItem('Grup nasıl oluşturabilirim?', 'Sohbet listesinde + butonuna tıklayın ve "Yeni Grup" seçeneğini seçin.'),
            _faqItem('Kaybolan mesajlar nedir?', 'Kaybolan mesajlar, belirlenen süre sonunda otomatik olarak silinen mesajlardır.'),
            _faqItem('Bildirimleri nasıl kapatabilirim?', 'Ayarlar > Bildirimler bölümünden bildirim tercihlerinizi yönetebilirsiniz.'),
            _faqItem('Hesabımı nasıl silebilirim?', 'Ayarlar > Hesap > Hesabı Sil bölümünden hesabınızı kalıcı olarak silebilirsiniz.'),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  void _showTermsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: const [
            Text('Kullanım Koşulları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: 20),
            Text('Son Güncelleme: 26 Aralık 2025\n', style: TextStyle(color: Colors.grey)),
            Text('1. Kabul', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Near uygulamasını kullanarak bu kullanım koşullarını kabul etmiş olursunuz.'),
            SizedBox(height: 16),
            Text('2. Hizmet Açıklaması', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Near, kullanıcıların mesajlaşmasına olanak tanıyan bir iletişim platformudur.'),
            SizedBox(height: 16),
            Text('3. Kullanıcı Yükümlülükleri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Kullanıcılar, platformu yasalara uygun şekilde kullanmayı kabul eder. Spam, kötü niyetli içerik ve yasadışı faaliyetler yasaktır.'),
            SizedBox(height: 16),
            Text('4. İçerik', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Paylaştığınız içeriklerden siz sorumlusunuz. Near, uygunsuz içerikleri kaldırma hakkını saklı tutar.'),
            SizedBox(height: 16),
            Text('5. Gizlilik', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Kişisel verileriniz Gizlilik Politikamıza uygun olarak işlenir.'),
            SizedBox(height: 16),
            Text('6. Değişiklikler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Bu koşulları önceden haber vermeksizin değiştirme hakkımız saklıdır.'),
          ],
        ),
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: const [
            Text('Gizlilik Politikası', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            SizedBox(height: 20),
            Text('Son Güncelleme: 26 Aralık 2025\n', style: TextStyle(color: Colors.grey)),
            Text('1. Toplanan Veriler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('• Telefon numaranız\n• Profil bilgileriniz (isim, fotoğraf, hakkında)\n• Mesajlarınız (uçtan uca şifreli)\n• Cihaz bilgileri'),
            SizedBox(height: 16),
            Text('2. Verilerin Kullanımı', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Verileriniz yalnızca hizmetlerimizi sunmak için kullanılır. Üçüncü taraflarla paylaşılmaz.'),
            SizedBox(height: 16),
            Text('3. Şifreleme', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Tüm mesajlarınız uçtan uca şifreleme ile korunur. Near dahil hiç kimse mesajlarınızı okuyamaz.'),
            SizedBox(height: 16),
            Text('4. Veri Saklama', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Hesabınız aktif olduğu sürece verileriniz saklanır. Hesap silindiğinde tüm veriler kalıcı olarak silinir.'),
            SizedBox(height: 16),
            Text('5. Haklarınız', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            SizedBox(height: 8),
            Text('Verilerinize erişme, düzeltme ve silme hakkına sahipsiniz. support@near.app adresinden bize ulaşabilirsiniz.'),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Near\'ı Değerlendir', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Near\'ı beğendiniz mi? App Store\'da değerlendirin!'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => Icon(
                Icons.star,
                color: i < 4 ? Colors.amber : Colors.grey.shade300,
                size: 40,
              )),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _toast(context, 'Değerlendirmeniz için teşekkürler! ⭐');
            },
            child: const Text('Değerlendir'),
          ),
        ],
      ),
    );
  }
}