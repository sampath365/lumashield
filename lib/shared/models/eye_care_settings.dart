import 'package:flutter/foundation.dart';

@immutable
class EyeCareSettings {
  const EyeCareSettings({
    this.twentyRuleEnabled = true,
    this.twentyIntervalMin = 20,
    this.twentyBreakSec = 20,
    this.eyeStrainEnabled = true,
    this.eyeStrainIntervalMin = 45,
    this.continuousUsageLimitMin = 60,
    this.lowLightReminder = true,
    this.sleepReminderEnabled = true,
    this.sleepTimeMinute = 22 * 60 + 30,
    this.dailyReportEnabled = true,
    this.quietHoursEnabled = true,
    this.quietStartMinute = 23 * 60,
    this.quietEndMinute = 7 * 60,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  final bool twentyRuleEnabled;
  final int twentyIntervalMin;
  final int twentyBreakSec;
  final bool eyeStrainEnabled;
  final int eyeStrainIntervalMin;
  final int continuousUsageLimitMin;
  final bool lowLightReminder;
  final bool sleepReminderEnabled;
  final int sleepTimeMinute;
  final bool dailyReportEnabled;
  final bool quietHoursEnabled;
  final int quietStartMinute;
  final int quietEndMinute;
  final bool soundEnabled;
  final bool vibrationEnabled;

  EyeCareSettings copyWith({
    bool? twentyRuleEnabled,
    int? twentyIntervalMin,
    int? twentyBreakSec,
    bool? eyeStrainEnabled,
    int? eyeStrainIntervalMin,
    int? continuousUsageLimitMin,
    bool? lowLightReminder,
    bool? sleepReminderEnabled,
    int? sleepTimeMinute,
    bool? dailyReportEnabled,
    bool? quietHoursEnabled,
    int? quietStartMinute,
    int? quietEndMinute,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) => EyeCareSettings(
    twentyRuleEnabled: twentyRuleEnabled ?? this.twentyRuleEnabled,
    twentyIntervalMin: twentyIntervalMin ?? this.twentyIntervalMin,
    twentyBreakSec: twentyBreakSec ?? this.twentyBreakSec,
    eyeStrainEnabled: eyeStrainEnabled ?? this.eyeStrainEnabled,
    eyeStrainIntervalMin: eyeStrainIntervalMin ?? this.eyeStrainIntervalMin,
    continuousUsageLimitMin: continuousUsageLimitMin ?? this.continuousUsageLimitMin,
    lowLightReminder: lowLightReminder ?? this.lowLightReminder,
    sleepReminderEnabled: sleepReminderEnabled ?? this.sleepReminderEnabled,
    sleepTimeMinute: sleepTimeMinute ?? this.sleepTimeMinute,
    dailyReportEnabled: dailyReportEnabled ?? this.dailyReportEnabled,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietStartMinute: quietStartMinute ?? this.quietStartMinute,
    quietEndMinute: quietEndMinute ?? this.quietEndMinute,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
  );

  Map<String, dynamic> toJson() => {
    'twentyRuleEnabled': twentyRuleEnabled,
    'twentyIntervalMin': twentyIntervalMin,
    'twentyBreakSec': twentyBreakSec,
    'eyeStrainEnabled': eyeStrainEnabled,
    'eyeStrainIntervalMin': eyeStrainIntervalMin,
    'continuousUsageLimitMin': continuousUsageLimitMin,
    'lowLightReminder': lowLightReminder,
    'sleepReminderEnabled': sleepReminderEnabled,
    'sleepTimeMinute': sleepTimeMinute,
    'dailyReportEnabled': dailyReportEnabled,
    'quietHoursEnabled': quietHoursEnabled,
    'quietStartMinute': quietStartMinute,
    'quietEndMinute': quietEndMinute,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
  };

  factory EyeCareSettings.fromJson(Map<String, dynamic> json) => EyeCareSettings(
    twentyRuleEnabled: json['twentyRuleEnabled'] as bool? ?? true,
    twentyIntervalMin: (json['twentyIntervalMin'] as num?)?.toInt() ?? 20,
    twentyBreakSec: (json['twentyBreakSec'] as num?)?.toInt() ?? 20,
    eyeStrainEnabled: json['eyeStrainEnabled'] as bool? ?? true,
    eyeStrainIntervalMin: (json['eyeStrainIntervalMin'] as num?)?.toInt() ?? 45,
    continuousUsageLimitMin: (json['continuousUsageLimitMin'] as num?)?.toInt() ?? 60,
    lowLightReminder: json['lowLightReminder'] as bool? ?? true,
    sleepReminderEnabled: json['sleepReminderEnabled'] as bool? ?? true,
    sleepTimeMinute: (json['sleepTimeMinute'] as num?)?.toInt() ?? 22 * 60 + 30,
    dailyReportEnabled: json['dailyReportEnabled'] as bool? ?? true,
    quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? true,
    quietStartMinute: (json['quietStartMinute'] as num?)?.toInt() ?? 23 * 60,
    quietEndMinute: (json['quietEndMinute'] as num?)?.toInt() ?? 7 * 60,
    soundEnabled: json['soundEnabled'] as bool? ?? true,
    vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
  );
}
