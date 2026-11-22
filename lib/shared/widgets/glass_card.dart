import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Rounded, softly elevated surface used for every grouped block.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.margin = EdgeInsets.zero,
    this.accentBorder = false,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final bool accentBorder;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radius = BorderRadius.circular(24);
    final decoration = BoxDecoration(
      color: gradient == null ? palette.surface : null,
      gradient: gradient,
      borderRadius: radius,
      border: Border.all(
        color: accentBorder ? palette.accent.withValues(alpha: 0.45) : palette.border,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: palette.isDark ? 0.28 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );

    final content = Padding(padding: padding, child: child);
    return Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
      ),
    );
  }
}
