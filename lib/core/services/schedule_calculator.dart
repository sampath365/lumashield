import '../../shared/models/schedule_settings.dart';
import '../utils/solar.dart';

/// A window during which the stronger night filter applies.
class ScheduleWindow {
  const ScheduleWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      moment.isAtSameMomentAs(start) || (moment.isAfter(start) && moment.isBefore(end));
}

/// Pure Dart mirror of SchedulePlanner.kt. Used for previews, iOS reminders and
/// unit tests; Android delegates the real work to the native alarms.
class ScheduleCalculator {
  ScheduleCalculator._();

  static List<ScheduleWindow> windowsAround(
    ScheduleSettings settings, {
    DateTime? now,
    int daysBack = 2,
    int daysForward = 8,
  }) {
    if (!settings.enabled) return const [];
    final moment = now ?? DateTime.now();
    final today = DateTime(moment.year, moment.month, moment.day);
    final windows = <ScheduleWindow>[];

    for (var offset = -daysBack; offset <= daysForward; offset++) {
      final day = today.add(Duration(days: offset));
      if (!settings.weekdays.contains(day.weekday)) continue;

      if (settings.mode == ScheduleMode.sunsetSunrise && settings.hasLocation) {
        final sunset = Solar.sunset(day, settings.latitude, settings.longitude);
        final sunrise = Solar.sunrise(
          day.add(const Duration(days: 1)),
          settings.latitude,
          settings.longitude,
        );
        if (sunset == null || sunrise == null) continue;
        final start = sunset.add(Duration(minutes: settings.sunsetOffsetMin));
        final end = sunrise.add(Duration(minutes: settings.sunriseOffsetMin));
        if (end.isAfter(start)) windows.add(ScheduleWindow(start, end));
      } else {
        final start = day.add(Duration(minutes: settings.startMinute));
        final endMinutes = settings.endMinute <= settings.startMinute
            ? settings.endMinute + 1440
            : settings.endMinute;
        final end = day.add(Duration(minutes: endMinutes));
        windows.add(ScheduleWindow(start, end));
      }
    }
    windows.sort((a, b) => a.start.compareTo(b.start));
    return windows;
  }

  static bool isNightNow(ScheduleSettings settings, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    return windowsAround(settings, now: moment).any((w) => w.contains(moment));
  }

  static DateTime? nextActivation(ScheduleSettings settings, {DateTime? now}) {
    if (!settings.enabled) return null;
    final moment = now ?? DateTime.now();
    final upcoming = windowsAround(settings, now: moment)
        .map((w) => w.start)
        .where((start) => start.isAfter(moment))
        .toList()
      ..sort();
    return upcoming.isEmpty ? null : upcoming.first;
  }

  static DateTime? nextDeactivation(ScheduleSettings settings, {DateTime? now}) {
    if (!settings.enabled) return null;
    final moment = now ?? DateTime.now();
    final upcoming = windowsAround(settings, now: moment)
        .map((w) => w.end)
        .where((end) => end.isAfter(moment))
        .toList()
      ..sort();
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// The next boundary of either kind, which is what the UI shows as
  /// "next automatic change".
  static DateTime? nextChange(ScheduleSettings settings, {DateTime? now}) {
    final moment = now ?? DateTime.now();
    final candidates = [nextActivation(settings, now: moment), nextDeactivation(settings, now: moment)]
        .whereType<DateTime>()
        .toList()
      ..sort();
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Sunrise and sunset for the schedule card, when a location is available.
  static ({DateTime? sunrise, DateTime? sunset}) todaySun(ScheduleSettings settings, {DateTime? now}) {
    if (!settings.hasLocation) return (sunrise: null, sunset: null);
    final moment = now ?? DateTime.now();
    return (
      sunrise: Solar.sunrise(moment, settings.latitude, settings.longitude),
      sunset: Solar.sunset(moment, settings.latitude, settings.longitude),
    );
  }
}
