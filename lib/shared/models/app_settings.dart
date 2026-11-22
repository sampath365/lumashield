import 'package:material_ui/material_ui.dart';

enum ThemeVariant {
  midnight('Midnight', 'Deep navy, the signature look'),
  amoled('AMOLED black', 'True black surfaces for OLED panels'),
  daylight('Daylight', 'Warm light theme for bright rooms'),
  system('Follow system', 'Match the device light or dark setting');

  const ThemeVariant(this.label, this.description);

  final String label;
  final String description;

  static ThemeVariant fromName(String? value) =>
      ThemeVariant.values.firstWhere((v) => v.name == value, orElse: () => ThemeVariant.midnight);
}

enum AccentChoice {
  amber('Amber', Color(0xFFF0A44A)),
  coral('Coral', Color(0xFFF0796A)),
  sky('Soft blue', Color(0xFF7FB2E5)),
  sand('Sand', Color(0xFFE3C48B));

  const AccentChoice(this.label, this.color);

  final String label;
  final Color color;

  static AccentChoice fromName(String? value) =>
      AccentChoice.values.firstWhere((v) => v.name == value, orElse: () => AccentChoice.amber);
}

/// User level preferences that are not tied to the filter itself.
@immutable
class AppSettings {
  const AppSettings({
    this.onboarded = false,
    this.themeVariant = ThemeVariant.midnight,
    this.accent = AccentChoice.amber,
    this.appLockEnabled = false,
    this.hapticsEnabled = true,
    this.showTips = true,
    this.crashReports = false,
    this.quickTileHintShown = false,
    this.lastBackupAt,
  });

  final bool onboarded;
  final ThemeVariant themeVariant;
  final AccentChoice accent;
  final bool appLockEnabled;
  final bool hapticsEnabled;
  final bool showTips;

  /// Opt in diagnostics. Off by default and never includes screen content.
  final bool crashReports;
  final bool quickTileHintShown;
  final DateTime? lastBackupAt;

  AppSettings copyWith({
    bool? onboarded,
    ThemeVariant? themeVariant,
    AccentChoice? accent,
    bool? appLockEnabled,
    bool? hapticsEnabled,
    bool? showTips,
    bool? crashReports,
    bool? quickTileHintShown,
    DateTime? lastBackupAt,
  }) => AppSettings(
    onboarded: onboarded ?? this.onboarded,
    themeVariant: themeVariant ?? this.themeVariant,
    accent: accent ?? this.accent,
    appLockEnabled: appLockEnabled ?? this.appLockEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    showTips: showTips ?? this.showTips,
    crashReports: crashReports ?? this.crashReports,
    quickTileHintShown: quickTileHintShown ?? this.quickTileHintShown,
    lastBackupAt: lastBackupAt ?? this.lastBackupAt,
  );

  Map<String, dynamic> toJson() => {
    'onboarded': onboarded,
    'themeVariant': themeVariant.name,
    'accent': accent.name,
    'appLockEnabled': appLockEnabled,
    'hapticsEnabled': hapticsEnabled,
    'showTips': showTips,
    'crashReports': crashReports,
    'quickTileHintShown': quickTileHintShown,
    'lastBackupAt': lastBackupAt?.toIso8601String(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    onboarded: json['onboarded'] as bool? ?? false,
    themeVariant: ThemeVariant.fromName(json['themeVariant'] as String?),
    accent: AccentChoice.fromName(json['accent'] as String?),
    appLockEnabled: json['appLockEnabled'] as bool? ?? false,
    hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    showTips: json['showTips'] as bool? ?? true,
    crashReports: json['crashReports'] as bool? ?? false,
    quickTileHintShown: json['quickTileHintShown'] as bool? ?? false,
    lastBackupAt: json['lastBackupAt'] == null
        ? null
        : DateTime.tryParse(json['lastBackupAt'] as String),
  );
}
