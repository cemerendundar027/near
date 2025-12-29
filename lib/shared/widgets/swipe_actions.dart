import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

/// Swipeable message widget
/// Sağa kaydır: Reply
/// Sola kaydır: More options (delete, forward, etc.)
class SwipeableMessage extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onForward;
  final VoidCallback? onMore;
  final bool isMe;

  const SwipeableMessage({
    super.key,
    required this.child,
    required this.onReply,
    this.onDelete,
    this.onForward,
    this.onMore,
    this.isMe = false,
  });

  @override
  State<SwipeableMessage> createState() => _SwipeableMessageState();
}

class _SwipeableMessageState extends State<SwipeableMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  double _dragExtent = 0;
  bool _hasTriggered = false;

  static const double _triggerThreshold = 60;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      // Sağa kaydırma için sınır (reply)
      if (_dragExtent > 0) {
        _dragExtent = _dragExtent.clamp(0, _triggerThreshold * 1.5);
      }
      // Sola kaydırma için sınır (more)
      else {
        _dragExtent = _dragExtent.clamp(-_triggerThreshold * 1.5, 0);
      }
    });

    // Trigger haptic feedback at threshold
    if (!_hasTriggered && _dragExtent.abs() >= _triggerThreshold) {
      _hasTriggered = true;
      HapticFeedback.mediumImpact();
    } else if (_hasTriggered && _dragExtent.abs() < _triggerThreshold) {
      _hasTriggered = false;
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent >= _triggerThreshold) {
      // Reply triggered
      HapticFeedback.lightImpact();
      widget.onReply();
    } else if (_dragExtent <= -_triggerThreshold && widget.onMore != null) {
      // More options triggered
      HapticFeedback.lightImpact();
      widget.onMore!();
    }

    // Animate back to start
    _animation = Tween<Offset>(
      begin: Offset(_dragExtent / 100, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward(from: 0);

    setState(() {
      _dragExtent = 0;
      _hasTriggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_dragExtent.abs() / _triggerThreshold).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Background action indicators
        Positioned.fill(
          child: Row(
            children: [
              // Reply indicator (left side - shown when swiping right)
              if (_dragExtent > 0)
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: AnimatedOpacity(
                    opacity: progress,
                    duration: const Duration(milliseconds: 100),
                    child: Transform.scale(
                      scale: 0.5 + (progress * 0.5),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: NearTheme.primary.withAlpha(
                            (progress * 255).round(),
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.reply_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              // More indicator (right side - shown when swiping left)
              if (_dragExtent < 0)
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: AnimatedOpacity(
                    opacity: progress,
                    duration: const Duration(milliseconds: 100),
                    child: Transform.scale(
                      scale: 0.5 + (progress * 0.5),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white24 : Colors.grey.shade300)
                              .withAlpha((progress * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.more_horiz,
                          color: isDark ? Colors.white : Colors.black54,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Message content
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = _controller.isAnimating
                  ? _animation.value
                  : Offset(_dragExtent / 100, 0);
              return Transform.translate(
                offset: Offset(offset.dx * 100, 0),
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// Swipeable chat list item
/// Sağa kaydır: Arşivle
/// Sola kaydır: Sil / Pin
class SwipeableChatTile extends StatelessWidget {
  final Widget child;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback? onPin;
  final bool isPinned;

  const SwipeableChatTile({
    super.key,
    required this.child,
    required this.onArchive,
    required this.onDelete,
    this.onPin,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Archive
          HapticFeedback.mediumImpact();
          onArchive();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Show options
          HapticFeedback.lightImpact();
          return await _showOptions(context);
        }
        return false;
      },
      background: Container(
        color: NearTheme.primary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.archive_rounded, color: Colors.white),
            const SizedBox(height: 4),
            const Text(
              'Arşivle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white),
            const SizedBox(height: 4),
            const Text(
              'Sil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }

  Future<bool> _showOptions(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                  if (onPin != null)
                    ListTile(
                      leading: Icon(
                        isPinned
                            ? Icons.push_pin_outlined
                            : Icons.push_pin_rounded,
                        color: NearTheme.primary,
                      ),
                      title: Text(isPinned ? 'Sabitlemeyi kaldır' : 'Sabitle'),
                      onTap: () {
                        Navigator.pop(ctx, false);
                        onPin!();
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.archive_rounded),
                    title: const Text('Arşivle'),
                    onTap: () {
                      Navigator.pop(ctx, false);
                      onArchive();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_rounded, color: Colors.red),
                    title: const Text(
                      'Sil',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(ctx, true);
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('İptal'),
                    onTap: () => Navigator.pop(ctx, false),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }
}
