import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  final bool isDarkMode;
  AppColors(this.isDarkMode);

  bool get isDark => isDarkMode;

  Color get background => isDarkMode ? Colors.black : Colors.white;
  Color get surface => isDarkMode ? const Color(0xFF111111) : const Color(0xFFF9F9F9);
  Color get primaryText => isDarkMode ? Colors.white : const Color(0xFF111111);
  Color get mutedText => isDarkMode ? const Color(0xFF666666) : const Color(0xFF888888);

  Color get shadow => Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05);

  Color get accent => const Color(0xFF1D9E75);
  Color get accentDarker => const Color(0xFF0F6B4F);
  
  Color get focusInterval => const Color(0xFF3B82F6);
  Color get restInterval => const Color(0xFF10B981);
  Color get warning => const Color(0xFFEF4444);
  
  Color get inputBorder => isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
}

class AppTheme {
  static ThemeData get lightTheme {
    final colors = AppColors(false);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.accent,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: colors.primaryText, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: colors.primaryText, fontSize: 14),
        titleLarge: GoogleFonts.inter(color: colors.primaryText, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      colorScheme: ColorScheme.light(
        primary: colors.accent,
        surface: colors.surface,
        error: colors.warning,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.primaryText,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colors = AppColors(true);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.accent,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(color: colors.primaryText, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: colors.primaryText, fontSize: 14),
        titleLarge: GoogleFonts.inter(color: colors.primaryText, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      colorScheme: ColorScheme.dark(
        primary: colors.accent,
        surface: colors.surface,
        error: colors.warning,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.primaryText,
        elevation: 0,
      ),
    );
  }
}
