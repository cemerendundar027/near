import 'package:flutter/material.dart';
import '../../shared/contact_service.dart';
import '../../shared/settings_widgets.dart';

class BlockedUsersPage extends StatefulWidget {
  static const route = '/settings/privacy/blocked';
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  final _contactService = ContactService.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    await _contactService.loadBlockedUsers();
    if (mounted) {
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

  Future<void> _unblockUser(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Engeli Kaldır'),
        content: Text('$name kişisinin engelini kaldırmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Engeli Kaldır'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _contactService.unblockUser(userId);
      if (success) {
        _toast('$name engeli kaldırıldı');
      } else {
        _toast('Bir hata oluştu');
      }
    }
  }

  void _showBlockUserDialog() {
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
          height: MediaQuery.of(context).size.height * 0.8,
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
                child: Text(
                  'Kullanıcı Engelle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
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
                            child: Text(
                              searchController.text.isEmpty
                                  ? 'Engellemek istediğiniz kullanıcıyı arayın'
                                  : 'Kullanıcı bulunamadı',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final user = searchResults[index];
                              final name = user['full_name'] ?? user['username'] ?? 'Bilinmeyen';
                              final username = user['username'] ?? '';
                              final isAlreadyBlocked = _contactService.isBlocked(user['id']);

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF7B3FF2),
                                  backgroundImage: user['avatar_url'] != null
                                      ? NetworkImage(user['avatar_url'])
                                      : null,
                                  child: user['avatar_url'] == null
                                      ? Text(
                                          name[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        )
                                      : null,
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
                                trailing: isAlreadyBlocked
                                    ? const Chip(
                                        label: Text('Engelli'),
                                        backgroundColor: SettingsColors.red,
                                        labelStyle: TextStyle(color: Colors.white),
                                      )
                                    : TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final success = await _contactService.blockUser(user['id']);
                                          if (success) {
                                            _toast('$name engellendi');
                                          } else {
                                            _toast('Bir hata oluştu');
                                          }
                                        },
                                        child: const Text(
                                          'Engelle',
                                          style: TextStyle(color: SettingsColors.red),
                                        ),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _contactService,
      builder: (_, _) {
        final blockedUsers = _contactService.blockedUsers;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            title: Text(
              'Engellenen Kişiler',
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
            actions: [
              IconButton(
                icon: Icon(Icons.person_add, color: cs.onSurface),
                onPressed: _showBlockUserDialog,
                tooltip: 'Kullanıcı Engelle',
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.block_rounded,
                          size: 40,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                            'Engellenen Kişi Yok',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Engellediğin kullanıcılar burada görünür',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _showBlockUserDialog,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Kullanıcı Engelle'),
                          ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Engellenen kişiler sana mesaj gönderemez veya profilini göremez.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                            itemCount: blockedUsers.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          indent: 70,
                          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
                        ),
                        itemBuilder: (_, i) {
                              final blocked = blockedUsers[i];
                              final contact = blocked['contact'] as Map<String, dynamic>?;
                              final name = contact?['full_name'] ?? contact?['username'] ?? 'Bilinmeyen';
                              final username = contact?['username'] ?? '';
                              final userId = blocked['contact_id'] as String;
                              final avatarUrl = contact?['avatar_url'];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                                  backgroundImage: avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null
                                      ? Icon(
                                Icons.person,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                                        )
                                      : null,
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            subtitle: Text(
                                  '@$username',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            trailing: TextButton(
                                  onPressed: () => _unblockUser(userId, name),
                              child: const Text(
                                    'Engeli Kaldır',
                                style: TextStyle(
                                  color: SettingsColors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
        );
      },
    );
  }
}
