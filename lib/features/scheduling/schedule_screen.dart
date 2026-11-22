import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/notification_settings_screen.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/platform_capabilities.dart';
import '../../shared/models/schedule_settings.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/luma_slider.dart';
import '../../shared/widgets/page_shell.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/segmented_control.dart';
import '../../shared/widgets/setting_tile.dart';
import '../../core/services/schedule_calculator.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final schedule = ref.watch(scheduleControllerProvider);
    final controller = ref.read(scheduleControllerProvider.notifier);
    final now = DateTime.now();
    final nextActivation = ScheduleCalculator.nextActivation(schedule, now: now);
    final sun = ScheduleCalculator.todaySun(schedule, now: now);

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(
            title: 'Automatic schedule',
            subtitle: 'Protection that follows your day',
            trailing: Switch(
              value: schedule.enabled,
              onChanged: (value) => controller.setEnabled(value),
            ),
          ),
          GlassCard(
            accentBorder: schedule.enabled,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      schedule.enabled ? Icons.nightlight_round : Icons.nightlight_outlined,
                      color: schedule.enabled ? palette.accent : palette.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.enabled ? 'Schedule is active' : 'Schedule is off',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            schedule.enabled
                                ? (nextActivation == null
                                      ? 'No upcoming activation in the next week'
                                      : 'Next activation ${Formatters.relativeToNow(nextActivation)} · ${Formatters.timeOfDay(nextActivation)}')
                                : 'Turn it on to apply the night filter automatically',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: 'When should it run?'),
          LumaSegmented<ScheduleMode>(
            value: schedule.mode,
            options: const [
              SegmentOption(value: ScheduleMode.custom, label: 'Custom times'),
              SegmentOption(value: ScheduleMode.sunsetSunrise, label: 'Sunset'),
            ],
            onChanged: (mode) => controller.setMode(mode),
          ),
          const SizedBox(height: 16),
          if (schedule.mode == ScheduleMode.custom)
            GlassCard(
              child: Column(
                children: [
                  _TimeRow(
                    label: 'Night starts',
                    minute: schedule.startMinute,
                    icon: Icons.bedtime_outlined,
                    onChanged: controller.setStart,
                  ),
                  Divider(color: palette.border.withValues(alpha: 0.5)),
                  _TimeRow(
                    label: 'Night ends',
                    minute: schedule.endMinute,
                    icon: Icons.wb_sunny_outlined,
                    onChanged: controller.setEnd,
                  ),
                  if (schedule.crossesMidnight)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 15, color: palette.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This window crosses midnight, which is the normal night setup.',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          else
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sun.sunset != null && sun.sunrise != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _SunTile(
                            icon: Icons.wb_twilight,
                            label: 'Sunset',
                            time: Formatters.timeOfDay(sun.sunset!),
                            colour: palette.warm,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SunTile(
                            icon: Icons.wb_sunny_outlined,
                            label: 'Sunrise',
                            time: Formatters.timeOfDay(sun.sunrise!),
                            colour: palette.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!schedule.hasLocation)
                    Text(
                      'Share an approximate location once and LumaShield calculates sunset '
                      'and sunrise offline. The coordinates never leave the device.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textMuted,
                        height: 1.45,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                          onPressed: () async {
                            final result = await ref.read(locationServiceProvider).current();
                            if (result.hasPosition) {
                              await controller.setLocation(
                                latitude: result.latitude!,
                                longitude: result.longitude!,
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result.error ?? 'Location unavailable')),
                              );
                            }
                          },
                          icon: const Icon(Icons.my_location_rounded, size: 18),
                          label: Text(schedule.hasLocation ? 'Refresh location' : 'Use my location'),
                        ),
                      ),
                      if (schedule.hasLocation) ...[
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: 'Remove location',
                          onPressed: controller.clearLocation,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ],
                  ),
                  if (schedule.hasLocation) ...[
                    const SizedBox(height: 8),
                    LumaSlider(
                      label: 'Sunset offset',
                      value: schedule.sunsetOffsetMin.toDouble(),
                      min: -120,
                      max: 120,
                      divisions: 48,
                      valueLabel: '${schedule.sunsetOffsetMin} min',
                      onChanged: (v) => controller.setSunsetOffset(v.round()),
                    ),
                    LumaSlider(
                      label: 'Sunrise offset',
                      value: schedule.sunriseOffsetMin.toDouble(),
                      min: -120,
                      max: 120,
                      divisions: 48,
                      valueLabel: '${schedule.sunriseOffsetMin} min',
                      onChanged: (v) => controller.setSunriseOffset(v.round()),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Active days',
            subtitle: Formatters.weekdayNames(schedule.weekdays),
            action: TextButton(
              onPressed: () => controller.setWeekdays({1, 2, 3, 4, 5, 6, 7}),
              child: const Text('All'),
            ),
          ),
          Row(
            children: [
              for (var day = 1; day <= 7; day++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.toggleDay(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 44,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: schedule.weekdays.contains(day)
                            ? palette.accent
                            : palette.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: schedule.weekdays.contains(day)
                              ? palette.accent
                              : palette.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day - 1],
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: schedule.weekdays.contains(day)
                                ? (palette.isDark ? const Color(0xFF1B1206) : Colors.white)
                                : palette.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Weekdays'),
                onPressed: () => controller.setWeekdays({1, 2, 3, 4, 5}),
              ),
              ActionChip(
                label: const Text('Weekends'),
                onPressed: () => controller.setWeekdays({6, 7}),
              ),
              ActionChip(
                label: const Text('Every day'),
                onPressed: () => controller.setWeekdays({1, 2, 3, 4, 5, 6, 7}),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Night filter',
            subtitle: 'Applied inside the scheduled window',
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Column(
              children: [
                LumaSlider(
                  label: 'Night intensity',
                  value: schedule.nightIntensity.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  valueLabel: '${schedule.nightIntensity}%',
                  onChanged: (v) => controller.setNightIntensity(v.round()),
                ),
                LumaSlider(
                  label: 'Night temperature',
                  value: schedule.nightKelvin.toDouble(),
                  min: 1900,
                  max: 6500,
                  divisions: 46,
                  valueLabel: '${schedule.nightKelvin}K',
                  activeColor: palette.warm,
                  onChanged: (v) => controller.setNightKelvin(v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Daytime protection',
            subtitle: 'A lighter tint outside the night window. Set 0% to turn the filter off by day.',
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Column(
              children: [
                LumaSlider(
                  label: 'Day intensity',
                  value: schedule.dayIntensity.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  valueLabel:
                      schedule.dayIntensity == 0 ? 'Off' : '${schedule.dayIntensity}%',
                  onChanged: (v) => controller.setDayIntensity(v.round()),
                ),
                LumaSlider(
                  label: 'Day temperature',
                  value: schedule.dayKelvin.toDouble(),
                  min: 1900,
                  max: 6500,
                  divisions: 46,
                  valueLabel: '${schedule.dayKelvin}K',
                  onChanged: (v) => controller.setDayKelvin(v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (PlatformCapabilities.isAndroid)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alarm_on_rounded, size: 18, color: palette.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Reliability',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LumaShield uses Android alarms, so the schedule survives reboots and '
                    'does not need the app to be open. Without the exact alarm permission '
                    'the switch can be a few minutes late. Aggressive battery savers can '
                    'still delay alarms; exempting the app helps.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            )
          else
            GlassCard(
              child: Text(
                'iOS does not allow background apps to tint the screen. On iPhone the '
                'schedule sends a reminder at the chosen times instead, and the in-app '
                'warm tint follows the same window while LumaShield is open.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                  height: 1.45,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SettingsGroup(
            title: 'Related',
            children: [
              SettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notification settings',
                subtitle: 'Persistent status, sounds and reminders',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minute,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final int minute;
  final IconData icon;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: (minute ~/ 60) % 24, minute: minute % 60),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked.hour * 60 + picked.minute);
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 19, color: palette.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: palette.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                Formatters.clock(minute),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SunTile extends StatelessWidget {
  const _SunTile({
    required this.icon,
    required this.label,
    required this.time,
    required this.colour,
  });

  final IconData icon;
  final String label;
  final String time;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colour.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colour, size: 20),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            time,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
