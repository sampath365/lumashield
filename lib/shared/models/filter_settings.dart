import 'package:material_ui/material_ui.dart';

/// The six quick modes shown on the dashboard.
enum FilterMode {
  normal(
    label: 'Normal',
    shortLabel: 'Normal',
    description: 'Neutral tone with a light protective tint.',
    kelvin: 5500,
    intensity: 20,
    icon: Icons.wb_sunny_outlined,
  ),
  eyeProtection(
    label: 'Eye Protection',
    shortLabel: 'Eye care',
    description: 'Balanced warm filter for long screen sessions.',
    kelvin: 4500,
    intensity: 45,
    icon: Icons.visibility_outlined,
  ),
  night(
    label: 'Night Mode',
    shortLabel: 'Night',
    description: 'Strong amber tint that is easy on the eyes after dark.',
    kelvin: 3400,
    intensity: 62,
    icon: Icons.nightlight_round,
  ),
  reading(
    label: 'Reading Mode',
    shortLabel: 'Reading',
    description: 'Soft paper tone for ebooks and long articles.',
    kelvin: 4000,
    intensity: 50,
    icon: Icons.menu_book_outlined,
  ),
  sleep(
    label: 'Sleep Mode',
    shortLabel: 'Sleep',
    description: 'Deep warm red that keeps melatonin production intact.',
    kelvin: 2700,
    intensity: 72,
    icon: Icons.bedtime_outlined,
  ),
  custom(
    label: 'Custom Mode',
    shortLabel: 'Custom',
    description: 'Your own temperature, intensity and colour.',
    kelvin: 4500,
    intensity: 40,
    icon: Icons.tune,
  );

  const FilterMode({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.kelvin,
    required this.intensity,
    required this.icon,
  });

  final String label;
  final String shortLabel;
  final String description;
  final int kelvin;
  final int intensity;
  final IconData icon;

  static FilterMode fromName(String? value) =>
      FilterMode.values.firstWhere((m) => m.name == value, orElse: () => FilterMode.eyeProtection);
}

@immutable
class FilterSettings {
  const FilterSettings({
    this.enabled = false,
    this.mode = FilterMode.eyeProtection,
    this.intensity = 45,
    this.kelvin = 4500,
    this.customColor,
    this.dim = 0,
  });

  final bool enabled;
  final FilterMode mode;
  final int intensity;
  final int kelvin;

  /// ARGB value for custom mode, null when the temperature drives the colour.
  final int? customColor;

  /// Extra neutral dimming, 0-60, used as a safe stand in for brightness.
  final int dim;

  bool get usesCustomColor => customColor != null;

  FilterSettings copyWith({
    bool? enabled,
    FilterMode? mode,
    int? intensity,
    int? kelvin,
    int? customColor,
    bool clearCustomColor = false,
    int? dim,
  }) => FilterSettings(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    intensity: (intensity ?? this.intensity).clamp(0, 100),
    kelvin: (kelvin ?? this.kelvin).clamp(1900, 6500),
    customColor: clearCustomColor ? null : (customColor ?? this.customColor),
    dim: (dim ?? this.dim).clamp(0, 60),
  );

  /// Applies a quick mode while preserving the on/off state.
  FilterSettings withMode(FilterMode next) => FilterSettings(
    enabled: enabled,
    mode: next,
    intensity: next.intensity,
    kelvin: next.kelvin,
    customColor: next == FilterMode.custom ? customColor : null,
    dim: dim,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'mode': mode.name,
    'intensity': intensity,
    'kelvin': kelvin,
    'customColor': customColor,
    'dim': dim,
  };

  factory FilterSettings.fromJson(Map<String, dynamic> json) => FilterSettings(
    enabled: json['enabled'] as bool? ?? false,
    mode: FilterMode.fromName(json['mode'] as String?),
    intensity: (json['intensity'] as num?)?.toInt() ?? 45,
    kelvin: (json['kelvin'] as num?)?.toInt() ?? 4500,
    customColor: (json['customColor'] as num?)?.toInt(),
    dim: (json['dim'] as num?)?.toInt() ?? 0,
  );

  /// Payload consumed by the Kotlin overlay service.
  Map<String, dynamic> toPlatformMap() => {
    'enabled': enabled,
    'intensity': intensity,
    'kelvin': kelvin,
    'customColor': customColor,
    'dim': dim,
    'modeLabel': mode.label,
  };
}
