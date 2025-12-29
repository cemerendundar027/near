import 'package:flutter/material.dart';

/// Disappearing messages indicator widget
class DisappearingIndicator extends StatelessWidget {
  final Duration duration;
  final double progress;
  final double size;
  final Color? color;

  const DisappearingIndicator({
    super.key,
    required this.duration,
    this.progress = 0.0,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indicatorColor = color ?? (isDark ? Colors.white54 : Colors.black45);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 1.5,
            backgroundColor: Colors.transparent,
            color: indicatorColor.withValues(alpha: 0.3),
          ),
          // Progress circle
          CircularProgressIndicator(
            value: 1.0 - progress,
            strokeWidth: 1.5,
            backgroundColor: Colors.transparent,
            color: indicatorColor,
          ),
          // Timer icon
          Icon(Icons.timer_outlined, size: size * 0.6, color: indicatorColor),
        ],
      ),
    );
  }
}

/// Animated disappearing indicator with countdown
class AnimatedDisappearingIndicator extends StatefulWidget {
  final Duration duration;
  final DateTime startTime;
  final double size;
  final Color? color;
  final VoidCallback? onExpired;

  const AnimatedDisappearingIndicator({
    super.key,
    required this.duration,
    required this.startTime,
    this.size = 16,
    this.color,
    this.onExpired,
  });

  @override
  State<AnimatedDisappearingIndicator> createState() =>
      _AnimatedDisappearingIndicatorState();
}

class _AnimatedDisappearingIndicatorState
    extends State<AnimatedDisappearingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    final elapsed = DateTime.now().difference(widget.startTime);
    final remaining = widget.duration - elapsed;
    final progress = elapsed.inMilliseconds / widget.duration.inMilliseconds;

    _controller = AnimationController(
      vsync: this,
      duration: remaining.isNegative ? Duration.zero : remaining,
      value: progress.clamp(0.0, 1.0),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onExpired?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return DisappearingIndicator(
          duration: widget.duration,
          progress: _controller.value,
          size: widget.size,
          color: widget.color,
        );
      },
    );
  }
}

/// Disappearing messages settings selector
class DisappearingMessagesSelector extends StatelessWidget {
  final Duration? selectedDuration;
  final void Function(Duration?)? onDurationSelected;

  const DisappearingMessagesSelector({
    super.key,
    this.selectedDuration,
    this.onDurationSelected,
  });

  static const _durations = [
    null, // Off
    Duration(hours: 24),
    Duration(days: 7),
    Duration(days: 90),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B3FF2).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: Color(0xFF7B3FF2),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kaybolan Mesajlar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Açıldığında mesajlar belirli süre sonra silinir',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
        ...List.generate(_durations.length, (index) {
          final duration = _durations[index];
          final isSelected = selectedDuration == duration;

          return _DurationOption(
            duration: duration,
            isSelected: isSelected,
            onTap: () => onDurationSelected?.call(duration),
          );
        }),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Kaybolan mesajları açtığınızda, bu sohbetteki yeni mesajlar seçilen süre sonunda tüm cihazlardan silinir.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      ],
    );
  }
}

class _DurationOption extends StatelessWidget {
  final Duration? duration;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DurationOption({
    required this.duration,
    required this.isSelected,
    this.onTap,
  });

  String _formatDuration(Duration? d) {
    if (d == null) return 'Kapalı';
    if (d.inDays >= 90) return '90 gün';
    if (d.inDays >= 7) return '7 gün';
    if (d.inHours >= 24) return '24 saat';
    return '${d.inHours} saat';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              duration == null
                  ? Icons.timer_off_outlined
                  : Icons.timer_outlined,
              size: 22,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF7B3FF2), size: 22),
          ],
        ),
      ),
    );
  }
}

/// Chat header badge showing disappearing messages status
class DisappearingMessagesBadge extends StatelessWidget {
  final Duration duration;

  const DisappearingMessagesBadge({super.key, required this.duration});

  String _formatShort(Duration d) {
    if (d.inDays >= 90) return '90g';
    if (d.inDays >= 7) return '7g';
    if (d.inHours >= 24) return '24s';
    return '${d.inHours}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF7B3FF2).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 12,
            color: isDark ? const Color(0xFF7B3FF2) : const Color(0xFF5A22C8),
          ),
          const SizedBox(width: 4),
          Text(
            _formatShort(duration),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF7B3FF2) : const Color(0xFF5A22C8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for configuring disappearing messages
class DisappearingMessagesSheet extends StatelessWidget {
  final Duration currentDuration;
  final ValueChanged<Duration> onDurationChanged;

  const DisappearingMessagesSheet({
    super.key,
    required this.currentDuration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final durations = [
      (Duration.zero, 'Kapalı', 'Mesajlar kaybolmaz'),
      (const Duration(hours: 24), '24 saat', 'Mesajlar 24 saat sonra silinir'),
      (const Duration(days: 7), '7 gün', 'Mesajlar 7 gün sonra silinir'),
      (const Duration(days: 90), '90 gün', 'Mesajlar 90 gün sonra silinir'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 48,
                    color: const Color(0xFF7B3FF2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kaybolan Mesajlar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seçtiğiniz süre sonunda mesajlar otomatik olarak silinir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            // ignore: deprecated_member_use - Radio groupValue ve onChanged Flutter 3.32+'da deprecated
            ...durations.map(
              (d) => ListTile(
                leading: Radio<Duration>(
                  value: d.$1,
                  // ignore: deprecated_member_use
                  groupValue: currentDuration,
                  activeColor: const Color(0xFF7B3FF2),
                  // ignore: deprecated_member_use
                  onChanged: (value) {
                    if (value != null) {
                      onDurationChanged(value);
                    }
                  },
                ),
                title: Text(
                  d.$2,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  d.$3,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                onTap: () => onDurationChanged(d.$1),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
