import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/contact_service.dart';

/// Yayın listesi oluşturma sayfası
class BroadcastListPage extends StatefulWidget {
  static const route = '/create-broadcast';
  const BroadcastListPage({super.key});

  @override
  State<BroadcastListPage> createState() => _BroadcastListPageState();
}

class _BroadcastListPageState extends State<BroadcastListPage> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  // Loading durumu kaldırıldı, kontaktlar hemen yükleniyor

  // Supabase'den yüklenen kişiler
  List<_Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contactService = ContactService.instance;
      await contactService.loadContacts();
      
      if (mounted) {
        setState(() {
          _contacts = contactService.contacts.map((c) {
            final contact = c['contact'] as Map<String, dynamic>?;
            return _Contact(
              id: contact?['id'] ?? c['contact_id'] ?? '',
              name: contact?['full_name'] ?? contact?['username'] ?? 'Kullanıcı',
              phone: '', // Telefon numarası gizlilik nedeniyle gösterilmiyor
            );
          }).toList();
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  List<_Contact> get _filteredContacts {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _contacts;
    return _contacts
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();
  }

  List<_Contact> get _selectedContacts {
    return _contacts.where((c) => _selectedUserIds.contains(c.id)).toList();
  }

  void _toggleContact(String id) {
    setState(() {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
      } else {
        _selectedUserIds.add(id);
      }
    });
  }

  void _createBroadcast() {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir kişi seçmelisiniz'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final displayName = name.isEmpty ? 'Yayın Listesi' : name;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"$displayName" oluşturuldu (${_selectedUserIds.length} alıcı)',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.close, size: 24, color: NearTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yeni Yayın Listesi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _createBroadcast,
            child: Text(
              'Oluştur',
              style: TextStyle(
                color: _selectedUserIds.isEmpty
                    ? (isDark ? Colors.white38 : Colors.black38)
                    : NearTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            color: NearTheme.primary.withAlpha(15),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: NearTheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yayın listesine gönderilen mesajlar, her alıcıya ayrı bir mesaj olarak iletilir.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste adı
          Container(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _nameController,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: 'Liste adı (isteğe bağlı)',
                labelStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: NearTheme.primary),
                ),
              ),
            ),
          ),

          // Seçili kişiler
          if (_selectedUserIds.isNotEmpty)
            Container(
              height: 100,
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: _selectedContacts.length,
                itemBuilder: (context, index) {
                  final contact = _selectedContacts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => _toggleContact(contact.id),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: NearTheme.primary.withAlpha(
                                  30,
                                ),
                                child: Text(
                                  contact.name[0],
                                  style: TextStyle(
                                    color: NearTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF1C1C1E)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: Text(
                              contact.name,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Arama
          Container(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Kişi ara',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.search,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                style: TextStyle(color: cs.onSurface),
              ),
            ),
          ),

          // Seçim sayısı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'ALıCıLAR: ${_selectedUserIds.length}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),

          // Kişi listesi
          Expanded(
            child: ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                final selected = _selectedUserIds.contains(contact.id);

                return Container(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  child: ListTile(
                    onTap: () => _toggleContact(contact.id),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: isDark
                          ? Colors.white12
                          : Colors.grey.shade300,
                      child: Text(
                        contact.name[0],
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      contact.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      contact.phone,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: selected
                            ? NearTheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? NearTheme.primary
                              : (isDark ? Colors.white38 : Colors.black38),
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Contact {
  final String id;
  final String name;
  final String phone;

  const _Contact({required this.id, required this.name, required this.phone});
}
