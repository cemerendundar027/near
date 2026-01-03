import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/chat_service.dart';
import '../../shared/models.dart';
import 'media_gallery_page.dart';

class GroupInfoPage extends StatefulWidget {
  final String groupId;

  const GroupInfoPage({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final _chatService = ChatService.instance;
  
  bool _isLoading = true;
  Map<String, dynamic>? _groupInfo;
  List<ChatParticipant> _participants = [];
  bool _isAdmin = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _chatService.currentUserId;
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    
    final info = await _chatService.getGroupInfo(widget.groupId);
    final membersData = await _chatService.getGroupMembers(widget.groupId);
    final isAdmin = await _chatService.isUserAdmin(widget.groupId);

    if (mounted) {
      setState(() {
        _groupInfo = info;
        _participants = membersData.map((m) => ChatParticipant.fromJson(m)).toList();
        _isAdmin = isAdmin;
        _isLoading = false;
      });
    }
  }

  void _showAddMemberSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMemberSheet(
        groupId: widget.groupId,
        existingMemberIds: _participants.map((p) => p.userId).toSet(),
        onAdded: _refreshData,
      ),
    );
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gruptan Çık'),
        content: const Text('Bu gruptan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çık', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _chatService.leaveGroup(widget.groupId);
      if (success && mounted) {
        context.go('/'); // Go to home
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gruptan çıkılamadı')),
        );
      }
    }
  }
  
  void _showEditNameDialog() {
    if (!_isAdmin) return;
    
    final controller = TextEditingController(text: _groupInfo?['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grup Adını Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Grup Adı'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (controller.text.trim().isNotEmpty) {
                 await _chatService.updateGroupName(widget.groupId, controller.text.trim());
                 _refreshData();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupName = _groupInfo?['name'] ?? 'Grup';
    final avatarUrl = _groupInfo?['avatar_url'];

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            iconTheme: IconThemeData(color: Colors.white), // Always white on image/gradient
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [NearTheme.primary, NearTheme.primaryDark],
                      ),
                    ),
                  ),
                  if (avatarUrl != null)
                    Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
                    ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        GestureDetector(
                          onTap: _isAdmin ? () {
                             // TODO: Implement avatar change
                          } : null,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white24,
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null
                                ? const Icon(Icons.group, size: 50, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _showEditNameDialog,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                groupName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isAdmin)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.edit, color: Colors.white70, size: 20),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${_participants.length} üye',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                   // More options
                },
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Column(
              children: [
                 // Actions
                Container(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(icon: Icons.search, label: 'Ara', onTap: () {}),
                      _ActionButton(icon: Icons.image, label: 'Medya', onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => MediaGalleryPage(chatId: widget.groupId, chatName: groupName)));
                      }),
                      if (_isAdmin)
                        _ActionButton(
                            icon: Icons.person_add, 
                            label: 'Ekle', 
                            onTap: _showAddMemberSheet,
                        ),
                    ],
                  ),
                ),

                // Participants Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'KATILIMCILAR',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ),
                ),

                // Participants List
                Container(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _participants.length,
                    separatorBuilder: (ctx, i) => Divider(
                      height: 1, 
                      indent: 72, 
                      color: isDark ? Colors.white10 : Colors.grey.shade200
                    ),
                    itemBuilder: (context, index) {
                      final participant = _participants[index];
                      final isMe = participant.userId == _currentUserId;
                      final isAdmin = participant.role == 'admin';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: NearTheme.primary.withOpacity(0.2),
                          backgroundImage: participant.avatarUrl != null 
                             ? NetworkImage(participant.avatarUrl!) 
                             : null,
                          child: participant.avatarUrl == null
                              ? Text(
                                  (participant.username ?? '?')[0].toUpperCase(),
                                  style: TextStyle(color: NearTheme.primary, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        title: Text(
                          isMe ? 'Siz' : (participant.username ?? 'Kullanıcı'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: participant.fullName != null
                            ? Text(
                                participant.fullName!,
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                              )
                            : null,
                        trailing: isAdmin
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: NearTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: NearTheme.primary.withOpacity(0.5)),
                                ),
                                child: Text(
                                  'Yönetici',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: NearTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                           if (!isMe && _isAdmin) {
                              _showAdminActions(participant);
                           }
                        },
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Exit Group
                Container(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text(
                      'Gruptan Çık',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                    onTap: _leaveGroup,
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminActions(ChatParticipant participant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Yönetici Yap', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatService.makeUserAdmin(chatId: widget.groupId, userId: participant.userId);
                    _refreshData();
                  },
                ),
                ListTile(
                  title: const Text('Gruptan Çıkar', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatService.removeMemberFromGroup(chatId: widget.groupId, userId: participant.userId);
                    _refreshData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: NearTheme.primary, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: NearTheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  final String groupId;
  final Set<String> existingMemberIds;
  final VoidCallback onAdded;

  const _AddMemberSheet({
    required this.groupId,
    required this.existingMemberIds,
    required this.onAdded,
  });

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _chatService = ChatService.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final all = await _chatService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = all.where((u) => !widget.existingMemberIds.contains(u['id'])).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _addMember(String userId) async {
    await _chatService.addMembersToGroup(chatId: widget.groupId, userIds: [userId]);
    widget.onAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Üye Ekle',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty 
                    ? const Center(child: Text('Eklenecek kimse yok'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                              child: user['avatar_url'] == null ? Text(user['username'][0]) : null,
                            ),
                            title: Text(user['username'], style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                            trailing:  IconButton(
                              icon: const Icon(Icons.add_circle, color: Color(0xFF7B3FF2)),
                              onPressed: () => _addMember(user['id']),
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
