import 'package:flutter/foundation.dart';

/// Service behaviour the user controls from the notification settings screen.
@immutable
class ServiceOptions {
  const ServiceOptions({
    this.showNotification = true,
    this.notificationActions = true,
    this.restoreOnBoot = true,
    this.autoRestart = true,
  });

  final bool showNotification;
  final bool notificationActions;
  final bool restoreOnBoot;
  final bool autoRestart;

  ServiceOptions copyWith({
    bool? showNotification,
    bool? notificationActions,
    bool? restoreOnBoot,
    bool? autoRestart,
  }) => ServiceOptions(
    showNotification: showNotification ?? this.showNotification,
    notificationActions: notificationActions ?? this.notificationActions,
    restoreOnBoot: restoreOnBoot ?? this.restoreOnBoot,
    autoRestart: autoRestart ?? this.autoRestart,
  );

  Map<String, dynamic> toJson() => {
    'showNotification': showNotification,
    'notificationActions': notificationActions,
    'restoreOnBoot': restoreOnBoot,
    'autoRestart': autoRestart,
  };

  factory ServiceOptions.fromJson(Map<String, dynamic> json) => ServiceOptions(
    showNotification: json['showNotification'] as bool? ?? true,
    notificationActions: json['notificationActions'] as bool? ?? true,
    restoreOnBoot: json['restoreOnBoot'] as bool? ?? true,
    autoRestart: json['autoRestart'] as bool? ?? true,
  );
}
