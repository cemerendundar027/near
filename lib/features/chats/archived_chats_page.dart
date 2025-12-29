import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/chat_store.dart';
import '../../shared/models.dart';

/// Arşivlenmiş sohbetler sayfası
class ArchivedChatsPage extends StatefulWidget {
  static const route = '/archived-chats';
  const ArchivedChatsPage({super.key});

  @override
  State<ArchivedChatsPage> createState() => _ArchivedChatsPageState();
}

class _ArchivedChatsPageState extends State<ArchivedChatsPage> {
  final store = ChatStore.instance;

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

  void _unarchive(ChatPreview chat) {
    store.toggleArchive(chat.id);
    _toast('Sohbet arşivden çıkarıldı');
  }

  void _openChat(ChatPreview chat) {
    context.push('/chat/${chat.id}');
  }

  Future<bool> _confirmDelete() async {
    return (await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sohbet silinsin mi?'),
            content: const Text('Bu işlem geri alınamaz.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
        )) ??
        false;
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
          icon: Icon(Icons.arrow_back_ios, size: 20, color: NearTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Arşivlenmiş Sohbetler',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final archived = store.chats
              .where((c) => store.isArchived(c.id))
              .toList();

          if (archived.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: NearTheme.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.archive_outlined,
                      size: 40,
                      color: NearTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arşivlenmiş sohbet yok',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sohbetleri sola kaydırarak\narşivleyebilirsiniz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: archived.length,
            itemBuilder: (context, index) {
              final chat = archived[index];
              final presence = store.presenceOf(chat.userId);
              final muted = store.isMuted(chat.userId);

              return Dismissible(
                key: Key('archived_${chat.id}'),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await _confirmDelete();
                  } else {
                    _unarchive(chat);
                    return false;
                  }
                },
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Row(
                    children: [
                      Icon(Icons.unarchive, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Arşivden Çıkar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Sil',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.delete, color: Colors.white),
                    ],
                  ),
                ),
                child: Container(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  child: ListTile(
                    onTap: () => _openChat(chat),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: isDark
                              ? Colors.white12
                              : Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            size: 28,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (presence.online)
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
                                  color: isDark
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          chat.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ),
                        if (muted)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.volume_off,
                              size: 16,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
