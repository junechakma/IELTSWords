import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const cream = Color(0xFFF3F0EA);
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1D1D1D);
  static const inkSoft = Color(0xFF6F6A66);
  static const line = Color(0xFFE9E5DE);

  static const sunflower = Color(0xFFFBB92C);
  static const sunflowerSoft = Color(0xFFFCC75A);
  static const peach = Color(0xFFECB98E);
  static const blush = Color(0xFFF5D4CE);
  static const lilac = Color(0xFFDDD6FB);
  static const sand = Color(0xFFE3DFD6);
  static const taupe = Color(0xFFD2C6B8);
  static const rust = Color(0xFFD15435);
  static const cocoa = Color(0xFF73443A);
  static const olive = Color(0xFF88A338);
  static const stone = Color(0xFF7A7463);

  /// Heatmap intensity, empty to busiest.
  static const heat = [
    Color(0xFFECE8E1),
    Color(0xFFFDE6B0),
    Color(0xFFFCCF6B),
    Color(0xFFFBB92C),
    Color(0xFFE0921A),
  ];
}

abstract final class AppTheme {
  static TextStyle poppins({double size = 14, FontWeight weight = FontWeight.w500, Color color = AppColors.ink}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      splashFactory: NoSplash.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sunflower,
        surface: AppColors.cream,
        primary: AppColors.ink,
        onPrimary: Colors.white,
        secondary: AppColors.sunflower,
        onSecondary: AppColors.ink,
        error: AppColors.rust,
      ),
    );

    final text = GoogleFonts.outfitTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return base.copyWith(
      textTheme: text.copyWith(
        displayMedium: text.displayMedium?.copyWith(fontWeight: FontWeight.w600),
        headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 32),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w500, fontSize: 21),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        bodyMedium: text.bodyMedium?.copyWith(color: AppColors.inkSoft, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.sunflower,
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
