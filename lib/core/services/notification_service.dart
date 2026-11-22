import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../shared/models/eye_care_settings.dart';
import '../constants/app_constants.dart';
import '../utils/platform_capabilities.dart';

/// Local reminders and the daily eye comfort report.
///
/// Reminders are scheduled as bounded batches (the next 12 hours) with inexact
/// alarms, which avoids the exact alarm permission and keeps the battery cost
/// low. The batch is refreshed whenever the app opens or the settings change.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialised = false;

  bool get isReady => _initialised;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (error) {
      debugPrint('timezone lookup failed, using UTC: $error');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@drawable/ic_stat_shield');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
        onDidReceiveNotificationResponse: (response) {
          debugPrint('notification tapped: ${response.payload}');
        },
      );
      _initialised = true;
    } catch (error) {
      debugPrint('notification init failed: $error');
    }
  }

  Future<bool> requestPermission() async {
    if (PlatformCapabilities.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (PlatformCapabilities.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  Future<bool> areEnabled() async {
    try {
      if (PlatformCapabilities.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
        return await android?.areNotificationsEnabled() ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _details(EyeCareSettings settings) => NotificationDetails(
    android: AndroidNotificationDetails(
      'eye_reminders',
      'Eye care reminders',
      channelDescription: 'Break reminders, the 20-20-20 rule and sleep preparation.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: settings.soundEnabled,
      enableVibration: settings.vibrationEnabled,
      category: AndroidNotificationCategory.reminder,
      styleInformation: const BigTextStyleInformation(''),
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: settings.soundEnabled,
    ),
  );

  Future<void> cancelAllReminders() async {
    if (!_initialised) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= AppConstants.reminderNotificationBaseId) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  /// Rebuilds the reminder batch from the current eye care settings.
  Future<void> rescheduleReminders(EyeCareSettings settings) async {
    if (!_initialised) return;
    await cancelAllReminders();

    final now = DateTime.now();
    final horizon = now.add(const Duration(hours: 12));
    final details = _details(settings);

    Future<void> scheduleAt(
      DateTime when,
      String title,
      String body, {
      required int slot,
    }) async {
      if (when.isBefore(now.add(const Duration(minutes: 2)))) return;
      if (when.isAfter(horizon)) return;
      if (_inQuietHours(settings, when)) return;
      try {
        await _plugin.zonedSchedule(
          id: AppConstants.reminderNotificationBaseId + slot,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(when, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'reminder',
        );
      } catch (error) {
        debugPrint('schedule reminder failed: $error');
      }
    }

    var slot = 0;
    if (settings.twentyRuleEnabled) {
      var cursor = now.add(Duration(minutes: settings.twentyIntervalMin));
      while (cursor.isBefore(horizon) && slot < 24) {
        await scheduleAt(
          cursor,
          'Look 20 feet away',
          '20 seconds of distance looking resets your focus. Your next ${settings.twentyIntervalMin} minute cycle starts now.',
          slot: slot++,
        );
        cursor = cursor.add(Duration(minutes: settings.twentyIntervalMin));
      }
    }

    if (settings.eyeStrainEnabled) {
      var cursor = now.add(Duration(minutes: settings.eyeStrainIntervalMin));
      while (cursor.isBefore(horizon) && slot < 30) {
        await scheduleAt(
          cursor,
          'Time to blink and breathe',
          'You have been focused for a while. Blink slowly a few times and relax your shoulders.',
          slot: slot++,
        );
        cursor = cursor.add(Duration(minutes: settings.eyeStrainIntervalMin));
      }
    }

    if (settings.continuousUsageLimitMin > 0) {
      await scheduleAt(
        now.add(Duration(minutes: settings.continuousUsageLimitMin)),
        'Take a longer break',
        'Continuous screen time reached ${settings.continuousUsageLimitMin} minutes. A five minute break helps your eyes recover.',
        slot: slot++,
      );
    }

    if (settings.sleepReminderEnabled) {
      final sleep = _todayAt(now, settings.sleepTimeMinute);
      final target = sleep.isAfter(now) ? sleep : sleep.add(const Duration(days: 1));
      await scheduleAt(
        target,
        'Wind down for sleep',
        'LumaShield Sleep mode keeps the warmest tint. Dim the room and put the phone down soon.',
        slot: slot++,
      );
    }

    if (settings.dailyReportEnabled) {
      final report = _todayAt(now, 21 * 60);
      final target = report.isAfter(now) ? report : report.add(const Duration(days: 1));
      await scheduleAt(
        target,
        'Your eye comfort report is ready',
        'Open LumaShield to see today\'s protection time and break reminders.',
        slot: slot++,
      );
    }
  }

  Future<void> showTestNotification() async {
    if (!_initialised) return;
    await _plugin.show(
      id: 500,
      title: 'LumaShield reminders are on',
      body: 'This is what an eye care reminder looks like.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'eye_reminders',
          'Eye care reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static DateTime _todayAt(DateTime now, int minuteOfDay) {
    final normalized = minuteOfDay % 1440;
    return DateTime(now.year, now.month, now.day, normalized ~/ 60, normalized % 60);
  }

  static bool _inQuietHours(EyeCareSettings settings, DateTime when) {
    if (!settings.quietHoursEnabled) return false;
    final minute = when.hour * 60 + when.minute;
    final start = settings.quietStartMinute;
    final end = settings.quietEndMinute;
    if (start == end) return false;
    return start < end ? (minute >= start && minute < end) : (minute >= start || minute < end);
  }
}
