import 'package:flutter/foundation.dart';

import '../../shared/models/protection_status.dart';
import '../utils/platform_capabilities.dart';
import 'filter_service.dart';
import 'notification_service.dart';

/// Aggregated permission state used by the setup screen and the dashboard
/// banner. Each flag reflects a real platform check, never an assumption.
@immutable
class PermissionSnapshot {
  const PermissionSnapshot({
    this.overlay = false,
    this.notifications = false,
    this.batteryUnrestricted = false,
    this.usageAccess = false,
    this.exactAlarms = false,
    this.loading = true,
  });

  final bool overlay;
  final bool notifications;

  /// True when the OS is not allowed to optimise the app out.
  final bool batteryUnrestricted;
  final bool usageAccess;
  final bool exactAlarms;
  final bool loading;

  bool get coreGranted => overlay && notifications;
  bool get allGranted =>
      coreGranted && batteryUnrestricted && usageAccess && exactAlarms;

  int get grantedCount => [overlay, notifications, batteryUnrestricted, usageAccess, exactAlarms]
      .where((value) => value)
      .length;

  static const PermissionSnapshot unknown = PermissionSnapshot();

  PermissionSnapshot copyWith({
    bool? overlay,
    bool? notifications,
    bool? batteryUnrestricted,
    bool? usageAccess,
    bool? exactAlarms,
    bool? loading,
  }) => PermissionSnapshot(
    overlay: overlay ?? this.overlay,
    notifications: notifications ?? this.notifications,
    batteryUnrestricted: batteryUnrestricted ?? this.batteryUnrestricted,
    usageAccess: usageAccess ?? this.usageAccess,
    exactAlarms: exactAlarms ?? this.exactAlarms,
    loading: loading ?? this.loading,
  );
}

class PermissionService {
  PermissionService(this._filterService, this._notifications);

  final FilterService _filterService;
  final NotificationService _notifications;

  Future<PermissionSnapshot> snapshot({ProtectionStatus? status}) async {
    if (!PlatformCapabilities.isAndroid) {
      final notificationsEnabled = await _notifications.areEnabled();
      return PermissionSnapshot(
        overlay: false,
        notifications: notificationsEnabled,
        batteryUnrestricted: true,
        usageAccess: false,
        exactAlarms: true,
        loading: false,
      );
    }
    final current = status ?? await _filterService.getStatus();
    return PermissionSnapshot(
      overlay: current.overlayGranted,
      notifications: await _notifications.areEnabled(),
      batteryUnrestricted: !current.batteryOptimized,
      usageAccess: current.usageAccessGranted,
      exactAlarms: current.exactAlarmsAllowed,
      loading: false,
    );
  }
}
