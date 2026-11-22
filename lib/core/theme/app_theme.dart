import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../shared/models/app_settings.dart';
import 'app_palette.dart';

class AppTheme {
  AppTheme._();

  static AppPalette paletteFor(ThemeVariant variant, AccentChoice accent) {
    final base = switch (variant) {
      ThemeVariant.midnight => AppPalette.midnight,
      ThemeVariant.amoled => AppPalette.amoled,
      ThemeVariant.daylight => AppPalette.daylight,
      ThemeVariant.system => AppPalette.midnight,
    };
    final accentColor = switch (accent) {
      AccentChoice.amber => AppPalette.amber,
      AccentChoice.coral => AppPalette.coral,
      AccentChoice.sky => AppPalette.sky,
      AccentChoice.sand => AppPalette.sand,
    };
    final warm = switch (accent) {
      AccentChoice.amber => AppPalette.midnight.warm,
      AccentChoice.coral => const Color(0xFFE2685F),
      AccentChoice.sky => const Color(0xFF5E8FC7),
      AccentChoice.sand => const Color(0xFFC9A46A),
    };
    return base.copyWith(accent: accentColor, warm: warm);
  }

  static ThemeData build(ThemeVariant variant, AccentChoice accent) {
    final palette = paletteFor(variant, accent);
    final brightness = palette.isDark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.isDark ? const Color(0xFF1B1206) : Colors.white,
      secondary: palette.warm,
      onSecondary: Colors.white,
      error: palette.danger,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.surfaceHigh,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = base.textTheme
        .apply(bodyColor: palette.textPrimary, displayColor: palette.textPrimary)
        .copyWith(
          displayLarge: base.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
          headlineLarge: base.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.4),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
          labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        );

    return base.copyWith(
      textTheme: textTheme,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: palette.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: palette.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.isDark
                    ? const Color(0xFF20180C)
                    : Colors.white
              : palette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.accent,
        inactiveTrackColor: palette.surfaceHigh,
        thumbColor: palette.accent,
        overlayColor: palette.accent.withValues(alpha: 0.16),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.backgroundAlt,
        selectedItemColor: palette.accent,
        unselectedItemColor: palette.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceHigh,
        contentTextStyle: TextStyle(color: palette.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.isDark ? const Color(0xFF1B1206) : Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.accent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceHigh,
        selectedColor: palette.accentSoft,
        side: BorderSide(color: palette.border),
        labelStyle: TextStyle(color: palette.textSecondary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.surfaceHigh,
      ),
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
