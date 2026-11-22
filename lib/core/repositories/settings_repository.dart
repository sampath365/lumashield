import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/app_profile.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/models/eye_care_settings.dart';
import '../../shared/models/filter_preset.dart';
import '../../shared/models/filter_settings.dart';
import '../../shared/models/schedule_settings.dart';
import '../../shared/models/service_options.dart';

/// All lightweight preferences live in SharedPreferences as JSON blobs. The
/// native service keeps its own mirror so it can restore state on boot.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _keyFilter = 'lumashield.filter';
  static const _keySchedule = 'lumashield.schedule';
  static const _keyEyeCare = 'lumashield.eyeCare';
  static const _keyApp = 'lumashield.app';
  static const _keyPresets = 'lumashield.presets';
  static const _keyProfiles = 'lumashield.profiles';
  static const _keyService = 'lumashield.service';

  T _read<T>(String key, T Function(Map<String, dynamic>) decode, T fallback) {
    final raw = _prefs.getString(key);
    if (raw == null) return fallback;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decode(decoded);
      if (decoded is Map) return decode(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // Corrupt or outdated value: fall back to defaults rather than crash.
    }
    return fallback;
  }

  FilterSettings readFilter() => _read(_keyFilter, FilterSettings.fromJson, const FilterSettings());

  Future<void> writeFilter(FilterSettings value) =>
      _prefs.setString(_keyFilter, jsonEncode(value.toJson()));

  ScheduleSettings readSchedule() =>
      _read(_keySchedule, ScheduleSettings.fromJson, const ScheduleSettings());

  Future<void> writeSchedule(ScheduleSettings value) =>
      _prefs.setString(_keySchedule, jsonEncode(value.toJson()));

  EyeCareSettings readEyeCare() =>
      _read(_keyEyeCare, EyeCareSettings.fromJson, const EyeCareSettings());

  Future<void> writeEyeCare(EyeCareSettings value) =>
      _prefs.setString(_keyEyeCare, jsonEncode(value.toJson()));

  AppSettings readApp() => _read(_keyApp, AppSettings.fromJson, const AppSettings());

  Future<void> writeApp(AppSettings value) =>
      _prefs.setString(_keyApp, jsonEncode(value.toJson()));

  ServiceOptions readService() =>
      _read(_keyService, ServiceOptions.fromJson, const ServiceOptions());

  Future<void> writeService(ServiceOptions value) =>
      _prefs.setString(_keyService, jsonEncode(value.toJson()));

  List<FilterPreset> readPresets() {
    final raw = _prefs.getString(_keyPresets);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => FilterPreset.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> writePresets(List<FilterPreset> value) => _prefs.setString(
    _keyPresets,
    jsonEncode(value.map((p) => p.toJson()).toList()),
  );

  List<AppProfile> readProfiles() {
    final raw = _prefs.getString(_keyProfiles);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => AppProfile.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> writeProfiles(List<AppProfile> value) => _prefs.setString(
    _keyProfiles,
    jsonEncode(value.map((p) => p.toJson()).toList()),
  );

  Future<void> clearAll() async {
    await Future.wait([
      _prefs.remove(_keyFilter),
      _prefs.remove(_keySchedule),
      _prefs.remove(_keyEyeCare),
      _prefs.remove(_keyApp),
      _prefs.remove(_keyPresets),
      _prefs.remove(_keyProfiles),
      _prefs.remove(_keyService),
    ]);
  }
}
