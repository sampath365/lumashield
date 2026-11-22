import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/color_temperature.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/schedule_calculator.dart';
import '../../core/utils/platform_capabilities.dart';
import '../../shared/models/protection_status.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/filter_preview.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/luma_slider.dart';
import '../../shared/widgets/mode_selector.dart';
import '../../shared/widgets/page_shell.dart';
import '../../shared/widgets/protection_orb.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_tile.dart';
import '../blue_filter/filter_settings_screen.dart';
import '../notifications/notification_settings_screen.dart';
import '../onboarding/permission_setup_screen.dart';
import 'home_tab_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      ref.read(statsRefreshProvider.notifier).bump();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Late night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Time to wind down';
  }

  Future<void> _toggleProtection() async {
    final settings = ref.read(appSettingsControllerProvider);
    if (settings.hapticsEnabled) await HapticFeedback.mediumImpact();
    final controller = ref.read(filterControllerProvider.notifier);
    final enabling = !ref.read(filterControllerProvider).enabled;
    final ok = await controller.setEnabled(enabling);
    if (!mounted) return;
    if (!ok && enabling) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    final palette = context.palette;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Overlay permission needed'),
        content: const Text(
          'Android needs the "Display over other apps" permission before LumaShield '
          'can tint anything. The filter is not on yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PermissionSetupScreen(),
                ),
              );
            },
            child: Text('Fix it', style: TextStyle(color: palette.isDark ? Colors.black : Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final filter = ref.watch(filterControllerProvider);
    final status = ref.watch(protectionStatusProvider);
    final schedule = ref.watch(scheduleControllerProvider);
    final stats = ref.watch(statsProvider);
    final permissions = ref.watch(permissionsControllerProvider);

    // iOS has no background service, so "on" means the in-app tint is active.
    final serviceRunning = PlatformCapabilities.backgroundService
        ? status.running
        : filter.enabled;
    final nextActivation = status.nextActivation ??
        (schedule.enabled ? ScheduleCalculator.nextActivation(schedule) : null);
    final strength = filter.intensity;

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(greeting: _greeting, active: filter.enabled),
          if (PlatformCapabilities.isAndroid && !permissions.overlay && !permissions.loading)
            _PermissionBanner(onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PermissionSetupScreen()),
              );
            }),
          const SizedBox(height: 12),
          _StatusChip(
            active: filter.enabled,
            serviceRunning: serviceRunning,
            modeLabel: filter.mode.label,
          ),
          const SizedBox(height: 8),
          Center(
            child: ProtectionOrb(
              active: filter.enabled,
              strength: strength,
              statusLabel: filter.enabled
                  ? (serviceRunning ? 'Protection active' : 'Starting…')
                  : 'Protection paused',
              onTap: _toggleProtection,
              size: 262,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              filter.enabled
                  ? 'Tap the shield to pause · ${ColorTemperature.labelFor(filter.kelvin)} ${filter.kelvin}K'
                  : 'Tap the shield to protect your eyes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'TODAY',
                  value: Formatters.duration(Duration(minutes: stats.todayMinutes)),
                  icon: Icons.timelapse_rounded,
                  caption: '${stats.totalSessions} sessions saved',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'NEXT CHANGE',
                  value: nextActivation == null
                      ? '—'
                      : Formatters.relativeToNow(nextActivation),
                  icon: Icons.wb_twilight_rounded,
                  caption: nextActivation == null
                      ? 'No schedule set'
                      : Formatters.timeOfDay(nextActivation),
                  accent: palette.warm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Quick modes',
            subtitle: 'One tap changes temperature and strength together',
            action: TextButton(
              onPressed: () => ref.read(homeTabProvider.notifier).select(1),
              child: const Text('Schedule'),
            ),
          ),
          ModeSelector(
            selected: filter.mode,
            onSelected: (mode) => ref.read(filterControllerProvider.notifier).setMode(mode),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Live filter',
            subtitle: filter.mode.description,
            action: IconButton(
              tooltip: 'All filter settings',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FilterSettingsScreen()),
              ),
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Column(
              children: [
                FilterPreview(
                  kelvin: filter.kelvin,
                  intensity: filter.intensity,
                  customColor: filter.customColor,
                  dim: filter.dim,
                  height: 132,
                ),
                const SizedBox(height: 14),
                LumaSlider(
                  label: 'Blue light reduction',
                  icon: Icons.opacity_rounded,
                  value: filter.intensity.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  valueLabel: '${filter.intensity}%',
                  onChanged: (value) => ref
                      .read(filterControllerProvider.notifier)
                      .setIntensity(value.round()),
                  captions: const ['Gentle', 'Balanced', 'Maximum'],
                ),
                LumaSlider(
                  label: 'Colour temperature',
                  icon: Icons.thermostat_rounded,
                  value: filter.kelvin.toDouble(),
                  min: 1900,
                  max: 6500,
                  divisions: 46,
                  valueLabel: '${filter.kelvin}K',
                  activeColor: palette.warm,
                  onChanged: (value) => ref
                      .read(filterControllerProvider.notifier)
                      .setKelvin(value.round()),
                  captions: const ['Candle', 'Warm', 'Neutral'],
                ),
                if (PlatformCapabilities.isAndroid)
                  LumaSlider(
                    label: 'Screen dim',
                    icon: Icons.brightness_6_rounded,
                    value: filter.dim.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 60,
                    valueLabel: '${filter.dim}%',
                    onChanged: (value) => ref
                        .read(filterControllerProvider.notifier)
                        .setDim(value.round()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Protection service',
            subtitle: PlatformCapabilities.backgroundService
                ? 'Foreground service with a silent status notification'
                : 'iOS keeps the tint inside LumaShield',
            action: IconButton(
              tooltip: 'Notification settings',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen()),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          _ServiceCard(status: status, active: filter.enabled),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Eye comfort today',
            subtitle: 'Breaks, streaks and weekly totals',
            action: TextButton(
              onPressed: () => ref.read(homeTabProvider.notifier).select(3),
              child: const Text('Reports'),
            ),
          ),
          GlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.duration(Duration(minutes: stats.todayMinutes)),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'protected today',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded, size: 16, color: palette.accent),
                          const SizedBox(width: 6),
                          Text(
                            '${stats.currentStreakDays} day streak',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: palette.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (stats.todayMinutes / 240).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: palette.surfaceHigh,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily goal 4h',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                    Text(
                      'This week ${Formatters.duration(Duration(minutes: stats.weekMinutes))}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const FilterSettingsScreen()),
                  ),
                  icon: const Icon(Icons.palette_outlined, size: 18),
                  label: const Text('Filter settings'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(homeTabProvider.notifier).select(2),
                  icon: const Icon(Icons.favorite_border_rounded, size: 18),
                  label: const Text('Eye care'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${AppConstants.appName} · filter stays on device',
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

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.active});

  final String greeting;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: palette.accentGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.shield_moon_rounded,
            color: palette.isDark ? const Color(0xFF1B1206) : Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '$greeting · ${active ? 'shields up' : 'shields down'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.active,
    required this.serviceRunning,
    required this.modeLabel,
  });

  final bool active;
  final bool serviceRunning;
  final String modeLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = !active
        ? palette.textMuted
        : (serviceRunning ? palette.success : palette.warm);
    final label = !active
        ? 'Filter off'
        : (serviceRunning ? 'Filter on · $modeLabel' : 'Starting service…');
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.warm.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.warm.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: palette.warm, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Overlay permission is missing, so the filter cannot cover other apps.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: palette.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.status, required this.active});

  final ProtectionStatus status;
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final options = ref.watch(serviceOptionsControllerProvider);
    Widget row(IconData icon, String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 17, color: palette.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color ?? palette.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Column(
        children: [
          row(
            Icons.power_settings_new_rounded,
            'Background service',
            status.supported
                ? (status.running ? 'Running' : (active ? 'Starting' : 'Stopped'))
                : 'Not available on iOS',
            color: status.running ? palette.success : palette.textMuted,
          ),
          Divider(color: palette.border.withValues(alpha: 0.5), height: 1),
          row(
            Icons.notifications_none_rounded,
            'Persistent notification',
            PlatformCapabilities.backgroundService
                ? (options.showNotification ? 'Visible' : 'Hidden')
                : 'Not available',
          ),
          Divider(color: palette.border.withValues(alpha: 0.5), height: 1),
          row(
            Icons.battery_charging_full_rounded,
            'Battery optimisation',
            !PlatformCapabilities.isAndroid
                ? 'Managed by iOS'
                : (status.batteryOptimized ? 'Restricted' : 'Unrestricted'),
            color: PlatformCapabilities.isAndroid && status.batteryOptimized
                ? palette.warm
                : palette.textPrimary,
          ),
          Divider(color: palette.border.withValues(alpha: 0.5), height: 1),
          row(
            Icons.alarm_rounded,
            'Next automatic change',
            status.nextActivation == null
                ? 'None scheduled'
                : Formatters.relativeToNow(status.nextActivation!),
          ),
          if (PlatformCapabilities.isAndroid && status.batteryOptimized)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ref
                      .read(permissionsControllerProvider.notifier)
                      .requestBatteryExemption(),
                  child: const Text('Review battery settings'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
