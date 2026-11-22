import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/platform_capabilities.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_scaffold.dart';
import '../../shared/widgets/permission_card.dart';

/// Real permission setup. Each row reflects the platform's actual answer and
/// every button opens the matching system screen; nothing is auto granted.
class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key, this.next});

  /// When provided, finishing replaces this route with [next]. When null the
  /// screen simply pops, which is what happens from Settings.
  final Widget? next;

  @override
  ConsumerState<PermissionSetupScreen> createState() =>
      _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen>
    with WidgetsBindingObserver {
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(permissionsControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionsControllerProvider.notifier).refresh();
    }
  }

  Future<void> _testFilter() async {
    if (_testing) return;
    setState(() => _testing = true);
    final controller = ref.read(filterControllerProvider.notifier);
    final started = await controller.setEnabled(true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            started
                ? 'Filter is on for 8 seconds. Look at the whole screen.'
                : 'Overlay permission is still missing.',
          ),
        ),
      );
    }
    await Future<void>.delayed(const Duration(seconds: 8));
    await controller.setEnabled(false);
    if (mounted) setState(() => _testing = false);
  }

  void _finish() {
    if (widget.next != null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute<void>(builder: (_) => widget.next!));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final permissions = ref.watch(permissionsControllerProvider);
    final controller = ref.read(permissionsControllerProvider.notifier);
    final isAndroid = PlatformCapabilities.isAndroid;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Permissions')),
      padding: EdgeInsets.zero,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            isAndroid ? 'Two permissions, no surprises' : 'A note about iOS',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            PlatformCapabilities.overlayLimitation,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: palette.textMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          if (isAndroid) ...[
            PermissionCard(
              icon: Icons.layers_outlined,
              title: 'Display over other apps',
              description:
                  'Required. This is the overlay that tints the screen above other '
                  'apps. Android grants it from a system screen you control.',
              granted: permissions.overlay,
              required: true,
              onAction: controller.openOverlay,
            ),
            PermissionCard(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              description:
                  'Required for the ongoing protection status and for eye care '
                  'reminders. You can turn individual channels off later.',
              granted: permissions.notifications,
              required: true,
              onAction: () => controller.requestNotifications(),
            ),
            PermissionCard(
              icon: Icons.battery_saver_outlined,
              title: 'Battery optimisation',
              description:
                  'Recommended. Exempting LumaShield keeps the filter from being '
                  'killed in the background. Android still owns the final say.',
              granted: permissions.batteryUnrestricted,
              actionLabel: 'Review',
              optionalLabel: 'Optional',
              onAction: controller.requestBatteryExemption,
            ),
            PermissionCard(
              icon: Icons.alarm_outlined,
              title: 'Exact alarms',
              description:
                  'Recommended. Needed for schedules that start on the minute. '
                  'Without it the filter may start a few minutes late.',
              granted: permissions.exactAlarms,
              actionLabel: 'Review',
              optionalLabel: 'Optional',
              onAction: controller.openExactAlarms,
            ),
            PermissionCard(
              icon: Icons.insights_outlined,
              title: 'Usage access',
              description:
                  'Optional. Only used to know which app is in front so per-app '
                  'profiles can adjust or lift the filter. Screen content is never read.',
              granted: permissions.usageAccess,
              actionLabel: 'Review',
              optionalLabel: 'Optional',
              onAction: controller.openUsageAccess,
            ),
            const SizedBox(height: 8),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science_outlined, color: palette.accent),
                      const SizedBox(width: 10),
                      Text(
                        'Verify it works',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Turn the filter on for eight seconds and watch the whole screen. '
                    'If nothing changes, check that the overlay permission is still granted.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.textMuted, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: permissions.overlay && !_testing
                        ? _testFilter
                        : null,
                    icon: Icon(
                      _testing ? Icons.hourglass_top : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      _testing ? 'Testing…' : 'Run the 8 second test',
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            PermissionCard(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              description: 'Used for break reminders, the daily report and the sleep wind down cue.',
              granted: permissions.notifications,
              required: true,
              onAction: () => controller.requestNotifications(),
            ),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What iOS allows',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• In-app warm tint and reading mode\n'
                    '• Break reminders and the 20-20-20 timer\n'
                    '• Sunset scheduling as reminders\n'
                    '• Statistics and reports\n\n'
                    'iOS does not let a third party app tint other apps. For system '
                    'wide warmth use Settings > Display & Brightness > Night Shift, '
                    'which LumaShield can remind you to schedule.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.textMuted, height: 1.55),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _finish,
            child: Text(
              widget.next != null ? 'Start protecting my eyes' : 'Done',
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'You can change all of this later in Settings.',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: palette.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
