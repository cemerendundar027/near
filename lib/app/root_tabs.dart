import 'package:flutter/material.dart';
import '../features/chats/chats_page.dart';
import '../features/calls/calls_page.dart';
import '../features/settings/settings_page.dart';
import 'theme.dart';

class RootTabs extends StatefulWidget {
  final int initialTab;

  const RootTabs({super.key, this.initialTab = 0});

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab;
  }

  // Tab state korunur (scroll, textfield vs.)
  final _pages = const [
    ChatsPage(),
    CallsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),

      // ✅ Premium bottom bar container
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface.withAlpha((0.92 * 255).round()),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withAlpha((0.06 * 255).round()),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: (isDark ? Colors.black : Colors.black).withAlpha((0.12 * 255).round()),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
                selectedItemColor: NearTheme.primary,
                unselectedItemColor: Theme.of(context).colorScheme.onSurface.withAlpha(140),
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_rounded),
                    label: 'Chats',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.call_rounded),
                    label: 'Calls',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
