import 'package:flutter/material.dart';
import '../../shared/chat_store.dart';
import '../../shared/settings_widgets.dart';

class MutedUsersPage extends StatelessWidget {
  static const route = '/settings/privacy/muted';
  const MutedUsersPage({super.key});

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final store = ChatStore.instance;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: store,
      builder: (_, _) {
        final ids = store.mutedUserIds;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
            title: Text(
              'Muted Users',
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
          ),
          body: ids.isEmpty
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
                          Icons.notifications_off_rounded,
                          size: 40,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Muted Users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sessize aldığın kullanıcılar burada görünür',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Sessize alınan kişilerden bildirim almayacaksın ama mesajları görebilirsin.',
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
                        itemCount: ids.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          indent: 70,
                          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
                        ),
                        itemBuilder: (_, i) {
                          final userId = ids[i];
                          final name = store.nameOfUser(userId);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              userId,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: () {
                                store.unmute(userId);
                                _toast(context, '$name sessiz modundan çıkarıldı');
                              },
                              child: const Text(
                                'Unmute',
                                style: TextStyle(
                                  color: SettingsColors.orange,
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
