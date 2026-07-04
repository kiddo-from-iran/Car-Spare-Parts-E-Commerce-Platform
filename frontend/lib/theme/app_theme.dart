import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8F8F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8F8F8);
  static const sidebarBg = Color(0xFF111111);

  // Brand — premium gold
  static const gold = Color(0xFFC8A24A);
  static const goldLight = Color(0xFFD4AF37);
  static const goldDark = Color(0xFFB8923F);

  // Matte black
  static const black = Color(0xFF111111);
  static const blackLight = Color(0xFF1B1B1B);

  // Text
  static const textPrimary = Color(0xFF222222);
  static const textSecondary = Color(0xFF666666);
  static const textMuted = Color(0xFFAAAAAA);
  static const textOnGold = Color(0xFF111111);
  static const textOnDark = Color(0xFFFFFFFF);

  // Borders & surfaces
  static const border = Color(0xFFE5E5E5);
  static const circleBg = Color(0xFFF8F8F8);

  // Semantic (keep for status indicators)
  static const success = Color(0xFF059669);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);

  // Theme aliases — primary = gold throughout the app
  static const primary = gold;
  static const primaryLight = goldLight;
  static const primaryDark = goldDark;
  static const accent = blackLight;
  static const accentLight = Color(0xFFF8F8F8);
  static const navy = black;
  static const discount = gold;
  static const rating = gold;

  // Catalog
  static const catalogDark = white;
  static const catalogPanel = surfaceMuted;

  // Legacy aliases
  static const cream = surfaceMuted;
  static const creamLight = background;
  static const creamDark = border;
  static const accentLegacy = accent;
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.gold,
        onPrimary: AppColors.textOnGold,
        secondary: AppColors.black,
        onSecondary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
    );

    final textTheme = GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineSmall: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.6, color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textOnGold,
          elevation: 0,
          shadowColor: AppColors.gold.withValues(alpha: 0.3),
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.vazirmatn(fontSize: 14, fontWeight: FontWeight.w600),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
              return AppColors.goldDark.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textOnGold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.black),
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(color: AppColors.gold, width: 1.5);
            }
            return const BorderSide(color: AppColors.black);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return AppColors.gold;
            return AppColors.textPrimary;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w600),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.gold;
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),
    );
  }

  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      );

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 6),
      );

  static BoxShadow get elevatedShadow => cardShadow;

  static BoxShadow get hoverShadow => BoxShadow(
        color: AppColors.gold.withValues(alpha: 0.15),
        blurRadius: 24,
        offset: const Offset(0, 8),
      );

  static BoxShadow get goldGlow => BoxShadow(
        color: AppColors.gold.withValues(alpha: 0.25),
        blurRadius: 12,
        spreadRadius: 1,
      );

  static BoxShadow get searchShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 2),
      );
}
