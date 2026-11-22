import 'package:flutter_test/flutter_test.dart';
import 'package:lumashield/shared/models/app_profile.dart';
import 'package:lumashield/shared/models/app_settings.dart';
import 'package:lumashield/shared/models/eye_care_settings.dart';
import 'package:lumashield/shared/models/filter_preset.dart';
import 'package:lumashield/shared/models/filter_settings.dart';
import 'package:lumashield/shared/models/protection_status.dart';
import 'package:lumashield/shared/models/schedule_settings.dart';
import 'package:lumashield/shared/models/service_options.dart';

void main() {
  group('FilterSettings', () {
    test('round trips through JSON', () {
      const value = FilterSettings(
        enabled: true,
        mode: FilterMode.sleep,
        intensity: 72,
        kelvin: 2700,
        customColor: 0xFFF0A44A,
        dim: 12,
      );
      final restored = FilterSettings.fromJson(value.toJson());
      expect(restored.enabled, value.enabled);
      expect(restored.mode, value.mode);
      expect(restored.intensity, value.intensity);
      expect(restored.kelvin, value.kelvin);
      expect(restored.customColor, value.customColor);
      expect(restored.dim, value.dim);
    });

    test('clamps out of range values', () {
      const value = FilterSettings(intensity: 500, kelvin: 100, dim: 900);
      final clamped = value.copyWith();
      expect(clamped.intensity, 100);
      expect(clamped.kelvin, 1900);
      expect(clamped.dim, 60);
    });

    test('applying a mode keeps the on state and adopts its values', () {
      const value = FilterSettings(enabled: true);
      final next = value.withMode(FilterMode.night);
      expect(next.enabled, isTrue);
      expect(next.kelvin, FilterMode.night.kelvin);
      expect(next.intensity, FilterMode.night.intensity);
    });

    test('platform map carries the fields the Kotlin service reads', () {
      const value = FilterSettings(enabled: true, intensity: 40, kelvin: 4000);
      final map = value.toPlatformMap();
      expect(map['enabled'], isTrue);
      expect(map['intensity'], 40);
      expect(map['kelvin'], 4000);
      expect(map['modeLabel'], isA<String>());
    });
  });

  group('ScheduleSettings', () {
    test('encodes weekdays as a mask', () {
      const settings = ScheduleSettings(weekdays: {1, 3, 5});
      expect(settings.daysMask, 0x15);
    });

    test('round trips and keeps the weekdays', () {
      const settings = ScheduleSettings(
        enabled: true,
        mode: ScheduleMode.sunsetSunrise,
        weekdays: {6, 7},
        latitude: 51.5,
        longitude: -0.12,
        useLocation: true,
      );
      final restored = ScheduleSettings.fromJson(settings.toJson());
      expect(restored.weekdays, {6, 7});
      expect(restored.mode, ScheduleMode.sunsetSunrise);
      expect(restored.hasLocation, isTrue);
    });

    test('detects windows that cross midnight', () {
      const settings = ScheduleSettings(startMinute: 22 * 60, endMinute: 6 * 60);
      expect(settings.crossesMidnight, isTrue);
    });
  });

  group('ProtectionStatus', () {
    test('reads the native map including millisecond timestamps', () {
      final status = ProtectionStatus.fromMap({
        'supported': true,
        'running': true,
        'enabled': true,
        'intensity': 55,
        'kelvin': 3300,
        'strength': 42,
        'overlayGranted': true,
        'nextActivation': DateTime(2026, 3, 10, 21).millisecondsSinceEpoch,
      });
      expect(status.active, isTrue);
      expect(status.intensity, 55);
      expect(status.nextActivation, DateTime(2026, 3, 10, 21));
    });

    test('unsupported status is inert', () {
      expect(ProtectionStatus.unsupported.active, isFalse);
      expect(ProtectionStatus.unsupported.supported, isFalse);
    });
  });

  group('Other models', () {
    test('app settings round trip', () {
      const settings = AppSettings(
        onboarded: true,
        themeVariant: ThemeVariant.amoled,
        accent: AccentChoice.sky,
        appLockEnabled: true,
      );
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.themeVariant, ThemeVariant.amoled);
      expect(restored.accent, AccentChoice.sky);
      expect(restored.appLockEnabled, isTrue);
    });

    test('eye care settings round trip', () {
      const settings = EyeCareSettings(twentyIntervalMin: 30, sleepTimeMinute: 1350);
      final restored = EyeCareSettings.fromJson(settings.toJson());
      expect(restored.twentyIntervalMin, 30);
      expect(restored.sleepTimeMinute, 1350);
    });

    test('service options round trip', () {
      const options = ServiceOptions(showNotification: false, autoRestart: false);
      final restored = ServiceOptions.fromJson(options.toJson());
      expect(restored.showNotification, isFalse);
      expect(restored.autoRestart, isFalse);
      expect(restored.restoreOnBoot, isTrue);
    });

    test('app profile round trip', () {
      const profile = AppProfile(
        packageName: 'com.example.app',
        label: 'Example',
        intensity: 30,
        kelvin: 3600,
      );
      final restored = AppProfile.fromJson(profile.toJson());
      expect(restored.packageName, 'com.example.app');
      expect(restored.intensity, 30);
      expect(restored.kelvin, 3600);
    });

    test('preset round trip', () {
      final preset = FilterPreset(
        id: '1',
        name: 'Evening',
        intensity: 60,
        kelvin: 3000,
        createdAt: DateTime(2026, 3, 1),
        favourite: true,
      );
      final restored = FilterPreset.fromJson(preset.toJson());
      expect(restored.name, 'Evening');
      expect(restored.favourite, isTrue);
      expect(restored.createdAt, DateTime(2026, 3, 1));
    });
  });
}
