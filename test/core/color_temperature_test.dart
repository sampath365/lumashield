import 'package:flutter_test/flutter_test.dart';
import 'package:lumashield/core/utils/color_temperature.dart';

void main() {
  group('ColorTemperature', () {
    test('returns a warm amber around 2700K', () {
      final colour = ColorTemperature.colorFor(2700);
      expect(colour.r, greaterThan(0.9));
      expect(colour.b, lessThan(colour.r));
      expect(colour.g, lessThan(colour.r));
    });

    test('is neutral white at 6500K', () {
      final colour = ColorTemperature.colorFor(6500);
      expect(colour.r, greaterThan(0.9));
      expect(colour.g, greaterThan(0.9));
      expect(colour.b, greaterThan(0.9));
    });

    test('warmth is zero at neutral and one at the minimum', () {
      expect(ColorTemperature.warmth(6500), 0);
      expect(ColorTemperature.warmth(1900), 1);
      expect(ColorTemperature.warmth(4200), closeTo(0.5, 0.01));
    });

    test('overlay alpha stays inside the safe range', () {
      expect(ColorTemperature.overlayAlpha(kelvin: 6500, intensity: 100), 0);
      expect(ColorTemperature.overlayAlpha(kelvin: 1900, intensity: 0), 0);
      final max = ColorTemperature.overlayAlpha(kelvin: 1900, intensity: 100);
      expect(max, closeTo(0.72, 0.001));
    });

    test('labels describe the temperature bands', () {
      expect(ColorTemperature.labelFor(1900), 'Candle');
      expect(ColorTemperature.labelFor(3200), 'Amber');
      expect(ColorTemperature.labelFor(4500), 'Soft white');
      expect(ColorTemperature.labelFor(6500), 'Neutral');
    });
  });
}
