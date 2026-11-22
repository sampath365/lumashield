import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Background + padding for the tab pages inside the home shell.
class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.scroll = true,
    this.maxContentWidth = 720,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool scroll;

  /// Keeps line lengths readable on tablets without shrinking phones.
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxContentWidth),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: scroll
              ? SingleChildScrollView(
                  padding: padding,
                  physics: const BouncingScrollPhysics(),
                  child: content,
                )
              : Padding(padding: padding, child: content),
        ),
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
