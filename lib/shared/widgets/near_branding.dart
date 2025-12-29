import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

/// Near logo text widget with custom styling
/// Uses Nunito font (bold, rounded) with Near's purple color
class NearLogo extends StatelessWidget {
  final double fontSize;
  final bool showVersion;
  final Color? color;

  const NearLogo({
    super.key,
    this.fontSize = 28,
    this.showVersion = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? NearTheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'near',
          style: GoogleFonts.nunito(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        if (showVersion) ...[
          const SizedBox(width: 4),
          Text(
            'v1.0.0',
            style: GoogleFonts.nunito(
              fontSize: fontSize * 0.4,
              fontWeight: FontWeight.w600,
              color: textColor.withAlpha(150),
            ),
          ),
        ],
      ],
    );
  }
}

/// Near logo text as a simple Text widget (for inline use)
class NearLogoText extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final FontWeight? fontWeight;

  const NearLogoText({
    super.key,
    this.fontSize = 16,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'near',
      style: GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w800,
        color: color ?? NearTheme.primary,
        letterSpacing: -0.3,
      ),
    );
  }
}

/// Near app icon widget
/// Shows the purple gradient chat bubble icon
class NearIcon extends StatelessWidget {
  final double size;
  final bool showShadow;
  final double borderRadius;

  const NearIcon({
    super.key,
    this.size = 60,
    this.showShadow = true,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8D5FF), // Light purple
            const Color(0xFFD4B8FF), // Medium purple
            const Color(0xFFC9A8FF), // Darker purple
          ],
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: NearTheme.primary.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background chat bubble (upper right)
          Positioned(
            top: size * 0.15,
            right: size * 0.12,
            child: _ChatBubble(
              size: size * 0.4,
              color: const Color(0xFF8B5CF6), // Solid purple
              showDots: false,
            ),
          ),
          // Foreground chat bubble with dots (lower left)
          Positioned(
            bottom: size * 0.18,
            left: size * 0.12,
            child: _ChatBubble(
              size: size * 0.48,
              color: const Color(0xFF9B6DFF), // Lighter purple
              showDots: true,
              hasBorder: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final double size;
  final Color color;
  final bool showDots;
  final bool hasBorder;

  const _ChatBubble({
    required this.size,
    required this.color,
    this.showDots = false,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.75,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.3),
          topRight: Radius.circular(size * 0.3),
          bottomRight: Radius.circular(size * 0.3),
          bottomLeft: Radius.circular(size * 0.08),
        ),
        border: hasBorder
            ? Border.all(
                color: Colors.white.withAlpha(180),
                width: size * 0.04,
              )
            : null,
      ),
      child: showDots
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Container(
                  margin: EdgeInsets.symmetric(horizontal: size * 0.04),
                  width: size * 0.1,
                  height: size * 0.1,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(220),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// Near branded version text
class NearVersionText extends StatelessWidget {
  final bool showBuildNumber;
  final Color? color;

  const NearVersionText({
    super.key,
    this.showBuildNumber = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = color ?? (isDark ? Colors.white38 : Colors.black38);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NearLogoText(
          fontSize: 13,
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
        Text(
          showBuildNumber ? ' v1.0.0 (Build 1)' : ' v1.0.0',
          style: TextStyle(
            fontSize: 13,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
