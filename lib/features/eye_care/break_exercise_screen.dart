import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';

/// A guided eye break: three short steps, an owl that blinks with you, and a
/// countdown you can follow without reading instructions twice.
///
/// Opening it from the break notification marks the break complete when the
/// countdown ends, which resets the eye comfort score.
class BreakExerciseScreen extends ConsumerStatefulWidget {
  const BreakExerciseScreen({super.key, this.autoStart = true});

  final bool autoStart;

  @override
  ConsumerState<BreakExerciseScreen> createState() => _BreakExerciseScreenState();
}

class _BreakStep {
  const _BreakStep({
    required this.title,
    required this.instruction,
    required this.seconds,
    required this.icon,
    required this.lookDirection,
  });

  final String title;
  final String instruction;
  final int seconds;
  final IconData icon;
  final Offset lookDirection;
}

class _BreakExerciseScreenState extends ConsumerState<BreakExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final List<_BreakStep> _steps;
  late final int _totalSeconds;
  int _stepIndex = 0;
  int _remaining = 0;
  int _elapsed = 0;
  Timer? _timer;
  bool _finished = false;
  bool _paused = false;

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    final length = ref.read(eyeCareControllerProvider).twentyBreakSec;
    _totalSeconds = length.clamp(10, 120);
    _steps = _buildSteps(_totalSeconds);
    _remaining = _steps.first.seconds;
    if (widget.autoStart) _start();
  }

  List<_BreakStep> _buildSteps(int total) {
    final look = math.max(6, (total * 0.5).round());
    final blink = math.max(4, (total * 0.25).round());
    final roll = math.max(4, total - look - blink);
    return [
      _BreakStep(
        title: 'Look far away',
        instruction:
            'Find something 20 feet away, out of a window if you can, and let your '
            'focus relax there.',
        seconds: look,
        icon: Icons.landscape_outlined,
        lookDirection: Offset.zero,
      ),
      _BreakStep(
        title: 'Blink slowly',
        instruction:
            'Blink fully, ten times. Screens cut blinking in half, so this re-wets '
            'the surface of your eyes.',
        seconds: blink,
        icon: Icons.remove_red_eye_outlined,
        lookDirection: const Offset(0, 0.15),
      ),
      _BreakStep(
        title: 'Roll and rest',
        instruction:
            'Roll your eyes once, slowly, then close them and breathe out. Shoulders down.',
        seconds: roll,
        icon: Icons.self_improvement_rounded,
        lookDirection: const Offset(0.35, 0),
      ),
    ];
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused) return;
      setState(() {
        _elapsed++;
        _remaining--;
        if (_remaining <= 0) {
          if (_stepIndex < _steps.length - 1) {
            _stepIndex++;
            _remaining = _steps[_stepIndex].seconds;
            HapticFeedback.lightImpact();
          } else {
            _complete();
          }
        }
      });
    });
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    // Log the break without blocking the UI: the score refresh is a native call
    // that may take a frame or two.
    final controller = ref.read(eyeCareControllerProvider.notifier);
    if (mounted) Navigator.of(context).pop(true);
    unawaited(controller.completeBreak());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final step = _steps[_stepIndex];
    final progress = _totalSeconds == 0 ? 0.0 : (_elapsed / _totalSeconds).clamp(0.0, 1.0);
    final stepProgress = step.seconds == 0 ? 0.0 : 1 - (_remaining / step.seconds);

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Eye break',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Skip without logging',
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                _CountdownRing(
                  progress: progress,
                  remaining: _remaining,
                  child: _OwlMascot(
                    blink: _blink,
                    lookDirection: step.lookDirection,
                    colour: palette.accent,
                  ),
                ),
                const Spacer(),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  step.instruction,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _steps.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _stepIndex ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i <= _stepIndex ? palette.accent : palette.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stepProgress,
                    minHeight: 5,
                    backgroundColor: palette.surfaceHigh,
                  ),
                ),
                const Spacer(flex: 2),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _paused = !_paused);
                        },
                        icon: Icon(
                          _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          size: 18,
                        ),
                        label: Text(_paused ? 'Resume' : 'Pause'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _complete,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Looking far away and blinking is the most effective thing you can do '
                  'for tired eyes. Screen distance sensors are not available to apps, so '
                  'this timer is your guide.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.progress,
    required this.remaining,
    required this.child,
  });

  final double progress;
  final int remaining;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              backgroundColor: palette.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
          child,
          Positioned(
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Text(
                '$remaining s',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The mascot: an owl that blinks on a slow cycle and looks where the step
/// asks you to look. Drawn in code so it scales to any screen.
class _OwlMascot extends StatelessWidget {
  const _OwlMascot({
    required this.blink,
    required this.lookDirection,
    required this.colour,
  });

  final Animation<double> blink;
  final Offset lookDirection;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: AnimatedBuilder(
        animation: blink,
        builder: (context, _) {
          // One quick blink every cycle, plus a soft breathing scale.
          final t = blink.value;
          final blinkAmount = t > 0.9 ? math.sin((t - 0.9) / 0.1 * math.pi) : 0.0;
          final breathe = 1 + 0.012 * math.sin(t * 2 * math.pi);
          return Transform.scale(
            scale: breathe,
            child: CustomPaint(
              painter: _OwlPainter(
                blink: blinkAmount,
                look: lookDirection,
                colour: colour,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OwlPainter extends CustomPainter {
  _OwlPainter({required this.blink, required this.look, required this.colour});

  final double blink;
  final Offset look;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centre = Offset(w / 2, h / 2 + h * 0.02);

    final body = Paint()..color = const Color(0xFF1B2740);
    final feather = Paint()..color = const Color(0xFF243453);
    final amber = Paint()..color = colour;
    final dark = Paint()..color = const Color(0xFF0A1020);
    final white = Paint()..color = const Color(0xFFF7FAFF);

    // Ear tufts.
    final tuft = Path()
      ..moveTo(w * 0.24, h * 0.30)
      ..lineTo(w * 0.30, h * 0.12)
      ..lineTo(w * 0.42, h * 0.26)
      ..close();
    final tuft2 = Path()
      ..moveTo(w * 0.76, h * 0.30)
      ..lineTo(w * 0.70, h * 0.12)
      ..lineTo(w * 0.58, h * 0.26)
      ..close();
    canvas.drawPath(tuft, feather);
    canvas.drawPath(tuft2, feather);

    // Head and body.
    canvas.drawCircle(centre, w * 0.36, body);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centre.dx, h * 0.80),
        width: w * 0.52,
        height: h * 0.34,
      ),
      body,
    );
    // Belly patch.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centre.dx, h * 0.80),
        width: w * 0.32,
        height: h * 0.22,
      ),
      feather,
    );

    // Eyes.
    final eyeY = h * 0.50;
    final eyeR = w * 0.155;
    final leftEye = Offset(w * 0.38, eyeY);
    final rightEye = Offset(w * 0.62, eyeY);
    for (final eye in [leftEye, rightEye]) {
      canvas.drawCircle(eye, eyeR, white);
      canvas.drawCircle(
        eye,
        eyeR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.018
          ..color = amber.color,
      );
      // Pupil follows the step's look direction.
      final pupil = Offset(
        eye.dx + look.dx * eyeR * 0.45,
        eye.dy + look.dy * eyeR * 0.45,
      );
      canvas.drawCircle(pupil, eyeR * 0.46, dark);
      canvas.drawCircle(
        Offset(pupil.dx - eyeR * 0.14, pupil.dy - eyeR * 0.16),
        eyeR * 0.12,
        white,
      );
      if (blink > 0.02) {
        // Eyelid closes from the top.
        final lid = Rect.fromLTWH(
          eye.dx - eyeR,
          eye.dy - eyeR,
          eyeR * 2,
          eyeR * 2 * blink.clamp(0.0, 1.0),
        );
        canvas.save();
        canvas.clipRect(lid);
        canvas.drawCircle(eye, eyeR, body);
        canvas.restore();
      }
    }

    // Beak.
    final beak = Path()
      ..moveTo(w * 0.465, h * 0.655)
      ..lineTo(w * 0.535, h * 0.655)
      ..lineTo(w * 0.50, h * 0.745)
      ..close();
    canvas.drawPath(beak, amber);

    // Feet.
    canvas.drawCircle(Offset(w * 0.42, h * 0.95), w * 0.035, amber);
    canvas.drawCircle(Offset(w * 0.58, h * 0.95), w * 0.035, amber);
  }

  @override
  bool shouldRepaint(covariant _OwlPainter oldDelegate) =>
      oldDelegate.blink != blink ||
      oldDelegate.look != look ||
      oldDelegate.colour != colour;
}

/// Small inline illustration used on the eye care screen card.
class OwlBadge extends StatelessWidget {
  const OwlBadge({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OwlPainter(
          blink: 0,
          look: Offset.zero,
          colour: palette.accent,
        ),
      ),
    );
  }
}

/// Convenience launcher used by the eye care screen and the dashboard.
Future<bool?> openBreakExercise(BuildContext context, {bool autoStart = true}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => BreakExerciseScreen(autoStart: autoStart),
      fullscreenDialog: true,
    ),
  );
}

/// Shared palette helper so the illustration matches every theme.
AppPalette paletteOf(BuildContext context) => context.palette;
