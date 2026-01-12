import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/chat_service.dart';

/// Arama Geçmişi Sayfası - Bottom Navigation Tab
class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  final _chatService = ChatService.instance;
  List<Map<String, dynamic>> _calls = [];
  bool _isLoading = true;
  bool _isEditing = false;
  final Set<String> _selectedCalls = {};

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _chatService.currentUserId;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Son 100 aramayı çek
      final calls = await _chatService.supabase
          .from('calls')
          .select('''
            *,
            caller:profiles!calls_caller_id_fkey(id, full_name, username, avatar_url),
            callee:profiles!calls_callee_id_fkey(id, full_name, username, avatar_url)
          ''')
          .or('caller_id.eq.$userId,callee_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _calls = List<Map<String, dynamic>>.from(calls);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('CallsPage: Error loading calls: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dk önce';
    } else if (diff.inHours < 24 && now.day == time.day) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (diff.inHours < 48) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      const days = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
      return days[time.weekday % 7];
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m}dk ${s}s';
    } else {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return '${h}sa ${m}dk';
    }
  }

  void _startCall(String userId, bool isVideo) {
    context.push('/call/$userId?video=$isVideo');
  }

  void _deleteSelectedCalls() async {
    if (_selectedCalls.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aramaları Sil'),
        content: Text('${_selectedCalls.length} arama silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Seçili aramaları sil
      try {
        for (final callId in _selectedCalls) {
          await _chatService.supabase.from('calls').delete().eq('id', callId);
        }
        _selectedCalls.clear();
        _isEditing = false;
        await _loadCallHistory();
      } catch (e) {
        debugPrint('CallsPage: Error deleting calls: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 100,
            backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF2F2F7),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Aramalar',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF2F2F7)),
            ),
            actions: [
              if (_calls.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) _selectedCalls.clear();
                    });
                  },
                  child: Text(
                    _isEditing ? 'Bitti' : 'Düzenle',
                    style: TextStyle(color: NearTheme.primary),
                  ),
                ),
            ],
          ),

          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_calls.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCallTile(_calls[index]),
                childCount: _calls.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewCallSheet,
        backgroundColor: NearTheme.primary,
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
      bottomSheet: _isEditing && _selectedCalls.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Text(
                      '${_selectedCalls.length} seçili',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _deleteSelectedCalls,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Sil', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Near branding
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [NearTheme.primary, NearTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'N',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Icon(
            Icons.call_outlined,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz arama yok',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir arama başlatmak için\n+ butonuna dokunun',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallTile(Map<String, dynamic> call) {
    final userId = _chatService.currentUserId;
    final isOutgoing = call['caller_id'] == userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Karşı tarafın bilgilerini al
    final otherUser = isOutgoing 
        ? call['callee'] as Map<String, dynamic>?
        : call['caller'] as Map<String, dynamic>?;
    
    final otherUserId = otherUser?['id'] as String?;
    final name = otherUser?['full_name'] ?? otherUser?['username'] ?? 'Unknown';
    final avatarUrl = otherUser?['avatar_url'] as String?;
    
    final status = call['status'] as String? ?? 'ended';
    final type = call['type'] as String? ?? 'voice';
    final isVideo = type == 'video';
    final createdAt = DateTime.tryParse(call['created_at'] ?? '');
    final duration = call['duration_seconds'] as int?;
    final callId = call['id'] as String;

    // İkon ve renk belirle
    IconData statusIcon;
    Color statusColor;

    if (status == 'missed' || (status == 'ended' && !isOutgoing && duration == null)) {
      statusIcon = Icons.call_missed;
      statusColor = Colors.red;
    } else if (status == 'rejected' || status == 'declined') {
      statusIcon = isOutgoing ? Icons.call_made : Icons.call_received;
      statusColor = Colors.red;
    } else {
      statusIcon = isOutgoing ? Icons.call_made : Icons.call_received;
      statusColor = Colors.green;
    }

    final isSelected = _selectedCalls.contains(callId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: NearTheme.primary, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _isEditing
            ? Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedCalls.add(callId);
                    } else {
                      _selectedCalls.remove(callId);
                    }
                  });
                },
                activeColor: NearTheme.primary,
              )
            : CircleAvatar(
                radius: 24,
                backgroundColor: NearTheme.primary.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: NearTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: status == 'missed' ? Colors.red : null,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 4),
            if (isVideo) ...[
              Icon(Icons.videocam, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
            ],
            Text(
              duration != null ? _formatDuration(duration) : (status == 'missed' ? 'Cevapsız' : ''),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        trailing: _isEditing
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    createdAt != null ? _formatTime(createdAt) : '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      isVideo ? Icons.videocam : Icons.call,
                      color: NearTheme.primary,
                    ),
                    onPressed: otherUserId != null
                        ? () => _startCall(otherUserId, isVideo)
                        : null,
                  ),
                ],
              ),
        onTap: _isEditing
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedCalls.remove(callId);
                  } else {
                    _selectedCalls.add(callId);
                  }
                });
              }
            : otherUserId != null
                ? () => _showCallDetails(call, name, avatarUrl, otherUserId)
                : null,
      ),
    );
  }

  void _showNewCallSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _NewCallSheet(
          onUserSelected: (userId, isVideo) {
            Navigator.pop(ctx);
            _startCall(userId, isVideo);
          },
        ),
      ),
    );
  }

  void _showCallDetails(Map<String, dynamic> call, String name, String? avatarUrl, String otherUserId) {
    final type = call['type'] as String? ?? 'voice';
    final createdAt = DateTime.tryParse(call['created_at'] ?? '');
    final duration = call['duration_seconds'] as int?;
    final userId = _chatService.currentUserId;
    final isOutgoing = call['caller_id'] == userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: NearTheme.primary.withValues(alpha: 0.1),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: NearTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${isOutgoing ? "Giden" : "Gelen"} ${type == "video" ? "görüntülü" : "sesli"} arama',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              createdAt != null
                  ? '${createdAt.day}.${createdAt.month}.${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                  : '',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 13,
              ),
            ),
            if (duration != null) ...[
              const SizedBox(height: 4),
              Text(
                'Süre: ${_formatDuration(duration)}',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.call,
                  label: 'Sesli Ara',
                  onTap: () {
                    Navigator.pop(context);
                    _startCall(otherUserId, false);
                  },
                ),
                _buildActionButton(
                  icon: Icons.videocam,
                  label: 'Görüntülü',
                  onTap: () {
                    Navigator.pop(context);
                    _startCall(otherUserId, true);
                  },
                ),
                _buildActionButton(
                  icon: Icons.message,
                  label: 'Mesaj',
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final router = GoRouter.of(context);
                    navigator.pop();
                    final chatId = await _chatService.createDirectChat(otherUserId);
                    if (chatId != null && mounted) {
                      router.push('/chat/$chatId');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NearTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: NearTheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yeni arama için kişi seçme sheet'i
class _NewCallSheet extends StatefulWidget {
  final Function(String userId, bool isVideo) onUserSelected;

  const _NewCallSheet({required this.onUserSelected});

  @override
  State<_NewCallSheet> createState() => _NewCallSheetState();
}

class _NewCallSheetState extends State<_NewCallSheet> {
  final _chatService = ChatService.instance;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _chatService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('_NewCallSheet: Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final name = (user['full_name'] ?? '').toLowerCase();
          final username = (user['username'] ?? '').toLowerCase();
          return name.contains(query) || username.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 36,
          height: 4,
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'İptal',
                  style: TextStyle(color: NearTheme.primary, fontSize: 17),
                ),
              ),
              const Spacer(),
              Text(
                'Yeni Arama',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 60),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
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
        const SizedBox(height: 16),
        // User list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Henüz kişi yok'
                            : 'Kişi bulunamadı',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserTile(user);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final name = user['full_name'] ?? user['username'] ?? 'Unknown';
    final username = user['username'] as String?;
    final avatarUrl = user['avatar_url'] as String?;
    final userId = user['id'] as String;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: NearTheme.primary.withValues(alpha: 0.1),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: NearTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(name),
      subtitle: username != null
          ? Text(
              '@$username',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.call, color: NearTheme.primary),
            onPressed: () => widget.onUserSelected(userId, false),
            tooltip: 'Sesli ara',
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: NearTheme.primary),
            onPressed: () => widget.onUserSelected(userId, true),
            tooltip: 'Görüntülü ara',
          ),
        ],
      ),
    );
  }
}
