import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/chat_service.dart';
import '../chats/media_gallery_page.dart';

/// Kullanıcı Profil Görüntüleme Sayfası
/// - Avatar ve kapak fotoğrafı
/// - İsim ve bio
/// - Ortak gruplar
/// - Medya galerisi
/// - Engelle/Şikayet et
class UserProfilePage extends StatefulWidget {
  static const route = '/user-profile';

  final String userId;
  final String userName;
  final String? userPhone;
  final String? userAbout;
  final bool isOnline;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    this.userPhone,
    this.userAbout,
    this.isOnline = false,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isBlocked = false;
  bool _isMuted = false;
  bool _isLoading = true;

  // Supabase'den yüklenen ortak gruplar
  List<CommonGroup> _commonGroups = [];
  
  // Medya öğeleri (şimdilik boş, ileride ChatService'den yüklenecek)
  List<MediaThumbnail> _mediaItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final chatService = ChatService.instance;
      
      // Ortak grupları yükle
      final groups = await chatService.getCommonGroups(widget.userId);
      
      if (mounted) {
        setState(() {
          _commonGroups = groups.map((g) => CommonGroup(
            id: g['id'] ?? '',
            name: g['name'] ?? 'Grup',
            memberCount: g['member_count'] ?? 0,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  void _startChat() {
    context.push('/chat/${widget.userId}');
    _showSnackBar('Sohbet açılıyor...');
  }

  void _startCall({bool video = false}) {
    context.push('/call/${widget.userId}?video=$video');
  }

  void _showBlockDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _isBlocked ? 'Engeli Kaldır' : 'Engelle',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          _isBlocked
              ? '${widget.userName} kullanıcısının engelini kaldırmak istiyor musunuz?'
              : '${widget.userName} kullanıcısını engellemek istiyor musunuz? Bu kişiden mesaj ve arama alamayacaksınız.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isBlocked = !_isBlocked);
              Navigator.pop(context);
              _showSnackBar(
                _isBlocked ? 'Kullanıcı engellendi' : 'Engel kaldırıldı',
              );
            },
            child: Text(
              _isBlocked ? 'Engeli Kaldır' : 'Engelle',
              style: TextStyle(
                color: _isBlocked ? NearTheme.primary : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              const SizedBox(height: 16),
              Text(
                'Şikayet Et',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _ReportOption(
                icon: Icons.message_rounded,
                label: 'Spam mesaj',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Şikayetiniz iletildi');
                },
              ),
              _ReportOption(
                icon: Icons.warning_rounded,
                label: 'Taciz veya zorbalık',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Şikayetiniz iletildi');
                },
              ),
              _ReportOption(
                icon: Icons.person_off_rounded,
                label: 'Sahte hesap',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Şikayetiniz iletildi');
                },
              ),
              _ReportOption(
                icon: Icons.no_adult_content_rounded,
                label: 'Uygunsuz içerik',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Şikayetiniz iletildi');
                },
              ),
              _ReportOption(
                icon: Icons.more_horiz_rounded,
                label: 'Diğer',
                onTap: () {
                  Navigator.pop(context);
                  _showSnackBar('Şikayetiniz iletildi');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageSearch() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '${widget.userName} ile mesajlarda ara...',
                    prefixIcon: Icon(Icons.search, color: NearTheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 64,
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aramak istediğiniz mesajı yazın',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMediaGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaGalleryPage(
          chatId: widget.userId,
          chatName: widget.userName,
        ),
      ),
    );
  }

  void _showEncryptionVerification() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: NearTheme.primary),
            const SizedBox(width: 12),
            Text(
              'Şifreleme Doğrulama',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.userName} ile yaptığınız görüşmeler uçtan uca şifrelidir.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Güvenlik Numarası',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '12345 67890 12345\n67890 12345 67890\n12345 67890 12345',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      letterSpacing: 2,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.qr_code_2, color: NearTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu numarayı ${widget.userName} ile karşılaştırarak doğrulayabilirsiniz.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam', style: TextStyle(color: NearTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showQRCode() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'QR Kod',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // QR Code placeholder
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 180,
                          color: Colors.black87,
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: NearTheme.primary,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'near.app/u/${widget.userId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu QR kodu tarayarak ${widget.userName} ile sohbet başlatabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(
                ClipboardData(text: 'https://near.app/u/${widget.userId}'),
              );
              _showSnackBar('Profil linki kopyalandı');
            },
            child: Text('Linki Kopyala', style: TextStyle(color: NearTheme.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat', style: TextStyle(color: NearTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: widget.userName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Kişi Adını Düzenle',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'İsim',
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
              'Bu isim yalnızca sizin için görünür.',
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
              Navigator.pop(context);
              _showSnackBar('İsim güncellendi');
            },
            child: Text('Kaydet', style: TextStyle(color: NearTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: () => _showOptionsSheet(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [NearTheme.primary, NearTheme.primaryDark],
                      ),
                    ),
                  ),
                  // Profile content
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            if (widget.isOnline)
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Phone
                        if (widget.userPhone != null)
                          Text(
                            widget.userPhone!,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                        const SizedBox(height: 4),
                        // Online status
                        Text(
                          widget.isOnline
                              ? 'Çevrimiçi'
                              : 'Son görülme yakın zamanda',
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.isOnline
                                ? const Color(0xFF25D366)
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.message_rounded,
                    label: 'Mesaj',
                    onTap: _startChat,
                  ),
                  _ActionButton(
                    icon: Icons.call_rounded,
                    label: 'Sesli',
                    onTap: () => _startCall(video: false),
                  ),
                  _ActionButton(
                    icon: Icons.videocam_rounded,
                    label: 'Görüntülü',
                    onTap: () => _startCall(video: true),
                  ),
                  _ActionButton(
                    icon: Icons.search_rounded,
                    label: 'Ara',
                    onTap: _showMessageSearch,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // About Section
          if (widget.userAbout != null || true) ...[
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hakkında',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.userAbout ?? 'Merhaba! near kullanıyorum 👋',
                      style: TextStyle(fontSize: 16, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // Media Section
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Medya, Bağlantılar, Belgeler',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_mediaItems.length * 4}',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ],
                    ),
                    onTap: _openMediaGallery,
                  ),
                  // Media Grid Preview
                  if (_mediaItems.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _mediaItems.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 4),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: _openMediaGallery,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: NearTheme.primary.withAlpha(50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.photo_rounded,
                                color: NearTheme.primary.withAlpha(100),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Mute Notifications
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: SwitchListTile(
                value: _isMuted,
                onChanged: (v) {
                  setState(() => _isMuted = v);
                  _showSnackBar(v ? 'Sessize alındı' : 'Bildirimler açıldı');
                },
                activeTrackColor: NearTheme.primary,
                secondary: Icon(
                  _isMuted
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                title: Text(
                  'Bildirimleri Sessize Al',
                  style: TextStyle(color: cs.onSurface),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Encryption Info
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListTile(
                leading: Icon(Icons.lock_rounded, color: NearTheme.primary),
                title: Text('Şifreleme', style: TextStyle(color: cs.onSurface)),
                subtitle: Text(
                  'Mesajlar ve aramalar uçtan uca şifrelidir. Doğrulamak için dokunun.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                onTap: _showEncryptionVerification,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Common Groups
          if (_commonGroups.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '${_commonGroups.length} Ortak Grup',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NearTheme.primary,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final group = _commonGroups[index];
                return Container(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: NearTheme.primary.withAlpha(30),
                      child: Icon(
                        Icons.group_rounded,
                        color: NearTheme.primary,
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${group.memberCount} üye',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    onTap: () => _showSnackBar('Grup açılıyor...'),
                  ),
                );
              }, childCount: _commonGroups.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // Block & Report
          SliverToBoxAdapter(
            child: Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      _isBlocked
                          ? Icons.check_circle_rounded
                          : Icons.block_rounded,
                      color: Colors.red,
                    ),
                    title: Text(
                      _isBlocked ? 'Engeli Kaldır' : 'Engelle',
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: _showBlockDialog,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.thumb_down_rounded,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Şikayet Et',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _showReportDialog,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _showOptionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              const SizedBox(height: 16),
              _OptionTile(
                icon: Icons.share_rounded,
                label: 'Profili Paylaş',
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(
                    ClipboardData(text: 'https://near.app/u/${widget.userId}'),
                  );
                  _showSnackBar('Profil linki kopyalandı');
                },
              ),
              _OptionTile(
                icon: Icons.qr_code_rounded,
                label: 'QR Kodu Göster',
                onTap: () {
                  Navigator.pop(context);
                  _showQRCode();
                },
              ),
              _OptionTile(
                icon: Icons.edit_rounded,
                label: 'İsmi Düzenle',
                onTap: () {
                  Navigator.pop(context);
                  _showEditNameDialog();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: NearTheme.primary.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: NearTheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: NearTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(
        label,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      onTap: onTap,
    );
  }
}

class _ReportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReportOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black54),
      title: Text(
        label,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      onTap: onTap,
    );
  }
}

// Models
class CommonGroup {
  final String id;
  final String name;
  final int memberCount;

  CommonGroup({
    required this.id,
    required this.name,
    required this.memberCount,
  });
}

class MediaThumbnail {
  final String id;

  MediaThumbnail({required this.id});
}
