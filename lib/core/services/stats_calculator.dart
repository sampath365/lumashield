import '../../shared/models/protection_session.dart';

/// Pure aggregation of locally stored sessions. Kept free of Flutter imports so
/// it is easy to unit test.
class StatsCalculator {
  StatsCalculator._();

  static StatsSummary summarize(
    List<ProtectionSession> sessions, {
    DateTime? now,
    Duration ongoing = Duration.zero,
    int days = 7,
  }) {
    final moment = now ?? DateTime.now();
    final today = DateTime(moment.year, moment.month, moment.day);
    final start = today.subtract(Duration(days: days - 1));

    final buckets = <DateTime, int>{};
    final counts = <DateTime, int>{};
    final intensitySum = <DateTime, int>{};

    for (final session in sessions) {
      final overlapStart = session.start.isAfter(start) ? session.start : start;
      final overlapEnd = session.end.isBefore(moment) ? session.end : moment;
      if (!overlapEnd.isAfter(overlapStart)) continue;

      var cursor = overlapStart;
      while (cursor.isBefore(overlapEnd)) {
        final day = DateTime(cursor.year, cursor.month, cursor.day);
        final nextDay = day.add(const Duration(days: 1));
        final segmentEnd = overlapEnd.isBefore(nextDay) ? overlapEnd : nextDay;
        final minutes = segmentEnd.difference(cursor).inMinutes;
        buckets[day] = (buckets[day] ?? 0) + minutes;
        counts[day] = (counts[day] ?? 0) + 1;
        intensitySum[day] = (intensitySum[day] ?? 0) + session.intensity;
        cursor = segmentEnd;
      }
    }

    if (ongoing > Duration.zero) {
      buckets[today] = (buckets[today] ?? 0) + ongoing.inMinutes;
      intensitySum[today] = (intensitySum[today] ?? 0) + 0;
    }

    final dailyStats = List.generate(days, (index) {
      final day = start.add(Duration(days: index));
      final minutes = buckets[day] ?? 0;
      final count = counts[day] ?? 0;
      final avg = count == 0 ? 0 : (intensitySum[day] ?? 0) ~/ count;
      return DailyStat(day: day, minutes: minutes, sessions: count, avgIntensity: avg);
    });

    final weekMinutes = dailyStats.fold<int>(0, (sum, day) => sum + day.minutes);
    final todayMinutes = buckets[today] ?? 0;
    final totalSessions = sessions.length;

    var streak = 0;
    var cursor = today;
    while (true) {
      final minutes = buckets[cursor] ?? 0;
      if (minutes >= 5) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (streak == 0 && cursor == today) {
        // Today may simply not have started yet.
        cursor = cursor.subtract(const Duration(days: 1));
        final yesterday = buckets[cursor] ?? 0;
        if (yesterday < 5) break;
      } else {
        break;
      }
      if (streak > 365) break;
    }

    final activeDays = dailyStats.where((d) => d.minutes > 0).toList();
    final avgIntensity = activeDays.isEmpty
        ? 0
        : activeDays.fold<int>(0, (sum, d) => sum + d.avgIntensity) ~/ activeDays.length;

    return StatsSummary(
      days: dailyStats,
      todayMinutes: todayMinutes,
      weekMinutes: weekMinutes,
      totalSessions: totalSessions,
      currentStreakDays: streak,
      avgIntensity: avgIntensity,
    );
  }

  /// Average protection per day over the window, used by the report card.
  static int averageDailyMinutes(StatsSummary summary) {
    if (summary.days.isEmpty) return 0;
    return summary.weekMinutes ~/ summary.days.length;
  }
}
