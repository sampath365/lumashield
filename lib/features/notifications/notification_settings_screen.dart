import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/platform_capabilities.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/permission_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/setting_tile.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final permissions = ref.watch(permissionsControllerProvider);
    final options = ref.watch(serviceOptionsControllerProvider);
    final serviceController = ref.read(serviceOptionsControllerProvider.notifier);
    final eyeCare = ref.watch(eyeCareControllerProvider);
    final eyeController = ref.read(eyeCareControllerProvider.notifier);
    final status = ref.watch(protectionStatusProvider);

    return GradientScaffold(
      appBar: AppBar(title: const Text('Notifications')),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        physics: const BouncingScrollPhysics(),
        children: [
          if (!permissions.notifications)
            PermissionCard(
              icon: Icons.notifications_off_outlined,
              title: 'Notifications are blocked',
              description:
                  'Android will not show the protection status or eye care reminders until '
                  'you allow notifications for LumaShield.',
              granted: false,
              required: true,
              onAction: () =>
                  ref.read(permissionsControllerProvider.notifier).requestNotifications(),
            ),
          SectionHeader(
            title: 'Protection status',
            subtitle: PlatformCapabilities.backgroundService
                ? 'A silent, ongoing notification keeps the service alive'
                : 'iOS manages the tint inside the app',
          ),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SettingTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Show status notification',
                  subtitle: 'Required for a foreground service on Android 8+',
                  trailing: Switch(
                    value: options.showNotification,
                    onChanged: PlatformCapabilities.backgroundService
                        ? (value) => serviceController.update(
                            (o) => o.copyWith(showNotification: value),
                          )
                        : null,
                  ),
                ),
                SettingTile(
                  icon: Icons.touch_app_outlined,
                  title: 'Pause action on the notification',
                  subtitle: 'Turn the filter off without opening the app',
                  trailing: Switch(
                    value: options.notificationActions,
                    onChanged: PlatformCapabilities.backgroundService
                        ? (value) => serviceController.update(
                            (o) => o.copyWith(notificationActions: value),
                          )
                        : null,
                  ),
                ),
                SettingTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'Restart after reboot',
                  subtitle: 'Restore the last filter state when the phone starts',
                  trailing: Switch(
                    value: options.restoreOnBoot,
                    onChanged: PlatformCapabilities.backgroundService
                        ? (value) => serviceController.update(
                            (o) => o.copyWith(restoreOnBoot: value),
                          )
                        : null,
                  ),
                ),
                SettingTile(
                  icon: Icons.healing_rounded,
                  title: 'Auto restart service',
                  subtitle: 'Ask Android to restart if the service is stopped',
                  trailing: Switch(
                    value: options.autoRestart,
                    onChanged: PlatformCapabilities.backgroundService
                        ? (value) => serviceController.update(
                            (o) => o.copyWith(autoRestart: value),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Eye care reminders',
            subtitle: 'Scheduled locally, never from a server',
          ),
          SettingsGroup(
            children: [
              SettingTile(
                icon: Icons.remove_red_eye_outlined,
                title: '20-20-20 reminder',
                subtitle: 'Every ${eyeCare.twentyIntervalMin} minutes',
                trailing: Switch(
                  value: eyeCare.twentyRuleEnabled,
                  onChanged: (value) => eyeController.update(
                    (s) => s.copyWith(twentyRuleEnabled: value),
                  ),
                ),
              ),
              SettingTile(
                icon: Icons.self_improvement_rounded,
                title: 'Eye strain reminder',
                subtitle: 'Every ${eyeCare.eyeStrainIntervalMin} minutes',
                trailing: Switch(
                  value: eyeCare.eyeStrainEnabled,
                  onChanged: (value) => eyeController.update(
                    (s) => s.copyWith(eyeStrainEnabled: value),
                  ),
                ),
              ),
              SettingTile(
                icon: Icons.bedtime_outlined,
                title: 'Sleep preparation',
                subtitle: 'At ${Formatters.clock(eyeCare.sleepTimeMinute)}',
                trailing: Switch(
                  value: eyeCare.sleepReminderEnabled,
                  onChanged: (value) => eyeController.update(
                    (s) => s.copyWith(sleepReminderEnabled: value),
                  ),
                ),
              ),
              SettingTile(
                icon: Icons.assessment_outlined,
                title: 'Daily eye comfort report',
                subtitle: 'A summary each evening',
                trailing: Switch(
                  value: eyeCare.dailyReportEnabled,
                  onChanged: (value) => eyeController.update(
                    (s) => s.copyWith(dailyReportEnabled: value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Sound and vibration'),
          SettingsGroup(
            children: [
              SettingTile(
                icon: Icons.volume_up_outlined,
                title: 'Reminder sound',
                trailing: Switch(
                  value: eyeCare.soundEnabled,
                  onChanged: (value) => eyeController.update(
                    (s) => s.copyWith(soundEnabled: value),
                  ),
                ),
              ),
              SettingTile(
                icon: Icons.vibration_rounded,
                title: 'Vibration',
                trailing: Switch(
                  value: eyeCare.vibrationEnabled,
                  onChanged: (value) => eyeController.update(
                    (s) => s.copyWith(vibrationEnabled: value),
                  ),
                ),
              ),
              SettingTile(
                icon: Icons.night_shelter_outlined,
                title: 'Quiet hours',
                subtitle:
                    '${Formatters.clock(eyeCare.quietStartMinute)} – ${Formatters.clock(eyeCare.quietEndMinute)}',
                trailing: Switch(
                  value: eyeCare.quietHoursEnabled,
                  onChanged: (value) => eyeController.update(
                    (s) => s.copyWith(quietHoursEnabled: value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: palette.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Android controls the final word',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Notification channels, Do Not Disturb and manufacturer battery savers can '
                  'still hide or delay notifications. Reminders are scheduled in twelve hour '
                  'batches with inexact alarms, so they use very little battery.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            ref.read(filterServiceProvider).openNotificationSettings(),
                        child: const Text('System settings'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                        onPressed: () async {
                          await ref
                              .read(notificationServiceProvider)
                              .showTestNotification();
                        },
                        child: const Text('Send test'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              status.supported
                  ? 'Service ${status.running ? 'running' : 'stopped'} · '
                        '${status.showNotification ? 'status visible' : 'status hidden'}'
                  : 'Limited on this platform',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
