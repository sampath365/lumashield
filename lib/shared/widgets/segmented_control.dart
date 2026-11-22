import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Compact segmented control with an animated selection pill.
class LumaSegmented<T> extends StatelessWidget {
  const LumaSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(vertical: compact ? 8 : 11),
                  decoration: BoxDecoration(
                    color: option.value == value ? palette.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (option.icon != null) ...[
                        Icon(
                          option.icon,
                          size: 15,
                          color: option.value == value
                              ? (palette.isDark ? const Color(0xFF1B1206) : Colors.white)
                              : palette.textMuted,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: option.value == value
                                ? (palette.isDark ? const Color(0xFF1B1206) : Colors.white)
                                : palette.textSecondary,
                            fontWeight: option.value == value
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
