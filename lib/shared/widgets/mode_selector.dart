import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../models/filter_settings.dart';

/// Horizontal quick mode picker used on the dashboard and filter screen.
class ModeSelector extends StatelessWidget {
  const ModeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.scrollable = true,
  });

  final FilterMode selected;
  final ValueChanged<FilterMode> onSelected;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = [
      for (final mode in FilterMode.values)
        _ModePill(
          mode: mode,
          selected: mode == selected,
          palette: palette,
          onTap: () => onSelected(mode),
        ),
    ];

    if (!scrollable) {
      return Wrap(spacing: 8, runSpacing: 8, children: items);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // 6 pills at 84 wide plus gaps need 554dp; centre them when they fit.
        if (constraints.maxWidth >= 560) {
          return SizedBox(
            height: 86,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    items[i],
                  ],
                ],
              ),
            ),
          );
        }
        return SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, index) => items[index],
          ),
        );
      },
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.mode,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final FilterMode mode;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          gradient: selected ? palette.accentGradient : null,
          color: selected ? null : palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : palette.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode.icon,
              size: 22,
              color: selected
                  ? (palette.isDark ? const Color(0xFF1B1206) : Colors.white)
                  : palette.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              mode.shortLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? (palette.isDark ? const Color(0xFF1B1206) : Colors.white)
                    : palette.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
