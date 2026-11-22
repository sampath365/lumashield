import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.iconColor,
    this.showDivider = false,
    this.tint,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? iconColor;
  final bool showDivider;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = iconColor ?? palette.accent;
    final effective = enabled ? onTap : null;
    return Column(
      children: [
        InkWell(
          onTap: effective,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                if (icon != null)
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (tint ?? color).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 21, color: tint ?? color),
                  ),
                if (icon != null) const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: enabled ? palette.textPrimary : palette.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              ],
            ),
          ),
        ),
        if (showDivider) Divider(color: palette.border.withValues(alpha: 0.6), height: 1),
      ],
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8, top: 4),
            child: Text(
              title!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: palette.textMuted,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(color: palette.border.withValues(alpha: 0.5), height: 1),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
