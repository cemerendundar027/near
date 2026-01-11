import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../app/theme.dart';
import '../../shared/chat_service.dart';
import '../../shared/models.dart';
import 'create_group_select_members_page.dart';

/// Yeni sohbet başlatma sayfası
/// - Kullanıcı arama (username ile)
/// - Rehberdeki Near kullanıcılarını göster
/// - Birebir sohbet başlatma
/// - Grup oluşturma
class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  static const route = '/new-chat';

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final _searchController = TextEditingController();
  final _chatService = ChatService.instance;

  List<Map<String, dynamic>> _contactUsers =
      []; // Rehberdeki Near kullanıcıları
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasContactPermission = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    // Rehberdeki kullanıcıları yükle
    await _loadContactUsers();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadContactUsers() async {
    try {
      // Rehber izni kontrolü
      final hasPermission = await FlutterContacts.requestPermission();
      if (!hasPermission) {
        if (mounted) {
          setState(() => _hasContactPermission = false);
        }
        return;
      }

      setState(() => _hasContactPermission = true);

      // Rehberdeki kişileri al
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      // Telefon numaralarını topla
      final phoneNumbers = <String>[];
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          // Telefon numarasını normalleştir
          final normalized = _normalizePhone(phone.number);
          if (normalized.isNotEmpty) {
            phoneNumbers.add(normalized);
          }
        }
      }

      if (phoneNumbers.isEmpty) return;

      // Bu numaralara sahip Near kullanıcılarını bul
      final nearUsers = await _chatService.findUsersByPhones(phoneNumbers);

      if (mounted) {
        setState(() => _contactUsers = nearUsers);
      }
    } catch (e) {
      debugPrint('NewChatPage: Error loading contact users: $e');
    }
  }

  String _normalizePhone(String phone) {
    // Sadece rakamları al
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return '';

    // Türkiye numarası normalleştirme
    if (digits.startsWith('0') && digits.length == 11) {
      return '+90${digits.substring(1)}';
    }
    if (digits.startsWith('90') && digits.length == 12) {
      return '+$digits';
    }
    if (!digits.startsWith('+')) {
      return '+$digits';
    }
    return digits;
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _query) {
      setState(() => _query = query);
      _searchUsers(query);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await _chatService.searchUsers(query);

    if (mounted && _query == query) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _startChat(Map<String, dynamic> user, {bool isFromContacts = false}) async {
    final userId = user['id'] as String;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          Center(child: CircularProgressIndicator(color: NearTheme.primary)),
    );

    // Rehberden değilse (aramadan geliyorsa) gizlilik kontrolü yap
    if (!isFromContacts) {
      final permission = await _chatService.canSendMessageTo(userId);
      if (permission['allowed'] != true) {
        if (!mounted) return;
        Navigator.pop(context); // Loading'i kapat
        _showPrivacyError(permission['message'] ?? 'Bu kullanıcıya mesaj gönderemezsiniz');
        return;
      }
    }

    // Chat oluştur veya mevcut olanı bul
    final chatId = await _chatService.createDirectChat(userId);

    if (!mounted) return;
    Navigator.pop(context); // Loading'i kapat

    if (chatId != null) {
      // Chat detay sayfasına git
      final userName = user['full_name'] ?? user['username'] ?? 'Kullanıcı';

      // ChatPreview oluştur ve chat sayfasına git
      final chatPreview = ChatPreview(
        id: chatId,
        userId: userId,
        name: userName,
        lastMessage: '',
        time: '',
        online: user['is_online'] ?? false,
      );

      if (mounted) {
        Navigator.pop(context); // NewChatPage'i kapat
        Navigator.pushNamed(context, '/chat/$chatId', arguments: chatPreview);
      }
    } else {
      _showError('Sohbet oluşturulamadı');
    }
  }

  void _showPrivacyError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mesaj Gönderilemedi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tamam', style: TextStyle(color: NearTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _openCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupSelectMembersPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: NearTheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yeni Sohbet',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Arama kutusu
          Container(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Kullanıcı ara...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Grup oluştur butonu
          Container(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: NearTheme.primary.withAlpha(38),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(Icons.group_add, color: NearTheme.primary),
              ),
              title: Text(
                'Yeni Grup Oluştur',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Arkadaşlarınla grup sohbeti başlat',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              onTap: _openCreateGroup,
            ),
          ),

          const SizedBox(height: 8),

          // İçerik
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: NearTheme.primary),
                  )
                : _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    // Arama yapılıyorsa
    if (_query.isNotEmpty) {
      return _buildSearchResults(isDark);
    }

    // Normal görünüm - sadece rehberdeki kullanıcılar
    return ListView(
      children: [
        // Rehberimdeki Near kullanıcıları
        if (_contactUsers.isNotEmpty) ...[
          _buildSectionHeader('Rehberimdekiler', isDark),
          ..._contactUsers.map(
            (user) => _UserTile(
              user: user,
              onTap: () => _startChat(user, isFromContacts: true),
              isFromContacts: true,
            ),
          ),
        ],

        // Rehber izni yoksa veya rehberde Near kullanıcısı yoksa bilgi göster
        if (!_hasContactPermission)
          _buildContactPermissionBanner(isDark)
        else if (_contactUsers.isEmpty)
          _buildNoContactUsersState(isDark),
      ],
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator(color: NearTheme.primary));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              '"$_query" için sonuç bulunamadı',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        _buildSectionHeader('Arama Sonuçları', isDark),
        ..._searchResults.map(
          (user) => _UserTile(user: user, onTap: () => _startChat(user)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNoContactUsersState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'Rehberinde Near kullanan kişi yok',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kullanıcı adı ile arama yaparak\nyeni kişiler bulabilirsin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPermissionBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NearTheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NearTheme.primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.contacts_outlined, color: NearTheme.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rehber Erişimi',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rehberindeki Near kullanıcılarını görmek için izin ver',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _loadContactUsers,
            child: Text(
              'İzin Ver',
              style: TextStyle(
                color: NearTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kullanıcı listesi item'ı
class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  final bool isFromContacts;

  const _UserTile({
    required this.user,
    required this.onTap,
    this.isFromContacts = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final username = user['username'] ?? '';
    final fullName = user['full_name'] ?? username;
    final avatarUrl = user['avatar_url'];
    final isOnline = user['is_online'] ?? false;

    return Container(
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                fullName,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isFromContacts)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: NearTheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Rehber',
                  style: TextStyle(
                    color: NearTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '@$username',
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: NearTheme.primary,
          size: 22,
        ),
        onTap: onTap,
      ),
    );
  }
}
