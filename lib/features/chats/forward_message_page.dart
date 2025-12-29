import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/chat_service.dart';

/// Mesaj İletme Sayfası
/// - Kişi/Grup seçimi
/// - Çoklu seçim
/// - Arama
/// - İlet butonu
class ForwardMessagePage extends StatefulWidget {
  static const route = '/forward-message';

  final String messageText;
  final String? messageId;

  const ForwardMessagePage({
    super.key,
    required this.messageText,
    this.messageId,
  });

  @override
  State<ForwardMessagePage> createState() => _ForwardMessagePageState();
}

class _ForwardMessagePageState extends State<ForwardMessagePage> {
  final _searchController = TextEditingController();
  final Set<String> _selectedChats = {};
  String _searchQuery = '';
  final _chatService = ChatService.instance;

  // Gerçek veriden oluşturulan listeler
  List<ForwardContact> _recentChats = [];
  List<ForwardContact> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _loadChats() {
    final chats = _chatService.chats;
    
    // Grupları ve direkt sohbetleri ayır
    final directChats = <ForwardContact>[];
    final groupChats = <ForwardContact>[];
    
    for (final chat in chats) {
      final isGroup = chat['is_group'] as bool? ?? false;
      final name = _chatService.getChatName(chat);
      final isOnline = !isGroup && _chatService.isOtherUserOnline(chat);
      
      if (isGroup) {
        groupChats.add(ForwardContact(
          id: chat['id'] as String,
          name: name,
          isGroup: true,
          memberCount: 0, // Grup üye sayısı ayrıca yüklenebilir
        ));
      } else {
        directChats.add(ForwardContact(
          id: chat['id'] as String,
          name: name,
          isOnline: isOnline,
        ));
      }
    }
    
    setState(() {
      _recentChats = directChats;
      _groups = groupChats;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedChats.contains(id)) {
        _selectedChats.remove(id);
      } else {
        _selectedChats.add(id);
      }
    });
  }

  Future<void> _forwardMessage() async {
    if (_selectedChats.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: NearTheme.primary),
            const SizedBox(width: 16),
            const Text('İletiliyor...'),
          ],
        ),
      ),
    );

    bool success = false;
    
    if (widget.messageId != null) {
      // Gerçek mesaj iletme (messageId varsa)
      success = await _chatService.forwardMessage(
        messageId: widget.messageId!,
        targetChatIds: _selectedChats.toList(),
      );
    } else {
      // Sadece metin iletme
      for (final chatId in _selectedChats) {
        await _chatService.sendMessage(
          chatId: chatId,
          content: widget.messageText,
        );
      }
      success = true;
    }

    if (!mounted) return;
    Navigator.pop(context); // Dialog
    
    if (success) {
      Navigator.pop(context); // Page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedChats.length} kişiye iletildi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İletme başarısız oldu'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<ForwardContact> _getFilteredContacts(List<ForwardContact> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    return contacts
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredRecent = _getFilteredContacts(_recentChats);
    final filteredGroups = _getFilteredContacts(_groups);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İlet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (_selectedChats.isNotEmpty)
              Text(
                '${_selectedChats.length} seçildi',
                style: TextStyle(fontSize: 12, color: NearTheme.primary),
              ),
          ],
        ),
        actions: [
          if (_selectedChats.isNotEmpty)
            TextButton(
              onPressed: _forwardMessage,
              child: Text(
                'İlet',
                style: TextStyle(
                  color: NearTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Selected Chips
          if (_selectedChats.isNotEmpty)
            Container(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedChats.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final id = _selectedChats.elementAt(index);
                  final allChats = [..._recentChats, ..._groups];
                  final contact = allChats.firstWhere(
                    (c) => c.id == id,
                    orElse: () => ForwardContact(id: id, name: 'Unknown'),
                  );

                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: NearTheme.primary,
                      child: contact.isGroup
                          ? const Icon(
                              Icons.group,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              contact.name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                    ),
                    label: Text(
                      contact.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _toggleSelection(id),
                    backgroundColor: isDark
                        ? const Color(0xFF2C2C2E)
                        : Colors.grey.shade200,
                  );
                },
              ),
            ),

          // Message Preview
          Container(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: NearTheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İletilen Mesaj',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: NearTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.messageText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contact List
          Expanded(
            child: ListView(
              children: [
                // Recent Chats
                if (filteredRecent.isNotEmpty) ...[
                  _SectionHeader(title: 'Son Sohbetler'),
                  ...filteredRecent.map(
                    (c) => _ContactTile(
                      contact: c,
                      isSelected: _selectedChats.contains(c.id),
                      onTap: () => _toggleSelection(c.id),
                    ),
                  ),
                ],

                // Groups
                if (filteredGroups.isNotEmpty) ...[
                  _SectionHeader(title: 'Gruplar'),
                  ...filteredGroups.map(
                    (c) => _ContactTile(
                      contact: c,
                      isSelected: _selectedChats.contains(c.id),
                      onTap: () => _toggleSelection(c.id),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),

      // Forward FAB
      floatingActionButton: _selectedChats.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'forward_fab',
              onPressed: _forwardMessage,
              backgroundColor: NearTheme.primary,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              label: Text(
                'İlet (${_selectedChats.length})',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: isDark ? Colors.black : Colors.grey.shade100,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: NearTheme.primary,
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final ForwardContact contact;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactTile({
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: NearTheme.primary.withAlpha(30),
              child: contact.isGroup
                  ? Icon(Icons.group_rounded, color: NearTheme.primary)
                  : Text(
                      contact.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: NearTheme.primary,
                      ),
                    ),
            ),
            if (contact.isOnline && !contact.isGroup)
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
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: contact.isGroup
            ? Text(
                '${contact.memberCount} üye',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              )
            : (contact.isOnline
                  ? Text(
                      'Çevrimiçi',
                      style: TextStyle(color: const Color(0xFF25D366)),
                    )
                  : Text(
                      contact.lastSeen ?? '',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    )),
        trailing: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isSelected ? NearTheme.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? NearTheme.primary
                  : (isDark ? Colors.white38 : Colors.black26),
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

// Model
class ForwardContact {
  final String id;
  final String name;
  final bool isGroup;
  final bool isOnline;
  final String? lastSeen;
  final int? memberCount;

  ForwardContact({
    required this.id,
    required this.name,
    this.isGroup = false,
    this.isOnline = false,
    this.lastSeen,
    this.memberCount,
  });
}
