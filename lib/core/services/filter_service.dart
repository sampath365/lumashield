import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../shared/models/app_profile.dart';
import '../../shared/models/eye_care_settings.dart';
import '../../shared/models/filter_settings.dart';
import '../../shared/models/protection_status.dart';
import '../../shared/models/schedule_settings.dart';
import '../../shared/models/service_options.dart';
import '../constants/app_constants.dart';
import '../utils/platform_capabilities.dart';

/// Thin, defensive wrapper around the Kotlin overlay bridge.
///
/// Every call is guarded: on iOS there is no plugin, and in widget tests there
/// is no platform at all. Callers therefore always receive a valid value and
/// the UI can render an honest "not supported" state.
class FilterService {
  const FilterService();

  static const MethodChannel _channel = MethodChannel(AppConstants.platformChannel);
  static const EventChannel _events = EventChannel(AppConstants.eventChannel);

  bool get isSupported => PlatformCapabilities.systemOverlay;

  Future<ProtectionStatus> getStatus() async {
    if (!isSupported) return ProtectionStatus.unsupported;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('getStatus');
      if (map == null) return ProtectionStatus.unsupported;
      return ProtectionStatus.fromMap(map);
    } on PlatformException catch (error) {
      debugPrint('getStatus failed: ${error.message}');
      return ProtectionStatus.unsupported;
    } on MissingPluginException {
      return ProtectionStatus.unsupported;
    }
  }

  Stream<ProtectionStatus> statusStream() {
    if (!isSupported) return const Stream.empty();
    return _events
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map((event) => ProtectionStatus.fromMap(event as Map))
        .handleError((Object error) {
          debugPrint('status stream error: $error');
        });
  }

  /// Raw native events, used for signals that are not part of the status map
  /// (for example `eyeBreakDue`).
  Stream<Map<String, dynamic>> rawEvents() {
    if (!isSupported) return const Stream.empty();
    return _events
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map<Map<String, dynamic>>((event) => (event as Map).cast<String, dynamic>())
        .handleError((Object error) {
          debugPrint('event stream error: $error');
        });
  }

  Future<bool> _bool(String method, {bool fallback = false}) async {
    if (!isSupported) return fallback;
    try {
      return await _channel.invokeMethod<bool>(method) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _void(String method, [Map<String, dynamic>? args]) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } catch (error) {
      debugPrint('$method failed: $error');
    }
  }

  Future<bool> isOverlayGranted() => _bool('isOverlayGranted');
  Future<void> openOverlaySettings() => _void('openOverlaySettings');

  Future<bool> isIgnoringBatteryOptimizations() => _bool('isIgnoringBatteryOptimizations');
  Future<void> requestIgnoreBatteryOptimizations() => _void('requestIgnoreBatteryOptimizations');
  Future<void> openBatterySettings() => _void('openBatterySettings');

  Future<bool> isUsageAccessGranted() => _bool('isUsageAccessGranted');
  Future<void> openUsageAccessSettings() => _void('openUsageAccessSettings');

  Future<bool> canScheduleExactAlarms() => _bool('canScheduleExactAlarms');
  Future<void> openExactAlarmSettings() => _void('openExactAlarmSettings');

  Future<void> openNotificationSettings() => _void('openNotificationSettings');
  Future<void> openAppSettings() => _void('openAppSettings');

  Future<ProtectionStatus> start(FilterSettings settings) async {
    if (!isSupported) return ProtectionStatus.unsupported;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>(
        'startProtection',
        settings.copyWith(enabled: true).toPlatformMap(),
      );
      return map == null ? await getStatus() : ProtectionStatus.fromMap(map);
    } catch (error) {
      debugPrint('startProtection failed: $error');
      return await getStatus();
    }
  }

  Future<ProtectionStatus> update(FilterSettings settings) async {
    if (!isSupported) return ProtectionStatus.unsupported;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>(
        'updateProtection',
        settings.toPlatformMap(),
      );
      return map == null ? await getStatus() : ProtectionStatus.fromMap(map);
    } catch (error) {
      debugPrint('updateProtection failed: $error');
      return await getStatus();
    }
  }

  Future<ProtectionStatus> stop() async {
    if (!isSupported) return ProtectionStatus.unsupported;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('stopProtection');
      return map == null ? await getStatus() : ProtectionStatus.fromMap(map);
    } catch (error) {
      debugPrint('stopProtection failed: $error');
      return await getStatus();
    }
  }

  Future<ProtectionStatus> toggle() async {
    if (!isSupported) return ProtectionStatus.unsupported;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('toggleProtection');
      return map == null ? await getStatus() : ProtectionStatus.fromMap(map);
    } catch (error) {
      debugPrint('toggleProtection failed: $error');
      return await getStatus();
    }
  }

  Future<ProtectionStatus> emergencyDisable() async {
    if (!isSupported) return ProtectionStatus.unsupported;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('emergencyDisable');
      return map == null ? await getStatus() : ProtectionStatus.fromMap(map);
    } catch (error) {
      debugPrint('emergencyDisable failed: $error');
      return await getStatus();
    }
  }

  Future<ProtectionStatus> applySchedule(ScheduleSettings settings) async {
    if (!isSupported) return ProtectionStatus.unsupported;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>(
        'applySchedule',
        settings.toPlatformMap(),
      );
      return map == null ? await getStatus() : ProtectionStatus.fromMap(map);
    } catch (error) {
      debugPrint('applySchedule failed: $error');
      return await getStatus();
    }
  }

  Future<void> cancelSchedule() => _void('cancelSchedule');

  Future<Map<String, dynamic>> getSchedulePreview() async {
    if (!isSupported) return const {};
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('getSchedulePreview');
      return map ?? const {};
    } catch (_) {
      return const {};
    }
  }

  Future<ProtectionStatus> setServiceOptions(ServiceOptions options) async {
    if (!isSupported) return ProtectionStatus.unsupported;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>(
        'setServiceOptions',
        options.toJson(),
      );
      return map == null ? await getStatus() : ProtectionStatus.fromMap(map);
    } catch (error) {
      debugPrint('setServiceOptions failed: $error');
      return await getStatus();
    }
  }

  Future<void> setProfiles(List<AppProfile> profiles) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>(
        'setProfiles',
        profiles.map((p) => p.toJson()).toList(),
      );
    } catch (error) {
      debugPrint('setProfiles failed: $error');
    }
  }

  Future<void> setProfilesEnabled(bool enabled) => _void('setProfilesEnabled', {'enabled': enabled});

  Future<List<AppProfile>> installedApps() async {
    if (!isSupported) return const [];
    try {
      final list = await _channel.invokeListMethod<dynamic>('getInstalledApps');
      if (list == null) return const [];
      return list
          .whereType<Map>()
          .map((item) => AppProfile.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (error) {
      debugPrint('getInstalledApps failed: $error');
      return const [];
    }
  }

  Future<String?> foregroundApp() async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<String>('getForegroundApp');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> deviceInfo() async {
    if (!isSupported) return const {'manufacturer': 'Apple', 'model': 'iPhone'};
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      return map ?? const {};
    } catch (_) {
      return const {};
    }
  }

  /// Asks Android 13+ to offer the quick settings tile. Returns the platform
  /// result code; the user still has to confirm.
  Future<bool> requestQuickTile() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<int>('requestAddTile');
      // TILE_ADD_REQUEST_RESULT_TILE_ADDED == 2
      return result == 2;
    } catch (error) {
      debugPrint('requestAddTile failed: $error');
      return false;
    }
  }

  Future<bool> requestHomeWidget() => _bool('requestPinWidget');

  /// Pushes the eye care configuration to the native break scheduler.
  Future<Map<String, dynamic>> updateEyeCare(EyeCareSettings settings) async {
    if (!isSupported) return const {};
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>(
        'updateEyeCare',
        settings.toPlatformMap(),
      );
      return map ?? const {};
    } catch (error) {
      debugPrint('updateEyeCare failed: $error');
      return const {};
    }
  }

  Future<Map<String, dynamic>> eyeCareState() async {
    if (!isSupported) return const {};
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('getEyeCare');
      return map ?? const {};
    } catch (_) {
      return const {};
    }
  }

  /// Marks a break as completed, which resets the eye comfort score.
  Future<void> completeEyeBreak() => _void('completeEyeBreak');

  Future<void> snoozeEyeBreak() => _void('snoozeEyeBreak');

  /// Arms the next break one interval from now without notifying immediately.
  Future<void> startEyeBreakNow() => _void('startEyeBreakNow');

  /// Returns "eye_break" when the app was opened from a break notification.
  Future<String?> consumeLaunchAction() async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<String>('consumeLaunchAction');
    } catch (_) {
      return null;
    }
  }
}
