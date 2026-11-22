import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// Full screen scaffold with the signature navy gradient. Every page uses it so
/// the app feels continuous instead of a set of separate screens.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomBar,
    this.floatingActionButton,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 0),
    this.safeBottom = true,
    this.maxContentWidth = 720,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final EdgeInsets padding;
  final bool safeBottom;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.heroGradient),
        child: SafeArea(
          bottom: safeBottom,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
