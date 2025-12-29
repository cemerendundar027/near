import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Bildirim Badge Widget'ları
/// - Basit sayı badge
/// - Animasyonlu badge
/// - Tab badge
/// - App bar badge
/// - Floating badge

/// Basit Bildirim Badge'i
class NotificationBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool showZero;
  final bool animate;

  const NotificationBadge({
    super.key,
    required this.count,
    this.size = 20,
    this.backgroundColor,
    this.textColor,
    this.showZero = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && !showZero) return const SizedBox.shrink();

    final displayCount = count > 99 ? '99+' : count.toString();
    final bgColor = backgroundColor ?? NearTheme.primary;

    Widget badge = Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: EdgeInsets.symmetric(horizontal: count > 9 ? 6 : 0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          displayCount,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (animate) {
      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.8, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: badge,
      );
    }

    return badge;
  }
}

/// Nokta Badge (sayı olmadan)
class DotBadge extends StatelessWidget {
  final Color? color;
  final double size;
  final bool show;
  final bool pulse;

  const DotBadge({
    super.key,
    this.color,
    this.size = 10,
    this.show = true,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    final dotColor = color ?? NearTheme.primary;

    if (pulse) {
      return _PulsingDot(color: dotColor, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingDot({required this.color, required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: 0.5 + (_animation.value - 0.8) * 1.25,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Badge ile sarmalanmış widget
class BadgeWrapper extends StatelessWidget {
  final Widget child;
  final int count;
  final bool showBadge;
  final AlignmentGeometry alignment;
  final Offset offset;
  final Color? badgeColor;

  const BadgeWrapper({
    super.key,
    required this.child,
    this.count = 0,
    this.showBadge = true,
    this.alignment = Alignment.topRight,
    this.offset = const Offset(0, 0),
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge || count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: alignment == Alignment.topRight || alignment == Alignment.topLeft
              ? -4 + offset.dy
              : null,
          bottom:
              alignment == Alignment.bottomRight ||
                  alignment == Alignment.bottomLeft
              ? -4 + offset.dy
              : null,
          right:
              alignment == Alignment.topRight ||
                  alignment == Alignment.bottomRight
              ? -4 + offset.dx
              : null,
          left:
              alignment == Alignment.topLeft ||
                  alignment == Alignment.bottomLeft
              ? -4 + offset.dx
              : null,
          child: NotificationBadge(
            count: count,
            size: 18,
            backgroundColor: badgeColor,
          ),
        ),
      ],
    );
  }
}

/// Tab Bar için Badge
class TabBadge extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;

  const TabBadge({
    super.key,
    required this.label,
    this.count = 0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : NearTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? NearTheme.primary : Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Avatar ile Badge
class AvatarWithBadge extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final String? initial;
  final int notificationCount;
  final bool isOnline;
  final bool showOnlineIndicator;
  final Color? backgroundColor;

  const AvatarWithBadge({
    super.key,
    this.radius = 24,
    this.imageUrl,
    this.initial,
    this.notificationCount = 0,
    this.isOnline = false,
    this.showOnlineIndicator = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? NearTheme.primary.withAlpha(30),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  initial ?? '?',
                  style: TextStyle(
                    fontSize: radius * 0.75,
                    fontWeight: FontWeight.w600,
                    color: NearTheme.primary,
                  ),
                )
              : null,
        ),
        // Notification Badge
        if (notificationCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: NotificationBadge(
              count: notificationCount,
              size: 18,
              backgroundColor: Colors.red,
            ),
          ),
        // Online Indicator
        if (showOnlineIndicator && isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.5,
              height: radius * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.black : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bottom Navigation Bar Item ile Badge
class NavBarBadge extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int count;
  final bool isSelected;

  const NavBarBadge({
    super.key,
    required this.icon,
    this.activeIcon,
    required this.label,
    this.count = 0,
    this.isSelected = false,
  });

  BottomNavigationBarItem toBottomNavigationBarItem() {
    return BottomNavigationBarItem(
      icon: _buildIcon(false),
      activeIcon: _buildIcon(true),
      label: label,
    );
  }

  Widget _buildIcon(bool active) {
    final displayIcon = active ? (activeIcon ?? icon) : icon;

    if (count <= 0) {
      return Icon(displayIcon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(displayIcon),
        Positioned(
          top: -4,
          right: -8,
          child: NotificationBadge(
            count: count,
            size: 16,
            backgroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildIcon(isSelected);
  }
}

/// Floating Badge (herhangi bir konumda)
class FloatingBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Alignment alignment;
  final EdgeInsets padding;

  const FloatingBadge({
    super.key,
    required this.child,
    this.count = 0,
    this.alignment = Alignment.topRight,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      alignment: alignment,
      children: [
        child,
        Padding(
          padding: padding,
          child: NotificationBadge(count: count, size: 20),
        ),
      ],
    );
  }
}

/// AppBar Action ile Badge
class ActionBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback? onTap;
  final Color? iconColor;

  const ActionBadge({
    super.key,
    required this.icon,
    this.count = 0,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: count > 0
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor),
                Positioned(
                  top: -4,
                  right: -4,
                  child: NotificationBadge(
                    count: count,
                    size: 16,
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            )
          : Icon(icon, color: iconColor),
    );
  }
}

/// Mesajda okunmadı göstergesi
class UnreadIndicator extends StatelessWidget {
  final bool isUnread;
  final Color? color;

  const UnreadIndicator({super.key, this.isUnread = true, this.color});

  @override
  Widget build(BuildContext context) {
    if (!isUnread) return const SizedBox.shrink();

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color ?? NearTheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Mention Badge (@)
class MentionBadge extends StatelessWidget {
  final int count;

  const MentionBadge({super.key, this.count = 0});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: NearTheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alternate_email, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sessize alınmış badge
class MutedBadge extends StatelessWidget {
  final bool isMuted;

  const MutedBadge({super.key, this.isMuted = false});

  @override
  Widget build(BuildContext context) {
    if (!isMuted) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Icon(
      Icons.notifications_off_rounded,
      size: 16,
      color: isDark ? Colors.white38 : Colors.black38,
    );
  }
}

/// Pinlenmiş badge
class PinnedBadge extends StatelessWidget {
  final bool isPinned;

  const PinnedBadge({super.key, this.isPinned = false});

  @override
  Widget build(BuildContext context) {
    if (!isPinned) return const SizedBox.shrink();

    return Icon(Icons.push_pin_rounded, size: 16, color: NearTheme.primary);
  }
}
