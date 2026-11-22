import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.onAction,
    this.actionLabel,
    this.required = false,
    this.optionalLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onAction;
  final String? actionLabel;
  final bool required;
  final String? optionalLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = granted ? palette.success : palette.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: granted ? palette.success.withValues(alpha: 0.35) : palette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (optionalLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: palette.surfaceHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              optionalLabel!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: palette.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      granted ? 'Granted' : (required ? 'Required' : 'Recommended'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (granted)
                Icon(Icons.check_circle_rounded, color: palette.success, size: 22)
              else
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel ?? 'Allow'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
