import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/platform_capabilities.dart';

class LocationResult {
  const LocationResult({this.latitude, this.longitude, this.error});

  final double? latitude;
  final double? longitude;
  final String? error;

  bool get hasPosition => latitude != null && longitude != null;
}

/// Reads the device position only when the user asks for sunset scheduling.
/// The coordinates stay on the device.
class LocationService {
  const LocationService();

  Future<LocationResult> current() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return const LocationResult(
          error: 'Location services are off. Turn them on, or set the times manually.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult(
          error: 'Location permission was not granted. Sunset scheduling needs a rough position.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      return LocationResult(latitude: position.latitude, longitude: position.longitude);
    } catch (error) {
      debugPrint('location lookup failed: $error');
      return LocationResult(
        error: PlatformCapabilities.isAndroid
            ? 'Could not read the position. You can enter times manually.'
            : 'Could not read the position.',
      );
    }
  }
}
