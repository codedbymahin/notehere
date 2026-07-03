import 'package:flutter/material.dart';

/// Centralised theme definitions for the NoteHere app.
///
/// Keeping the colours and text styles here means widgets throughout
/// the app can rely on `Theme.of(context)` instead of hard coding any
/// visual values.
class AppTheme {
  AppTheme._();

  /// Seed colour used for both light and dark Material 3 schemes.
  static const Color _seedColor = Colors.indigo;

  /// Light theme — soft surfaces, indigo primary, comfortable
  /// typography. Designed to feel close to paper.
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).copyWith(
          surface: const Color(0xFFFBFBFE),
          surfaceContainerLowest: const Color(0xFFFFFFFF),
          surfaceContainerLow: const Color(0xFFF4F4F9),
          surfaceContainer: const Color(0xFFEEEEF4),
          surfaceContainerHigh: const Color(0xFFE8E8F0),
          surfaceContainerHighest: const Color(0xFFE2E2EB),
        );
    return _build(colorScheme);
  }

  /// Dark theme — deep surfaces with subtle violet undertone so cards
  /// visibly contrast with the background.
  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).copyWith(
          surface: const Color(0xFF101015),
          surfaceContainerLowest: const Color(0xFF0B0B10),
          surfaceContainerLow: const Color(0xFF16161D),
          surfaceContainer: const Color(0xFF1C1C24),
          surfaceContainerHigh: const Color(0xFF22222C),
          surfaceContainerHighest: const Color(0xFF2A2A35),
        );
    return _build(colorScheme);
  }

  static ThemeData _build(ColorScheme colorScheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      scaffoldBackgroundColor: colorScheme.surface,
    );

    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme, colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 6,
        extendedTextStyle: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, ColorScheme colorScheme) {
    final onSurface = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: onSurface, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(color: onSurface, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(color: muted, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: base.labelMedium?.copyWith(color: muted),
      labelSmall: base.labelSmall?.copyWith(color: muted),
    );
  }
}
