import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

/// The hero control.
///
/// The outer ring is the eye comfort score: it drains as screen time adds up and
/// climbs back when a break is taken, so the circle visibly grows and shrinks
/// through the day. The thin inner ring is the filter strength. Tapping the orb
/// turns the filter on or off.
class ProtectionOrb extends StatefulWidget {
  const ProtectionOrb({
    super.key,
    required this.active,
    required this.score,
    required this.filterStrength,
    required this.statusLabel,
    required this.onTap,
    this.size = 260,
    this.enabled = true,
    this.nextBreakIn,
  });

  final bool active;

  /// Eye comfort percentage, 0-100.
  final int score;

  /// Blue light filter percentage, 0-100.
  final int filterStrength;
  final String statusLabel;
  final VoidCallback onTap;
  final double size;
  final bool enabled;
  final int? nextBreakIn;

  @override
  State<ProtectionOrb> createState() => _ProtectionOrbState();
}

class _ProtectionOrbState extends State<ProtectionOrb> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _breath.repeat(reverse: true);
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
      tween: Tween<double>(end: widget.score.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animatedScore, _) =>
          _buildOrb(context, palette, animatedScore),
    );
  }

  Widget _buildOrb(BuildContext context, AppPalette palette, double animatedScore) {
    final score = animatedScore.round();

    return Semantics(
      button: true,
      label: widget.active
          ? 'Blue light filter on. Eye comfort $score percent. '
                'Double tap to turn the filter off.'
          : 'Blue light filter off. Eye comfort $score percent. '
                'Double tap to turn the filter on.',
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
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
                      score: animatedScore / 100,
                      filterStrength: widget.filterStrength / 100,
                      accent: scoreColour,
                      filterColour: palette.accent,
                      warm: palette.warm,
                      track: palette.surfaceHigh,
                      pulse: pulse,
                      isDark: palette.isDark,
                      showFilterRing: widget.active,
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
                          Text(
                            '$score%',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            'EYE COMFORT',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scoreColour,
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
                                  color: widget.active
                                      ? palette.accent
                                      : palette.textMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.active
                                    ? 'Filter ${widget.filterStrength}%'
                                    : 'Filter off',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: palette.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.active
                                  ? palette.accent
                                  : palette.textMuted.withValues(alpha: 0.18),
                            ),
                            child: Icon(
                              Icons.power_settings_new_rounded,
                              size: 20,
                              color: widget.active
                                  ? (palette.isDark ? const Color(0xFF1B1206) : Colors.white)
                                  : palette.textMuted,
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
    required this.score,
    required this.filterStrength,
    required this.accent,
    required this.filterColour,
    required this.warm,
    required this.track,
    required this.pulse,
    required this.isDark,
    required this.showFilterRing,
  });

  final double score;
  final double filterStrength;
  final Color accent;
  final Color filterColour;
  final Color warm;
  final Color track;
  final double pulse;
  final bool isDark;
  final bool showFilterRing;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (pulse > 0) {
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.20 * pulse), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 18));
      canvas.drawCircle(center, radius + 18, glow);
    }

    // Tick marks give the ring a watch face quality.
    for (var i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final major = i % 5 == 0;
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
          ..color = track.withValues(alpha: isDark ? 0.9 : 0.6)
          ..strokeWidth = major ? 2 : 1
          ..strokeCap = StrokeCap.round,
      );
    }

    // Eye comfort ring.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = track,
    );

    if (score > 0.001) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * score.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [
              accent.withValues(alpha: 0.65),
              accent,
              accent.withValues(alpha: 0.85),
            ],
            stops: const [0, 0.75, 1],
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(rect),
      );

      final endAngle = -math.pi / 2 + 2 * math.pi * score.clamp(0.0, 1.0);
      final knob = Offset(
        center.dx + math.cos(endAngle) * radius,
        center.dy + math.sin(endAngle) * radius,
      );
      canvas.drawCircle(knob, 6, Paint()..color = Colors.white);
      canvas.drawCircle(
        knob,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.35),
      );
    }

    // Filter strength ring, inside the eye score ring.
    if (showFilterRing) {
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
      if (filterStrength > 0.001) {
        canvas.drawArc(
          innerRect,
          -math.pi / 2,
          2 * math.pi * filterStrength.clamp(0.0, 1.0),
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..color = filterColour.withValues(alpha: 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.score != score ||
      oldDelegate.filterStrength != filterStrength ||
      oldDelegate.pulse != pulse ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track ||
      oldDelegate.showFilterRing != showFilterRing;
}
