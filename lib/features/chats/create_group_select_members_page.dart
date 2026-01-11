import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/chat_service.dart';
import 'create_group_details_page.dart';

class CreateGroupSelectMembersPage extends StatefulWidget {
  const CreateGroupSelectMembersPage({super.key});

  @override
  State<CreateGroupSelectMembersPage> createState() => _CreateGroupSelectMembersPageState();
}

class _CreateGroupSelectMembersPageState extends State<CreateGroupSelectMembersPage> {
  final _chatService = ChatService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final Set<String> _selectedUserIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((u) {
          final username = (u['username'] as String? ?? '').toLowerCase();
          final fullname = (u['full_name'] as String? ?? '').toLowerCase();
          return username.contains(query) || fullname.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    // In a real app, this should probably be "contacts" not "all users"
    // But for now following existing pattern
    final users = await _chatService.getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _onNext() {
    if (_selectedUserIds.isEmpty) return;
    
    // Get full user objects for selected IDs
    final selectedUsers = _allUsers
        .where((u) => _selectedUserIds.contains(u['id']))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGroupDetailsPage(
          selectedMembers: selectedUsers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yeni Grup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              'Katılımcı ekle',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ara',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          
          // Selected Users Horizontal List
          if (_selectedUserIds.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedUserIds.length,
                itemBuilder: (context, index) {
                  final userId = _selectedUserIds.elementAt(index);
                  final user = _allUsers.firstWhere((u) => u['id'] == userId, orElse: () => {});
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: NearTheme.primary,
                              backgroundImage: user['avatar_url'] != null
                                  ? NetworkImage(user['avatar_url'])
                                  : null,
                              child: user['avatar_url'] == null
                                  ? Text(
                                      (user['username'] as String? ?? '?')[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () => _toggleSelection(userId),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (user['username'] as String? ?? '').split(' ').first,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          if (_selectedUserIds.isNotEmpty) const Divider(),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _selectedUserIds.contains(user['id']);
                      
                      return ListTile(
                        leading: Stack(
                          children: [
                             CircleAvatar(
                              radius: 24,
                              backgroundColor: NearTheme.primary.withValues(alpha: 0.2),
                              backgroundImage: user['avatar_url'] != null
                                  ? NetworkImage(user['avatar_url'])
                                  : null,
                              child: user['avatar_url'] == null
                                  ? Text(
                                      (user['username'] as String? ?? '?')[0].toUpperCase(),
                                      style: TextStyle(
                                        color: NearTheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            if (isSelected)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: NearTheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          user['username'] ?? 'Bilinmeyen',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          user['full_name'] ?? '',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                        ),
                        onTap: () => _toggleSelection(user['id']),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedUserIds.isNotEmpty
          ? FloatingActionButton(
              onPressed: _onNext,
              backgroundColor: NearTheme.primary,
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            )
          : null,
    );
  }
}
