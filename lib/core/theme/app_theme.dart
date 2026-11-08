import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ivory = Color(0xFFFBF7EF);
  static const cream = Color(0xFFFFFDF8);
  static const sandstone = Color(0xFFE8DCC7);
  static const champagne = Color(0xFFD7B77A);
  static const gold = Color(0xFFB88A44);
  static const brown = Color(0xFF2B2118);
  static const charcoal = Color(0xFF3B332D);
  static const sage = Color(0xFF8FA38A);
  static const terracotta = Color(0xFFC98262);
  static const success = Color(0xFF3C7A57);
  static const error = Color(0xFFB85656);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppTheme {
  static ThemeData light({required bool khmer}) => _theme(
    brightness: Brightness.light,
    khmer: khmer,
    scaffold: AppColors.ivory,
    surface: AppColors.cream,
    text: AppColors.brown,
  );

  static ThemeData dark({required bool khmer}) => _theme(
    brightness: Brightness.dark,
    khmer: khmer,
    scaffold: const Color(0xFF211C18),
    surface: const Color(0xFF2D2722),
    text: const Color(0xFFF7EEDD),
  );

  static ThemeData _theme({
    required Brightness brightness,
    required bool khmer,
    required Color scaffold,
    required Color surface,
    required Color text,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.gold,
      onPrimary: Colors.white,
      secondary: AppColors.sage,
      onSecondary: AppColors.brown,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      outline: brightness == Brightness.light
          ? const Color(0xFFCCBEA7)
          : const Color(0xFF716457),
      outlineVariant: brightness == Brightness.light
          ? AppColors.sandstone
          : const Color(0xFF493F37),
      surfaceContainerHighest: brightness == Brightness.light
          ? const Color(0xFFF3EBDD)
          : const Color(0xFF3B332D),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: khmer ? 'NotoSansKhmer' : 'Inter',
      splashFactory: InkSparkle.splashFactory,
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        height: khmer ? 1.35 : 1.1,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: khmer ? 1.45 : 1.15,
        letterSpacing: -0.4,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: khmer ? 1.45 : 1.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: khmer ? 1.45 : 1.25,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        height: khmer ? 1.65 : 1.45,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        height: khmer ? 1.6 : 1.4,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        height: 76,
        indicatorColor: AppColors.champagne.withValues(alpha: 0.28),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: AppColors.champagne.withValues(alpha: 0.32),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
