import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        height: 1.1,
        color: DesignSystem.textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.15,
        color: DesignSystem.textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
        color: DesignSystem.textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
        color: DesignSystem.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.3,
        color: DesignSystem.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.0,
        height: 1.35,
        color: DesignSystem.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0.1,
        color: DesignSystem.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14.5,
        height: 1.5,
        letterSpacing: 0.1,
        color: DesignSystem.textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12.5,
        height: 1.45,
        letterSpacing: 0.15,
        color: DesignSystem.textMuted,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: DesignSystem.textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: DesignSystem.textPrimary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: DesignSystem.textMuted,
      ),
    );

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: DesignSystem.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: DesignSystem.primary,
        secondary: DesignSystem.secondary,
        tertiary: DesignSystem.tertiary,
        surface: DesignSystem.backgroundBase,
        error: DesignSystem.error,
      ),
      scaffoldBackgroundColor: DesignSystem.backgroundBase,
      canvasColor: DesignSystem.backgroundBase,
      cardColor: DesignSystem.backgroundSurface,
      dividerColor: DesignSystem.border,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: DesignSystem.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20.0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.2,
          color: DesignSystem.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: DesignSystem.primary,
          foregroundColor: DesignSystem.textPrimary,
          disabledBackgroundColor: DesignSystem.textDisabled.withAlpha(50),
          disabledForegroundColor: DesignSystem.textMuted,
          minimumSize: const Size(0, 56),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: DesignSystem.backgroundRaised,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x40000000),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: DesignSystem.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: DesignSystem.backgroundBase.withAlpha(240),
        indicatorColor: DesignSystem.primary.withAlpha(50),
        elevation: 8,
        height: 72,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: DesignSystem.textPrimary,
              letterSpacing: 0.2,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: DesignSystem.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: DesignSystem.primary, size: 24);
          }
          return const IconThemeData(color: DesignSystem.textMuted, size: 24);
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
