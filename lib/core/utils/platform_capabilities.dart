import 'package:flutter/foundation.dart';

/// Feature matrix. Nothing in the UI claims a capability the OS does not offer:
/// iOS cannot tint other apps, so those controls are explained rather than
/// faked.
class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// A system wide overlay above other apps.
  static bool get systemOverlay => isAndroid;

  /// A foreground service with a persistent notification.
  static bool get backgroundService => isAndroid;

  /// Quick settings tile, home screen widget, boot restore and exact alarms.
  static bool get androidExtras => isAndroid;

  /// Per-app profiles need the foreground app name.
  static bool get perAppProfiles => isAndroid;

  /// Usage statistics of other apps.
  static bool get usageStats => isAndroid;

  /// Lowering the panel brightness of the whole device.
  static bool get systemBrightness => isAndroid;

  /// Screen distance monitoring is not available to third party apps on either
  /// platform, so it stays a documented recommendation.
  static bool get screenDistanceSensor => false;

  /// Biometric app lock is available on both platforms.
  static bool get biometricLock => true;

  /// Local notifications are available on both platforms.
  static bool get localNotifications => true;

  /// An in-app tint that only covers LumaShield itself.
  static bool get inAppTint => true;

  static String get overlayLimitation {
    if (isIOS) {
      return 'iOS does not allow an app to tint other apps or the system UI. '
          'LumaShield can warm its own screens, schedule reminders and use the '
          'built-in Night Shift and Display & Brightness settings instead.';
    }
    return 'Android allows the filter above other apps once "Display over other '
        'apps" is granted. Banking apps, secure video and some manufacturer '
        'power savers can hide overlays, and no app can bypass that.';
  }
}
