import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';

/// The hero control: a breathing ring that shows the live filter strength.
///
/// Everything drawn here comes from real state. When protection is off the ring
/// empties and the centre reads "Off", so the dashboard can never look active
/// while the service is idle.
class ProtectionOrb extends StatefulWidget {
  const ProtectionOrb({
    super.key,
    required this.active,
    required this.strength,
    required this.statusLabel,
    required this.onTap,
    this.size = 260,
    this.enabled = true,
  });

  final bool active;
  final int strength;
  final String statusLabel;
  final VoidCallback onTap;
  final double size;
  final bool enabled;

  @override
  State<ProtectionOrb> createState() => _ProtectionOrbState();
}

class _ProtectionOrbState extends State<ProtectionOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ProtectionOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = widget.active ? palette.accent : palette.textMuted;
    final progress = (widget.strength.clamp(0, 100)) / 100;

    return Semantics(
      button: true,
      label: widget.active
          ? 'Blue light filter on, ${widget.strength} percent. Double tap to turn off.'
          : 'Blue light filter off. Double tap to turn on.',
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = widget.active ? 0.5 + _controller.value * 0.5 : 0.0;
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(widget.size),
                    painter: _OrbPainter(
                      progress: progress,
                      accent: accent,
                      warm: palette.warm,
                      track: palette.surfaceHigh,
                      pulse: pulse,
                      isDark: palette.isDark,
                    ),
                  ),
                  Transform.scale(
                    scale: 1 + pulse * 0.02,
                    child: Container(
                      width: widget.size * 0.66,
                      height: widget.size * 0.66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: widget.active
                              ? [
                                  palette.accent.withValues(alpha: 0.22),
                                  palette.orbCore,
                                  palette.surface,
                                ]
                              : [palette.surfaceHigh, palette.surface],
                          stops: widget.active ? const [0, 0.62, 1] : const [0, 1],
                        ),
                        border: Border.all(
                          color: widget.active
                              ? palette.accent.withValues(alpha: 0.35)
                              : palette.border,
                        ),
                        boxShadow: widget.active
                            ? [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.18 + pulse * 0.12),
                                  blurRadius: 42,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.active
                                  ? palette.accent
                                  : palette.textMuted.withValues(alpha: 0.18),
                            ),
                            child: Icon(
                              Icons.power_settings_new_rounded,
                              size: 24,
                              color: widget.active
                                  ? (palette.isDark ? const Color(0xFF1B1206) : Colors.white)
                                  : palette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.active ? '${widget.strength}%' : 'Off',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.statusLabel.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: widget.active ? palette.accent : palette.textMuted,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w700,
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
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.progress,
    required this.accent,
    required this.warm,
    required this.track,
    required this.pulse,
    required this.isDark,
  });

  final double progress;
  final Color accent;
  final Color warm;
  final Color track;
  final double pulse;
  final bool isDark;

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

    // Faint tick marks give the ring a watch face quality.
    final tickPaint = Paint()
      ..color = track.withValues(alpha: isDark ? 0.9 : 0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius + 10),
        center.dy + math.sin(angle) * (radius + 10),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius + (i % 5 == 0 ? 3 : 6)),
        center.dy + math.sin(angle) * (radius + (i % 5 == 0 ? 3 : 6)),
      );
      canvas.drawLine(inner, outer, tickPaint..strokeWidth = i % 5 == 0 ? 2 : 1);
    }

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    if (progress > 0.001) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [accent, warm, accent],
          stops: const [0, 0.55, 1],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect);
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arcPaint);

      final endAngle = -math.pi / 2 + 2 * math.pi * progress;
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
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pulse != pulse ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track;
}
