import 'dart:math' as math;

/// Sunrise / sunset for scheduling previews. Mirrors SolarCalc.kt.
class Solar {
  Solar._();

  static DateTime? sunrise(DateTime date, double latitude, double longitude) =>
      _event(date, latitude, longitude, sunrise: true);

  static DateTime? sunset(DateTime date, double latitude, double longitude) =>
      _event(date, latitude, longitude, sunrise: false);

  static DateTime? _event(
    DateTime date,
    double latitude,
    double longitude, {
    required bool sunrise,
  }) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final lngHour = longitude / 15.0;

    double? eventHours() {
      final t = dayOfYear + ((sunrise ? 6.0 : 18.0) - lngHour) / 24.0;
      final m = 0.9856 * t - 3.289;
      final l = _normalize(
        m +
            1.916 * math.sin(_rad(m)) +
            0.020 * math.sin(_rad(2 * m)) +
            282.634,
      );
      var ra = _normalize(math.atan(0.91764 * math.tan(_rad(l))) * 180 / math.pi);
      final lQuadrant = (l / 90).floor() * 90.0;
      final raQuadrant = (ra / 90).floor() * 90.0;
      ra = (ra + (lQuadrant - raQuadrant)) / 15.0;
      final sinDec = 0.39782 * math.sin(_rad(l));
      final cosDec = math.cos(math.asin(sinDec));
      final cosH =
          (math.cos(_rad(90.833)) - sinDec * math.sin(_rad(latitude))) /
          (cosDec * math.cos(_rad(latitude)));
      if (cosH > 1 || cosH < -1) return null;
      final h = (sunrise ? 360 - math.acos(cosH) * 180 / math.pi : math.acos(cosH) * 180 / math.pi) / 15.0;
      final localMean = h + ra - 0.06571 * t - 6.622;
      return ((localMean - lngHour) % 24 + 24) % 24;
    }

    final hours = eventHours();
    if (hours == null) return null;
    final utcMinutes = (hours * 60).round();
    return DateTime.utc(date.year, date.month, date.day)
        .add(Duration(minutes: utcMinutes))
        .toLocal();
  }

  static double _rad(double degrees) => degrees * math.pi / 180;

  static double _normalize(double value) => ((value % 360) + 360) % 360;
}
