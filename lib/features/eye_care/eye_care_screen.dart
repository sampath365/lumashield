import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/platform_capabilities.dart';
import '../../shared/models/eye_care_settings.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/luma_slider.dart';
import '../../shared/widgets/page_shell.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/setting_tile.dart';
import '../../shared/widgets/stat_tile.dart';
import '../statistics/statistics_screen.dart';
import 'break_exercise_screen.dart';

class EyeCareScreen extends ConsumerWidget {
  const EyeCareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final settings = ref.watch(eyeCareControllerProvider);
    final controller = ref.read(eyeCareControllerProvider.notifier);
    final stats = ref.watch(statsProvider);
    final status = ref.watch(protectionStatusProvider);
    final score = status.eyeScore;
    final nextBreak = status.nextBreakIn;

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(
            title: 'Eye care',
            subtitle: 'Small habits, comfortable eyes',
            trailing: IconButton(
              tooltip: 'Start an eye break',
              onPressed: () => openBreakExercise(context),
              icon: const Icon(Icons.timer_outlined),
            ),
          ),
          GlassCard(
            accentBorder: score < 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const OwlBadge(size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Eye comfort $score%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextBreak == null
                                ? 'Breaks are off'
                                : (nextBreak <= 0
                                      ? 'Break is due now'
                                      : 'Next break in $nextBreak min'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Start an eye break',
                      onPressed: () => openBreakExercise(context),
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 8,
                    backgroundColor: palette.surfaceHigh,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Starts at 100 and drops one point per minute of continuous screen time. '
                  'A completed break, or five minutes with the screen off, resets it. '
                  'Not a medical measurement.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'TODAY',
                  value: Formatters.duration(Duration(minutes: stats.todayMinutes)),
                  icon: Icons.visibility_outlined,
                  caption: 'Protected screen time',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'STREAK',
                  value: '${stats.currentStreakDays} days',
                  icon: Icons.local_fire_department_rounded,
                  caption: 'Keep it going',
                  accent: palette.warm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'The 20-20-20 rule',
            subtitle: 'Every 20 minutes, look 20 feet away for 20 seconds',
            action: Switch(
              value: settings.twentyRuleEnabled,
              onChanged: (value) =>
                  controller.update((s) => s.copyWith(twentyRuleEnabled: value)),
            ),
          ),
          GlassCard(
            accentBorder: settings.twentyRuleEnabled,
            child: Column(
              children: [
                LumaSlider(
                  label: 'Reminder interval',
                  icon: Icons.schedule_rounded,
                  value: settings.twentyIntervalMin.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  valueLabel: '${settings.twentyIntervalMin} min',
                  enabled: settings.twentyRuleEnabled,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(twentyIntervalMin: v.round())),
                ),
                LumaSlider(
                  label: 'Break length',
                  icon: Icons.timelapse_rounded,
                  value: settings.twentyBreakSec.toDouble(),
                  min: 10,
                  max: 60,
                  divisions: 10,
                  valueLabel: '${settings.twentyBreakSec}s',
                  enabled: settings.twentyRuleEnabled,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(twentyBreakSec: v.round())),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Remind me every',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    for (final minutes in const [20, 30, 45])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text('${minutes}m'),
                          selected: settings.twentyIntervalMin == minutes,
                          onSelected: settings.twentyRuleEnabled
                              ? (_) => controller.update(
                                  (s) => s.copyWith(twentyIntervalMin: minutes),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: () => openBreakExercise(context),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Take a break now'),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(title: 'Reminders'),
          SettingsGroup(
            children: [
              SettingTile(
                icon: Icons.remove_red_eye_outlined,
                title: 'Eye strain reminder',
                subtitle: 'A nudge every ${settings.eyeStrainIntervalMin} minutes',
                trailing: Switch(
                  value: settings.eyeStrainEnabled,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(eyeStrainEnabled: v)),
                ),
              ),
              SettingTile(
                icon: Icons.timelapse_rounded,
                title: 'Continuous screen limit',
                subtitle: settings.continuousUsageLimitMin == 0
                    ? 'Disabled'
                    : 'Suggest a longer break after ${settings.continuousUsageLimitMin} minutes',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickContinuousLimit(context, ref, settings),
              ),
              SettingTile(
                icon: Icons.bedtime_outlined,
                title: 'Sleep preparation',
                subtitle: 'Wind down at ${Formatters.clock(settings.sleepTimeMinute)}',
                trailing: Switch(
                  value: settings.sleepReminderEnabled,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(sleepReminderEnabled: v)),
                ),
              ),
              SettingTile(
                icon: Icons.nightlight_outlined,
                title: 'Low light advice',
                subtitle: PlatformCapabilities.systemOverlay
                    ? 'Suggests the night filter when your screen is very dim'
                    : 'Suggests a warmer tint when the room is dark',
                trailing: Switch(
                  value: settings.lowLightReminder,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(lowLightReminder: v)),
                ),
              ),
              SettingTile(
                icon: Icons.monitor_heart_outlined,
                title: 'Eye score in the status bar',
                subtitle: settings.showEyeStatus
                    ? 'A silent ongoing notification with the percentage'
                    : 'Hidden',
                trailing: Switch(
                  value: settings.showEyeStatus,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(showEyeStatus: v)),
                ),
              ),
              SettingTile(
                icon: Icons.assessment_outlined,
                title: 'Daily eye comfort report',
                subtitle: settings.dailyReportEnabled
                    ? 'A summary notification each evening'
                    : 'Off',
                trailing: Switch(
                  value: settings.dailyReportEnabled,
                  onChanged: (v) =>
                      controller.update((s) => s.copyWith(dailyReportEnabled: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Quiet hours',
            subtitle: 'No reminders while you should be asleep',
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Column(
              children: [
                SettingTile(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: 'Silence reminders',
                  subtitle:
                      '${Formatters.clock(settings.quietStartMinute)} to ${Formatters.clock(settings.quietEndMinute)}',
                  trailing: Switch(
                    value: settings.quietHoursEnabled,
                    onChanged: (v) =>
                        controller.update((s) => s.copyWith(quietHoursEnabled: v)),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await _pickTime(
                            context,
                            settings.quietStartMinute,
                          );
                          if (picked != null) {
                            controller.update((s) => s.copyWith(quietStartMinute: picked));
                          }
                        },
                        child: const Text('Start'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await _pickTime(
                            context,
                            settings.quietEndMinute,
                          );
                          if (picked != null) {
                            controller.update((s) => s.copyWith(quietEndMinute: picked));
                          }
                        },
                        child: const Text('End'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Comfort tips',
            subtitle: 'Evidence based, no gimmicks',
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final tip in const [
                  ('Blink fully', 'Staring reduces blink rate. A full blink re-wets the eye surface.'),
                  ('Distance', 'Hold the phone about 40 cm away and slightly below eye level.'),
                  ('Lighting', 'Keep the room lit. A bright screen in a dark room is the worst case.'),
                  ('Screen distance', 'Depth sensors that watch your face are not available to third party apps on either platform, so LumaShield reminds you instead.'),
                ]) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 16, color: palette.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                                height: 1.45,
                              ),
                              children: [
                                TextSpan(
                                  text: '${tip.$1}. ',
                                  style: TextStyle(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: tip.$2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const StatisticsScreen()),
                      );
                    },
                    icon: const Icon(Icons.insights_rounded, size: 18),
                    label: const Text('Open full report'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await controller.reset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eye care settings restored to defaults')),
                  );
                }
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset eye care settings'),
            ),
          ),
        ],
      ),
    );
  }

  Future<int?> _pickTime(BuildContext context, int minute) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (minute ~/ 60) % 24, minute: minute % 60),
    );
    if (picked == null) return null;
    return picked.hour * 60 + picked.minute;
  }

  Future<void> _pickContinuousLimit(
    BuildContext context,
    WidgetRef ref,
    EyeCareSettings settings,
  ) async {
    final options = [0, 30, 45, 60, 90, 120];
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Continuous screen limit'),
            ),
            for (final option in options)
              ListTile(
                title: Text(option == 0 ? 'Disabled' : '$option minutes'),
                trailing: option == settings.continuousUsageLimitMin
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      await ref
          .read(eyeCareControllerProvider.notifier)
          .update((s) => s.copyWith(continuousUsageLimitMin: picked));
    }
  }
}
