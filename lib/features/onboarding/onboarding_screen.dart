import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/color_temperature.dart';
import '../../core/utils/platform_capabilities.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/filter_preview.dart';
import '../dashboard/home_shell.dart';
import 'permission_setup_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  double _demoKelvin = 3400;
  double _demoIntensity = 65;

  static const _pages = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(appSettingsControllerProvider.notifier).completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const PermissionSetupScreen(next: HomeShell()),
      ),
    );
  }

  void _next() {
    if (_page == _pages - 1) {
      _finish();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  children: [
                    Icon(Icons.shield_moon_rounded, color: palette.accent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip',
                        style: TextStyle(color: palette.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _page = index),
                  children: [
                    _IntroPage(
                      icon: Icons.nightlight_round,
                      title: 'Blue light after dark\nis not your friend',
                      body:
                          'Short wavelengths keep your brain alert and strain the eyes. '
                          'LumaShield warms the screen so you can keep reading without the glare.',
                      accent: palette.accent,
                    ),
                    _DemoPage(
                      kelvin: _demoKelvin,
                      intensity: _demoIntensity,
                      onKelvin: (value) => setState(() => _demoKelvin = value),
                      onIntensity: (value) => setState(() => _demoIntensity = value),
                    ),
                    _SchedulePage(palette: palette),
                    _EyeCarePage(palette: palette),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pages; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _page ? palette.accent : palette.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _next,
                      child: Text(_page == _pages - 1 ? 'Set up LumaShield' : 'Continue'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      PlatformCapabilities.isIOS
                          ? 'iOS cannot tint other apps. LumaShield warms its own screens and reminds you to rest.'
                          : 'Android needs overlay permission to filter other apps. You stay in control.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                        height: 1.4,
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

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: 0.28), Colors.transparent],
              ),
            ),
            child: Center(
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, size: 48, color: accent),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.25),
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoPage extends StatelessWidget {
  const _DemoPage({
    required this.kelvin,
    required this.intensity,
    required this.onKelvin,
    required this.onIntensity,
  });

  final double kelvin;
  final double intensity;
  final ValueChanged<double> onKelvin;
  final ValueChanged<double> onIntensity;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try the filter',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'This is a live preview of the tint. The real filter covers every app.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: 18),
          FilterPreview(
            kelvin: kelvin.round(),
            intensity: intensity.round(),
            height: 210,
            compare: true,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Temperature', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${ColorTemperature.labelFor(kelvin.round())} · ${kelvin.round()}K',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: palette.accent),
              ),
            ],
          ),
          Slider(
            value: kelvin,
            min: 1900,
            max: 6500,
            onChanged: onKelvin,
          ),
          Row(
            children: [
              Text('Intensity', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(
                '${intensity.round()}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: palette.accent),
              ),
            ],
          ),
          Slider(
            value: intensity,
            min: 0,
            max: 100,
            onChanged: onIntensity,
          ),
        ],
      ),
    );
  }
}

class _SchedulePage extends StatelessWidget {
  const _SchedulePage({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_twilight, color: palette.warm),
                    const SizedBox(width: 10),
                    const Text('Sunset'),
                    const Spacer(),
                    Text('7:42 PM', style: TextStyle(color: palette.textMuted)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        Expanded(flex: 6, child: Container(color: palette.surfaceHigh)),
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: BoxDecoration(gradient: palette.accentGradient),
                          ),
                        ),
                        Expanded(flex: 3, child: Container(color: palette.surfaceHigh)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: palette.accent),
                    const SizedBox(width: 10),
                    const Text('Sunrise'),
                    const Spacer(),
                    Text('6:18 AM', style: TextStyle(color: palette.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Automatic from\ndusk to dawn',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.25),
          ),
          const SizedBox(height: 14),
          Text(
            'Follow the sun with your location, or choose exact hours for weekdays '
            'and weekends. The night filter is stronger than the daytime one.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _EyeCarePage extends StatelessWidget {
  const _EyeCarePage({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.accent.withValues(alpha: 0.35), width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '20',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '20 · 20',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.textMuted,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 34),
          Text(
            'Every 20 minutes,\nlook 20 feet away',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.25),
          ),
          const SizedBox(height: 14),
          Text(
            'Gentle reminders for the 20-20-20 rule, longer breaks, hydration and a wind '
            'down cue before bed. All local, all private.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
