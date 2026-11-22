import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Optional app lock. Biometrics are only used to gate the UI; no data leaves
/// the device and no screen content is captured.
class BiometricService {
  BiometricService({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      final enrolled = await _auth.getAvailableBiometrics();
      return canCheck || enrolled.isNotEmpty;
    } catch (error) {
      debugPrint('biometric availability failed: $error');
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock LumaShield'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: false,
      );
    } catch (error) {
      debugPrint('biometric auth failed: $error');
      return false;
    }
  }
}
