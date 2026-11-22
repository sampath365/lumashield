import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Slider with a label, a live value badge and optional captions underneath.
class LumaSlider extends StatelessWidget {
  const LumaSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    this.valueLabel,
    this.icon,
    this.captions,
    this.divisions,
    this.activeColor,
    this.enabled = true,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? valueLabel;
  final IconData? icon;
  final List<String>? captions;
  final int? divisions;
  final Color? activeColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = activeColor ?? palette.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: palette.textMuted),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                valueLabel ?? value.round().toString(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.16),
            inactiveTrackColor: palette.surfaceHigh,
            disabledActiveTrackColor: palette.border,
            disabledInactiveTrackColor: palette.surfaceHigh,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: enabled ? onChanged : null,
            onChangeEnd: enabled ? onChangeEnd : null,
          ),
        ),
        if (captions != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final caption in captions!)
                  Text(
                    caption,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        if (captions != null) const SizedBox(height: 10),
      ],
    );
  }
}
