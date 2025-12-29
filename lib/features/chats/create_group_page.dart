import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../shared/chat_service.dart';

/// Create new group page - Supabase entegreli
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  static const route = '/create-group';

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _chatService = ChatService.instance;
  
  final Set<String> _selectedUserIds = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      setState(() => _searchResults = []);
      return;
    }
    final results = await _chatService.searchUsers(query);
    if (mounted && _query == query) {
      setState(() => _searchResults = results);
    }
  }

  List<Map<String, dynamic>> get _displayUsers {
    return _query.isEmpty ? _users : _searchResults;
  }

  List<Map<String, dynamic>> get _selectedUsers {
    return _users.where((u) => _selectedUserIds.contains(u['id'])).toList();
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
          'Yeni Grup',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _selectedUserIds.isNotEmpty
                ? () {
                    // Navigate to group name/icon setup
                    _showGroupInfoSheet();
                  }
                : null,
            child: Text(
              'İleri',
              style: TextStyle(
                color: _selectedUserIds.isNotEmpty
                    ? const Color(0xFF7B3FF2)
                    : (isDark ? Colors.white38 : Colors.black38),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: NearTheme.primary))
          : Column(
        children: [
          // Selected users chips
          if (_selectedUserIds.isNotEmpty)
            Container(
              height: 90,
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  return _SelectedUserChip(
                    user: user,
                    onRemove: () {
                      setState(() => _selectedUserIds.remove(user['id']));
                    },
                  );
                },
              ),
            ),

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
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          // Users list
          Expanded(
            child: _displayUsers.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty 
                          ? 'Henüz başka kullanıcı yok'
                          : 'Sonuç bulunamadı',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _displayUsers.length,
                    itemBuilder: (context, index) {
                      final user = _displayUsers[index];
                      final isSelected = _selectedUserIds.contains(user['id']);

                      return _UserSelectTile(
                        user: user,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedUserIds.remove(user['id']);
                            } else {
                              _selectedUserIds.add(user['id']);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showGroupInfoSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedUsers = _users.where((u) => _selectedUserIds.contains(u['id'])).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Grup Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isCreating ? null : () async {
                        if (_nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Grup adı girin')),
                          );
                          return;
                        }
                        
                        setSheetState(() => _isCreating = true);
                        
                        try {
                          final chatId = await _chatService.createGroupChat(
                            name: _nameController.text.trim(),
                            memberIds: _selectedUserIds.toList(),
                          );
                          
                          if (chatId != null && mounted) {
                            Navigator.pop(context); // Close sheet
                            Navigator.pop(context); // Close create page
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: {'chatId': chatId},
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: $e')),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setSheetState(() => _isCreating = false);
                          }
                        }
                      },
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Oluştur',
                              style: TextStyle(
                                color: Color(0xFF7B3FF2),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              // Group icon
              GestureDetector(
                onTap: () {
                  // TODO: Pick group icon
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B3FF2).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 40,
                    color: Color(0xFF7B3FF2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Grup simgesi ekle',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // Group name input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Grup adı',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF7B3FF2)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Participants preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katılımcılar: ${selectedUsers.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedUsers.map((user) {
                        final username = user['username'] ?? 'Kullanıcı';
                        return Chip(
                          label: Text(username.split(' ').first),
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                          labelStyle: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// User tile for group member selection
class _UserSelectTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isSelected;
  final VoidCallback? onTap;

  const _UserSelectTile({
    required this.user,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = user['username'] ?? 'Kullanıcı';
    final fullName = user['full_name'] ?? '';
    final avatarUrl = user['avatar_url'];

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF7B3FF2),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          if (isSelected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B3FF2),
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
        username,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: fullName.isNotEmpty
          ? Text(
              fullName,
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            )
          : null,
    );
  }
}

/// Selected user chip for horizontal list
class _SelectedUserChip extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onRemove;

  const _SelectedUserChip({required this.user, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final username = user['username'] ?? 'Kullanıcı';
    final avatarUrl = user['avatar_url'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF7B3FF2),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              username.split(' ').first,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Group info/settings page - Supabase entegreli
class GroupInfoPage extends StatefulWidget {
  final String groupId;

  const GroupInfoPage({
    super.key,
    required this.groupId,
  });

  static const route = '/group-info';

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final _chatService = ChatService.instance;
  
  Map<String, dynamic>? _groupInfo;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _chatService.currentUserId;
    _loadGroupInfo();
  }

  Future<void> _loadGroupInfo() async {
    setState(() => _isLoading = true);
    
    final groupInfo = await _chatService.getGroupInfo(widget.groupId);
    final members = await _chatService.getGroupMembers(widget.groupId);
    final isAdmin = await _chatService.isUserAdmin(widget.groupId);

    if (mounted) {
      setState(() {
        _groupInfo = groupInfo;
        _members = members;
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    }
  }

  String get _groupName => _groupInfo?['name'] ?? 'Grup';
  String? get _avatarUrl => _groupInfo?['avatar_url'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          // Header with group image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isAdmin)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: isDark ? Colors.white : Colors.black,
                ),
                  onPressed: _showEditGroupSheet,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF7B3FF2), Color(0xFF5A22C8)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      _avatarUrl != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(_avatarUrl!),
                            )
                          : Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.group,
                          size: 50,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_members.length} katılımcı',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Actions
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.notifications_off_outlined,
                    label: 'Sustur',
                    onTap: () async {
                      await _chatService.toggleMuteChat(widget.groupId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bildirim ayarı güncellendi')),
                        );
                      }
                    },
                  ),
                  _ActionButton(
                    icon: Icons.wallpaper,
                    label: 'Duvar Kağıdı',
                    onTap: () {
                      // TODO: Wallpaper seçici
                    },
                  ),
                  _ActionButton(
                    icon: Icons.search, 
                    label: 'Ara', 
                    onTap: () {
                      // TODO: Mesajlarda ara
                    },
                  ),
                ],
              ),
            ),
          ),

          // Media section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF7B3FF2),
                ),
                title: Text(
                  'Medya, bağlantılar ve belgeler',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                trailing: Icon(
                      Icons.chevron_right,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                onTap: () {
                  // TODO: Media gallery
                },
              ),
            ),
          ),

          // Members header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${_members.length} Katılımcı',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          ),

          // Members list
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Add member button (only for admins)
                  if (_isAdmin)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B3FF2).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Color(0xFF7B3FF2),
                      ),
                    ),
                      title: const Text(
                      'Katılımcı ekle',
                      style: TextStyle(
                          color: Color(0xFF7B3FF2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                      onTap: _showAddMemberSheet,
                  ),
                  if (_isAdmin) const Divider(height: 1),
                  // Member list
                  ..._members.map((member) => _buildMemberTile(member, isDark)),
                ],
              ),
            ),
          ),

          // Leave group
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Gruptan Ayrıl',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _showLeaveGroupDialog,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, bool isDark) {
    final profile = member['profiles'] as Map<String, dynamic>?;
    final userId = member['user_id'] as String;
    final role = member['role'] as String?;
    final isCurrentUser = userId == _currentUserId;
    
    final username = profile?['username'] ?? 'Kullanıcı';
    final fullName = profile?['full_name'] ?? '';
    final avatarUrl = profile?['avatar_url'];
    final isOnline = profile?['is_online'] ?? false;
    final isMemberAdmin = role == 'admin';

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
                        backgroundColor: const Color(0xFF7B3FF2),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                  color: Colors.green,
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
          Text(
            isCurrentUser ? 'Sen' : (fullName.isNotEmpty ? fullName : username),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
              fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
          if (isMemberAdmin)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7B3FF2).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: Color(0xFF7B3FF2),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: fullName.isNotEmpty && !isCurrentUser
          ? Text(
              '@$username',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 12,
                        ),
            )
          : null,
      trailing: _isAdmin && !isCurrentUser
          ? IconButton(
              icon: Icon(
                Icons.more_vert,
                color: isDark ? Colors.white54 : Colors.black45,
                    ),
              onPressed: () => _showMemberOptionsSheet(member),
            )
          : null,
      onTap: isCurrentUser ? null : () => _showMemberOptionsSheet(member),
    );
  }

  void _showEditGroupSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: _groupName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Grup Adını Düzenle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Grup adı',
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7B3FF2)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3FF2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.isEmpty) return;

                    final success = await _chatService.updateGroupName(widget.groupId, newName);
                    if (success && mounted) {
                      Navigator.pop(context);
                      await _loadGroupInfo();
                    }
                  },
                  child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
                ],
              ),
            ),
          ),
    );
  }

  void _showAddMemberSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final users = await _chatService.getAllUsers();
    
    // Mevcut üyeleri filtrele
    final memberIds = _members.map((m) => m['user_id'] as String).toSet();
    final availableUsers = users.where((u) => !memberIds.contains(u['id'])).toList();
    
    final selectedUserIds = <String>{};

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Üye Ekle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: selectedUserIds.isEmpty
                          ? null
                          : () async {
                              final success = await _chatService.addMembersToGroup(
                                chatId: widget.groupId,
                                userIds: selectedUserIds.toList(),
                              );
                              if (success && mounted) {
                                Navigator.pop(context);
                                await _loadGroupInfo();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${selectedUserIds.length} üye eklendi'),
                                    ),
                                  );
                                }
                              }
                            },
                      child: Text(
                        'Ekle (${selectedUserIds.length})',
                        style: TextStyle(
                          color: selectedUserIds.isEmpty
                              ? Colors.grey
                              : const Color(0xFF7B3FF2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // User list
              Expanded(
                child: availableUsers.isEmpty
                    ? Center(
                        child: Text(
                          'Eklenebilecek kullanıcı yok',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: availableUsers.length,
                        itemBuilder: (context, index) {
                          final user = availableUsers[index];
                          final isSelected = selectedUserIds.contains(user['id']);

                          return _UserSelectTile(
                            user: user,
                            isSelected: isSelected,
                            onTap: () {
                              setSheetState(() {
                                if (isSelected) {
                                  selectedUserIds.remove(user['id']);
                                } else {
                                  selectedUserIds.add(user['id']);
                                }
                              });
                            },
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

  void _showMemberOptionsSheet(Map<String, dynamic> member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = member['profiles'] as Map<String, dynamic>?;
    final userId = member['user_id'] as String;
    final role = member['role'] as String?;
    final isCurrentUser = userId == _currentUserId;
    final isMemberAdmin = role == 'admin';
    
    final username = profile?['username'] ?? 'Kullanıcı';
    final fullName = profile?['full_name'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // User info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF7B3FF2),
                    backgroundImage: profile?['avatar_url'] != null 
                        ? NetworkImage(profile!['avatar_url']) 
                        : null,
                    child: profile?['avatar_url'] == null
                        ? Text(
                            username[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Options
            if (!isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF7B3FF2)),
                title: Text(
                  'Mesaj Gönder',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final chatId = await _chatService.createDirectChat(userId);
                  if (chatId != null && mounted) {
                    Navigator.pushNamed(context, '/chat', arguments: {'chatId': chatId});
                  }
                },
              ),
              if (_isAdmin) ...[
                ListTile(
                  leading: Icon(
                    isMemberAdmin ? Icons.person_remove : Icons.admin_panel_settings,
                    color: const Color(0xFF7B3FF2),
                  ),
                  title: Text(
                    isMemberAdmin ? 'Adminlikten Çıkar' : 'Admin Yap',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    bool success;
                    if (isMemberAdmin) {
                      success = await _chatService.removeUserAdmin(
                        chatId: widget.groupId,
                        userId: userId,
                      );
                    } else {
                      success = await _chatService.makeUserAdmin(
                        chatId: widget.groupId,
                        userId: userId,
                      );
                    }
                    if (success) {
                      await _loadGroupInfo();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                title: const Text(
                    'Gruptan Çıkar',
                  style: TextStyle(color: Colors.red),
                ),
                  onTap: () => _showRemoveMemberDialog(userId, fullName.isNotEmpty ? fullName : username),
              ),
              ],
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(String userId, String name) {
    Navigator.pop(context); // Close options sheet first
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üyeyi Çıkar'),
        content: Text('$name kullanıcısını gruptan çıkarmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _chatService.removeMemberFromGroup(
                chatId: widget.groupId,
                userId: userId,
              );
              if (success) {
                await _loadGroupInfo();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Üye gruptan çıkarıldı')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gruptan Ayrıl'),
        content: const Text('Bu gruptan ayrılmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _chatService.leaveGroup(widget.groupId);
              if (success && mounted) {
                Navigator.pop(context); // Close group info
                Navigator.pop(context); // Go back to chat list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gruptan ayrıldınız')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF7B3FF2), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
