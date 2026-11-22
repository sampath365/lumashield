import 'dart:math' as math;
import 'dart:ui';

/// Black body approximation (Tanner Helland). The same formula runs in Kotlin
/// so the in-app preview and the system overlay always agree.
class ColorTemperature {
  ColorTemperature._();

  static const int minKelvin = 1900;
  static const int maxKelvin = 6500;

  static Color colorFor(int kelvin) {
    final temp = kelvin.clamp(1000, 40000) / 100.0;
    final double red;
    final double green;
    final double blue;
    if (temp <= 66) {
      red = 255;
      green = 99.4708025861 * math.log(temp) - 161.1195681661;
    } else {
      red = 329.698727446 * math.pow(temp - 60, -0.1332047592);
      green = 288.1221695283 * math.pow(temp - 60, -0.0755148492);
    }
    if (temp >= 66) {
      blue = 255;
    } else if (temp <= 19) {
      blue = 0;
    } else {
      blue = 138.5177312231 * math.log(temp - 10) - 305.0447927307;
    }
    return Color.fromARGB(
      255,
      red.round().clamp(0, 255),
      green.round().clamp(0, 255),
      blue.round().clamp(0, 255),
    );
  }

  /// How far the temperature is from neutral daylight, 0 to 1.
  static double warmth(int kelvin) =>
      ((maxKelvin - kelvin) / (maxKelvin - minKelvin)).clamp(0.0, 1.0);

  /// Alpha the native overlay applies for the given settings, mirrored here so
  /// previews are faithful.
  static double overlayAlpha({required int kelvin, required int intensity}) =>
      (intensity / 100) * warmth(kelvin) * 0.72;

  static String labelFor(int kelvin) {
    if (kelvin <= 2400) return 'Candle';
    if (kelvin <= 3000) return 'Warm red';
    if (kelvin <= 3600) return 'Amber';
    if (kelvin <= 4200) return 'Warm';
    if (kelvin <= 5000) return 'Soft white';
    if (kelvin <= 5800) return 'Daylight';
    return 'Neutral';
  }

  static Color blend(Color base, Color tint, double alpha) =>
      Color.lerp(base, tint, alpha.clamp(0.0, 1.0))!;
}
