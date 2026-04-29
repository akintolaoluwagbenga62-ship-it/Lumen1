import 'package:flutter/material.dart';

class LumenTheme {
  // Light
  static const Color bgLight = Color(0xFFF8F8F7);
  static const Color bg1Light = Color(0xFFFFFFFF);
  static const Color bg2Light = Color(0xFFF2F1EF);
  static const Color bg3Light = Color(0xFFEAE9E6);
  static const Color bg4Light = Color(0xFFDDDBD6);
  static const Color textLight = Color(0xFF1A1A18);
  static const Color textMutedLight = Color(0xFF8A8880);
  static const Color textSecondaryLight = Color(0xFF4A4A48);
  static const Color accentLight = Color(0xFF1A1A18);
  static const Color glassBorderLight = Color(0x178A8880);

  // Dark
  static const Color bgDark = Color(0xFF0A0A0C);
  static const Color bg1Dark = Color(0xFF111114);
  static const Color bg2Dark = Color(0xFF18181C);
  static const Color bg3Dark = Color(0xFF202025);
  static const Color bg4Dark = Color(0xFF2A2A30);
  static const Color textDark = Color(0xFFF0EFF8);
  static const Color textMutedDark = Color(0xFF6B6880);
  static const Color textSecondaryDark = Color(0xFF9993B4);
  static const Color accentDark = Color(0xFFA78BFA);
  static const Color glassBorderDark = Color(0x1AF0EFF8);

  // Shared
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerDark = Color(0xFFFB7185);
  static const Color success = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF34D399);
  static const Color warning = Color(0xFFCA8A04);
  static const Color gold = Color(0xFFB45309);
  static const Color goldDark = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF3B82F6);

  static InputDecorationTheme _inputTheme(Color fill, Color border, Color focus) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: focus, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    colorScheme: const ColorScheme.light(
      primary: accentLight,
      surface: bg1Light,
      onSurface: textLight,
      error: danger,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: bgLight,
      foregroundColor: textLight,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgLight,
    ),
    inputDecorationTheme: _inputTheme(bg2Light, glassBorderLight, accentLight),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: accentDark,
      surface: bg1Dark,
      onSurface: textDark,
      error: dangerDark,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      foregroundColor: textDark,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgDark,
    ),
    inputDecorationTheme: _inputTheme(bg2Dark, glassBorderDark, accentDark),
  );
}

extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg => isDark ? LumenTheme.bgDark : LumenTheme.bgLight;
  Color get bg1 => isDark ? LumenTheme.bg1Dark : LumenTheme.bg1Light;
  Color get bg2 => isDark ? LumenTheme.bg2Dark : LumenTheme.bg2Light;
  Color get bg3 => isDark ? LumenTheme.bg3Dark : LumenTheme.bg3Light;
  Color get bg4 => isDark ? LumenTheme.bg4Dark : LumenTheme.bg4Light;
  Color get textColor => isDark ? LumenTheme.textDark : LumenTheme.textLight;
  Color get textMuted => isDark ? LumenTheme.textMutedDark : LumenTheme.textMutedLight;
  Color get textSecondary => isDark ? LumenTheme.textSecondaryDark : LumenTheme.textSecondaryLight;
  Color get accent => isDark ? LumenTheme.accentDark : LumenTheme.accentLight;
  Color get accentDim => isDark ? const Color(0x1AA78BFA) : const Color(0x111A1A18);
  Color get glassBorder => isDark ? LumenTheme.glassBorderDark : LumenTheme.glassBorderLight;
  Color get dangerColor => isDark ? LumenTheme.dangerDark : LumenTheme.danger;
  Color get successColor => isDark ? LumenTheme.successDark : LumenTheme.success;
  Color get goldColor => isDark ? LumenTheme.goldDark : LumenTheme.gold;
}
