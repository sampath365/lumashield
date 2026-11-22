import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/platform_capabilities.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/setting_tile.dart';
import '../notifications/notification_settings_screen.dart';
import 'about_screen.dart';

class AdvancedSettingsScreen extends ConsumerWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final appSettings = ref.watch(appSettingsControllerProvider);
    final settingsController = ref.read(appSettingsControllerProvider.notifier);
    final biometrics = ref.watch(biometricAvailableProvider);
    final status = ref.watch(protectionStatusProvider);
    final stats = ref.watch(statsProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Advanced')),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        physics: const BouncingScrollPhysics(),
        children: [
          SectionHeader(
            title: 'Quick access',
            subtitle: PlatformCapabilities.androidExtras
                ? 'Control the filter without opening the app'
                : 'Available on Android only',
          ),
          SettingsGroup(
            children: [
              SettingTile(
                icon: Icons.dashboard_customize_outlined,
                title: 'Quick settings tile',
                subtitle: 'Add LumaShield to the notification shade',
                enabled: PlatformCapabilities.androidExtras,
                trailing: const Icon(Icons.add_circle_outline_rounded),
                onTap: PlatformCapabilities.androidExtras
                    ? () async {
                        final added =
                            await ref.read(filterServiceProvider).requestQuickTile();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? 'Tile added to quick settings'
                                    : 'Android will show the tile prompt if it is supported',
                              ),
                            ),
                          );
                        }
                      }
                    : null,
              ),
              SettingTile(
                icon: Icons.widgets_outlined,
                title: 'Home screen widget',
                subtitle: 'Live status and a one tap toggle',
                enabled: PlatformCapabilities.androidExtras,
                trailing: const Icon(Icons.add_circle_outline_rounded),
                onTap: PlatformCapabilities.androidExtras
                    ? () async {
                        final ok =
                            await ref.read(filterServiceProvider).requestHomeWidget();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Confirm the widget placement on your home screen'
                                    : 'This launcher does not support pinned widgets',
                              ),
                            ),
                          );
                        }
                      }
                    : null,
              ),
              SettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notification behaviour',
                subtitle: 'Status notification and actions',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Service reliability',
            subtitle: 'Android decides how far it will let any app go',
          ),
          SettingsGroup(
            children: [
              SettingTile(
                icon: Icons.battery_saver_outlined,
                title: 'Battery optimisation',
                subtitle: status.batteryOptimized ? 'Restricted' : 'Unrestricted',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => ref
                    .read(permissionsControllerProvider.notifier)
                    .requestBatteryExemption(),
              ),
              SettingTile(
                icon: Icons.alarm_outlined,
                title: 'Exact alarms',
                subtitle: status.exactAlarmsAllowed ? 'Allowed' : 'Not allowed',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => ref
                    .read(permissionsControllerProvider.notifier)
                    .openExactAlarms(),
              ),
              SettingTile(
                icon: Icons.settings_applications_outlined,
                title: 'App system settings',
                subtitle: 'Manufacturer power management lives here',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => ref.read(filterServiceProvider).openAppSettings(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Privacy and security',
            subtitle: 'Your eyes, your data',
          ),
          SettingsGroup(
            children: [
              SettingTile(
                icon: Icons.fingerprint_rounded,
                title: 'App lock',
                subtitle: biometrics.value == false
                    ? 'No biometrics enrolled on this device'
                    : 'Require biometrics to open LumaShield',
                trailing: Switch(
                  value: appSettings.appLockEnabled,
                  onChanged: biometrics.value == false
                      ? null
                      : (value) async {
                          await settingsController.update(
                            (s) => s.copyWith(appLockEnabled: value),
                          );
                          ref.read(appLockProvider.notifier).syncWithSetting();
                        },
                ),
              ),
              SettingTile(
                icon: Icons.analytics_outlined,
                title: 'Anonymous diagnostics',
                subtitle: 'Off by default. Never includes screen content.',
                trailing: Switch(
                  value: appSettings.crashReports,
                  onChanged: (value) =>
                      settingsController.update((s) => s.copyWith(crashReports: value)),
                ),
              ),
              SettingTile(
                icon: Icons.policy_outlined,
                title: 'Privacy policy',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Data'),
          SettingsGroup(
            children: [
              SettingTile(
                icon: Icons.copy_all_outlined,
                title: 'Copy report',
                subtitle: 'Copies a text summary to the clipboard',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final report = StringBuffer()
                    ..writeln('LumaShield report')
                    ..writeln('Date: ${DateTime.now().toIso8601String()}')
                    ..writeln('Today: ${Formatters.duration(Duration(minutes: stats.todayMinutes))}')
                    ..writeln('Week: ${Formatters.duration(Duration(minutes: stats.weekMinutes))}')
                    ..writeln('Sessions: ${stats.totalSessions}')
                    ..writeln('Streak: ${stats.currentStreakDays} days')
                    ..writeln('Average intensity: ${stats.avgIntensity}%')
                    ..writeln('Service running: ${status.running}')
                    ..writeln('Schedule: ${status.scheduleEnabled}');
                  await Clipboard.setData(ClipboardData(text: report.toString()));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report copied to clipboard')),
                    );
                  }
                },
              ),
              SettingTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear protection history',
                subtitle: 'Deletes local sessions only',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear history?'),
                      content: const Text('All locally stored sessions will be deleted.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(historyRepositoryProvider).clear();
                    ref.read(statsRefreshProvider.notifier).bump();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('History cleared')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Emergency'),
          GlassCard(
            accentBorder: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.power_off_rounded, color: palette.danger, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Stop everything now',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Removes the overlay immediately and turns the schedule off. Useful if the '
                  'filter ever interferes with a call, a payment or a video.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.danger,
                      side: BorderSide(color: palette.danger.withValues(alpha: 0.5)),
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Turn everything off?'),
                          content: const Text(
                            'The filter and the automatic schedule will stop until you turn '
                            'them back on.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Stop'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(filterControllerProvider.notifier).emergencyDisable();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Protection stopped')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('Emergency disable'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Platform support'),
          GlassCard(
            child: Column(
              children: [
                for (final row in const [
                  ('System wide filter', 'Android only'),
                  ('Foreground service', 'Android only'),
                  ('Quick tile and widget', 'Android only'),
                  ('Per-app profiles', 'Android only'),
                  ('In-app warm tint', 'Android and iOS'),
                  ('Break reminders', 'Android and iOS'),
                  ('Sunset schedule', 'Android (iOS as reminders)'),
                  ('Screen distance sensor', 'Not available to third party apps'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.$1,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          row.$2,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: row.$2.startsWith('Android only')
                                ? palette.warm
                                : palette.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
