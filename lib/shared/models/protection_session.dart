import 'package:flutter/foundation.dart';

/// One stretch of active protection, stored locally in Hive.
@immutable
class ProtectionSession {
  const ProtectionSession({
    required this.start,
    required this.end,
    required this.mode,
    required this.intensity,
    required this.kelvin,
  });

  final DateTime start;
  final DateTime end;
  final String mode;
  final int intensity;
  final int kelvin;

  Duration get duration => end.difference(start);

  Map<String, dynamic> toJson() => {
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'mode': mode,
    'intensity': intensity,
    'kelvin': kelvin,
  };

  factory ProtectionSession.fromJson(Map<dynamic, dynamic> json) => ProtectionSession(
    start: DateTime.fromMillisecondsSinceEpoch((json['start'] as num).toInt()),
    end: DateTime.fromMillisecondsSinceEpoch((json['end'] as num).toInt()),
    mode: json['mode'] as String? ?? 'Custom',
    intensity: (json['intensity'] as num?)?.toInt() ?? 0,
    kelvin: (json['kelvin'] as num?)?.toInt() ?? 4500,
  );
}

@immutable
class DailyStat {
  const DailyStat({
    required this.day,
    required this.minutes,
    required this.sessions,
    required this.avgIntensity,
  });

  final DateTime day;
  final int minutes;
  final int sessions;
  final int avgIntensity;

  double get hours => minutes / 60;
}

@immutable
class StatsSummary {
  const StatsSummary({
    required this.days,
    required this.todayMinutes,
    required this.weekMinutes,
    required this.totalSessions,
    required this.currentStreakDays,
    required this.avgIntensity,
  });

  final List<DailyStat> days;
  final int todayMinutes;
  final int weekMinutes;
  final int totalSessions;
  final int currentStreakDays;
  final int avgIntensity;

  static const StatsSummary empty = StatsSummary(
    days: [],
    todayMinutes: 0,
    weekMinutes: 0,
    totalSessions: 0,
    currentStreakDays: 0,
    avgIntensity: 0,
  );
}
