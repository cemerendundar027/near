import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/chat_store.dart';
import '../../shared/chat_service.dart';
import '../../shared/models.dart';
import '../../shared/story_service.dart';
import '../../shared/mood_aura.dart';
import '../../shared/widgets/swipe_actions.dart';
import '../../shared/widgets/shimmer_loading.dart';
import 'chat_extras_pages.dart';
import 'create_group_page.dart';
import '../story/story_viewer_page.dart';

class ChatsPage extends StatefulWidget {
  static const route = '/';
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final store = ChatStore.instance;
  final chatService = ChatService.instance;
  final storyService = StoryService.instance;
  // ignore: prefer_final_fields
  String _query = '';
  int _filterIndex = 0; // 0: Tümü, 1: Okunmamış, 2: Gruplar
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    await chatService.init();
    await storyService.loadStories();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await chatService.loadChats();
    await storyService.loadStories();
    if (mounted) {
      _toast('Güncellendi');
    }
  }

  Future<void> _openChat(ChatPreview chat) async {
    HapticFeedback.selectionClick();
    context.push('/chat/${chat.id}');
  }

  void _openStory(int userIndex) {
    // Gerçek story'leri StoryService'den al
    final userStories = storyService.userStories;
    if (userStories.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerPage(),
        settings: RouteSettings(
          arguments: StoryViewerArgs(
            userStoriesList: userStories,
            initialUserIndex: userIndex,
          ),
        ),
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openCameraForStory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: NearTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: NearTheme.primary),
                ),
                title: Text(
                  'Fotoğraf Çek',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Kamera ile fotoğraf çek',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/create-story');
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: NearTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: NearTheme.primary),
                ),
                title: Text(
                  'Galeriden Seç',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Mevcut fotoğraflardan seç',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/create-story');
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: NearTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.text_fields, color: NearTheme.primary),
                ),
                title: Text(
                  'Metin Durumu',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Renkli arka planlı metin paylaş',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/create-story');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.group_add, color: cs.onSurface),
                title: Text('Yeni Grup', style: TextStyle(color: cs.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/create-group');
                },
              ),
              ListTile(
                leading: Icon(Icons.campaign, color: cs.onSurface),
                title: Text(
                  'Yeni Yayın',
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/broadcasts');
                },
              ),
              ListTile(
                leading: Icon(Icons.archive_outlined, color: cs.onSurface),
                title: Text(
                  'Arşivlenmiş Sohbetler',
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/archived');
                },
              ),
              ListTile(
                leading: Icon(Icons.laptop_mac, color: cs.onSurface),
                title: Text(
                  'Bağlı Cihazlar',
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings/devices');
                },
              ),
              ListTile(
                leading: Icon(Icons.star, color: cs.onSurface),
                title: Text(
                  'Yıldızlı Mesajlar',
                  style: TextStyle(color: cs.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StarredMessagesPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: cs.onSurface),
                title: Text('Ayarlar', style: TextStyle(color: cs.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  // Settings tab'a geç
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirm(String title, String msg) async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil'),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _onChatMenu(ChatPreview chat, _ChatMenuAction a) async {
    switch (a) {
      case _ChatMenuAction.pin:
        store.togglePin(chat.id);
        _toast(
          store.isPinned(chat.id)
              ? 'Sohbet sabitlendi'
              : 'Sabitleme kaldırıldı',
        );
        break;
      case _ChatMenuAction.mute:
        store.toggleMute(chat.userId);
        _toast(
          store.isMuted(chat.userId)
              ? 'Sohbet sessize alındı'
              : 'Sessiz kaldırıldı',
        );
        break;
      case _ChatMenuAction.archive:
        store.toggleArchive(chat.id);
        _toast(
          store.isArchived(chat.id)
              ? 'Sohbet arşivlendi'
              : 'Sohbet arşivden çıkarıldı',
        );
        break;
      case _ChatMenuAction.delete:
        final ok = await _confirm(
          'Sohbet silinsin mi?',
          'Bu işlem geri alınamaz.',
        );
        if (ok && mounted) {
          store.removeChat(chat.id);
          _toast('Sohbet silindi');
        }
        break;
    }
  }

  void _showNewChatSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
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
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'İptal',
                      style: TextStyle(color: NearTheme.primary, fontSize: 17),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Yeni Sohbet',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Ara',
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
            // New Group / New Contact
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: NearTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.group_add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Yeni Grup',
                      style: TextStyle(
                        color: NearTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateGroupPage(),
                        ),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: NearTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Yeni Kişi',
                      style: TextStyle(
                        color: NearTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NewContactPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'KİŞİLER',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: store.chats.length,
                itemBuilder: (_, i) {
                  final chat = store.chats[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDark
                          ? Colors.white12
                          : Colors.grey.shade300,
                      child: Icon(
                        Icons.person,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                    title: Text(
                      chat.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Çevrimiçi',
                      style: TextStyle(fontSize: 13, color: NearTheme.primary),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openChat(chat);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([store, chatService]),
      builder: (_, _) {
        final q = _query.trim().toLowerCase();
        final all = store.chats
            .where((c) => !store.isBlocked(c.userId))
            .toList();

        // Filtreleme
        List<ChatPreview> filtered;
        switch (_filterIndex) {
          case 1: // Okunmamış
            filtered = all.where((c) => store.unreadCount(c.id) > 0).toList();
            break;
          case 2: // Gruplar
            filtered = all.where((c) => c.isGroup).toList();
            break;
          default:
            filtered = all;
        }

        // Arama
        final chats = q.isEmpty
            ? filtered
            : filtered.where((c) {
                final n = c.name.toLowerCase();
                final lm = c.lastMessage.toLowerCase();
                return n.contains(q) || lm.contains(q);
              }).toList();

        final userStories = storyService.userStories;
        final myStories = storyService.myStories;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            color: NearTheme.primary,
            child: CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: isDark
                    ? const Color(0xFF000000)
                    : Colors.white,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 60,
                title: Text(
                  'Sohbetler',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _openCameraForStory();
                    },
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: NearTheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showMoreMenu(),
                    icon: Icon(Icons.more_horiz, color: NearTheme.primary),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: GestureDetector(
                    onTap: () {
                      showSearch(
                        context: context,
                        delegate: _ChatSearchDelegate(store, _openChat),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ara',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tümü',
                        selected: _filterIndex == 0,
                        onTap: () => setState(() => _filterIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Okunmamış',
                        selected: _filterIndex == 1,
                        onTap: () => setState(() => _filterIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Gruplar',
                        selected: _filterIndex == 2,
                        onTap: () => setState(() => _filterIndex = 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Stories
              SliverToBoxAdapter(
                child: _isLoading
                    ? const StoryListShimmer()
                    : SizedBox(
                  height: 100,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: userStories.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _MyStatusBubble(
                          hasStory: myStories.isNotEmpty,
                          onTap: () {
                            if (myStories.isNotEmpty) {
                              // Kendi story'lerimi görüntüle
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StoryViewerPage(),
                                  settings: RouteSettings(
                                    arguments: StoryViewerArgs(
                                      userStoriesList: [
                                        UserStories(
                                          userId: storyService.currentUserId ?? '',
                                          userName: 'Ben',
                                          stories: myStories,
                                          hasUnviewed: false,
                                        ),
                                      ],
                                      initialUserIndex: 0,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              context.push('/create-story');
                            }
                          },
                        );
                      }
                      final userStory = userStories[i - 1];
                      return Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _StoryBubble(
                          name: userStory.userName,
                          avatarUrl: userStory.userAvatar,
                          hasUnviewed: userStory.hasUnviewed,
                          onTap: () => _openStory(i - 1),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Chat List
              _isLoading
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => const ChatListItemShimmer(),
                        childCount: 6,
                      ),
                    )
                  : chats.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 40,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filterIndex == 1
                                  ? 'Okunmamış mesaj yok'
                                  : (_filterIndex == 2
                                        ? 'Henüz grup yok'
                                        : 'Henüz sohbet yok'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Yeni bir sohbet başlatmak için\naşağıdaki butona dokun',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final chat = chats[i];
                        // Önce ChatService'den unread count al, yoksa store'dan
                        final unread = chatService.getCachedUnreadCount(chat.id) > 0 
                            ? chatService.getCachedUnreadCount(chat.id)
                            : store.unreadCount(chat.id);
                        final typing = store.isTyping(chat.id);
                        final pinned = store.isPinned(chat.id);
                        final muted = store.isMuted(chat.userId);
                        
                        // Online durumunu Supabase'den al (last_seen'e göre)
                        final supabaseChat = chatService.chats.firstWhere(
                          (c) => c['id'] == chat.id,
                          orElse: () => <String, dynamic>{},
                        );
                        final online = supabaseChat.isNotEmpty 
                            ? chatService.isOtherUserOnline(supabaseChat)
                            : store.presenceOf(chat.userId).online;

                        return SwipeableChatTile(
                          isPinned: pinned,
                          onArchive: () {
                            store.toggleArchive(chat.id);
                            _toast(
                              store.isArchived(chat.id)
                                  ? 'Sohbet arşivlendi'
                                  : 'Sohbet arşivden çıkarıldı',
                            );
                          },
                          onDelete: () async {
                            final ok = await _confirm(
                              'Sohbet silinsin mi?',
                              'Bu işlem geri alınamaz.',
                            );
                            if (ok && mounted) {
                              _toast('Sohbet silindi');
                            }
                          },
                          onPin: () {
                            store.togglePin(chat.id);
                            _toast(
                              store.isPinned(chat.id)
                                  ? 'Sohbet sabitlendi'
                                  : 'Sabitleme kaldırıldı',
                            );
                          },
                          child: _ChatTile(
                            chat: chat,
                            supabaseChat: supabaseChat,
                            unread: unread,
                            typing: typing,
                            pinned: pinned,
                            muted: muted,
                            online: online,
                            onTap: () => _openChat(chat),
                            onLongPress: () =>
                                _showChatOptions(chat, pinned, muted),
                          ),
                        );
                      }, childCount: chats.length),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'chats_fab',
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/new-chat');
            },
            backgroundColor: NearTheme.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            child: const Icon(Icons.chat, size: 24),
          ),
        );
      },
    );
  }

  void _showChatOptions(ChatPreview chat, bool pinned, bool muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              // Chat info
              CircleAvatar(
                radius: 30,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                chat.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              // Options
              _OptionTile(
                icon: Icons.push_pin_rounded,
                label: pinned ? 'Sabitlemeyi Kaldır' : 'Sabitle',
                onTap: () {
                  Navigator.pop(ctx);
                  _onChatMenu(chat, _ChatMenuAction.pin);
                },
              ),
              _OptionTile(
                icon: muted
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_rounded,
                label: muted ? 'Sesi Aç' : 'Sessize Al',
                onTap: () {
                  Navigator.pop(ctx);
                  _onChatMenu(chat, _ChatMenuAction.mute);
                },
              ),
              _OptionTile(
                icon: Icons.archive_rounded,
                label: 'Arşivle',
                onTap: () {
                  Navigator.pop(ctx);
                  _onChatMenu(chat, _ChatMenuAction.archive);
                },
              ),
              _OptionTile(
                icon: Icons.delete_rounded,
                label: 'Sil',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(ctx);
                  _onChatMenu(chat, _ChatMenuAction.delete);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ChatMenuAction { pin, mute, archive, delete }

// Filter Chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? NearTheme.primary
              : (isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// My Status Bubble
class _MyStatusBubble extends StatelessWidget {
  final bool hasStory;
  final VoidCallback onTap;
  const _MyStatusBubble({this.hasStory = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStory
                        ? LinearGradient(
                            colors: [NearTheme.primary, NearTheme.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: hasStory
                        ? null
                        : Border.all(
                            color: isDark ? Colors.white24 : Colors.grey.shade400,
                            width: 2,
                          ),
                  ),
                  child: CircleAvatar(
                    radius: 27,
                    backgroundColor: isDark
                        ? Colors.white12
                        : Colors.grey.shade300,
                    child: Icon(
                      Icons.person,
                      size: 28,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (!hasStory)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: NearTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF000000) : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Durumum',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Story Bubble
class _StoryBubble extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool hasUnviewed;
  final VoidCallback onTap;

  const _StoryBubble({
    required this.name,
    this.avatarUrl,
    required this.hasUnviewed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? LinearGradient(
                        colors: [NearTheme.primary, NearTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: hasUnviewed
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                        width: 2,
                      ),
              ),
              child: CircleAvatar(
                radius: 27,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 28,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chat Tile
class _ChatTile extends StatelessWidget {
  final ChatPreview chat;
  final Map<String, dynamic>? supabaseChat;
  final int unread;
  final bool typing;
  final bool pinned;
  final bool muted;
  final bool online;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatTile({
    required this.chat,
    this.supabaseChat,
    required this.unread,
    required this.typing,
    required this.pinned,
    required this.muted,
    required this.online,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with Mood Aura
            _buildAvatarWithAura(isDark),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: unread > 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 13,
                          color: unread > 0
                              ? NearTheme.primary
                              : (isDark ? Colors.white54 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          typing ? 'yazıyor...' : chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: typing
                                ? NearTheme.primary
                                : (isDark
                                      ? Colors.white54
                                      : Colors.black54),
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (muted)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.notifications_off,
                            size: 16,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      if (pinned)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.push_pin,
                            size: 16,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NearTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Avatar with Mood Aura Premium Effect
  Widget _buildAvatarWithAura(bool isDark) {
    // Supabase chat'ten diğer kullanıcının bilgilerini al
    final isGroup = supabaseChat?['is_group'] == true;
    String? avatarUrl;
    MoodAura mood = MoodAura.none;

    if (!isGroup && supabaseChat != null) {
      // 1:1 sohbette diğer kullanıcının bilgilerini al
      final participants = supabaseChat!['chat_participants'] as List?;
      final chatService = ChatService.instance;
      final currentUserId = chatService.currentUserId;

      if (participants != null) {
        for (final p in participants) {
          final profile = p['profiles'] as Map<String, dynamic>?;
          if (profile != null && profile['id'] != currentUserId) {
            avatarUrl = profile['avatar_url'] as String?;
            mood = MoodAura.fromString(profile['mood_aura'] as String?);
            break;
          }
        }
      }
    } else if (isGroup) {
      avatarUrl = supabaseChat?['avatar_url'] as String?;
    }

    // Avatar widget
    final avatarWidget = CircleAvatar(
      radius: 28,
      backgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Icon(
              isGroup ? Icons.group : Icons.person,
              size: 28,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            )
          : null,
    );

    // Stack for online indicator
    return Stack(
      children: [
        // Mood Aura wrapped avatar
        if (mood != MoodAura.none)
          MoodAuraWidget(
            mood: mood,
            size: 56,
            child: avatarWidget,
          )
        else
          avatarWidget,
        // Online indicator
        if (online)
          Positioned(
            right: mood != MoodAura.none ? 4 : 0,
            bottom: mood != MoodAura.none ? 4 : 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF000000) : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Option Tile
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurface;

    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

// Search Delegate
class _ChatSearchDelegate extends SearchDelegate<ChatPreview?> {
  final ChatStore store;
  final Function(ChatPreview) onSelect;

  _ChatSearchDelegate(this.store, this.onSelect);

  @override
  String get searchFieldLabel => 'İsim veya mesaj ara...';

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase();
    final results = store.chats.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.lastMessage.toLowerCase().contains(q);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final chat = results[i];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(chat.name),
          subtitle: Text(
            chat.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            close(context, chat);
            onSelect(chat);
          },
        );
      },
    );
  }
}
