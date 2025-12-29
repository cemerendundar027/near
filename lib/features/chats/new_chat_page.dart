import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/chat_service.dart';
import '../../shared/models.dart';
import 'create_group_page.dart';

/// Yeni sohbet başlatma sayfası
/// - Kullanıcı arama
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
  
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _query) {
      setState(() => _query = query);
      _searchUsers(query);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    final users = await _chatService.getAllUsers();
    
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
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

  Future<void> _startChat(Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: CircularProgressIndicator(color: NearTheme.primary),
      ),
    );

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
        Navigator.pushNamed(
          context,
          '/chat/$chatId',
          arguments: chatPreview,
        );
      }
    } else {
      _showError('Sohbet oluşturulamadı');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _openCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayUsers = _query.isEmpty ? _users : _searchResults;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: NearTheme.primary,
            size: 20,
          ),
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
                  color: NearTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.group_add,
                  color: NearTheme.primary,
                ),
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

          // Kullanıcı listesi başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _query.isEmpty ? 'Tüm Kullanıcılar' : 'Arama Sonuçları',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Kullanıcı listesi
          Expanded(
            child: _isLoading || _isSearching
                ? Center(
                    child: CircularProgressIndicator(color: NearTheme.primary),
                  )
                : displayUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _query.isEmpty ? Icons.people_outline : Icons.search_off,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _query.isEmpty
                                  ? 'Henüz başka kullanıcı yok'
                                  : '"$_query" için sonuç bulunamadı',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayUsers.length,
                        itemBuilder: (context, index) {
                          final user = displayUsers[index];
                          return _UserTile(
                            user: user,
                            onTap: () => _startChat(user),
                          );
                        },
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

  const _UserTile({
    required this.user,
    required this.onTap,
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
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
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
        title: Text(
          fullName,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
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
