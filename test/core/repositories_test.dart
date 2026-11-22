import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:lumashield/core/repositories/history_repository.dart';
import 'package:lumashield/core/repositories/settings_repository.dart';
import 'package:lumashield/shared/models/filter_settings.dart';
import 'package:lumashield/shared/models/protection_session.dart';
import 'package:lumashield/shared/models/schedule_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryRepository', () {
    late Directory dir;
    late Box<dynamic> box;
    late HistoryRepository repository;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('lumashield_history');
      Hive.init(dir.path);
      box = await Hive.openBox<dynamic>('history_test');
      repository = HistoryRepository(box);
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('stores and reads sessions in reverse order', () async {
      await repository.add(
        ProtectionSession(
          start: DateTime(2026, 3, 9, 10),
          end: DateTime(2026, 3, 9, 11),
          mode: 'Night',
          intensity: 60,
          kelvin: 3200,
        ),
      );
      await repository.add(
        ProtectionSession(
          start: DateTime(2026, 3, 10, 10),
          end: DateTime(2026, 3, 10, 12),
          mode: 'Night',
          intensity: 60,
          kelvin: 3200,
        ),
      );
      final sessions = repository.all();
      expect(sessions.length, 2);
      expect(sessions.first.start.day, 10);
    });

    test('ignores sessions shorter than the noise threshold', () async {
      await repository.add(
        ProtectionSession(
          start: DateTime(2026, 3, 10, 10, 0, 0),
          end: DateTime(2026, 3, 10, 10, 0, 5),
          mode: 'Night',
          intensity: 60,
          kelvin: 3200,
        ),
      );
      expect(repository.all(), isEmpty);
    });

    test('prunes sessions older than the retention window', () async {
      await repository.add(
        ProtectionSession(
          start: DateTime.now().subtract(const Duration(days: 400)),
          end: DateTime.now().subtract(const Duration(days: 400)).add(
            const Duration(minutes: 30),
          ),
          mode: 'Old',
          intensity: 40,
          kelvin: 4000,
        ),
      );
      await repository.prune(retention: const Duration(days: 30));
      expect(repository.all(), isEmpty);
    });

    test('clear removes everything', () async {
      await repository.add(
        ProtectionSession(
          start: DateTime(2026, 3, 10, 10),
          end: DateTime(2026, 3, 10, 11),
          mode: 'Night',
          intensity: 60,
          kelvin: 3200,
        ),
      );
      await repository.clear();
      expect(repository.all(), isEmpty);
    });
  });

  group('SettingsRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns defaults on a fresh install', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);
      expect(repository.readFilter().enabled, isFalse);
      expect(repository.readSchedule().weekdays.length, 7);
      expect(repository.readPresets(), isEmpty);
      expect(repository.readApp().onboarded, isFalse);
    });

    test('persists filter and schedule values', () async {
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);
      await repository.writeFilter(
        const FilterSettings(enabled: true, intensity: 70, kelvin: 2800),
      );
      await repository.writeSchedule(
        const ScheduleSettings(enabled: true, weekdays: {1, 2}),
      );
      final filter = repository.readFilter();
      expect(filter.enabled, isTrue);
      expect(filter.intensity, 70);
      expect(filter.kelvin, 2800);
      expect(repository.readSchedule().weekdays, {1, 2});
    });

    test('survives corrupt stored values', () async {
      SharedPreferences.setMockInitialValues({'lumashield.filter': 'not json'});
      final prefs = await SharedPreferences.getInstance();
      final repository = SettingsRepository(prefs);
      expect(repository.readFilter().intensity, 45);
    });
  });
}
