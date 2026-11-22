import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.caption,
    this.accent,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? caption;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = accent ?? palette.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 16, color: color),
              if (icon != null) const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
