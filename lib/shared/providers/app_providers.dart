import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/repositories/history_repository.dart';
import '../../core/repositories/settings_repository.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/filter_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/stats_calculator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/platform_capabilities.dart';
import '../models/app_profile.dart';
import '../models/app_settings.dart';
import '../models/eye_care_settings.dart';
import '../models/filter_preset.dart';
import '../models/filter_settings.dart';
import '../models/protection_session.dart';
import '../models/protection_status.dart';
import '../models/schedule_settings.dart';
import '../models/service_options.dart';

/// Injected in main() after the platform stores are open.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final historyBoxProvider = Provider<Box<dynamic>>(
  (ref) => throw UnimplementedError('historyBoxProvider must be overridden'),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('notificationServiceProvider must be overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(historyBoxProvider)),
);

final filterServiceProvider = Provider<FilterService>((ref) => const FilterService());

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());

final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(ref.watch(filterServiceProvider), ref.watch(notificationServiceProvider)),
);

/// Bumped whenever stored history changes so derived providers recompute.
class StatsRefresh extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final statsRefreshProvider = NotifierProvider<StatsRefresh, int>(StatsRefresh.new);

// ---------------------------------------------------------------------------
// Filter
// ---------------------------------------------------------------------------

class FilterController extends Notifier<FilterSettings> {
  DateTime? _sessionStart;

  @override
  FilterSettings build() {
    final stored = ref.watch(settingsRepositoryProvider).readFilter();
    if (stored.enabled) _sessionStart = DateTime.now();
    return stored;
  }

  DateTime? get sessionStart => _sessionStart;

  Duration get sessionDuration =>
      _sessionStart == null ? Duration.zero : DateTime.now().difference(_sessionStart!);

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);
  FilterService get _service => ref.read(filterServiceProvider);

  Future<void> _persist({bool push = true}) async {
    await _repo.writeFilter(state);
    if (!push) return;
    if (!PlatformCapabilities.systemOverlay) return;
    if (state.enabled) {
      final status = await _service.update(state);
      if (!status.enabled && state.enabled) {
        // The native side refused (permission revoked or overlay blocked).
        state = state.copyWith(enabled: false);
        await _repo.writeFilter(state);
        _endSession();
      }
    } else {
      await _service.stop();
    }
    ref.invalidate(statusProvider);
  }

  void _startSession() {
    _sessionStart = DateTime.now();
  }

  void _endSession() {
    final start = _sessionStart;
    _sessionStart = null;
    if (start == null) return;
    final session = ProtectionSession(
      start: start,
      end: DateTime.now(),
      mode: state.mode.label,
      intensity: state.intensity,
      kelvin: state.kelvin,
    );
    ref.read(historyRepositoryProvider).add(session).then((_) {
      ref.read(statsRefreshProvider.notifier).bump();
    });
  }

  /// Returns false when the overlay permission is missing so the UI can guide
  /// the user instead of silently failing.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled && PlatformCapabilities.systemOverlay) {
      final granted = await _service.isOverlayGranted();
      if (!granted) return false;
    }
    state = state.copyWith(enabled: enabled);
    if (enabled) {
      _startSession();
      if (PlatformCapabilities.systemOverlay) {
        final status = await _service.start(state);
        if (!status.enabled) {
          state = state.copyWith(enabled: false);
          _sessionStart = null;
          await _repo.writeFilter(state);
          ref.invalidate(statusProvider);
          return false;
        }
      }
    } else {
      _endSession();
    }
    await _persist();
    return true;
  }

  Future<void> toggle() => setEnabled(!state.enabled);

  Future<void> setMode(FilterMode mode) async {
    state = state.withMode(mode);
    await _persist();
  }

  Future<void> setIntensity(int intensity) async {
    state = state.copyWith(intensity: intensity);
    await _persist();
  }

  Future<void> setKelvin(int kelvin) async {
    state = state.copyWith(kelvin: kelvin);
    await _persist();
  }

  Future<void> setDim(int dim) async {
    state = state.copyWith(dim: dim);
    await _persist();
  }

  Future<void> setCustomColor(int? color) async {
    state = color == null
        ? state.copyWith(clearCustomColor: true)
        : state.copyWith(customColor: color, mode: FilterMode.custom);
    await _persist();
  }

  Future<void> applyPreset(FilterPreset preset) async {
    state = state.copyWith(
      mode: FilterMode.custom,
      intensity: preset.intensity,
      kelvin: preset.kelvin,
      customColor: preset.customColor,
      clearCustomColor: preset.customColor == null,
    );
    await _persist();
  }

  /// Applies a filter coming from the native side (tile, widget, schedule).
  Future<void> syncFromPlatform(ProtectionStatus status) async {
    if (!status.supported) return;
    if (status.enabled == state.enabled &&
        status.intensity == state.intensity &&
        status.kelvin == state.kelvin) {
      return;
    }
    state = state.copyWith(
      enabled: status.enabled,
      intensity: status.intensity,
      kelvin: status.kelvin,
      dim: status.dim,
    );
    if (status.enabled && _sessionStart == null) _startSession();
    if (!status.enabled && _sessionStart != null) _endSession();
    await _repo.writeFilter(state);
    ref.invalidate(statsProvider);
  }

  Future<void> emergencyDisable() async {
    _endSession();
    state = state.copyWith(enabled: false);
    await _repo.writeFilter(state);
    if (PlatformCapabilities.systemOverlay) {
      await _service.emergencyDisable();
    }
    ref.read(scheduleControllerProvider.notifier).disableSilently();
    ref.invalidate(statusProvider);
    ref.read(statsRefreshProvider.notifier).bump();
  }
}

final filterControllerProvider = NotifierProvider<FilterController, FilterSettings>(
  FilterController.new,
);

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

/// Live native state. The first value comes from a direct query, then the
/// event channel keeps it fresh when the tile, widget or service changes it.
final statusProvider = StreamProvider<ProtectionStatus>((ref) async* {
  final service = ref.watch(filterServiceProvider);
  yield await service.getStatus();
  yield* service.statusStream();
});

final protectionStatusProvider = Provider<ProtectionStatus>((ref) {
  final async = ref.watch(statusProvider);
  return async.value ?? ProtectionStatus.unsupported;
});

final protectionActiveProvider = Provider<bool>((ref) {
  final filter = ref.watch(filterControllerProvider);
  return filter.enabled;
});

// ---------------------------------------------------------------------------
// Schedule
// ---------------------------------------------------------------------------

class ScheduleController extends Notifier<ScheduleSettings> {
  @override
  ScheduleSettings build() => ref.watch(settingsRepositoryProvider).readSchedule();

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  Future<void> _save() async {
    await _repo.writeSchedule(state);
    if (PlatformCapabilities.systemOverlay) {
      await ref.read(filterServiceProvider).applySchedule(state);
      ref.invalidate(statusProvider);
    }
    await ref.read(notificationServiceProvider).rescheduleReminders(
      ref.read(eyeCareControllerProvider),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _save();
  }

  void disableSilently() {
    state = state.copyWith(enabled: false);
    _repo.writeSchedule(state);
  }

  Future<void> setMode(ScheduleMode mode) async {
    state = state.copyWith(mode: mode);
    await _save();
  }

  Future<void> setStart(int minute) async {
    state = state.copyWith(startMinute: minute);
    await _save();
  }

  Future<void> setEnd(int minute) async {
    state = state.copyWith(endMinute: minute);
    await _save();
  }

  Future<void> toggleDay(int weekday) async {
    final days = Set<int>.from(state.weekdays);
    if (!days.remove(weekday)) days.add(weekday);
    state = state.copyWith(weekdays: days);
    await _save();
  }

  Future<void> setWeekdays(Set<int> days) async {
    state = state.copyWith(weekdays: days);
    await _save();
  }

  Future<void> setNightIntensity(int value) async {
    state = state.copyWith(nightIntensity: value);
    await _save();
  }

  Future<void> setNightKelvin(int value) async {
    state = state.copyWith(nightKelvin: value);
    await _save();
  }

  Future<void> setDayIntensity(int value) async {
    state = state.copyWith(dayIntensity: value);
    await _save();
  }

  Future<void> setDayKelvin(int value) async {
    state = state.copyWith(dayKelvin: value);
    await _save();
  }

  Future<void> setLocation({required double latitude, required double longitude}) async {
    state = state.copyWith(
      useLocation: true,
      mode: ScheduleMode.sunsetSunrise,
      latitude: latitude,
      longitude: longitude,
    );
    await _save();
  }

  Future<void> clearLocation() async {
    state = state.copyWith(useLocation: false, latitude: 0, longitude: 0);
    await _save();
  }

  Future<void> setSunsetOffset(int minutes) async {
    state = state.copyWith(sunsetOffsetMin: minutes);
    await _save();
  }

  Future<void> setSunriseOffset(int minutes) async {
    state = state.copyWith(sunriseOffsetMin: minutes);
    await _save();
  }
}

final scheduleControllerProvider = NotifierProvider<ScheduleController, ScheduleSettings>(
  ScheduleController.new,
);

// ---------------------------------------------------------------------------
// Eye care
// ---------------------------------------------------------------------------

class EyeCareController extends Notifier<EyeCareSettings> {
  @override
  EyeCareSettings build() {
    final stored = ref.watch(settingsRepositoryProvider).readEyeCare();
    // Hand the settings to the native scheduler so breaks survive app death.
    Future.microtask(() async {
      await ref.read(filterServiceProvider).updateEyeCare(stored);
      ref.invalidate(statusProvider);
    });
    return stored;
  }

  Future<void> update(EyeCareSettings Function(EyeCareSettings) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).writeEyeCare(state);
    if (PlatformCapabilities.systemOverlay) {
      await ref.read(filterServiceProvider).updateEyeCare(state);
      ref.invalidate(statusProvider);
    }
    await ref.read(notificationServiceProvider).rescheduleReminders(state);
  }

  Future<void> reset() async {
    state = const EyeCareSettings();
    await ref.read(settingsRepositoryProvider).writeEyeCare(state);
    if (PlatformCapabilities.systemOverlay) {
      await ref.read(filterServiceProvider).updateEyeCare(state);
      ref.invalidate(statusProvider);
    }
    await ref.read(notificationServiceProvider).rescheduleReminders(state);
  }

  /// Logs a completed break, resetting the native eye comfort score.
  Future<void> completeBreak() async {
    if (PlatformCapabilities.systemOverlay) {
      await ref.read(filterServiceProvider).completeEyeBreak();
      ref.invalidate(statusProvider);
    }
  }
}

final eyeCareControllerProvider = NotifierProvider<EyeCareController, EyeCareSettings>(
  EyeCareController.new,
);

// ---------------------------------------------------------------------------
// App settings, theme and service options
// ---------------------------------------------------------------------------

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).readApp();

  Future<void> update(AppSettings Function(AppSettings) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).writeApp(state);
  }

  Future<void> completeOnboarding() => update((s) => s.copyWith(onboarded: true));
}

final appSettingsControllerProvider = NotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

class ThemeBundle {
  const ThemeBundle({required this.theme, required this.darkTheme, required this.mode});

  final ThemeData theme;
  final ThemeData darkTheme;
  final ThemeMode mode;
}

final themeBundleProvider = Provider<ThemeBundle>((ref) {
  final settings = ref.watch(appSettingsControllerProvider);
  final darkPalette = AppTheme.build(ThemeVariant.midnight, settings.accent);
  final lightPalette = AppTheme.build(ThemeVariant.daylight, settings.accent);
  switch (settings.themeVariant) {
    case ThemeVariant.amoled:
      return ThemeBundle(
        theme: AppTheme.build(ThemeVariant.amoled, settings.accent),
        darkTheme: AppTheme.build(ThemeVariant.amoled, settings.accent),
        mode: ThemeMode.dark,
      );
    case ThemeVariant.daylight:
      return ThemeBundle(theme: lightPalette, darkTheme: lightPalette, mode: ThemeMode.light);
    case ThemeVariant.system:
      return ThemeBundle(theme: lightPalette, darkTheme: darkPalette, mode: ThemeMode.system);
    case ThemeVariant.midnight:
      return ThemeBundle(theme: darkPalette, darkTheme: darkPalette, mode: ThemeMode.dark);
  }
});

class ServiceOptionsController extends Notifier<ServiceOptions> {
  @override
  ServiceOptions build() => ref.watch(settingsRepositoryProvider).readService();

  Future<void> update(ServiceOptions Function(ServiceOptions) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).writeService(state);
    if (PlatformCapabilities.systemOverlay) {
      await ref.read(filterServiceProvider).setServiceOptions(state);
      ref.invalidate(statusProvider);
    }
  }
}

final serviceOptionsControllerProvider =
    NotifierProvider<ServiceOptionsController, ServiceOptions>(ServiceOptionsController.new);

// ---------------------------------------------------------------------------
// Permissions
// ---------------------------------------------------------------------------

class PermissionsController extends Notifier<PermissionSnapshot> {
  @override
  PermissionSnapshot build() {
    Future.microtask(refresh);
    return PermissionSnapshot.unknown;
  }

  Future<void> refresh() async {
    final status = await ref.read(filterServiceProvider).getStatus();
    state = await ref.read(permissionServiceProvider).snapshot(status: status);
  }

  Future<bool> requestNotifications() async {
    final granted = await ref.read(notificationServiceProvider).requestPermission();
    await refresh();
    return granted;
  }

  Future<void> openOverlay() async {
    await ref.read(filterServiceProvider).openOverlaySettings();
  }

  Future<void> requestBatteryExemption() async {
    await ref.read(filterServiceProvider).requestIgnoreBatteryOptimizations();
  }

  Future<void> openUsageAccess() async {
    await ref.read(filterServiceProvider).openUsageAccessSettings();
  }

  Future<void> openExactAlarms() async {
    await ref.read(filterServiceProvider).openExactAlarmSettings();
  }
}

final permissionsControllerProvider =
    NotifierProvider<PermissionsController, PermissionSnapshot>(PermissionsController.new);

// ---------------------------------------------------------------------------
// Profiles and presets
// ---------------------------------------------------------------------------

class ProfilesController extends Notifier<List<AppProfile>> {
  @override
  List<AppProfile> build() => ref.watch(settingsRepositoryProvider).readProfiles();

  Future<void> upsert(AppProfile profile) async {
    final next = [...state.where((p) => p.packageName != profile.packageName), profile]
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    state = next;
    await ref.read(settingsRepositoryProvider).writeProfiles(next);
    await ref.read(filterServiceProvider).setProfiles(next);
  }

  Future<void> remove(String packageName) async {
    final next = state.where((p) => p.packageName != packageName).toList();
    state = next;
    await ref.read(settingsRepositoryProvider).writeProfiles(next);
    await ref.read(filterServiceProvider).setProfiles(next);
  }

  Future<void> setEnabled(bool enabled) async {
    await ref.read(filterServiceProvider).setProfilesEnabled(enabled);
  }
}

final profilesControllerProvider = NotifierProvider<ProfilesController, List<AppProfile>>(
  ProfilesController.new,
);

final installedAppsProvider = FutureProvider<List<AppProfile>>((ref) async {
  final apps = await ref.watch(filterServiceProvider).installedApps();
  return apps;
});

class PresetsController extends Notifier<List<FilterPreset>> {
  @override
  List<FilterPreset> build() => ref.watch(settingsRepositoryProvider).readPresets();

  Future<void> add(FilterPreset preset) async {
    state = [...state, preset];
    await ref.read(settingsRepositoryProvider).writePresets(state);
  }

  Future<void> remove(String id) async {
    state = state.where((p) => p.id != id).toList();
    await ref.read(settingsRepositoryProvider).writePresets(state);
  }

  Future<void> toggleFavourite(String id) async {
    state = [
      for (final preset in state)
        preset.id == id ? preset.copyWith(favourite: !preset.favourite) : preset,
    ];
    await ref.read(settingsRepositoryProvider).writePresets(state);
  }
}

final presetsControllerProvider = NotifierProvider<PresetsController, List<FilterPreset>>(
  PresetsController.new,
);

// ---------------------------------------------------------------------------
// Statistics
// ---------------------------------------------------------------------------

final statsProvider = Provider<StatsSummary>((ref) {
  ref.watch(statsRefreshProvider);
  final history = ref.watch(historyRepositoryProvider);
  final filter = ref.watch(filterControllerProvider);
  final controller = ref.watch(filterControllerProvider.notifier);
  final ongoing = filter.enabled ? controller.sessionDuration : Duration.zero;
  return StatsCalculator.summarize(history.all(), ongoing: ongoing);
});

final sessionsProvider = Provider<List<ProtectionSession>>((ref) {
  ref.watch(statsRefreshProvider);
  return ref.watch(historyRepositoryProvider).all();
});

// ---------------------------------------------------------------------------
// App lock
// ---------------------------------------------------------------------------

class AppLockController extends Notifier<bool> {
  /// True when the UI is unlocked (or the lock is disabled).
  @override
  bool build() => !ref.watch(appSettingsControllerProvider).appLockEnabled;

  Future<bool> unlock() async {
    final ok = await ref.read(biometricServiceProvider).authenticate();
    if (ok) state = true;
    return ok;
  }

  void lock() => state = false;

  void syncWithSetting() {
    final enabled = ref.read(appSettingsControllerProvider).appLockEnabled;
    state = !enabled;
  }
}

final appLockProvider = NotifierProvider<AppLockController, bool>(AppLockController.new);

final biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricServiceProvider).isAvailable(),
);
