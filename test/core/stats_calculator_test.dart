import 'package:flutter_test/flutter_test.dart';
import 'package:lumashield/core/services/stats_calculator.dart';
import 'package:lumashield/shared/models/protection_session.dart';

ProtectionSession session(
  DateTime start,
  DateTime end, {
  int intensity = 50,
  String mode = 'Night Mode',
}) => ProtectionSession(
  start: start,
  end: end,
  mode: mode,
  intensity: intensity,
  kelvin: 3400,
);

void main() {
  final now = DateTime(2026, 3, 10, 18);

  group('StatsCalculator', () {
    test('splits a session across midnight', () {
      final summary = StatsCalculator.summarize(
        [
          session(DateTime(2026, 3, 9, 23), DateTime(2026, 3, 10, 1)),
        ],
        now: now,
      );
      final yesterday = summary.days.firstWhere((d) => d.day.day == 9);
      final today = summary.days.firstWhere((d) => d.day.day == 10);
      expect(yesterday.minutes, 60);
      expect(today.minutes, 60);
    });

    test('includes the ongoing session', () {
      final summary = StatsCalculator.summarize(
        [session(DateTime(2026, 3, 10, 8), DateTime(2026, 3, 10, 9))],
        now: now,
        ongoing: const Duration(minutes: 30),
      );
      expect(summary.todayMinutes, 90);
    });

    test('ignores sessions outside the window', () {
      final summary = StatsCalculator.summarize(
        [session(DateTime(2026, 1, 1, 10), DateTime(2026, 1, 1, 12))],
        now: now,
      );
      expect(summary.weekMinutes, 0);
      expect(summary.totalSessions, 1);
    });

    test('counts a streak of consecutive days', () {
      final summary = StatsCalculator.summarize(
        [
          session(DateTime(2026, 3, 10, 9), DateTime(2026, 3, 10, 11)),
          session(DateTime(2026, 3, 9, 9), DateTime(2026, 3, 9, 11)),
          session(DateTime(2026, 3, 8, 9), DateTime(2026, 3, 8, 11)),
        ],
        now: now,
      );
      expect(summary.currentStreakDays, 3);
    });

    test('average intensity is based on active days', () {
      final summary = StatsCalculator.summarize(
        [
          session(DateTime(2026, 3, 10, 9), DateTime(2026, 3, 10, 10), intensity: 40),
          session(DateTime(2026, 3, 9, 9), DateTime(2026, 3, 9, 10), intensity: 60),
        ],
        now: now,
      );
      expect(summary.avgIntensity, 50);
    });

    test('empty history produces an empty but valid summary', () {
      final summary = StatsCalculator.summarize(const [], now: now);
      expect(summary.weekMinutes, 0);
      expect(summary.days.length, 7);
      expect(summary.currentStreakDays, 0);
      expect(StatsCalculator.averageDailyMinutes(summary), 0);
    });

    test('thirty day window returns thirty buckets', () {
      final summary = StatsCalculator.summarize(const [], now: now, days: 30);
      expect(summary.days.length, 30);
      expect(summary.days.last.day, DateTime(2026, 3, 10));
    });
  });
}
