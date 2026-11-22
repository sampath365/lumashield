import 'package:material_ui/material_ui.dart';

/// Colours for one theme variant. Every screen reads colours from here instead
/// of hard coding values, so the AMOLED and daylight variants stay consistent.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.warm,
    required this.success,
    required this.danger,
    required this.orbCore,
    required this.isDark,
  });

  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceHigh;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color warm;
  final Color success;
  final Color danger;
  final Color orbCore;
  final bool isDark;

  static const Color amber = Color(0xFFF0A44A);
  static const Color coral = Color(0xFFF0796A);
  static const Color sky = Color(0xFF7FB2E5);
  static const Color sand = Color(0xFFE3C48B);

  static const AppPalette midnight = AppPalette(
    background: Color(0xFF0A1020),
    backgroundAlt: Color(0xFF0D1628),
    surface: Color(0xFF131E33),
    surfaceHigh: Color(0xFF1A2740),
    border: Color(0xFF24314C),
    textPrimary: Color(0xFFF3F6FD),
    textSecondary: Color(0xFFB9C5DA),
    textMuted: Color(0xFF7E8CA8),
    accent: amber,
    accentSoft: Color(0x33F0A44A),
    warm: Color(0xFFE8823C),
    success: Color(0xFF63C79B),
    danger: Color(0xFFEF6F6F),
    orbCore: Color(0xFF182236),
    isDark: true,
  );

  static const AppPalette amoled = AppPalette(
    background: Color(0xFF000000),
    backgroundAlt: Color(0xFF050505),
    surface: Color(0xFF0C0C0E),
    surfaceHigh: Color(0xFF141417),
    border: Color(0xFF222226),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFFB4B4BC),
    textMuted: Color(0xFF7A7A85),
    accent: amber,
    accentSoft: Color(0x2EF0A44A),
    warm: Color(0xFFE8823C),
    success: Color(0xFF5BC493),
    danger: Color(0xFFEE6A6A),
    orbCore: Color(0xFF0B0B0D),
    isDark: true,
  );

  static const AppPalette daylight = AppPalette(
    background: Color(0xFFF6F4EF),
    backgroundAlt: Color(0xFFFDFCF9),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF1EEE7),
    border: Color(0xFFE2DDD2),
    textPrimary: Color(0xFF16202F),
    textSecondary: Color(0xFF4A5668),
    textMuted: Color(0xFF7C8798),
    accent: Color(0xFFC97B23),
    accentSoft: Color(0x1FC97B23),
    warm: Color(0xFFD9822B),
    success: Color(0xFF2E8C63),
    danger: Color(0xFFC24B4B),
    orbCore: Color(0xFFFFFFFF),
    isDark: false,
  );

  /// Deep navy gradient used behind the hero areas.
  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? const [Color(0xFF15223C), Color(0xFF0A1020), Color(0xFF070B14)]
        : const [Color(0xFFFFF6E8), Color(0xFFF6F4EF), Color(0xFFEFEADF)],
  );

  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent.withValues(alpha: 0.95), warm.withValues(alpha: 0.85)],
  );

  @override
  AppPalette copyWith({Color? accent, Color? warm, bool? isDark}) => AppPalette(
    background: background,
    backgroundAlt: backgroundAlt,
    surface: surface,
    surfaceHigh: surfaceHigh,
    border: border,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    textMuted: textMuted,
    accent: accent ?? this.accent,
    accentSoft: (accent ?? this.accent).withValues(alpha: 0.20),
    warm: warm ?? this.warm,
    success: success,
    danger: danger,
    orbCore: orbCore,
    isDark: isDark ?? this.isDark,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      backgroundAlt: mix(backgroundAlt, other.backgroundAlt),
      surface: mix(surface, other.surface),
      surfaceHigh: mix(surfaceHigh, other.surfaceHigh),
      border: mix(border, other.border),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      accent: mix(accent, other.accent),
      accentSoft: mix(accentSoft, other.accentSoft),
      warm: mix(warm, other.warm),
      success: mix(success, other.success),
      danger: mix(danger, other.danger),
      orbCore: mix(orbCore, other.orbCore),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}
