import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility Settings - Global state for accessibility preferences
class AccessibilitySettings extends ChangeNotifier {
  static final AccessibilitySettings _instance = AccessibilitySettings._();
  static AccessibilitySettings get instance => _instance;
  AccessibilitySettings._();

  static const String _keyHighContrast = 'accessibility_high_contrast';
  static const String _keyColorBlindMode = 'accessibility_color_blind_mode';
  static const String _keyReduceMotion = 'accessibility_reduce_motion';
  static const String _keyForceRTL = 'accessibility_force_rtl';
  static const String _keyLargeTouchTargets = 'accessibility_large_touch_targets';
  static const String _keyScreenReaderAnnouncements = 'accessibility_screen_reader';
  static const String _keyBoldText = 'accessibility_bold_text';

  bool _initialized = false;

  /// Ayarları yükle (uygulama başlangıcında çağrılmalı)
  Future<void> init() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    _highContrastMode = prefs.getBool(_keyHighContrast) ?? false;
    _colorBlindMode = prefs.getInt(_keyColorBlindMode) ?? 0;
    _reduceMotion = prefs.getBool(_keyReduceMotion) ?? false;
    _forceRTL = prefs.getBool(_keyForceRTL) ?? false;
    _largeTouchTargets = prefs.getBool(_keyLargeTouchTargets) ?? false;
    _screenReaderAnnouncements = prefs.getBool(_keyScreenReaderAnnouncements) ?? true;
    _boldText = prefs.getBool(_keyBoldText) ?? false;
    
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  // High Contrast Mode
  bool _highContrastMode = false;
  bool get highContrastMode => _highContrastMode;
  set highContrastMode(bool value) {
    _highContrastMode = value;
    _saveSetting(_keyHighContrast, value);
    notifyListeners();
  }

  // Color Blind Mode (0: Off, 1: Protanopia, 2: Deuteranopia, 3: Tritanopia)
  int _colorBlindMode = 0;
  int get colorBlindMode => _colorBlindMode;
  set colorBlindMode(int value) {
    _colorBlindMode = value;
    _saveSetting(_keyColorBlindMode, value);
    notifyListeners();
  }

  String get colorBlindModeName {
    switch (_colorBlindMode) {
      case 1:
        return 'Protanopia (Kırmızı-Yeşil)';
      case 2:
        return 'Deuteranopia (Yeşil-Kırmızı)';
      case 3:
        return 'Tritanopia (Mavi-Sarı)';
      default:
        return 'Kapalı';
    }
  }

  // Reduce Motion
  bool _reduceMotion = false;
  bool get reduceMotion => _reduceMotion;
  set reduceMotion(bool value) {
    _reduceMotion = value;
    _saveSetting(_keyReduceMotion, value);
    notifyListeners();
  }

  // RTL Support
  bool _forceRTL = false;
  bool get forceRTL => _forceRTL;
  set forceRTL(bool value) {
    _forceRTL = value;
    _saveSetting(_keyForceRTL, value);
    notifyListeners();
  }

  // Large Touch Targets
  bool _largeTouchTargets = false;
  bool get largeTouchTargets => _largeTouchTargets;
  set largeTouchTargets(bool value) {
    _largeTouchTargets = value;
    _saveSetting(_keyLargeTouchTargets, value);
    notifyListeners();
  }

  // Screen Reader Announcements
  bool _screenReaderAnnouncements = true;
  bool get screenReaderAnnouncements => _screenReaderAnnouncements;
  set screenReaderAnnouncements(bool value) {
    _screenReaderAnnouncements = value;
    _saveSetting(_keyScreenReaderAnnouncements, value);
    notifyListeners();
  }

  // Bold Text
  bool _boldText = false;
  bool get boldText => _boldText;
  set boldText(bool value) {
    _boldText = value;
    _saveSetting(_keyBoldText, value);
    notifyListeners();
  }

  // Reset all settings
  Future<void> resetAll() async {
    _highContrastMode = false;
    _colorBlindMode = 0;
    _reduceMotion = false;
    _forceRTL = false;
    _largeTouchTargets = false;
    _screenReaderAnnouncements = true;
    _boldText = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHighContrast);
    await prefs.remove(_keyColorBlindMode);
    await prefs.remove(_keyReduceMotion);
    await prefs.remove(_keyForceRTL);
    await prefs.remove(_keyLargeTouchTargets);
    await prefs.remove(_keyScreenReaderAnnouncements);
    await prefs.remove(_keyBoldText);
    
    notifyListeners();
  }
}

/// Color Blind Safe Palette
class ColorBlindPalette {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  final Color online;
  final Color offline;

  const ColorBlindPalette({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.online,
    required this.offline,
  });

  /// Normal color palette
  static const normal = ColorBlindPalette(
    primary: Color(0xFF7B3FF2),
    secondary: Color(0xFF5A22C8),
    success: Color(0xFF25D366),
    error: Color(0xFFFF3B30),
    warning: Color(0xFFFF9500),
    info: Color(0xFF007AFF),
    online: Color(0xFF25D366),
    offline: Color(0xFF8E8E93),
  );

  /// Protanopia (Red-Green) - Replace red/green with blue/orange
  static const protanopia = ColorBlindPalette(
    primary: Color(0xFF7B3FF2),
    secondary: Color(0xFF5A22C8),
    success: Color(0xFF0077BB), // Blue instead of green
    error: Color(0xFFEE7733), // Orange instead of red
    warning: Color(0xFFFFDD00),
    info: Color(0xFF33BBEE),
    online: Color(0xFF0077BB),
    offline: Color(0xFF8E8E93),
  );

  /// Deuteranopia (Green-Red) - Similar adjustments
  static const deuteranopia = ColorBlindPalette(
    primary: Color(0xFF7B3FF2),
    secondary: Color(0xFF5A22C8),
    success: Color(0xFF009988), // Teal instead of green
    error: Color(0xFFCC3311), // Dark orange instead of red
    warning: Color(0xFFEE7733),
    info: Color(0xFF0077BB),
    online: Color(0xFF009988),
    offline: Color(0xFF8E8E93),
  );

  /// Tritanopia (Blue-Yellow) - Replace blue/yellow
  static const tritanopia = ColorBlindPalette(
    primary: Color(0xFFEE3377), // Pink instead of purple
    secondary: Color(0xFFCC3311),
    success: Color(0xFF009988),
    error: Color(0xFFEE3377),
    warning: Color(0xFFEE7733),
    info: Color(0xFF33BBEE),
    online: Color(0xFF009988),
    offline: Color(0xFF8E8E93),
  );

  /// Get palette based on mode
  static ColorBlindPalette forMode(int mode) {
    switch (mode) {
      case 1:
        return protanopia;
      case 2:
        return deuteranopia;
      case 3:
        return tritanopia;
      default:
        return normal;
    }
  }
}

/// High contrast theme extension for accessibility
extension AccessibilityTheme on ThemeData {
  ThemeData withHighContrast() {
    return copyWith(
      colorScheme: colorScheme.copyWith(
        primary: const Color(0xFF000000),
        secondary: const Color(0xFF7B3FF2),
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      textTheme: textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
    );
  }
}

/// Semantic wrapper for accessibility
class SemanticWrapper extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final bool isButton;
  final bool isHeader;
  final bool excludeSemantics;
  final VoidCallback? onTap;

  const SemanticWrapper({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.isButton = false,
    this.isHeader = false,
    this.excludeSemantics = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      child: child,
    );
  }
}

/// Focus-aware button that provides visual and haptic feedback
class AccessibleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius,
  });

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onPressed?.call();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              border: _isFocused
                  ? Border.all(color: const Color(0xFF7B3FF2), width: 2)
                  : null,
              color: _isFocused
                  ? (isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05))
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Accessible icon button with proper semantics
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final double size;
  final Color? color;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        icon: Icon(icon, size: size, color: color),
        tooltip: semanticLabel,
      ),
    );
  }
}

/// Text with proper scaling and accessibility
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool selectable;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure minimum font size for readability
    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      fontSize: (style?.fontSize ?? 14).clamp(12.0, double.infinity),
    );

    if (selectable) {
      return SelectableText(
        text,
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Form field with accessibility support
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;

  const AccessibleTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      textField: true,
      label: labelText,
      hint: hintText,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        maxLines: maxLines,
        maxLength: maxLength,
        autofocus: autofocus,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: errorText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          filled: true,
          fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7B3FF2), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
      ),
    );
  }
}

/// Announce messages to screen readers
class ScreenReaderAnnouncer {
  static void announce(BuildContext context, String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  static void announceNewMessage(BuildContext context, String senderName) {
    announce(context, '$senderName\'den yeni mesaj');
  }

  static void announceNotification(BuildContext context, String title) {
    announce(context, 'Bildirim: $title');
  }

  static void announcePageChange(BuildContext context, String pageName) {
    announce(context, '$pageName sayfasına geçildi');
  }
}

/// Reduced motion detector
class ReducedMotionDetector extends StatelessWidget {
  final Widget Function(BuildContext context, bool reduceMotion) builder;

  const ReducedMotionDetector({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion = mediaQuery.disableAnimations;

    return builder(context, reduceMotion);
  }
}

/// Animated widget that respects reduced motion settings
class AccessibleAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;

  const AccessibleAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: decoration,
        alignment: alignment,
        child: child,
      );
    }

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// Tap area size enforcer for accessibility (minimum 48x48)
class AccessibleTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minSize;

  const AccessibleTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AccessibilitySettings.instance;
    final effectiveMinSize = settings.largeTouchTargets
        ? 56.0
        : minSize.toDouble();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: effectiveMinSize,
          minHeight: effectiveMinSize,
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ==================== KEYBOARD NAVIGATION ====================

/// Keyboard navigation handler with shortcuts
class KeyboardNavigationWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEnter;
  final VoidCallback? onEscape;
  final VoidCallback? onTab;
  final VoidCallback? onArrowUp;
  final VoidCallback? onArrowDown;
  final VoidCallback? onArrowLeft;
  final VoidCallback? onArrowRight;

  const KeyboardNavigationWrapper({
    super.key,
    required this.child,
    this.onEnter,
    this.onEscape,
    this.onTab,
    this.onArrowUp,
    this.onArrowDown,
    this.onArrowLeft,
    this.onArrowRight,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(
          TraversalDirection.up,
        ),
        LogicalKeySet(LogicalKeyboardKey.arrowDown):
            const DirectionalFocusIntent(TraversalDirection.down),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft):
            const DirectionalFocusIntent(TraversalDirection.left),
        LogicalKeySet(LogicalKeyboardKey.arrowRight):
            const DirectionalFocusIntent(TraversalDirection.right),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onEnter?.call();
              return null;
            },
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              onEscape?.call();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

/// Focus traversal group for keyboard navigation
class AccessibleFocusGroup extends StatelessWidget {
  final Widget child;
  final FocusTraversalPolicy? policy;
  final bool descendantsAreFocusable;
  final bool descendantsAreTraversable;

  const AccessibleFocusGroup({
    super.key,
    required this.child,
    this.policy,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: policy ?? OrderedTraversalPolicy(),
      descendantsAreFocusable: descendantsAreFocusable,
      descendantsAreTraversable: descendantsAreTraversable,
      child: child,
    );
  }
}

/// Focusable list item for keyboard navigation
class FocusableListItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final int? focusOrder;
  final String? semanticLabel;
  final bool autofocus;

  const FocusableListItem({
    super.key,
    required this.child,
    this.onPressed,
    this.focusOrder,
    this.semanticLabel,
    this.autofocus = false,
  });

  @override
  State<FocusableListItem> createState() => _FocusableListItemState();
}

class _FocusableListItemState extends State<FocusableListItem> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget item = Semantics(
      button: widget.onPressed != null,
      label: widget.semanticLabel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Focus(
          autofocus: widget.autofocus,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.space)) {
              widget.onPressed?.call();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _isFocused
                    ? (isDark ? Colors.white24 : Colors.black12)
                    : _isHovered
                    ? (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05))
                    : Colors.transparent,
                border: _isFocused
                    ? Border.all(color: const Color(0xFF7B3FF2), width: 2)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.focusOrder != null) {
      item = FocusTraversalOrder(
        order: NumericFocusOrder(widget.focusOrder!.toDouble()),
        child: item,
      );
    }

    return item;
  }
}

// ==================== RTL SUPPORT ====================

/// RTL-aware layout wrapper
class RTLAwareLayout extends StatelessWidget {
  final Widget child;

  const RTLAwareLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settings = AccessibilitySettings.instance;

    if (settings.forceRTL) {
      return Directionality(textDirection: TextDirection.rtl, child: child);
    }

    return child;
  }
}

/// RTL-aware row with automatic direction handling
class RTLAwareRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const RTLAwareRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AccessibilitySettings.instance;
    final effectiveChildren = settings.forceRTL
        ? children.reversed.toList()
        : children;

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: effectiveChildren,
    );
  }
}

/// RTL-aware padding
class RTLAwarePadding extends StatelessWidget {
  final Widget child;
  final double? start;
  final double? end;
  final double? top;
  final double? bottom;

  const RTLAwarePadding({
    super.key,
    required this.child,
    this.start,
    this.end,
    this.top,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final isRTL = textDirection == TextDirection.rtl;

    return Padding(
      padding: EdgeInsets.only(
        left: isRTL ? (end ?? 0) : (start ?? 0),
        right: isRTL ? (start ?? 0) : (end ?? 0),
        top: top ?? 0,
        bottom: bottom ?? 0,
      ),
      child: child,
    );
  }
}


// ==================== COLOR BLIND SUPPORT ====================

/// Color blind mode wrapper that adjusts colors
class ColorBlindModeWrapper extends StatelessWidget {
  final Widget child;

  const ColorBlindModeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AccessibilitySettings.instance,
      builder: (context, _) {
        final mode = AccessibilitySettings.instance.colorBlindMode;

        if (mode == 0) {
          return child;
        }

        // ColorFiltered ile renk ayarlaması
        return ColorFiltered(colorFilter: _getColorFilter(mode), child: child);
      },
    );
  }

  ColorFilter _getColorFilter(int mode) {
    switch (mode) {
      case 1: // Protanopia
        return const ColorFilter.matrix(<double>[
          0.567,
          0.433,
          0.0,
          0.0,
          0.0,
          0.558,
          0.442,
          0.0,
          0.0,
          0.0,
          0.0,
          0.242,
          0.758,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
        ]);
      case 2: // Deuteranopia
        return const ColorFilter.matrix(<double>[
          0.625,
          0.375,
          0.0,
          0.0,
          0.0,
          0.7,
          0.3,
          0.0,
          0.0,
          0.0,
          0.0,
          0.3,
          0.7,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
        ]);
      case 3: // Tritanopia
        return const ColorFilter.matrix(<double>[
          0.95,
          0.05,
          0.0,
          0.0,
          0.0,
          0.0,
          0.433,
          0.567,
          0.0,
          0.0,
          0.0,
          0.475,
          0.525,
          0.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }
  }
}

/// Color that adapts to color blind mode
class AccessibleColor {
  /// Get accessible color based on current color blind mode
  static Color adaptColor(Color original, ColorType type) {
    final mode = AccessibilitySettings.instance.colorBlindMode;
    final palette = ColorBlindPalette.forMode(mode);

    switch (type) {
      case ColorType.primary:
        return palette.primary;
      case ColorType.secondary:
        return palette.secondary;
      case ColorType.success:
        return palette.success;
      case ColorType.error:
        return palette.error;
      case ColorType.warning:
        return palette.warning;
      case ColorType.info:
        return palette.info;
      case ColorType.online:
        return palette.online;
      case ColorType.offline:
        return palette.offline;
    }
  }
}

enum ColorType {
  primary,
  secondary,
  success,
  error,
  warning,
  info,
  online,
  offline,
}

// ==================== ACCESSIBILITY SETTINGS SCREEN ====================

/// Accessibility settings screen widget
class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erişilebilirlik'), centerTitle: true),
      body: ListenableBuilder(
        listenable: AccessibilitySettings.instance,
        builder: (context, _) {
          final settings = AccessibilitySettings.instance;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Görsel Ayarlar
              _buildSectionHeader(context, 'Görsel Ayarlar'),
              _buildSwitchTile(
                context,
                title: 'Yüksek Kontrast Modu',
                subtitle: 'Daha belirgin renkler ve kontrastlar',
                value: settings.highContrastMode,
                onChanged: (v) => settings.highContrastMode = v,
                icon: Icons.contrast,
              ),
              _buildSwitchTile(
                context,
                title: 'Kalın Yazı',
                subtitle: 'Tüm metinleri kalın göster',
                value: settings.boldText,
                onChanged: (v) => settings.boldText = v,
                icon: Icons.format_bold,
              ),
              const SizedBox(height: 8),

              // Renk Körü Modu
              _buildSectionHeader(context, 'Renk Görme Desteği'),
              _buildColorBlindSelector(context, settings),
              const SizedBox(height: 16),

              // Hareket Ayarları
              _buildSectionHeader(context, 'Hareket Ayarları'),
              _buildSwitchTile(
                context,
                title: 'Azaltılmış Hareket',
                subtitle: 'Animasyonları devre dışı bırak',
                value: settings.reduceMotion,
                onChanged: (v) => settings.reduceMotion = v,
                icon: Icons.animation,
              ),
              const SizedBox(height: 8),

              // Etkileşim Ayarları
              _buildSectionHeader(context, 'Etkileşim Ayarları'),
              _buildSwitchTile(
                context,
                title: 'Büyük Dokunma Alanları',
                subtitle: 'Butonları daha kolay tıklanabilir yap',
                value: settings.largeTouchTargets,
                onChanged: (v) => settings.largeTouchTargets = v,
                icon: Icons.touch_app,
              ),
              _buildSwitchTile(
                context,
                title: 'Ekran Okuyucu Bildirimleri',
                subtitle: 'VoiceOver/TalkBack için sesli bildirimler',
                value: settings.screenReaderAnnouncements,
                onChanged: (v) => settings.screenReaderAnnouncements = v,
                icon: Icons.record_voice_over,
              ),
              const SizedBox(height: 8),

              // Dil ve Yön
              _buildSectionHeader(context, 'Dil ve Yön'),
              _buildSwitchTile(
                context,
                title: 'Sağdan Sola (RTL)',
                subtitle: 'Arapça, İbranice gibi diller için',
                value: settings.forceRTL,
                onChanged: (v) => settings.forceRTL = v,
                icon: Icons.format_textdirection_r_to_l,
              ),
              const SizedBox(height: 24),

              // Sıfırla butonu
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await settings.resetAll();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erişilebilirlik ayarları sıfırlandı'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Tüm Ayarları Sıfırla'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildColorBlindSelector(
    BuildContext context,
    AccessibilitySettings settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Renk Körü Modu', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Seçili: ${settings.colorBlindModeName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _colorBlindChip(context, settings, 0, 'Kapalı'),
                _colorBlindChip(context, settings, 1, 'Protanopia'),
                _colorBlindChip(context, settings, 2, 'Deuteranopia'),
                _colorBlindChip(context, settings, 3, 'Tritanopia'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorBlindChip(
    BuildContext context,
    AccessibilitySettings settings,
    int mode,
    String label,
  ) {
    final isSelected = settings.colorBlindMode == mode;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => settings.colorBlindMode = mode,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

// ==================== ACCESSIBILITY PROVIDER ====================

/// Accessibility wrapper that applies all settings
class AccessibilityWrapper extends StatelessWidget {
  final Widget child;

  const AccessibilityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AccessibilitySettings.instance,
      builder: (context, _) {
        final settings = AccessibilitySettings.instance;

        Widget result = child;

        // Apply RTL if needed
        if (settings.forceRTL) {
          result = Directionality(
            textDirection: TextDirection.rtl,
            child: result,
          );
        }

        // Apply color blind filter if needed
        if (settings.colorBlindMode > 0) {
          result = ColorBlindModeWrapper(child: result);
        }

        return result;
      },
    );
  }
}

/// Skip link for keyboard navigation (web accessibility)
class SkipToContentLink extends StatelessWidget {
  final VoidCallback onActivate;
  final String label;

  const SkipToContentLink({
    super.key,
    required this.onActivate,
    this.label = 'Ana içeriğe atla',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            onActivate();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;

            if (!isFocused) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF7B3FF2),
              child: Text(label, style: const TextStyle(color: Colors.white)),
            );
          },
        ),
      ),
    );
  }
}
