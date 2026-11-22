import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';
import '../eye_care/eye_care_screen.dart';
import '../scheduling/schedule_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';
import 'dashboard_screen.dart';
import 'home_tab_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _destinations = [
    (icon: Icons.shield_outlined, active: Icons.shield_rounded, label: 'Home'),
    (icon: Icons.schedule_outlined, active: Icons.schedule_rounded, label: 'Schedule'),
    (icon: Icons.remove_red_eye_outlined, active: Icons.remove_red_eye_rounded, label: 'Eye care'),
    (icon: Icons.bar_chart_outlined, active: Icons.bar_chart_rounded, label: 'Insights'),
    (icon: Icons.settings_outlined, active: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(homeTabProvider);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: const [
          DashboardScreen(),
          ScheduleScreen(),
          EyeCareScreen(),
          StatisticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: palette.backgroundAlt.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: palette.isDark ? 0.4 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _destinations[i].icon,
                      activeIcon: _destinations[i].active,
                      label: _destinations[i].label,
                      selected: index == i,
                      onTap: () {
                        ref.read(homeTabProvider.notifier).select(i);
                        if (ref.read(appSettingsControllerProvider).hapticsEnabled) {
                          Feedback.forTap(context);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? palette.accent.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              selected ? activeIcon : icon,
              size: 21,
              color: selected ? palette.accent : palette.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: selected ? palette.accent : palette.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
