import 'package:flutter/foundation.dart';

enum ScheduleMode {
  custom('Custom times', 'Pick the exact hours for protection'),
  sunsetSunrise('Sunset to sunrise', 'Follow the sun where location is available');

  const ScheduleMode(this.label, this.description);

  final String label;
  final String description;

  static ScheduleMode fromName(String? value) =>
      ScheduleMode.values.firstWhere((m) => m.name == value, orElse: () => ScheduleMode.custom);
}

@immutable
class ScheduleSettings {
  const ScheduleSettings({
    this.enabled = false,
    this.mode = ScheduleMode.custom,
    this.startMinute = 21 * 60,
    this.endMinute = 7 * 60,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.nightIntensity = 65,
    this.nightKelvin = 3200,
    this.dayIntensity = 15,
    this.dayKelvin = 5400,
    this.useLocation = false,
    this.latitude = 0,
    this.longitude = 0,
    this.sunriseOffsetMin = 0,
    this.sunsetOffsetMin = 0,
  });

  final bool enabled;
  final ScheduleMode mode;
  final int startMinute;
  final int endMinute;

  /// ISO weekday numbers, 1 = Monday through 7 = Sunday.
  final Set<int> weekdays;
  final int nightIntensity;
  final int nightKelvin;
  final int dayIntensity;
  final int dayKelvin;
  final bool useLocation;
  final double latitude;
  final double longitude;
  final int sunriseOffsetMin;
  final int sunsetOffsetMin;

  bool get hasLocation =>
      useLocation && !(latitude == 0 && longitude == 0) && latitude.abs() <= 89;

  bool get crossesMidnight => endMinute <= startMinute;

  int get daysMask {
    var mask = 0;
    for (final day in weekdays) {
      if (day >= 1 && day <= 7) mask |= 1 << (day - 1);
    }
    return mask;
  }

  ScheduleSettings copyWith({
    bool? enabled,
    ScheduleMode? mode,
    int? startMinute,
    int? endMinute,
    Set<int>? weekdays,
    int? nightIntensity,
    int? nightKelvin,
    int? dayIntensity,
    int? dayKelvin,
    bool? useLocation,
    double? latitude,
    double? longitude,
    int? sunriseOffsetMin,
    int? sunsetOffsetMin,
  }) => ScheduleSettings(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    startMinute: startMinute ?? this.startMinute,
    endMinute: endMinute ?? this.endMinute,
    weekdays: weekdays ?? this.weekdays,
    nightIntensity: nightIntensity ?? this.nightIntensity,
    nightKelvin: nightKelvin ?? this.nightKelvin,
    dayIntensity: dayIntensity ?? this.dayIntensity,
    dayKelvin: dayKelvin ?? this.dayKelvin,
    useLocation: useLocation ?? this.useLocation,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    sunriseOffsetMin: sunriseOffsetMin ?? this.sunriseOffsetMin,
    sunsetOffsetMin: sunsetOffsetMin ?? this.sunsetOffsetMin,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'mode': mode.name,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'weekdays': weekdays.toList()..sort(),
    'nightIntensity': nightIntensity,
    'nightKelvin': nightKelvin,
    'dayIntensity': dayIntensity,
    'dayKelvin': dayKelvin,
    'useLocation': useLocation,
    'latitude': latitude,
    'longitude': longitude,
    'sunriseOffsetMin': sunriseOffsetMin,
    'sunsetOffsetMin': sunsetOffsetMin,
  };

  factory ScheduleSettings.fromJson(Map<String, dynamic> json) => ScheduleSettings(
    enabled: json['enabled'] as bool? ?? false,
    mode: ScheduleMode.fromName(json['mode'] as String?),
    startMinute: (json['startMinute'] as num?)?.toInt() ?? 21 * 60,
    endMinute: (json['endMinute'] as num?)?.toInt() ?? 7 * 60,
    weekdays: ((json['weekdays'] as List?) ?? const [1, 2, 3, 4, 5, 6, 7])
        .map((e) => (e as num).toInt())
        .toSet(),
    nightIntensity: (json['nightIntensity'] as num?)?.toInt() ?? 65,
    nightKelvin: (json['nightKelvin'] as num?)?.toInt() ?? 3200,
    dayIntensity: (json['dayIntensity'] as num?)?.toInt() ?? 15,
    dayKelvin: (json['dayKelvin'] as num?)?.toInt() ?? 5400,
    useLocation: json['useLocation'] as bool? ?? false,
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    sunriseOffsetMin: (json['sunriseOffsetMin'] as num?)?.toInt() ?? 0,
    sunsetOffsetMin: (json['sunsetOffsetMin'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toPlatformMap() => {
    'enabled': enabled,
    'mode': mode == ScheduleMode.sunsetSunrise ? 'sun' : 'custom',
    'startMinute': startMinute,
    'endMinute': endMinute,
    'daysMask': daysMask,
    'nightIntensity': nightIntensity,
    'nightKelvin': nightKelvin,
    'dayIntensity': dayIntensity,
    'dayKelvin': dayKelvin,
    'useLocation': useLocation,
    'latitude': latitude,
    'longitude': longitude,
    'sunriseOffsetMin': sunriseOffsetMin,
    'sunsetOffsetMin': sunsetOffsetMin,
  };
}
