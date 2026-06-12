import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // We use Nunito across the board for its highly readable, soft, rounded, and approachable aesthetic.
  static final TextTheme _appTextTheme = TextTheme(
    displayLarge: GoogleFonts.nunito(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -0.5),
    titleLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w500),
    bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
  );

  // Soft Healthcare Palette
  static const Color primaryTeal = Color(0xFF006D77); // Calming, trustworthy primary
  static const Color accentTeal = Color(0xFF83C5BE);  // Soft highlight
  static const Color softBackground = Color(0xFFEDF6F9); // Warm neutral background
  static const Color coralAccent = Color(0xFFE29578); // Very soft, non-alarming accent for actions

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: softBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      brightness: Brightness.light,
      primary: primaryTeal,
      secondary: accentTeal,
      tertiary: coralAccent,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFE0EBEB), // Soft grey-teal for cards
    ),
    textTheme: _appTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryTeal,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1, // Flatter, calmer shadows
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryTeal,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryTeal,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryTeal,
      brightness: Brightness.dark,
      primary: accentTeal, // Use the lighter teal as primary in dark mode for contrast
      secondary: primaryTeal,
      tertiary: coralAccent,
    ),
    textTheme: _appTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color(0xFF121212),
        backgroundColor: accentTeal,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentTeal,
      foregroundColor: Color(0xFF121212),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
  );
}
