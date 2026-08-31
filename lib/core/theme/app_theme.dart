// ─────────────────────────────────────────────────────────────────────────────
// app_theme.dart — Ultra-Sleek Modern Monochrome & Minimalist Theme (UI/UX Pro Max)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class AppTheme {
  AppTheme._();

  // ── Brand & Neutral Tokens ──────────────────────────────────────────────
  // Light Mode Tokens
  static const Color lightBg = Color(0xFFF3F4F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightPrimary = Color(0xFF111111);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightInputBg = Color(0xFFFFFFFF);

  // Dark Mode Tokens (Matching attached mockup)
  static const Color darkBg = Color(0xFF0C0C0E);
  static const Color darkSurface = Color(0xFF16161A);
  static const Color darkBorder = Color(0xFF26262B);
  static const Color darkPrimary = Color(0xFFFFFFFF);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkInputBg = Color(0xFF16161A);

  // Status Accent Colors (Vibrant & Refined)
  static const Color statusMissingFiles = Color(0xFFEF4444);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusReady = Color(0xFF3B82F6);
  static const Color statusCompleted = Color(0xFF10B981);

  // Sync Accent Colors
  static const Color syncSynced = Color(0xFF10B981);
  static const Color syncSyncing = Color(0xFF3B82F6);
  static const Color syncOffline = Color(0xFF9CA3AF);
  static const Color syncError = Color(0xFFEF4444);

  // Accent Blue & Green
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color green = Color(0xFF10B981);

  static TextTheme _buildTextTheme(Color baseColor, Color mutedColor) {
    return GoogleFonts.cairoTextTheme().copyWith(
      displayLarge: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w800, color: baseColor, height: 1.4),
      displayMedium: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w700, color: baseColor, height: 1.4),
      titleLarge: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700, color: baseColor, height: 1.35),
      titleMedium: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: baseColor, height: 1.35),
      titleSmall: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: baseColor, height: 1.35),
      bodyLarge: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w500, color: baseColor, height: 1.4),
      bodyMedium: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: baseColor, height: 1.4),
      bodySmall: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w400, color: mutedColor, height: 1.35),
      labelLarge: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: baseColor, height: 1.35),
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: lightPrimary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE5E7EB),
      onPrimaryContainer: lightPrimary,
      secondary: accentBlue,
      onSecondary: Colors.white,
      surface: lightSurface,
      onSurface: lightTextPrimary,
      onSurfaceVariant: lightTextSecondary,
      error: statusMissingFiles,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _buildTextTheme(lightTextPrimary, lightTextSecondary),
      scaffoldBackgroundColor: lightBg,
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: lightBorder, width: 1.2),
        ),
        color: lightSurface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.cairo(fontSize: 13, color: lightTextPrimary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
        backgroundColor: lightSurface,
        selectedColor: lightPrimary,
        side: const BorderSide(color: lightBorder, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: lightPrimary,
        unselectedLabelColor: lightTextSecondary,
        indicatorColor: lightPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: lightBorder,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: lightBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: lightBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: lightPrimary, width: 2),
        ),
        labelStyle: GoogleFonts.cairo(color: lightTextSecondary, fontWeight: FontWeight.w600),
        floatingLabelStyle: GoogleFonts.cairo(color: lightPrimary, fontWeight: FontWeight.w700),
        hintStyle: GoogleFonts.cairo(color: const Color(0xFF9CA3AF)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: const Color(0xFFE5E7EB),
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? lightPrimary : lightTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? lightPrimary : lightTextSecondary,
            size: 24,
          );
        }),
      ),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: Color(0xFF0F0F12),
      primaryContainer: Color(0xFF26262B),
      onPrimaryContainer: darkPrimary,
      secondary: accentBlue,
      onSecondary: Colors.white,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      onSurfaceVariant: darkTextSecondary,
      error: statusMissingFiles,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _buildTextTheme(darkTextPrimary, darkTextSecondary),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: darkBorder, width: 1.2),
        ),
        color: darkSurface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.cairo(fontSize: 13, color: darkTextPrimary, fontWeight: FontWeight.w600),
        secondaryLabelStyle: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF0F0F12), fontWeight: FontWeight.w800),
        backgroundColor: const Color(0xFF1E1E24),
        selectedColor: darkPrimary,
        side: const BorderSide(color: darkBorder, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: darkPrimary,
        unselectedLabelColor: darkTextSecondary,
        indicatorColor: darkPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: darkBorder,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: darkBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: darkBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        labelStyle: GoogleFonts.cairo(color: darkTextSecondary, fontWeight: FontWeight.w600),
        floatingLabelStyle: GoogleFonts.cairo(color: darkPrimary, fontWeight: FontWeight.w700),
        hintStyle: GoogleFonts.cairo(color: const Color(0xFF6B7280)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: const Color(0xFF0F0F12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: Color(0xFF0F0F12),
        elevation: 3,
        shape: StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: const Color(0xFF26262B),
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? darkPrimary : darkTextSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? darkPrimary : darkTextSecondary,
            size: 24,
          );
        }),
      ),
    );
  }
}
