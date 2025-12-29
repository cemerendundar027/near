import 'package:flutter/material.dart';

class NearTheme {
  // Brand colors (near eflatun)
  static const Color primary = Color(0xFF7B3FF2);      // ana eflatun
  static const Color primaryDark = Color(0xFF5A22C8);  // koyu eflatun
  static const Color primarySoft = Color(0xFFE9DEFF);  // çok açık eflatun

  // Chat bubble tones
  static const Color myBubble = Color(0xFF6C2FEA);     // bizim mesaj
  static const Color theirBubble = Color(0xFFE6DAFF);  // karşı taraf

  // withOpacity deprecated -> güvenli alpha helper
  static Color _alpha(Color c, double opacity) =>
      c.withAlpha((opacity * 255).round().clamp(0, 255));

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
    );

    final divider = _alpha(Colors.black, 0.06);
    final border = _alpha(Colors.black, 0.08);

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F7FB),
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: primaryDark,
        surface: Colors.white,
      ),

      // Cursor / selection
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x337B3FF2),
        selectionHandleColor: primary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: base.colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: base.colorScheme.onSurface),
      ),

      // Text
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.2,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.25,
        ),
      ),

      // Cards ✅ CardThemeData
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: divider),
        ),
        margin: EdgeInsets.zero,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: _alpha(Colors.black, 0.45)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: Colors.black54,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
      ),
    );

    final divider = _alpha(Colors.white, 0.10);
    final border = _alpha(Colors.white, 0.12);
    final surface = const Color(0xFF12121A);

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B0B10),
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: primarySoft,
        surface: surface,
      ),

      // Cursor / selection
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0x337B3FF2),
        selectionHandleColor: primary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: base.colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: base.colorScheme.onSurface),
      ),

      // Text
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: Colors.white,
        ),
        titleMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: Colors.white,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.2,
          color: Colors.white,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.25,
          color: Colors.white70,
        ),
      ),

      // Cards ✅ CardThemeData
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: divider),
        ),
        margin: EdgeInsets.zero,
      ),

      // Inputs ✅ Dark uyumlu + yazı görünür
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: _alpha(Colors.white, 0.55)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primary,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        backgroundColor: Color(0xFF0B0B10),
      ),

      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

