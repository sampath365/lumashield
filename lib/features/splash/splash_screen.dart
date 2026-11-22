import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final Animation<double> _scale = Tween<double>(begin: 0.82, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.heroGradient),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: palette.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.35),
                        blurRadius: 48,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shield_moon_rounded,
                    size: 52,
                    color: palette.isDark ? const Color(0xFF1B1206) : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Opacity(
                opacity: _fade.value.clamp(0, 1),
                child: Column(
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        letterSpacing: -0.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppConstants.tagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
