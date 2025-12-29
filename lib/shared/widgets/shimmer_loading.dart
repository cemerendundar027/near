import 'package:flutter/material.dart';

/// Shimmer Loading Widget
/// - Skeleton placeholder animasyonu
/// - Chat listesi, mesaj listesi için
/// - Farklı şekiller destekler
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ??
        (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300);
    final highlightColor = widget.highlightColor ??
        (isDark ? const Color(0xFF3C3C3E) : Colors.grey.shade100);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Shimmer Box - Basit dikdörtgen placeholder
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer Circle - Yuvarlak placeholder (avatar için)
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Chat List Item Shimmer
class ChatListItemShimmer extends StatelessWidget {
  const ChatListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const ShimmerCircle(size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: ShimmerBox(height: 16, width: 120),
                      ),
                      const SizedBox(width: 8),
                      ShimmerBox(height: 12, width: 40, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const ShimmerBox(height: 14, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat List Shimmer - Birden fazla item
class ChatListShimmer extends StatelessWidget {
  final int itemCount;

  const ChatListShimmer({
    super.key,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ChatListItemShimmer(),
    );
  }
}

/// Message Shimmer - Tek mesaj placeholder
class MessageShimmer extends StatelessWidget {
  final bool isMe;

  const MessageShimmer({
    super.key,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isMe ? 80 : 16,
            right: isMe ? 16 : 80,
            top: 4,
            bottom: 4,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerBox(height: 14, width: isMe ? 100 : 150),
              const SizedBox(height: 6),
              ShimmerBox(height: 14, width: isMe ? 80 : 120),
            ],
          ),
        ),
      ),
    );
  }
}

/// Message List Shimmer
class MessageListShimmer extends StatelessWidget {
  final int itemCount;

  const MessageListShimmer({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      reverse: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => MessageShimmer(isMe: index % 3 == 0),
    );
  }
}

/// Story Item Shimmer
class StoryItemShimmer extends StatelessWidget {
  const StoryItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 4),
          const ShimmerBox(height: 10, width: 50),
        ],
      ),
    );
  }
}

/// Story List Shimmer
class StoryListShimmer extends StatelessWidget {
  final int itemCount;

  const StoryListShimmer({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => const StoryItemShimmer(),
      ),
    );
  }
}

/// Profile Header Shimmer
class ProfileHeaderShimmer extends StatelessWidget {
  const ProfileHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          const ShimmerCircle(size: 100),
          const SizedBox(height: 16),
          const ShimmerBox(height: 24, width: 150),
          const SizedBox(height: 8),
          ShimmerBox(height: 14, width: 200, borderRadius: 7),
        ],
      ),
    );
  }
}

/// Settings Item Shimmer
class SettingsItemShimmer extends StatelessWidget {
  const SettingsItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const ShimmerCircle(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(height: 16, width: 120),
                  SizedBox(height: 4),
                  ShimmerBox(height: 12, width: 180),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic Card Shimmer
class CardShimmer extends StatelessWidget {
  final double height;

  const CardShimmer({
    super.key,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Media Grid Shimmer
class MediaGridShimmer extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const MediaGridShimmer({
    super.key,
    this.itemCount = 9,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          color: Colors.white,
        ),
      ),
    );
  }
}
