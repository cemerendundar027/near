import 'package:flutter/material.dart';

/// Message reactions overlay widget
class MessageReactions extends StatelessWidget {
  final List<Reaction> reactions;
  final bool isFromMe;
  final VoidCallback? onTap;

  const MessageReactions({
    super.key,
    required this.reactions,
    this.isFromMe = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group reactions by emoji
    final grouped = <String, int>{};
    for (final reaction in reactions) {
      grouped[reaction.emoji] = (grouped[reaction.emoji] ?? 0) + 1;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: grouped.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
                  if (entry.value > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Reaction picker that shows when long-pressing a message
class ReactionPicker extends StatefulWidget {
  final void Function(String emoji)? onReactionSelected;
  final VoidCallback? onMorePressed;

  const ReactionPicker({
    super.key,
    this.onReactionSelected,
    this.onMorePressed,
  });

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  static const _quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._quickReactions.map(
              (emoji) => _ReactionButton(
                emoji: emoji,
                onTap: () => widget.onReactionSelected?.call(emoji),
              ),
            ),
            GestureDetector(
              onTap: widget.onMorePressed,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatefulWidget {
  final String emoji;
  final VoidCallback? onTap;

  const _ReactionButton({required this.emoji, this.onTap});

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          child: Text(widget.emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

/// Message context menu with actions
class MessageContextMenu extends StatelessWidget {
  final bool isFromMe;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onCopy;
  final VoidCallback? onStar;
  final VoidCallback? onDelete;
  final VoidCallback? onInfo;

  const MessageContextMenu({
    super.key,
    this.isFromMe = false,
    this.onReply,
    this.onForward,
    this.onCopy,
    this.onStar,
    this.onDelete,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuItem(icon: Icons.reply, label: 'Yanıtla', onTap: onReply),
          _MenuItem(icon: Icons.forward, label: 'İlet', onTap: onForward),
          _MenuItem(icon: Icons.copy, label: 'Kopyala', onTap: onCopy),
          _MenuItem(icon: Icons.star_outline, label: 'Yıldızla', onTap: onStar),
          if (isFromMe)
            _MenuItem(icon: Icons.info_outline, label: 'Bilgi', onTap: onInfo),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
          _MenuItem(
            icon: Icons.delete_outline,
            label: 'Sil',
            color: Colors.red,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = color ?? (isDark ? Colors.white : Colors.black87);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: itemColor),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: itemColor, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

/// Reaction model
class Reaction {
  final String emoji;
  final String senderId;
  final DateTime timestamp;

  const Reaction({
    required this.emoji,
    required this.senderId,
    required this.timestamp,
  });
}

/// Reaction details sheet
class ReactionDetailsSheet extends StatelessWidget {
  final List<Reaction> reactions;
  final Map<String, String> userNames;

  const ReactionDetailsSheet({
    super.key,
    required this.reactions,
    required this.userNames,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group by emoji
    final grouped = <String, List<Reaction>>{};
    for (final reaction in reactions) {
      grouped.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Emoji tabs
          DefaultTabController(
            length: grouped.length + 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  isScrollable: true,
                  indicatorColor: const Color(0xFF7B3FF2),
                  labelColor: isDark ? Colors.white : Colors.black,
                  unselectedLabelColor: isDark
                      ? Colors.white54
                      : Colors.black54,
                  tabs: [
                    Tab(
                      child: Row(
                        children: [
                          const Text('Tümü'),
                          const SizedBox(width: 4),
                          Text(
                            '${reactions.length}',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...grouped.entries.map(
                      (e) => Tab(
                        child: Row(
                          children: [
                            Text(e.key),
                            const SizedBox(width: 4),
                            Text(
                              '${e.value.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      // All reactions
                      _ReactionList(reactions: reactions, userNames: userNames),
                      // Grouped reactions
                      ...grouped.entries.map(
                        (e) => _ReactionList(
                          reactions: e.value,
                          userNames: userNames,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionList extends StatelessWidget {
  final List<Reaction> reactions;
  final Map<String, String> userNames;

  const _ReactionList({required this.reactions, required this.userNames});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: reactions.length,
      itemBuilder: (context, index) {
        final reaction = reactions[index];
        final userName = userNames[reaction.senderId] ?? 'Bilinmeyen';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF7B3FF2),
            child: Text(
              userName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            userName,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Text(reaction.emoji, style: const TextStyle(fontSize: 24)),
        );
      },
    );
  }
}
