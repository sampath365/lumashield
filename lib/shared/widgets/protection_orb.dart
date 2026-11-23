import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

/// The hero control.
///
/// The ring is a circular slider: drag your finger around it to set the blue
/// light reduction, with haptic ticks every five percent. The thick arc grows
/// and shrinks with the percentage, and the power button in the middle toggles
/// the filter. The thin inner arc is the eye comfort score.
class ProtectionOrb extends StatefulWidget {
  const ProtectionOrb({
    super.key,
    required this.active,
    required this.strength,
    required this.eyeScore,
    required this.statusLabel,
    required this.onToggle,
    required this.onStrengthChanged,
    this.size = 260,
    this.enabled = true,
  });

  final bool active;

  /// Blue light reduction, 0-100. Dragging around the ring sets this.
  final int strength;

  /// Eye comfort percentage, shown as the thin inner ring.
  final int eyeScore;
  final String statusLabel;
  final VoidCallback onToggle;
  final ValueChanged<int> onStrengthChanged;
  final double size;
  final bool enabled;

  @override
  State<ProtectionOrb> createState() => _ProtectionOrbState();
}

class _ProtectionOrbState extends State<ProtectionOrb> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  bool _dragging = false;
  int _lastHapticStep = -1;

  @override
  void initState() {
    super.initState();
    if (widget.active) _breath.repeat(reverse: true);
  }

  /// Turns a touch position into a percentage around the ring, starting at the
  /// top and running clockwise.
  void _handleRingTouch(Offset local, Size size) {
    if (!widget.enabled) return;
    final centre = Offset(size.width / 2, size.height / 2);
    final vector = local - centre;
    if (vector.distance < size.shortestSide * 0.24) return; // ignore the centre
    var angle = math.atan2(vector.dy, vector.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final value = ((angle / (2 * math.pi)) * 100).round().clamp(0, 100);
    final step = value ~/ 5;
    if (step != _lastHapticStep) {
      _lastHapticStep = step;
      HapticFeedback.selectionClick();
    }
    if (value != widget.strength) widget.onStrengthChanged(value);
  }

  @override
  void didUpdateWidget(covariant ProtectionOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!widget.active && _breath.isAnimating) {
      _breath.stop();
      _breath.value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.eyeScore.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedScore, _) =>
          _buildOrb(context, palette, animatedScore),
    );
  }

  Widget _buildOrb(BuildContext context, AppPalette palette, double animatedScore) {
    final score = animatedScore.round();
    final strength = widget.strength;

    return Semantics(
      slider: true,
      label:
          '${widget.statusLabel}. Blue light reduction $strength percent. '
          'Eye comfort $score percent. Drag around the ring to change it.',
      value: '$strength%',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onVerticalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onVerticalDragUpdate: (details) =>
            _handleRingTouch(details.localPosition, Size.square(widget.size)),
        onHorizontalDragUpdate: (details) =>
            _handleRingTouch(details.localPosition, Size.square(widget.size)),
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, _) {
            final pulse = widget.active ? 0.5 + _breath.value * 0.5 : 0.0;
            final scoreColour = _scoreColour(palette, score);
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(widget.size),
                    painter: _OrbPainter(
                      strength: strength / 100,
                      eyeScore: animatedScore / 100,
                      accent: palette.accent,
                      eyeColour: scoreColour,
                      track: palette.surfaceHigh,
                      pulse: pulse,
                      isDark: palette.isDark,
                      active: widget.active,
                      dragging: _dragging,
                    ),
                  ),
                  Transform.scale(
                    scale: 1 + pulse * 0.02,
                    child: Container(
                      width: widget.size * 0.64,
                      height: widget.size * 0.64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: widget.active
                              ? [
                                  scoreColour.withValues(alpha: 0.22),
                                  palette.orbCore,
                                  palette.surface,
                                ]
                              : [palette.surfaceHigh, palette.surface],
                          stops: widget.active ? const [0, 0.62, 1] : const [0, 1],
                        ),
                        border: Border.all(
                          color: widget.active
                              ? scoreColour.withValues(alpha: 0.35)
                              : palette.border,
                        ),
                        boxShadow: widget.active
                            ? [
                                BoxShadow(
                                  color: scoreColour.withValues(alpha: 0.16 + pulse * 0.12),
                                  blurRadius: 42,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                              color: widget.active ? palette.textPrimary : palette.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                              fontSize: _dragging ? 48 : 44,
                            ),
                            child: Text('$strength%'),
                          ),
                          Text(
                            widget.active ? 'BLUE LIGHT' : 'BLUE LIGHT OFF',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: widget.active ? palette.accent : palette.textMuted,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scoreColour,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Eyes $score%',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: palette.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: widget.enabled ? widget.onToggle : null,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.active
                                    ? palette.accent
                                    : palette.textMuted.withValues(alpha: 0.18),
                              ),
                              child: Icon(
                                Icons.power_settings_new_rounded,
                                size: 21,
                                color: widget.active
                                    ? (palette.isDark ? const Color(0xFF1B1206) : Colors.white)
                                    : palette.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Green when rested, amber through the day, red when a break is overdue.
  Color _scoreColour(AppPalette palette, int score) {
    if (score >= 75) return palette.success;
    if (score >= 45) return palette.accent;
    return palette.danger;
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.strength,
    required this.eyeScore,
    required this.accent,
    required this.eyeColour,
    required this.track,
    required this.pulse,
    required this.isDark,
    required this.active,
    required this.dragging,
  });

  /// Blue light reduction, 0-1.
  final double strength;

  /// Eye comfort score, 0-1.
  final double eyeScore;
  final Color accent;
  final Color eyeColour;
  final Color track;
  final double pulse;
  final bool isDark;
  final bool active;
  final bool dragging;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (pulse > 0) {
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [
            (active ? accent : eyeColour).withValues(alpha: 0.20 * pulse),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 18));
      canvas.drawCircle(center, radius + 18, glow);
    }

    // Tick marks give the ring a watch face quality and read as slider stops.
    for (var i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final major = i % 5 == 0;
      final lit = (i / 60) <= strength;
      final inner = Offset(
        center.dx + math.cos(angle) * (radius + (major ? 3 : 6)),
        center.dy + math.sin(angle) * (radius + (major ? 3 : 6)),
      );
      final outer = Offset(
        center.dx + math.cos(angle) * (radius + 10),
        center.dy + math.sin(angle) * (radius + 10),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = lit
              ? accent.withValues(alpha: dragging ? 0.9 : 0.65)
              : track.withValues(alpha: isDark ? 0.55 : 0.45)
          ..strokeWidth = major ? 2.2 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // Blue light ring (the slider track and value).
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = track,
    );

    if (strength > 0.001) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * strength.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [
              accent.withValues(alpha: active ? 0.75 : 0.35),
              active ? accent : accent.withValues(alpha: 0.45),
              accent.withValues(alpha: active ? 0.9 : 0.4),
            ],
            stops: const [0, 0.72, 1],
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(rect),
      );

      // Handle you can see yourself dragging.
      final endAngle = -math.pi / 2 + 2 * math.pi * strength.clamp(0.0, 1.0);
      final knob = Offset(
        center.dx + math.cos(endAngle) * radius,
        center.dy + math.sin(endAngle) * radius,
      );
      if (dragging) {
        canvas.drawCircle(
          knob,
          16,
          Paint()..color = accent.withValues(alpha: 0.22),
        );
      }
      canvas.drawCircle(knob, dragging ? 8 : 6.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        knob,
        dragging ? 12 : 10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.35),
      );
    }

    // Eye comfort, a thin arc just inside the slider.
    final innerRadius = radius - 17;
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    canvas.drawArc(
      innerRect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = track.withValues(alpha: 0.75),
    );
    if (eyeScore > 0.001) {
      canvas.drawArc(
        innerRect,
        -math.pi / 2,
        2 * math.pi * eyeScore.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = eyeColour.withValues(alpha: 0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.strength != strength ||
      oldDelegate.eyeScore != eyeScore ||
      oldDelegate.pulse != pulse ||
      oldDelegate.accent != accent ||
      oldDelegate.eyeColour != eyeColour ||
      oldDelegate.track != track ||
      oldDelegate.active != active ||
      oldDelegate.dragging != dragging;
}
