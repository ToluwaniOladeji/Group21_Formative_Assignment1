import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens. Everyone uses these - never hard-code colours or sizes in screens.
/// Identity: deep "ink" indigo chrome + traffic-light SLA colours that carry meaning.
class AppColors {
  static const primary = Color(0xFF4338CA);
  static const ink = Color(0xFF1E1B4B);
  static const background = Color(0xFFF6F6FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE4E4EF);
  static const textMuted = Color(0xFF6B7280);

  // SLA signal colours
  static const onTrack = Color(0xFF16A34A);
  static const atRisk = Color(0xFFD97706);
  static const overdue = Color(0xFFDC2626);
  static const completed = Color(0xFF64748B);
}

class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
  static const double listBottom = 96;
}

class AppRadius {
  static const double chip = 999, card = 14, input = 12;
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    // Type scale: Plus Jakarta Sans for headings, Inter for reading text.
    final body = GoogleFonts.interTextTheme(base.textTheme);
    TextStyle head(double size, FontWeight w) =>
        GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: AppColors.ink);

    final text = body.copyWith(
      headlineMedium: head(26, FontWeight.w800), // screen greetings
      titleLarge: head(20, FontWeight.w700), // app bar / section titles
      titleMedium: head(16, FontWeight.w700), // card titles
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
      bodySmall: body.bodySmall?.copyWith(fontSize: 12, color: AppColors.textMuted),
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
      ),
    );
  }
}
