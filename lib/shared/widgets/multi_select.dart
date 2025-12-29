import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Multi-Select Messages Widget
/// - Checkbox ile mesaj seçimi
/// - Toplu silme, iletme, yıldızlama
/// - Seçim sayısı gösterimi
class MultiSelectController extends ChangeNotifier {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  int get selectedCount => _selectedIds.length;
  bool get hasSelection => _selectedIds.isNotEmpty;

  void enterSelectionMode() {
    _isSelectionMode = true;
    notifyListeners();
  }

  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedIds.clear();
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll(List<String> ids) {
    _selectedIds.addAll(ids);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  bool isSelected(String id) => _selectedIds.contains(id);
}

/// Multi-Select AppBar
/// Seçim modunda gösterilen özel app bar
class MultiSelectAppBar extends StatelessWidget implements PreferredSizeWidget {
  final MultiSelectController controller;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final VoidCallback? onForward;
  final VoidCallback? onStar;
  final VoidCallback? onCopy;
  final VoidCallback? onSelectAll;
  final int totalCount;

  const MultiSelectAppBar({
    super.key,
    required this.controller,
    this.onClose,
    this.onDelete,
    this.onForward,
    this.onStar,
    this.onCopy,
    this.onSelectAll,
    this.totalCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return AppBar(
          backgroundColor: NearTheme.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              HapticFeedback.lightImpact();
              controller.exitSelectionMode();
              onClose?.call();
            },
          ),
          title: Text(
            '${controller.selectedCount} seçildi',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (onSelectAll != null && controller.selectedCount < totalCount)
              IconButton(
                icon: const Icon(Icons.select_all),
                tooltip: 'Tümünü Seç',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onSelectAll?.call();
                },
              ),
            if (onCopy != null && controller.hasSelection)
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Kopyala',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onCopy?.call();
                },
              ),
            if (onStar != null && controller.hasSelection)
              IconButton(
                icon: const Icon(Icons.star_outline),
                tooltip: 'Yıldızla',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onStar?.call();
                },
              ),
            if (onForward != null && controller.hasSelection)
              IconButton(
                icon: const Icon(Icons.forward),
                tooltip: 'İlet',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onForward?.call();
                },
              ),
            if (onDelete != null && controller.hasSelection)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Sil',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onDelete?.call();
                },
              ),
          ],
        );
      },
    );
  }
}

/// Multi-Select Bottom Bar
/// Alt kısımda gösterilen action bar
class MultiSelectBottomBar extends StatelessWidget {
  final MultiSelectController controller;
  final VoidCallback? onDelete;
  final VoidCallback? onForward;
  final VoidCallback? onStar;
  final VoidCallback? onCopy;
  final VoidCallback? onMore;

  const MultiSelectBottomBar({
    super.key,
    required this.controller,
    this.onDelete,
    this.onForward,
    this.onStar,
    this.onCopy,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        if (!controller.isSelectionMode || !controller.hasSelection) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.copy,
                    label: 'Kopyala',
                    onTap: onCopy,
                  ),
                  _ActionButton(
                    icon: Icons.star_outline,
                    label: 'Yıldızla',
                    onTap: onStar,
                  ),
                  _ActionButton(
                    icon: Icons.forward,
                    label: 'İlet',
                    onTap: onForward,
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Sil',
                    onTap: onDelete,
                    isDestructive: true,
                  ),
                  if (onMore != null)
                    _ActionButton(
                      icon: Icons.more_vert,
                      label: 'Daha',
                      onTap: onMore,
                    ),
                ],
              ),
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
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive
        ? Colors.red
        : (isDark ? Colors.white70 : Colors.black87);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable Message Wrapper
/// Mesajları seçilebilir yapar
class SelectableMessage extends StatelessWidget {
  final Widget child;
  final String messageId;
  final MultiSelectController controller;
  final VoidCallback? onLongPress;

  const SelectableMessage({
    super.key,
    required this.child,
    required this.messageId,
    required this.controller,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isSelected = controller.isSelected(messageId);
        final isSelectionMode = controller.isSelectionMode;

        return GestureDetector(
          onLongPress: () {
            if (!isSelectionMode) {
              HapticFeedback.mediumImpact();
              controller.enterSelectionMode();
              controller.toggleSelection(messageId);
              onLongPress?.call();
            }
          },
          onTap: () {
            if (isSelectionMode) {
              HapticFeedback.selectionClick();
              controller.toggleSelection(messageId);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: isSelected
                ? NearTheme.primary.withAlpha(30)
                : Colors.transparent,
            child: Row(
              children: [
                // Checkbox (only in selection mode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelectionMode ? 48 : 0,
                  child: isSelectionMode
                      ? Center(
                          child: _SelectionCheckbox(isSelected: isSelected),
                        )
                      : null,
                ),

                // Message content
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectionCheckbox extends StatelessWidget {
  final bool isSelected;

  const _SelectionCheckbox({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? NearTheme.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? NearTheme.primary : Colors.grey,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }
}

/// Selection Counter Badge
class SelectionCountBadge extends StatelessWidget {
  final MultiSelectController controller;

  const SelectionCountBadge({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.hasSelection) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: NearTheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${controller.selectedCount}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
      },
    );
  }
}

/// Confirm Delete Dialog
class ConfirmDeleteDialog extends StatelessWidget {
  final int count;
  final bool forEveryone;

  const ConfirmDeleteDialog({
    super.key,
    required this.count,
    this.forEveryone = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int count,
    bool showForEveryone = true,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        count: count,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '$count mesajı sil?',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      content: Text(
        'Bu işlem geri alınamaz.',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'İptal',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Sil',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

/// Forward Messages Sheet
class ForwardMessagesSheet extends StatefulWidget {
  final int messageCount;
  final List<ForwardContact> contacts;
  final Function(List<String> contactIds) onForward;

  const ForwardMessagesSheet({
    super.key,
    required this.messageCount,
    required this.contacts,
    required this.onForward,
  });

  static Future<void> show(
    BuildContext context, {
    required int messageCount,
    required List<ForwardContact> contacts,
    required Function(List<String> contactIds) onForward,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ForwardMessagesSheet(
          messageCount: messageCount,
          contacts: contacts,
          onForward: onForward,
        ),
      ),
    );
  }

  @override
  State<ForwardMessagesSheet> createState() => _ForwardMessagesSheetState();
}

class _ForwardMessagesSheetState extends State<ForwardMessagesSheet> {
  final Set<String> _selectedContacts = {};
  String _searchQuery = '';

  List<ForwardContact> get _filteredContacts {
    if (_searchQuery.isEmpty) return widget.contacts;
    return widget.contacts
        .where(
            (c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
                Text(
                  '${widget.messageCount} mesajı ilet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_selectedContacts.isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      widget.onForward(_selectedContacts.toList());
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NearTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Gönder (${_selectedContacts.length})'),
                  ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Kişi ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Contact list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                final isSelected = _selectedContacts.contains(contact.id);

                return ListTile(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedContacts.remove(contact.id);
                      } else {
                        _selectedContacts.add(contact.id);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                  leading: CircleAvatar(
                    backgroundColor: NearTheme.primary.withAlpha(50),
                    child: Text(
                      contact.name[0].toUpperCase(),
                      style: TextStyle(color: NearTheme.primary),
                    ),
                  ),
                  title: Text(
                    contact.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  trailing: _SelectionCheckbox(isSelected: isSelected),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Forward contact model
class ForwardContact {
  final String id;
  final String name;
  final String? avatar;

  const ForwardContact({
    required this.id,
    required this.name,
    this.avatar,
  });
}
