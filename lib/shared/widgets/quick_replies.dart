import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../chat_store.dart';

/// Quick Replies Bottom Sheet
/// Hızlı yanıt şablonlarını gösterir
class QuickRepliesSheet extends StatefulWidget {
  final Function(String) onReplySelected;

  const QuickRepliesSheet({
    super.key,
    required this.onReplySelected,
  });

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => QuickRepliesSheet(
        onReplySelected: (reply) => Navigator.pop(ctx, reply),
      ),
    );
  }

  @override
  State<QuickRepliesSheet> createState() => _QuickRepliesSheetState();
}

class _QuickRepliesSheetState extends State<QuickRepliesSheet> {
  final _store = ChatStore.instance;
  final _newReplyController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _newReplyController.dispose();
    super.dispose();
  }

  void _addNewReply() {
    final text = _newReplyController.text.trim();
    if (text.isNotEmpty) {
      _store.addQuickReply(text);
      _newReplyController.clear();
      setState(() => _isAdding = false);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final replies = _store.quickReplies;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                Icon(
                  Icons.flash_on_rounded,
                  color: NearTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hızlı Yanıtlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _isAdding = !_isAdding),
                  icon: Icon(
                    _isAdding ? Icons.close : Icons.add,
                    size: 20,
                  ),
                  label: Text(_isAdding ? 'İptal' : 'Ekle'),
                  style: TextButton.styleFrom(
                    foregroundColor: NearTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Add new reply
          if (_isAdding)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newReplyController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Yeni hızlı yanıt...',
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _addNewReply(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addNewReply,
                    icon: const Icon(Icons.send_rounded),
                    color: NearTheme.primary,
                  ),
                ],
              ),
            ),

          // Divider
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.black12,
          ),

          // Replies list
          Flexible(
            child: replies.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: replies.length,
                    itemBuilder: (context, index) {
                      final reply = replies[index];
                      return _QuickReplyTile(
                        text: reply,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          widget.onReplySelected(reply);
                        },
                        onDelete: () {
                          _store.removeQuickReply(reply);
                          setState(() {});
                          HapticFeedback.lightImpact();
                        },
                      );
                    },
                  ),
          ),

          // Safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flash_off_rounded,
            size: 48,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz hızlı yanıt yok',
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"Ekle" butonuna tıklayarak\nyeni yanıtlar ekleyebilirsin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReplyTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _QuickReplyTile({
    required this.text,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(text),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: NearTheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: NearTheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.send_rounded,
          color: NearTheme.primary,
          size: 20,
        ),
      ),
    );
  }
}

/// Quick replies compact bar - input üzerinde gösterilir
class QuickRepliesBar extends StatelessWidget {
  final Function(String) onReplySelected;
  final VoidCallback onShowAll;

  const QuickRepliesBar({
    super.key,
    required this.onReplySelected,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final replies = ChatStore.instance.quickReplies.take(5).toList();

    if (replies.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: replies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return _QuickChip(
                  text: replies[index],
                  onTap: () => onReplySelected(replies[index]),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onShowAll,
            icon: Icon(
              Icons.more_horiz,
              color: NearTheme.primary,
            ),
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: NearTheme.primary.withAlpha(isDark ? 40 : 25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NearTheme.primary.withAlpha(60),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: NearTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
