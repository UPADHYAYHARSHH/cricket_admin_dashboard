import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryDarkGreen,
        secondary: AppColors.accentOrange,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: AppColors.lightTextPrimary),
        displayMedium: GoogleFonts.outfit(color: AppColors.lightTextPrimary),
        bodyLarge: GoogleFonts.outfit(color: AppColors.lightTextPrimary),
        bodyMedium: GoogleFonts.outfit(color: AppColors.lightTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
      ),
      dividerColor: AppColors.lightBorder,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDarkGreen,
        secondary: AppColors.accentOrange,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: AppColors.darkTextPrimary),
        displayMedium: GoogleFonts.outfit(color: AppColors.darkTextPrimary),
        bodyLarge: GoogleFonts.outfit(color: AppColors.darkTextPrimary),
        bodyMedium: GoogleFonts.outfit(color: AppColors.darkTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
      ),
      dividerColor: AppColors.darkBorder,
    );
  }
}
