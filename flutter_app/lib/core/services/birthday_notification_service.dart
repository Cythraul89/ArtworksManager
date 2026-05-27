import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app_logger.dart';

/// Schedules an annual birthday notification on May 28 at 09:00 local time.
///
/// Supported platforms: Android, iOS, macOS, Linux.
/// Windows is skipped (its notification setup requires registry/AUMID wiring
/// outside the scope of this plugin alone).
class BirthdayNotificationService {
  static const _id = 528; // May 28
  static const _channelId = 'birthday';
  static const _channelName = 'Birthday';

  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (kIsWeb || Platform.isWindows) return;

    try {
      tz_data.initializeTimeZones();

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        ),
      );

      await _requestPermissions();
      await _schedule();
    } catch (e, st) {
      AppLogger.error('BirthdayNotification: init failed', e, st);
    }
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }
  }

  static Future<void> _schedule() async {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, 5, 28, 9, 0);
    if (!next.isAfter(now)) {
      next = tz.TZDateTime(tz.local, now.year + 1, 5, 28, 9, 0);
    }

    await _plugin.zonedSchedule(
      _id,
      'Happy Birthday, Sthandwa sami! 🎂',
      'Wishing you the most wonderful day! ❤️',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    AppLogger.info('BirthdayNotification: scheduled for $next');
  }
}
