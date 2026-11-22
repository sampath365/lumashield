/// Product wide constants. Keeping them in one place makes the copy and the
/// numeric limits easy to audit against the store listing.
class AppConstants {
  AppConstants._();

  static const String appName = 'LumaShield';
  static const String tagline = 'Blue light filter & eye care';
  static const String packageName = 'com.lumashield.app';
  static const String privacyUrl = 'https://lumashield.app/privacy';
  static const String supportEmail = 'support@lumashield.app';
  static const String githubUrl = 'https://github.com/lumashield/lumashield';

  static const int minKelvin = 1900;
  static const int maxKelvin = 6500;
  static const int defaultKelvin = 4500;

  static const int minIntensity = 0;
  static const int maxIntensity = 100;

  /// Channel and notification identifiers shared with the Kotlin layer.
  static const String platformChannel = 'com.lumashield.app/filter';
  static const String eventChannel = 'com.lumashield.app/events';

  static const int reminderNotificationBaseId = 5000;
  static const int dailyReportNotificationId = 5100;
  static const int sleepReminderNotificationId = 5101;
  static const int eyeStrainNotificationId = 5102;

  /// Sessions older than this are pruned from local history.
  static const Duration historyRetention = Duration(days: 120);

  static const List<int> quickIntensities = [0, 25, 40, 55, 70, 85, 100];
}
