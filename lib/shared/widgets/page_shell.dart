import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Background + padding for the tab pages inside the home shell.
class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.scroll = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.heroGradient),
      child: SafeArea(
        bottom: false,
        child: scroll
            ? SingleChildScrollView(
                padding: padding,
                physics: const BouncingScrollPhysics(),
                child: child,
              )
            : Padding(padding: padding, child: child),
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
