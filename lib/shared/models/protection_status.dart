import 'package:flutter/foundation.dart';

/// Snapshot of the native protection state. On iOS the platform reports
/// `supported = false` and the UI explains why instead of pretending.
@immutable
class ProtectionStatus {
  const ProtectionStatus({
    this.supported = false,
    this.running = false,
    this.enabled = false,
    this.intensity = 0,
    this.kelvin = 4500,
    this.dim = 0,
    this.modeLabel = '',
    this.strength = 0,
    this.overlayGranted = false,
    this.batteryOptimized = true,
    this.usageAccessGranted = false,
    this.exactAlarmsAllowed = false,
    this.scheduleEnabled = false,
    this.nextActivation,
    this.nextDeactivation,
    this.nightNow = false,
    this.showNotification = true,
    this.notificationActions = true,
    this.restoreOnBoot = true,
    this.autoRestart = true,
    this.profilesEnabled = false,
    this.eyeScore = 100,
    this.nextBreakIn,
    this.eyeStatusEnabled = true,
    this.breaksEnabled = true,
    this.breakIntervalMin = 20,
  });

  final bool supported;
  final bool running;
  final bool enabled;
  final int intensity;
  final int kelvin;
  final int dim;
  final String modeLabel;
  final int strength;
  final bool overlayGranted;
  final bool batteryOptimized;
  final bool usageAccessGranted;
  final bool exactAlarmsAllowed;
  final bool scheduleEnabled;
  final DateTime? nextActivation;
  final DateTime? nextDeactivation;
  final bool nightNow;
  final bool showNotification;
  final bool notificationActions;
  final bool restoreOnBoot;
  final bool autoRestart;
  final bool profilesEnabled;

  /// Explainable eye comfort score, 0-100, computed by the native layer.
  final int eyeScore;

  /// Minutes until the next scheduled eye break, null when breaks are off.
  final int? nextBreakIn;
  final bool eyeStatusEnabled;
  final bool breaksEnabled;
  final int breakIntervalMin;

  bool get active => enabled && running;

  static const ProtectionStatus unsupported = ProtectionStatus();

  factory ProtectionStatus.fromMap(Map<dynamic, dynamic> map) {
    DateTime? time(Object? value) {
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      return null;
    }

    return ProtectionStatus(
      supported: map['supported'] as bool? ?? false,
      running: map['running'] as bool? ?? false,
      enabled: map['enabled'] as bool? ?? false,
      intensity: (map['intensity'] as num?)?.toInt() ?? 0,
      kelvin: (map['kelvin'] as num?)?.toInt() ?? 4500,
      dim: (map['dim'] as num?)?.toInt() ?? 0,
      modeLabel: map['modeLabel'] as String? ?? '',
      strength: (map['strength'] as num?)?.toInt() ?? 0,
      overlayGranted: map['overlayGranted'] as bool? ?? false,
      batteryOptimized: map['batteryOptimized'] as bool? ?? true,
      usageAccessGranted: map['usageAccessGranted'] as bool? ?? false,
      exactAlarmsAllowed: map['exactAlarmsAllowed'] as bool? ?? false,
      scheduleEnabled: map['scheduleEnabled'] as bool? ?? false,
      nextActivation: time(map['nextActivation']),
      nextDeactivation: time(map['nextDeactivation']),
      nightNow: map['nightNow'] as bool? ?? false,
      showNotification: map['showNotification'] as bool? ?? true,
      notificationActions: map['notificationActions'] as bool? ?? true,
      restoreOnBoot: map['restoreOnBoot'] as bool? ?? true,
      autoRestart: map['autoRestart'] as bool? ?? true,
      profilesEnabled: map['profilesEnabled'] as bool? ?? false,
      eyeScore: (map['eyeScore'] as num?)?.toInt() ?? 100,
      nextBreakIn: (map['nextBreakIn'] as num?)?.toInt(),
      eyeStatusEnabled: map['eyeStatusEnabled'] as bool? ?? true,
      breaksEnabled: map['breaksEnabled'] as bool? ?? true,
      breakIntervalMin: (map['breakIntervalMin'] as num?)?.toInt() ?? 20,
    );
  }

  ProtectionStatus copyWith({
    bool? supported,
    bool? running,
    bool? enabled,
    int? intensity,
    int? kelvin,
    int? dim,
    String? modeLabel,
    int? strength,
    bool? overlayGranted,
    bool? batteryOptimized,
    bool? usageAccessGranted,
    bool? exactAlarmsAllowed,
    bool? scheduleEnabled,
    DateTime? nextActivation,
    DateTime? nextDeactivation,
    bool? nightNow,
    bool? showNotification,
    bool? notificationActions,
    bool? restoreOnBoot,
    bool? autoRestart,
    bool? profilesEnabled,
    int? eyeScore,
    int? nextBreakIn,
    bool? eyeStatusEnabled,
    bool? breaksEnabled,
    int? breakIntervalMin,
  }) => ProtectionStatus(
    supported: supported ?? this.supported,
    running: running ?? this.running,
    enabled: enabled ?? this.enabled,
    intensity: intensity ?? this.intensity,
    kelvin: kelvin ?? this.kelvin,
    dim: dim ?? this.dim,
    modeLabel: modeLabel ?? this.modeLabel,
    strength: strength ?? this.strength,
    overlayGranted: overlayGranted ?? this.overlayGranted,
    batteryOptimized: batteryOptimized ?? this.batteryOptimized,
    usageAccessGranted: usageAccessGranted ?? this.usageAccessGranted,
    exactAlarmsAllowed: exactAlarmsAllowed ?? this.exactAlarmsAllowed,
    scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
    nextActivation: nextActivation ?? this.nextActivation,
    nextDeactivation: nextDeactivation ?? this.nextDeactivation,
    nightNow: nightNow ?? this.nightNow,
    showNotification: showNotification ?? this.showNotification,
    notificationActions: notificationActions ?? this.notificationActions,
    restoreOnBoot: restoreOnBoot ?? this.restoreOnBoot,
    autoRestart: autoRestart ?? this.autoRestart,
    profilesEnabled: profilesEnabled ?? this.profilesEnabled,
    eyeScore: eyeScore ?? this.eyeScore,
    nextBreakIn: nextBreakIn ?? this.nextBreakIn,
    eyeStatusEnabled: eyeStatusEnabled ?? this.eyeStatusEnabled,
    breaksEnabled: breaksEnabled ?? this.breaksEnabled,
    breakIntervalMin: breakIntervalMin ?? this.breakIntervalMin,
  );
}
