import 'package:flutter_test/flutter_test.dart';
import 'package:lumashield/core/utils/solar.dart';

void main() {
  group('Solar', () {
    test('London midsummer has a long day', () {
      final date = DateTime(2026, 6, 21);
      final sunrise = Solar.sunrise(date, 51.5074, -0.1278);
      final sunset = Solar.sunset(date, 51.5074, -0.1278);
      expect(sunrise, isNotNull);
      expect(sunset, isNotNull);
      expect(sunset!.isAfter(sunrise!), isTrue);
      final daylight = sunset.difference(sunrise).inHours;
      expect(daylight, inInclusiveRange(15, 18));
    });

    test('London midwinter has a short day', () {
      final date = DateTime(2026, 12, 21);
      final sunrise = Solar.sunrise(date, 51.5074, -0.1278)!;
      final sunset = Solar.sunset(date, 51.5074, -0.1278)!;
      expect(sunset.difference(sunrise).inHours, inInclusiveRange(6, 9));
    });

    test('the equator has roughly twelve hour days all year', () {
      for (final month in [1, 4, 7, 10]) {
        final date = DateTime(2026, month, 15);
        final sunrise = Solar.sunrise(date, 0.1, 32.5)!;
        final sunset = Solar.sunset(date, 0.1, 32.5)!;
        expect(sunset.difference(sunrise).inMinutes, inInclusiveRange(700, 740));
      }
    });

    test('polar night returns null instead of inventing a time', () {
      final date = DateTime(2026, 12, 21);
      expect(Solar.sunrise(date, 78.2, 15.6), isNull);
    });
  });
}
