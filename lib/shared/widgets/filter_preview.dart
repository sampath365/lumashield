import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/color_temperature.dart';

/// A faithful mini preview of what the overlay does to the screen.
///
/// The tint uses the same alpha the Kotlin overlay applies, so the preview and
/// the real filter match. In [compare] mode the left half stays untinted so the
/// blue reduction is visible side by side.
class FilterPreview extends StatelessWidget {
  const FilterPreview({
    super.key,
    required this.kelvin,
    required this.intensity,
    this.customColor,
    this.dim = 0,
    this.height = 168,
    this.compare = false,
  });

  final int kelvin;
  final int intensity;
  final int? customColor;
  final int dim;
  final double height;
  final bool compare;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = customColor != null ? Color(customColor!) : ColorTemperature.colorFor(kelvin);
    final alpha = customColor != null
        ? (intensity / 100) * 0.72
        : ColorTemperature.overlayAlpha(kelvin: kelvin, intensity: intensity);
    final dimAlpha = (dim / 100) * 0.55;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _MockScreen(),
            _TintLayer(
              tint: tint,
              alpha: alpha,
              dimAlpha: dimAlpha,
              widthFactor: compare ? 0.5 : 1,
              alignment: compare ? Alignment.centerRight : Alignment.center,
            ),
            if (compare)
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 1.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            Positioned(
              left: 10,
              top: 10,
              child: _Badge(
                text: compare ? 'Before' : 'Live preview',
                palette: palette,
                muted: true,
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _Badge(
                text: compare
                    ? 'After · ${kelvin}K'
                    : (customColor != null
                          ? 'Custom colour'
                          : '${ColorTemperature.labelFor(kelvin)} · ${kelvin}K'),
                palette: palette,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TintLayer extends StatelessWidget {
  const _TintLayer({
    required this.tint,
    required this.alpha,
    required this.dimAlpha,
    required this.widthFactor,
    required this.alignment,
  });

  final Color tint;
  final double alpha;
  final double dimAlpha;
  final double widthFactor;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (alpha <= 0.001 && dimAlpha <= 0.001) return const SizedBox.shrink();
    return Align(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: 1,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (dimAlpha > 0.001) ColoredBox(color: Colors.black.withValues(alpha: dimAlpha)),
            if (alpha > 0.001) ColoredBox(color: tint.withValues(alpha: alpha)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.palette, this.muted = false});

  final String text;
  final AppPalette palette;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: palette.isDark
            ? Colors.black.withValues(alpha: muted ? 0.32 : 0.48)
            : Colors.white.withValues(alpha: muted ? 0.6 : 0.88),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: palette.isDark ? Colors.white : const Color(0xFF16202F),
          fontWeight: FontWeight.w600,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

/// A small "photo" plus text, deliberately blue so the warmth shift is obvious.
class _MockScreen extends StatelessWidget {
  const _MockScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDCEBFF), Color(0xFFF4F8FF)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 44, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF2F6FBF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(width: 84, height: 8, colour: Color(0xFF16233A), opacity: 0.85),
                    SizedBox(height: 5),
                    _Line(width: 52, height: 6, colour: Color(0xFF16233A), opacity: 0.45),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Expanded(
            child: Row(
              children: [
                Expanded(flex: 3, child: _PhotoCard()),
                SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Line(
                        width: double.infinity,
                        height: 7,
                        colour: Color(0xFF16233A),
                        opacity: 0.32,
                      ),
                      SizedBox(height: 6),
                      _Line(width: 110, height: 7, colour: Color(0xFF16233A), opacity: 0.24),
                      SizedBox(height: 6),
                      _Line(width: 84, height: 7, colour: Color(0xFF16233A), opacity: 0.18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4E8FD6), Color(0xFF9CC4EE)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9A8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 22,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6FA8DC), Color(0xFF3D6FA6)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.width,
    required this.height,
    required this.colour,
    required this.opacity,
  });

  final double width;
  final double height;
  final Color colour;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: colour.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(height / 2),
    ),
  );
}
