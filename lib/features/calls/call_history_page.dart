import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../app/theme.dart';
import '../../shared/chat_service.dart';

/// Arama Geçmişi Sayfası
class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key});

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  final _chatService = ChatService.instance;
  List<Map<String, dynamic>> _calls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _chatService.currentUserId;
      if (userId == null) return;

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
      debugPrint('CallHistoryPage: Error loading calls: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aramalar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Arama arama
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _calls.isEmpty
              ? _buildEmptyState()
              : _buildCallList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewCallDialog(),
        backgroundColor: NearTheme.primary,
        child: const Icon(Icons.call, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz arama yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bir kişiyi aramak için + butonuna tıklayın',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallList() {
    return RefreshIndicator(
      onRefresh: _loadCallHistory,
      child: ListView.builder(
        itemCount: _calls.length,
        itemBuilder: (context, index) {
          final call = _calls[index];
          return _buildCallTile(call);
        },
      ),
    );
  }

  Widget _buildCallTile(Map<String, dynamic> call) {
    final userId = _chatService.currentUserId;
    final isOutgoing = call['caller_id'] == userId;
    
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
    final duration = call['duration'] as int?;

    // İkon ve renk belirle
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (status == 'missed' || (status == 'ended' && !isOutgoing && duration == null)) {
      statusIcon = Icons.call_missed;
      statusColor = Colors.red;
      statusText = 'Cevapsız';
    } else if (status == 'rejected' || status == 'declined') {
      statusIcon = isOutgoing ? Icons.call_made : Icons.call_received;
      statusColor = Colors.red;
      statusText = isOutgoing ? 'Reddedildi' : 'Reddettiniz';
    } else if (status == 'ended' || status == 'connected') {
      statusIcon = isOutgoing ? Icons.call_made : Icons.call_received;
      statusColor = Colors.green;
      statusText = duration != null ? _formatDuration(duration) : 'Tamamlandı';
    } else {
      statusIcon = isOutgoing ? Icons.call_made : Icons.call_received;
      statusColor = Colors.grey;
      statusText = 'Bilinmiyor';
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
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
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(color: statusColor, fontSize: 13),
          ),
          if (isVideo) ...[
            const SizedBox(width: 8),
            Icon(Icons.videocam, size: 14, color: Colors.grey[600]),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            createdAt != null ? timeago.format(createdAt, locale: 'tr') : '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.call, size: 20),
                onPressed: otherUserId != null
                    ? () => _startCall(otherUserId, false)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.videocam, size: 20),
                onPressed: otherUserId != null
                    ? () => _startCall(otherUserId, true)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
      onTap: otherUserId != null
          ? () => _showCallDetails(call, name, avatarUrl)
          : null,
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m}m ${s}s';
    } else {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return '${h}h ${m}m';
    }
  }

  void _startCall(String userId, bool isVideo) {
    context.push('/call/$userId?video=$isVideo');
  }

  void _showNewCallDialog() {
    // Kişi seçme dialogu göster
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _NewCallSheet(
          scrollController: scrollController,
          onUserSelected: (userId, isVideo) {
            Navigator.pop(context);
            _startCall(userId, isVideo);
          },
        ),
      ),
    );
  }

  void _showCallDetails(Map<String, dynamic> call, String name, String? avatarUrl) {
    final type = call['type'] as String? ?? 'voice';
    final createdAt = DateTime.tryParse(call['created_at'] ?? '');
    final duration = call['duration'] as int?;
    final userId = _chatService.currentUserId;
    final isOutgoing = call['caller_id'] == userId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              createdAt != null
                  ? '${createdAt.day}.${createdAt.month}.${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                  : '',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            if (duration != null) ...[
              const SizedBox(height: 4),
              Text(
                'Süre: ${_formatDuration(duration)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
                    final otherUser = isOutgoing ? call['callee'] : call['caller'];
                    if (otherUser != null) {
                      _startCall(otherUser['id'], false);
                    }
                  },
                ),
                _buildActionButton(
                  icon: Icons.videocam,
                  label: 'Görüntülü Ara',
                  onTap: () {
                    Navigator.pop(context);
                    final otherUser = isOutgoing ? call['callee'] : call['caller'];
                    if (otherUser != null) {
                      _startCall(otherUser['id'], true);
                    }
                  },
                ),
                _buildActionButton(
                  icon: Icons.message,
                  label: 'Mesaj Gönder',
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final router = GoRouter.of(context);
                    navigator.pop();
                    final otherUser = isOutgoing ? call['callee'] : call['caller'];
                    if (otherUser != null) {
                      // Chat oluştur veya mevcut olanı bul
                      final chatId = await _chatService.createDirectChat(otherUser['id']);
                      if (chatId != null && mounted) {
                        router.push('/chat/$chatId');
                      }
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
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yeni arama için kişi seçme sheet'i
class _NewCallSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(String userId, bool isVideo) onUserSelected;

  const _NewCallSheet({
    required this.scrollController,
    required this.onUserSelected,
  });

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
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Kişi ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
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
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
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
      subtitle: username != null ? Text('@$username') : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => widget.onUserSelected(userId, false),
            tooltip: 'Sesli ara',
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => widget.onUserSelected(userId, true),
            tooltip: 'Görüntülü ara',
          ),
        ],
      ),
    );
  }
}
