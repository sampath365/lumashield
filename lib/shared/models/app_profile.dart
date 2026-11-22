import 'package:flutter/foundation.dart';

@immutable
class AppProfile {
  const AppProfile({
    required this.packageName,
    required this.label,
    this.enabled = true,
    this.intensity = 0,
    this.kelvin = 4500,
  });

  final String packageName;
  final String label;

  /// When false the filter is lifted completely for this app, which is what
  /// users want for photo editors and video players.
  final bool enabled;
  final int intensity;
  final int kelvin;

  AppProfile copyWith({
    String? label,
    bool? enabled,
    int? intensity,
    int? kelvin,
  }) => AppProfile(
    packageName: packageName,
    label: label ?? this.label,
    enabled: enabled ?? this.enabled,
    intensity: intensity ?? this.intensity,
    kelvin: kelvin ?? this.kelvin,
  );

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'label': label,
    'enabled': enabled,
    'intensity': intensity,
    'kelvin': kelvin,
  };

  factory AppProfile.fromJson(Map<String, dynamic> json) => AppProfile(
    packageName: json['packageName'] as String? ?? '',
    label: json['label'] as String? ?? '',
    enabled: json['enabled'] as bool? ?? true,
    intensity: (json['intensity'] as num?)?.toInt() ?? 0,
    kelvin: (json['kelvin'] as num?)?.toInt() ?? 4500,
  );
}
