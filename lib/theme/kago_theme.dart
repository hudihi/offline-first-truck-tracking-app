import 'package:flutter/material.dart';

class KagoTheme {
  // Brand colors
  static const Color orange = Color(0xFFE85D04);
  static const Color orangeDark = Color(0xFFC44B02);
  static const Color darkBg = Color(0xFF1A1A2E);
  static const Color cardBg = Color(0xFF16213E);
  static const Color deepBlue = Color(0xFF0F3460);
  static const Color green = Color(0xFF06D6A0);
  static const Color red = Color(0xFFEF233C);
  static const Color amber = Color(0xFFFFB703);
  static const Color grey = Color(0xFF8B8FA8);
  static const Color border = Color(0x14FFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        secondary: green,
        surface: cardBg,
        error: red,
        onPrimary: Colors.white,
        onSurface: Color(0xFFE8EAF0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE8EAF0),
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFFE8EAF0)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: orange,
        unselectedItemColor: grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0AFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: grey,
          fontFamily: 'SpaceGrotesk',
          fontSize: 11,
          letterSpacing: 0.3,
        ),
        hintStyle: const TextStyle(
          color: Color(0x33FFFFFF),
          fontFamily: 'SpaceGrotesk',
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, color: Color(0xFFE8EAF0)),
        titleLarge: TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFFE8EAF0)),
        titleMedium: TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFFE8EAF0)),
        titleSmall: TextStyle(fontFamily: 'SpaceGrotesk', fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFE8EAF0)),
        bodyLarge: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 14, color: Color(0xFFE8EAF0)),
        bodyMedium: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 13, color: Color(0xFFE8EAF0)),
        bodySmall: TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 11, color: grey),
        labelSmall: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, color: grey, letterSpacing: 0.5),
      ),
    );
  }
}
