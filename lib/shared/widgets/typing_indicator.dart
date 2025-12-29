import 'package:flutter/material.dart';

/// Typing indicator dots animation
class TypingIndicator extends StatefulWidget {
  final double dotSize;
  final Color? color;

  const TypingIndicator({super.key, this.dotSize = 8, this.color});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: -8,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    // Start animations with staggered delay
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor =
        widget.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white54
            : Colors.black45);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                width: widget.dotSize,
                height: widget.dotSize,
                margin: EdgeInsets.symmetric(horizontal: widget.dotSize / 4),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Typing bubble that contains the typing indicator
class TypingBubble extends StatelessWidget {
  final String? userName;

  const TypingBubble({super.key, this.userName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      userName!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B3FF2),
                      ),
                    ),
                  ),
                const TypingIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Message status indicator (sent, delivered, read)
class MessageStatus extends StatelessWidget {
  final MessageStatusType status;
  final double size;
  final Color? color;

  const MessageStatus({
    super.key,
    required this.status,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = color ?? _getStatusColor();

    switch (status) {
      case MessageStatusType.sending:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: statusColor,
          ),
        );
      case MessageStatusType.sent:
        return Icon(Icons.check, size: size, color: statusColor);
      case MessageStatusType.delivered:
        return SizedBox(
          width: size + 4,
          height: size,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Icon(Icons.check, size: size, color: statusColor),
              ),
              Positioned(
                left: 6,
                child: Icon(Icons.check, size: size, color: statusColor),
              ),
            ],
          ),
        );
      case MessageStatusType.read:
        return SizedBox(
          width: size + 4,
          height: size,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Icon(
                  Icons.check,
                  size: size,
                  color: const Color(0xFF34B7F1),
                ),
              ),
              Positioned(
                left: 6,
                child: Icon(
                  Icons.check,
                  size: size,
                  color: const Color(0xFF34B7F1),
                ),
              ),
            ],
          ),
        );
      case MessageStatusType.failed:
        return Icon(Icons.error_outline, size: size, color: Colors.red);
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case MessageStatusType.sending:
      case MessageStatusType.sent:
      case MessageStatusType.delivered:
        return Colors.white70;
      case MessageStatusType.read:
        return const Color(0xFF34B7F1);
      case MessageStatusType.failed:
        return Colors.red;
    }
  }
}

enum MessageStatusType { sending, sent, delivered, read, failed }

/// Online status indicator
class OnlineIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;

  const OnlineIndicator({super.key, required this.isOnline, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF4CAF50) : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      ),
    );
  }
}

/// Last seen status text
class LastSeenText extends StatelessWidget {
  final DateTime? lastSeen;
  final bool isOnline;
  final TextStyle? style;

  const LastSeenText({
    super.key,
    this.lastSeen,
    this.isOnline = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultStyle = TextStyle(
      fontSize: 12,
      color: isDark ? Colors.white54 : Colors.black54,
    );

    if (isOnline) {
      return Text(
        'çevrimiçi',
        style: (style ?? defaultStyle).copyWith(color: const Color(0xFF4CAF50)),
      );
    }

    if (lastSeen == null) {
      return Text('son görülme gizli', style: style ?? defaultStyle);
    }

    return Text(_formatLastSeen(lastSeen!), style: style ?? defaultStyle);
  }

  String _formatLastSeen(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'az önce görüldü';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dakika önce görüldü';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce görüldü';
    } else if (diff.inDays == 1) {
      return 'dün ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} görüldü';
    } else if (diff.inDays < 7) {
      final days = ['Pzr', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
      return '${days[time.weekday % 7]} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} görüldü';
    } else {
      return '${time.day}/${time.month}/${time.year} görüldü';
    }
  }
}
