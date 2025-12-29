import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/chat_service.dart';
import '../../app/theme.dart';

/// Starred messages page - Yıldızlı mesajlar
class StarredMessagesPage extends StatefulWidget {
  const StarredMessagesPage({super.key});

  static const route = '/starred-messages';

  @override
  State<StarredMessagesPage> createState() => _StarredMessagesPageState();
}

class _StarredMessagesPageState extends State<StarredMessagesPage> {
  final _chatService = ChatService.instance;
  List<Map<String, dynamic>> _starredMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStarredMessages();
  }

  Future<void> _loadStarredMessages() async {
    setState(() => _isLoading = true);
    
    final messages = await _chatService.getStarredMessages();
    
    if (mounted) {
      setState(() {
        _starredMessages = messages;
        _isLoading = false;
      });
    }
  }

  Future<void> _unstarMessage(String messageId) async {
    await _chatService.toggleStarMessage(messageId);
    _loadStarredMessages();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Dün';
      } else if (diff.inDays < 7) {
        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        return days[date.weekday - 1];
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
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
          'Yıldızlı Mesajlar',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: NearTheme.primary),
            )
          : _starredMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 64,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Yıldızlı mesaj yok',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Önemli mesajları yıldızlayarak\nburadan ulaşabilirsiniz',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStarredMessages,
                  child: ListView.builder(
                    itemCount: _starredMessages.length,
                    itemBuilder: (context, index) {
                      final starred = _starredMessages[index];
                      final message = starred['message'] as Map<String, dynamic>?;
                      if (message == null) return const SizedBox.shrink();
                      
                      final sender = message['sender'] as Map<String, dynamic>?;
                      final chat = message['chat'] as Map<String, dynamic>?;
                      
                      return _StarredMessageTile(
                        messageId: message['id'] as String,
                        content: message['content'] as String? ?? '',
                        type: message['type'] as String? ?? 'text',
                        senderName: sender?['full_name'] ?? sender?['username'] ?? 'Bilinmeyen',
                        chatName: chat?['name'] ?? 'Sohbet',
                        chatId: chat?['id'] as String?,
                        timestamp: _formatDate(message['created_at'] as String?),
                        onUnstar: () => _unstarMessage(message['id'] as String),
                        onTap: () {
                          // Navigate to chat
                          if (chat != null && chat['id'] != null) {
                            context.push('/chat/${chat['id']}');
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _StarredMessageTile extends StatelessWidget {
  final String messageId;
  final String content;
  final String type;
  final String senderName;
  final String chatName;
  final String? chatId;
  final String timestamp;
  final VoidCallback? onUnstar;
  final VoidCallback? onTap;

  const _StarredMessageTile({
    required this.messageId,
    required this.content,
    required this.type,
    required this.senderName,
    required this.chatName,
    this.chatId,
    required this.timestamp,
    this.onUnstar,
    this.onTap,
  });

  IconData _getTypeIcon() {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.mic;
      case 'voice':
        return Icons.mic;
      case 'file':
        return Icons.insert_drive_file;
      case 'gif':
        return Icons.gif;
      default:
        return Icons.message;
    }
  }

  String _getDisplayContent() {
    switch (type) {
      case 'image':
        return '📷 Fotoğraf';
      case 'video':
        return '🎥 Video';
      case 'audio':
      case 'voice':
        return '🎤 Sesli mesaj';
      case 'file':
        return '📎 Dosya';
      case 'gif':
        return 'GIF';
      default:
        return content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(messageId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.star_border, color: Colors.white),
      ),
      onDismissed: (_) => onUnstar?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: NearTheme.primary,
                      child: Text(
                        senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            chatName,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      timestamp,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Content
                Row(
                  children: [
                    if (type != 'text') ...[
                      Icon(
                        _getTypeIcon(),
                        size: 16,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        _getDisplayContent(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Broadcast list page
class BroadcastListPage extends StatefulWidget {
  const BroadcastListPage({super.key});

  static const route = '/broadcast';

  @override
  State<BroadcastListPage> createState() => _BroadcastListPageState();
}

class _BroadcastListPageState extends State<BroadcastListPage> {
  final _broadcasts = <_BroadcastList>[
    _BroadcastList(
      id: '1',
      name: 'Aile',
      recipientCount: 12,
      lastMessage: 'Bayram kutlu olsun! 🎉',
      lastMessageTime: '10:30',
    ),
    _BroadcastList(
      id: '2',
      name: 'İş Arkadaşları',
      recipientCount: 8,
      lastMessage: 'Toplantı notları ektedir',
      lastMessageTime: 'Dün',
    ),
  ];

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
          'Toplu Mesaj Listeleri',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: Column(
        children: [
          // Create new broadcast
          Container(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B3FF2).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Color(0xFF7B3FF2)),
              ),
              title: Text(
                'Yeni toplu mesaj listesi',
                style: TextStyle(
                  color: const Color(0xFF7B3FF2),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                // Navigate to create broadcast
              },
            ),
          ),

          const SizedBox(height: 16),

          // Broadcast lists
          Expanded(
            child: _broadcasts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 64,
                          color: isDark ? Colors.white38 : Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Toplu mesaj listesi yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _broadcasts.length,
                    itemBuilder: (context, index) {
                      final broadcast = _broadcasts[index];
                      return _BroadcastTile(broadcast: broadcast);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BroadcastList {
  final String id;
  final String name;
  final int recipientCount;
  final String lastMessage;
  final String lastMessageTime;

  const _BroadcastList({
    required this.id,
    required this.name,
    required this.recipientCount,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}

class _BroadcastTile extends StatelessWidget {
  final _BroadcastList broadcast;

  const _BroadcastTile({required this.broadcast});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF7B3FF2).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.campaign, color: Color(0xFF7B3FF2)),
        ),
        title: Text(
          broadcast.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${broadcast.recipientCount} alıcı',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              broadcast.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        trailing: Text(
          broadcast.lastMessageTime,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        onTap: () {
          // Open broadcast chat
        },
      ),
    );
  }
}

/// Archived chats page
class ArchivedChatsPage extends StatelessWidget {
  const ArchivedChatsPage({super.key});

  static const route = '/archived-chats';

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
          'Arşivlenmiş Sohbetler',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Arşivlenmiş sohbet yok',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sohbetleri sola kaydırarak\narşivleyebilirsiniz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// New chat FAB menu
class NewChatMenu extends StatefulWidget {
  final VoidCallback? onNewChat;
  final VoidCallback? onNewGroup;
  final VoidCallback? onNewBroadcast;

  const NewChatMenu({
    super.key,
    this.onNewChat,
    this.onNewGroup,
    this.onNewBroadcast,
  });

  @override
  State<NewChatMenu> createState() => _NewChatMenuState();
}

class _NewChatMenuState extends State<NewChatMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Sub buttons
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _controller.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _controller.value)),
                child: child,
              ),
            );
          },
          child: _isOpen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MiniButton(
                      icon: Icons.campaign,
                      label: 'Toplu Mesaj',
                      onTap: () {
                        _toggle();
                        widget.onNewBroadcast?.call();
                      },
                    ),
                    const SizedBox(height: 8),
                    _MiniButton(
                      icon: Icons.group_add,
                      label: 'Yeni Grup',
                      onTap: () {
                        _toggle();
                        widget.onNewGroup?.call();
                      },
                    ),
                    const SizedBox(height: 8),
                    _MiniButton(
                      icon: Icons.person_add,
                      label: 'Yeni Sohbet',
                      onTap: () {
                        _toggle();
                        widget.onNewChat?.call();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // Main FAB
        FloatingActionButton(
          heroTag: 'chat_extras_fab',
          onPressed: _toggle,
          backgroundColor: const Color(0xFF7B3FF2),
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MiniButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          onPressed: onTap,
          backgroundColor: const Color(0xFF7B3FF2),
          heroTag: label,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

/// Yeni kişi ekleme sayfası
class NewContactPage extends StatefulWidget {
  const NewContactPage({super.key});

  static const route = '/new-contact';

  @override
  State<NewContactPage> createState() => _NewContactPageState();
}

class _NewContactPageState extends State<NewContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveContact() {
    if (_formKey.currentState?.validate() ?? false) {
      // Simüle kayıt
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text} kişi listesine eklendi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yeni Kişi',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: _saveContact,
            child: const Text(
              'Kaydet',
              style: TextStyle(
                color: Color(0xFF7B3FF2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF7B3FF2).withAlpha(30),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: Color(0xFF7B3FF2),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B3FF2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF000000) : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // İsim
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen isim girin';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Telefon
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen telefon numarası girin';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // E-posta
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-posta (İsteğe bağlı)',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
