import 'package:flutter_test/flutter_test.dart';
import 'package:lumashield/core/services/schedule_calculator.dart';
import 'package:lumashield/shared/models/schedule_settings.dart';

void main() {
  const overnight = ScheduleSettings(
    enabled: true,
    startMinute: 21 * 60,
    endMinute: 7 * 60,
    nightIntensity: 65,
    nightKelvin: 3200,
  );

  group('ScheduleCalculator custom windows', () {
    test('reports night inside an overnight window', () {
      final now = DateTime(2026, 3, 10, 22, 30);
      expect(ScheduleCalculator.isNightNow(overnight, now: now), isTrue);
    });

    test('reports day outside the window', () {
      final now = DateTime(2026, 3, 10, 12);
      expect(ScheduleCalculator.isNightNow(overnight, now: now), isFalse);
    });

    test('counts the early morning tail of an overnight window', () {
      final now = DateTime(2026, 3, 10, 2, 30);
      expect(ScheduleCalculator.isNightNow(overnight, now: now), isTrue);
    });

    test('next activation is later the same day', () {
      final now = DateTime(2026, 3, 10, 12);
      final next = ScheduleCalculator.nextActivation(overnight, now: now);
      expect(next, DateTime(2026, 3, 10, 21));
    });

    test('next deactivation is the following morning', () {
      final now = DateTime(2026, 3, 10, 22);
      final next = ScheduleCalculator.nextDeactivation(overnight, now: now);
      expect(next, DateTime(2026, 3, 11, 7));
    });

    test('a daytime window works too', () {
      const daytime = ScheduleSettings(
        enabled: true,
        startMinute: 9 * 60,
        endMinute: 17 * 60,
      );
      expect(
        ScheduleCalculator.isNightNow(daytime, now: DateTime(2026, 3, 10, 10)),
        isTrue,
      );
      expect(
        ScheduleCalculator.isNightNow(daytime, now: DateTime(2026, 3, 10, 18)),
        isFalse,
      );
    });

    test('disabled schedules never activate', () {
      const disabled = ScheduleSettings(enabled: false);
      expect(ScheduleCalculator.isNightNow(disabled), isFalse);
      expect(ScheduleCalculator.nextActivation(disabled), isNull);
    });
  });

  group('ScheduleCalculator weekday filtering', () {
    test('skips days that are not selected', () {
      const mondaysOnly = ScheduleSettings(
        enabled: true,
        weekdays: {1},
        startMinute: 21 * 60,
        endMinute: 7 * 60,
      );
      // Tuesday 10 March 2026.
      final now = DateTime(2026, 3, 10, 12);
      expect(ScheduleCalculator.isNightNow(mondaysOnly, now: now), isFalse);
      final next = ScheduleCalculator.nextActivation(mondaysOnly, now: now);
      expect(next, DateTime(2026, 3, 16, 21));
    });
  });

  group('ScheduleCalculator sunset mode', () {
    test('uses real sunset and sunrise when a location is present', () {
      final settings = ScheduleSettings(
        enabled: true,
        mode: ScheduleMode.sunsetSunrise,
        useLocation: true,
        latitude: 51.5074,
        longitude: -0.1278,
      );
      final now = DateTime(2026, 6, 21, 12);
      final sun = ScheduleCalculator.todaySun(settings, now: now);
      expect(sun.sunset, isNotNull);
      expect(sun.sunrise, isNotNull);
      final next = ScheduleCalculator.nextActivation(settings, now: now);
      expect(next, isNotNull);
      expect(next!.hour, inInclusiveRange(20, 22));
    });

    test('falls back to custom times without a location', () {
      const settings = ScheduleSettings(
        enabled: true,
        mode: ScheduleMode.sunsetSunrise,
        startMinute: 20 * 60,
        endMinute: 6 * 60,
      );
      final now = DateTime(2026, 6, 21, 12);
      final next = ScheduleCalculator.nextActivation(settings, now: now);
      expect(next, DateTime(2026, 6, 21, 20));
    });
  });
}
