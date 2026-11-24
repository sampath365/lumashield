import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/color_temperature.dart';
import '../../shared/models/filter_settings.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/luma_slider.dart';
import '../eye_care/break_exercise_screen.dart';

/// Dedicated reading surface: warm paper tone, larger type and a session timer
/// that offers a break every 20 minutes.
class ReadingModeScreen extends ConsumerStatefulWidget {
  const ReadingModeScreen({super.key});

  @override
  ConsumerState<ReadingModeScreen> createState() => _ReadingModeScreenState();
}

class _ReadingModeScreenState extends ConsumerState<ReadingModeScreen> {
  double _textScale = 1.0;
  double _warmth = 0.55;
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds % 1200 == 0) {
        openBreakExercise(context);
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  String get _elapsed {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final filter = ref.watch(filterControllerProvider);
    final tint = ColorTemperature.colorFor(
      (6500 - (_warmth * (6500 - 2400))).round(),
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Reading mode'),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: palette.accent),
                  const SizedBox(width: 6),
                  Text(
                    _elapsed,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: _showControls ? 'Hide controls' : 'Show controls',
            onPressed: () => setState(() => _showControls = !_showControls),
            icon: Icon(_showControls ? Icons.visibility_off_outlined : Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF3),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
                    children: [
                      Text(
                        'Why warm light helps at night',
                        style: TextStyle(
                          fontSize: 26 * _textScale,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: const Color(0xFF20180F),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A 3 minute read · LumaShield',
                        style: TextStyle(
                          fontSize: 12 * _textScale,
                          color: const Color(0xFF8A7A64),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (final paragraph in const [
                        'Your eyes do not have a blue light filter. What they have is a '
                            'sensitivity: short wavelengths scatter more inside the eye, which '
                            'makes text look softer and forces the focusing muscles to work harder.',
                        'In the evening the problem changes. Bright, blue rich light tells the '
                            'brain that it is still daytime. Melatonin release is delayed, and '
                            'falling asleep takes longer even after the phone is put down.',
                        'Warming the display does not remove light, it shifts the balance. Red '
                            'and amber pass through almost unchanged, blue is reduced, and the '
                            'contrast stays comfortable enough to keep reading.',
                        'The best result comes from three small things together: a warmer '
                            'screen, a dimmer room light and a habit of looking into the distance '
                            'every twenty minutes.',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Text(
                            paragraph,
                            style: TextStyle(
                              fontSize: 16.5 * _textScale,
                              height: 1.72,
                              color: const Color(0xFF2C2318),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6ECDC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, color: Color(0xFFB07A2A)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tip: hold the phone at eye level and keep a lamp on behind you.',
                                style: TextStyle(
                                  fontSize: 13.5 * _textScale,
                                  height: 1.5,
                                  color: const Color(0xFF5C4A32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: _warmth * 0.42),
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showControls)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  LumaSlider(
                    label: 'Page warmth',
                    icon: Icons.thermostat_rounded,
                    value: _warmth * 100,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    valueLabel: '${(_warmth * 100).round()}%',
                    onChanged: (value) => setState(() => _warmth = value / 100),
                  ),
                  LumaSlider(
                    label: 'Text size',
                    icon: Icons.format_size_rounded,
                    value: _textScale,
                    min: 0.85,
                    max: 1.5,
                    divisions: 13,
                    valueLabel: '${(_textScale * 100).round()}%',
                    onChanged: (value) => setState(() => _textScale = value),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final controller = ref.read(filterControllerProvider.notifier);
                            controller.setMode(FilterModeForReading.mode);
                            controller.setIntensity(50);
                            controller.setKelvin(4000);
                            controller.setEnabled(true);
                          },
                          icon: const Icon(Icons.wb_incandescent_outlined, size: 18),
                          label: Text(
                            filter.enabled && filter.mode == FilterMode.reading
                                ? 'Reading filter applied'
                                : 'Apply reading filter',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: () => openBreakExercise(context),
                        icon: const Icon(Icons.timer_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }
}

/// Small indirection so the reading screen does not import the whole filter
/// model just for one constant.
class FilterModeForReading {
  static const mode = FilterMode.reading;
}
