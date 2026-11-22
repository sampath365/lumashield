import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/platform_capabilities.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_shell.dart';
import '../../shared/widgets/setting_tile.dart';
import '../app_profiles/app_profiles_screen.dart';
import '../blue_filter/filter_settings_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../onboarding/permission_setup_screen.dart';
import '../reading_mode/reading_mode_screen.dart';
import '../scheduling/schedule_screen.dart';
import 'about_screen.dart';
import 'advanced_settings_screen.dart';
import 'theme_settings_screen.dart';
import '../dashboard/home_tab_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final status = ref.watch(protectionStatusProvider);
    final permissions = ref.watch(permissionsControllerProvider);
    final appSettings = ref.watch(appSettingsControllerProvider);

    void push(Widget screen) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageTitle(title: 'Settings', subtitle: 'Everything stays on this device'),
          GlassCard(
            gradient: palette.heroGradient,
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: palette.accentGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.shield_moon_rounded,
                    color: palette.isDark ? const Color(0xFF1B1206) : Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        PlatformCapabilities.isAndroid
                            ? 'System wide filter available'
                            : 'In-app warmth on iOS',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (status.running ? palette.success : palette.textMuted)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.running ? 'Active' : 'Idle',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: status.running ? palette.success : palette.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (PlatformCapabilities.isAndroid && !permissions.coreGranted) ...[
            const SizedBox(height: 14),
            GlassCard(
              accentBorder: true,
              onTap: () => push(const PermissionSetupScreen()),
              child: Row(
                children: [
                  Icon(Icons.lock_open_rounded, color: palette.warm, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${permissions.grantedCount} of 5 permissions granted. Finish setup to '
                      'keep protection reliable.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SettingsGroup(
            title: 'Protection',
            children: [
              SettingTile(
                icon: Icons.palette_outlined,
                title: 'Filter settings',
                subtitle: 'Colour, intensity, presets',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => push(const FilterSettingsScreen()),
              ),
              SettingTile(
                icon: Icons.schedule_outlined,
                title: 'Automatic schedule',
                subtitle: 'Sunset to sunrise, or exact hours',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => push(const ScheduleScreen()),
              ),
              SettingTile(
                icon: Icons.apps_rounded,
                title: 'Per-app profiles',
                subtitle: PlatformCapabilities.perAppProfiles
                    ? 'Different filters for different apps'
                    : 'Android only',
                enabled: PlatformCapabilities.perAppProfiles,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => push(const AppProfilesScreen()),
              ),
              SettingTile(
                icon: Icons.shield_outlined,
                title: 'Permissions',
                subtitle: PlatformCapabilities.isAndroid
                    ? 'Overlay, notifications, battery, alarms'
                    : 'Notifications',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => push(const PermissionSetupScreen()),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsGroup(
            title: 'Eye care',
            children: [
              SettingTile(
                icon: Icons.remove_red_eye_outlined,
                title: 'Eye care reminders',
                subtitle: '20-20-20, strain, sleep',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ref.read(homeTabProvider.notifier).select(2);
                },
              ),
              SettingTile(
                icon: Icons.menu_book_outlined,
                title: 'Reading mode',
                subtitle: 'Warm paper surface with a timer',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => push(const ReadingModeScreen()),
              ),
              SettingTile(
                icon: Icons.bar_chart_rounded,
                title: 'Insights',
                subtitle: 'Daily and weekly reports',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ref.read(homeTabProvider.notifier).select(3);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          SettingsGroup(
            title: 'App',
            children: [
              SettingTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Status, reminders, sound',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => push(const NotificationSettingsScreen()),
              ),
              SettingTile(
                icon: Icons.brightness_6_outlined,
                title: 'Appearance',
                subtitle: appSettings.themeVariant.label,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => push(const ThemeSettingsScreen()),
              ),
              SettingTile(
                icon: Icons.tune_rounded,
                title: 'Advanced',
                subtitle: 'Widgets, app lock, emergency stop',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => push(const AdvancedSettingsScreen()),
              ),
              SettingTile(
                icon: Icons.info_outline_rounded,
                title: 'About and privacy',
                subtitle: 'Version, support, policy',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => push(const AboutScreen()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data == null
                    ? ''
                    : 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})';
                return Column(
                  children: [
                    Text(
                      '${AppConstants.appName} $version',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No account. No tracking. No screen capture.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Today: ${Formatters.duration(Duration(minutes: ref.watch(statsProvider).todayMinutes))} protected',
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
