import 'package:flutter_test/flutter_test.dart';
import 'package:lumashield/core/utils/auto_mode.dart';
import 'package:lumashield/shared/models/filter_settings.dart';
import 'package:lumashield/shared/models/schedule_settings.dart';

void main() {
  ScheduleSettings nightly({bool enabled = true, bool autoMode = true}) =>
      ScheduleSettings(
        enabled: enabled,
        autoMode: autoMode,
        startMinute: 20 * 60,
        endMinute: 7 * 60,
        nightIntensity: 70,
        dayIntensity: 20,
      );

  test('night window switches to Night mode', () {
    final mode = scheduledModeFor(DateTime(2026, 11, 23, 22, 0), nightly());
    expect(mode, FilterMode.night);
  });

  test('daytime switches back to Normal mode', () {
    final mode = scheduledModeFor(DateTime(2026, 11, 23, 13, 0), nightly());
    expect(mode, FilterMode.normal);
  });

  test('the window wraps midnight correctly', () {
    expect(
      scheduledModeFor(DateTime(2026, 11, 24, 2, 0), nightly()),
      FilterMode.night,
    );
    expect(
      scheduledModeFor(DateTime(2026, 11, 23, 19, 59), nightly()),
      FilterMode.normal,
    );
  });

  test('a disabled schedule never overrides the user', () {
    expect(
      scheduledModeFor(DateTime(2026, 11, 23, 22, 0), nightly(enabled: false)),
      isNull,
    );
  });

  test('automatic switching can be turned off', () {
    expect(
      scheduledModeFor(DateTime(2026, 11, 23, 22, 0), nightly(autoMode: false)),
      isNull,
    );
  });

  test('scheduled activity follows the day intensity', () {
    expect(scheduledActiveFor(DateTime(2026, 11, 23, 22, 0), nightly()), isTrue);
    expect(scheduledActiveFor(DateTime(2026, 11, 23, 13, 0), nightly()), isTrue);
    expect(
      scheduledActiveFor(
        DateTime(2026, 11, 23, 13, 0),
        nightly().copyWith(dayIntensity: 0),
      ),
      isFalse,
    );
  });
}
