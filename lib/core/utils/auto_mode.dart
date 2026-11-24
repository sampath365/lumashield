import '../../shared/models/filter_settings.dart';
import '../../shared/models/schedule_settings.dart';
import '../services/schedule_calculator.dart';

/// Decides which mode the schedule wants right now.
///
/// Returns null when the schedule is off or automatic switching is disabled, so
/// a manual choice is never overridden unless the user asked for it.
FilterMode? scheduledModeFor(DateTime now, ScheduleSettings schedule) {
  if (!schedule.enabled || !schedule.autoMode) return null;
  return ScheduleCalculator.isNightNow(schedule, now: now)
      ? FilterMode.night
      : FilterMode.normal;
}

/// True when the filter should be running at [now] according to the schedule.
bool scheduledActiveFor(DateTime now, ScheduleSettings schedule) {
  if (!schedule.enabled) return false;
  return ScheduleCalculator.isNightNow(schedule, now: now)
      ? true
      : schedule.dayIntensity > 0;
}
