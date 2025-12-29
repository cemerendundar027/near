import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../shared/contact_service.dart';
import '../../shared/chat_service.dart';
import '../../shared/widgets/qr_code.dart';
import '../../app/theme.dart';

/// Global search page for chats, messages, contacts
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  static const route = '/search';

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _chatService = ChatService.instance;
  late TabController _tabController;
  String _query = '';
  
  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _messageResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() => _query = query);
    
    if (query.length >= 2) {
      _performSearch(query);
    } else {
      setState(() {
        _userResults = [];
        _messageResults = [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    
    final results = await Future.wait([
      _chatService.searchUsers(query),
      _chatService.searchAllMessages(query),
    ]);
    
    if (mounted) {
      setState(() {
        _userResults = results[0];
        _messageResults = results[1];
        _isSearching = false;
    });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Sohbet, mesaj veya kişi ara',
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.close,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: NearTheme.primary,
          labelColor: NearTheme.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Kişiler'),
            Tab(text: 'Mesajlar'),
            Tab(text: 'Medya'),
          ],
        ),
      ),
      body: _query.isEmpty
          ? _buildRecentSearches()
          : _isSearching
              ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                    _AllResultsTab(
                      userResults: _userResults, 
                      messageResults: _messageResults,
                      query: _query,
                    ),
                    _UsersResultsTab(users: _userResults),
                    _MessagesResultsTab(messages: _messageResults, query: _query),
                _MediaResultsTab(query: _query),
              ],
            ),
    );
  }

  Widget _buildRecentSearches() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Son Aramalar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.history,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          title: Text(
            'Toplantı',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            onPressed: () {},
          ),
          onTap: () {
            _searchController.text = 'Toplantı';
          },
        ),
      ],
    );
  }
}

class _AllResultsTab extends StatelessWidget {
  final List<Map<String, dynamic>> userResults;
  final List<Map<String, dynamic>> messageResults;
  final String query;

  const _AllResultsTab({
    required this.userResults,
    required this.messageResults,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userResults.isEmpty && messageResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
      children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
          children: [
        if (userResults.isNotEmpty) ...[
          _SearchSection(
            title: 'Kullanıcılar',
            count: userResults.length,
            children: userResults.take(3).map((user) => _UserResultTile(user: user)).toList(),
            ),
          ],
        if (messageResults.isNotEmpty) ...[
        _SearchSection(
            title: 'Mesajlar',
            count: messageResults.length,
            children: messageResults.take(5).map((msg) => _MessageResultTile(
              message: msg,
              query: query,
            )).toList(),
            ),
          ],
      ],
    );
  }
}

class _UsersResultsTab extends StatelessWidget {
  final List<Map<String, dynamic>> users;

  const _UsersResultsTab({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _EmptyState(
        icon: Icons.person_search,
        message: 'Kullanıcı bulunamadı',
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) => _UserResultTile(user: users[index]),
    );
  }
}

class _MessagesResultsTab extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final String query;

  const _MessagesResultsTab({required this.messages, required this.query});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _EmptyState(
        icon: Icons.message_outlined,
        message: 'Mesaj bulunamadı',
      );
    }

    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) => _MessageResultTile(
        message: messages[index],
          query: query,
        ),
    );
  }
}

class _MediaResultsTab extends StatelessWidget {
  final String query;

  const _MediaResultsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.photo_library_outlined,
      message: 'Medya bulunamadı',
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  final String title;
  final int count;
  final List<Widget> children;

  const _SearchSection({
    required this.title,
    required this.count,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final Map<String, dynamic> user;

  const _UserResultTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = user['full_name'] ?? user['username'] ?? 'Bilinmeyen';
    final username = user['username'] ?? '';
    final avatarUrl = user['avatar_url'];
    final isOnline = user['is_online'] ?? false;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: NearTheme.primary,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        '@$username',
        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
      ),
      onTap: () {
        // Open chat with this user
        context.push('/chat/${user['id']}');
      },
    );
  }
}

class _MessageResultTile extends StatelessWidget {
  final Map<String, dynamic> message;
  final String query;

  const _MessageResultTile({required this.message, required this.query});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sender = message['sender'] as Map<String, dynamic>?;
    final senderName = sender?['full_name'] ?? sender?['username'] ?? 'Bilinmeyen';
    final content = message['content'] ?? '';
    final createdAt = message['created_at'];
    
    String time = '';
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        final now = DateTime.now();
        if (date.day == now.day && date.month == now.month && date.year == now.year) {
          time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        } else {
          time = '${date.day}.${date.month}';
        }
      }
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: NearTheme.primary,
        child: Text(
          senderName[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        senderName,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: _HighlightedText(
        text: content,
        query: query,
        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        highlightStyle: TextStyle(
          color: NearTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
      onTap: () {
        final chatId = message['chat_id'];
        if (chatId != null) {
          context.push('/chat/$chatId');
        }
      },
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (index > 0) TextSpan(text: text.substring(0, index), style: style),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: highlightStyle,
          ),
          if (index + query.length < text.length)
            TextSpan(text: text.substring(index + query.length), style: style),
        ],
      ),
    );
  }
}

/// Contacts page - Kişi listesi ve kişi ekleme (2.4)
class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  static const route = '/contacts';

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _contactService = ContactService.instance;
  final _chatService = ChatService.instance;
  final _searchController = TextEditingController();
  String _query = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  Future<void> _loadContacts() async {
    await _contactService.loadContacts();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredContacts {
    if (_query.isEmpty) return _contactService.contacts;
    return _contactService.contacts.where((c) {
      final contact = c['contact'] as Map<String, dynamic>?;
      if (contact == null) return false;
      final name = (contact['full_name'] ?? '').toString().toLowerCase();
      final username = (contact['username'] ?? '').toString().toLowerCase();
      final q = _query.toLowerCase();
      return name.contains(q) || username.contains(q);
    }).toList();
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

  void _showAddContactSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
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
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'İptal',
                        style: TextStyle(color: NearTheme.primary, fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Kişi Ekle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 60),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı adı veya isim ara...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (query) async {
                    if (query.length >= 2) {
                      setModalState(() => isSearching = true);
                      final results = await _contactService.searchUsers(query);
                      setModalState(() {
                        searchResults = results;
                        isSearching = false;
                      });
                    } else {
                      setModalState(() => searchResults = []);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search,
                                  size: 64,
                                  color: isDark ? Colors.white24 : Colors.black26,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isEmpty
                                      ? 'Eklemek istediğiniz kişiyi arayın'
                                      : 'Kullanıcı bulunamadı',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final user = searchResults[index];
                              final name = user['full_name'] ?? user['username'] ?? 'Bilinmeyen';
                              final username = user['username'] ?? '';
                              final avatarUrl = user['avatar_url'];
                              final isOnline = user['is_online'] ?? false;
                              final isAlreadyContact = _contactService.isContact(user['id']);

                              return ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: NearTheme.primary,
                                      backgroundImage: avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl == null
                                          ? Text(
                                              name[0].toUpperCase(),
                                              style: const TextStyle(color: Colors.white),
                                            )
                                          : null,
                                    ),
                                    if (isOnline)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF25D366),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  '@$username',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                                trailing: isAlreadyContact
                                    ? Chip(
                                        label: const Text('Kişilerimde'),
                                        backgroundColor: NearTheme.primary.withAlpha(30),
                                        labelStyle: TextStyle(
                                          color: NearTheme.primary,
                                          fontSize: 12,
                                        ),
                                      )
                                    : FilledButton(
                                        onPressed: () async {
                                          HapticFeedback.selectionClick();
                                          final success = await _contactService.addContact(user['id']);
                                          if (success) {
                                            Navigator.pop(context);
                                            _toast('$name kişilere eklendi');
                                          } else {
                                            _toast('Kişi eklenemedi');
                                          }
                                        },
                                        child: const Text('Ekle'),
                                      ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startChat(Map<String, dynamic> contact) async {
    final contactData = contact['contact'] as Map<String, dynamic>?;
    if (contactData == null) return;

    final userId = contactData['id'] as String?;
    if (userId == null) return;

    // Mevcut sohbet var mı kontrol et veya yeni oluştur
    final chatId = await _chatService.createDirectChat(userId);
    if (chatId != null && mounted) {
      context.push('/chat/$chatId');
    }
  }

  void _showContactOptions(Map<String, dynamic> contact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactData = contact['contact'] as Map<String, dynamic>?;
    final name = contactData?['full_name'] ?? contactData?['username'] ?? 'Bilinmeyen';
    final userId = contact['contact_id'] as String;

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
              CircleAvatar(
                radius: 30,
                backgroundColor: NearTheme.primary,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.chat, color: NearTheme.primary),
                title: Text(
                  'Mesaj Gönder',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startChat(contact);
                },
              ),
              ListTile(
                leading: Icon(Icons.call, color: isDark ? Colors.white70 : Colors.black54),
                title: Text(
                  'Sesli Arama',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/call/$userId?video=false');
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam, color: isDark ? Colors.white70 : Colors.black54),
                title: Text(
                  'Görüntülü Arama',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/call/$userId?video=true');
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text(
                  'Engelle',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await _contactService.blockUser(userId);
                  if (success) {
                    _toast('$name engellendi');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Kişilerden Çıkar',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Kişiyi Sil'),
                      content: Text('$name kişilerinden çıkarılsın mı?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('İptal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Sil'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final success = await _contactService.removeContact(userId);
                    if (success) {
                      _toast('$name kişilerden çıkarıldı');
                    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kişiler',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.qr_code,
              color: NearTheme.primary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyQRCodePage()),
              );
            },
            tooltip: 'QR Kodum',
          ),
          IconButton(
            icon: Icon(
              Icons.person_add,
              color: NearTheme.primary,
            ),
            onPressed: _showAddContactSheet,
            tooltip: 'Kişi Ekle',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _contactService,
        builder: (context, _) {
          final contacts = _filteredContacts;

          return Column(
        children: [
          // Search bar
          Container(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Kişi ara',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

              // Add contact options
          Container(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                child: Column(
                  children: [
                    ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                          color: NearTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                        child: Icon(Icons.qr_code, color: NearTheme.primary),
              ),
              title: Text(
                        'QR Kodum',
                style: TextStyle(
                          color: NearTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
                      subtitle: Text(
                        'QR kodunla kişi ekle veya eklendir',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      trailing: Icon(
                        Icons.qr_code_scanner,
                        color: NearTheme.primary,
                        size: 20,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyQRCodePage()),
                        );
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: NearTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_add, color: NearTheme.primary),
                      ),
                      title: Text(
                        'Yeni Kişi Ekle',
                        style: TextStyle(
                          color: NearTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Kullanıcı adı veya isim ile ara',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      onTap: _showAddContactSheet,
                    ),
                  ],
            ),
          ),

          const SizedBox(height: 8),

          // Contacts header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                      'Kişilerim',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const Spacer(),
                Text(
                      '${contacts.length} kişi',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),

          // Contacts list
          Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : contacts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: isDark ? Colors.white24 : Colors.black26,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _query.isEmpty
                                      ? 'Henüz kişi eklemediniz'
                                      : 'Kişi bulunamadı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                                if (_query.isEmpty) ...[
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    onPressed: _showAddContactSheet,
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Kişi Ekle'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadContacts,
            child: ListView.builder(
                              itemCount: contacts.length,
              itemBuilder: (context, index) {
                                final contact = contacts[index];
                                return _ContactTile(
                                  contact: contact,
                                  onTap: () => _startChat(contact),
                                  onLongPress: () => _showContactOptions(contact),
                                );
              },
                            ),
            ),
          ),
        ],
          );
        },
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ContactTile({
    required this.contact,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contactData = contact['contact'] as Map<String, dynamic>?;
    final name = contactData?['full_name'] ?? contactData?['username'] ?? 'Bilinmeyen';
    final username = contactData?['username'] ?? '';
    final avatarUrl = contactData?['avatar_url'];
    final isOnline = contactData?['is_online'] ?? false;
    final nickname = contact['nickname'];

    return Container(
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: NearTheme.primary,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
                    )
                  : null,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
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
          nickname ?? name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          '@$username',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: NearTheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
