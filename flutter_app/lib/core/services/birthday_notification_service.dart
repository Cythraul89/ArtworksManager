import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'app_logger.dart';

// Shared by both classes — top-level so BirthdayWorker can access them.
const _notificationId = 528;
const _channelId = 'birthday';
const _channelName = 'Birthday';
const _birthdayMonth = 6;
const _birthdayDay = 3;
const _notifyHour = 9;
const _notifyMinute = 0;

final _plugin = FlutterLocalNotificationsPlugin();

const _details = NotificationDetails(
  android: AndroidNotificationDetails(
    _channelId,
    _channelName,
    importance: Importance.high,
    priority: Priority.high,
  ),
  iOS: DarwinNotificationDetails(),
  macOS: DarwinNotificationDetails(),
  linux: LinuxNotificationDetails(),
);

/// Schedules an annual birthday notification on June 3 at 09:00 local time.
///
/// Supported platforms: Android, iOS, macOS, Linux.
/// Windows is skipped (its notification setup requires registry/AUMID wiring
/// outside the scope of this plugin alone).
class BirthdayNotificationService {
  /// Initialises the plugin and schedules the alarm.
  /// Does NOT request runtime permissions — call [requestPermissions] instead
  /// from addPostFrameCallback so the Activity is in RESUMED state first.
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

      await _schedule();
      if (Platform.isAndroid) BirthdayWorker.schedule();
    } catch (e, st) {
      AppLogger.error('BirthdayNotification: init failed', e, st);
    }
  }

  /// Request runtime notification permissions.
  /// Must be called after the first frame (via addPostFrameCallback) so the
  /// Activity is in RESUMED state — calling earlier throws SecurityException
  /// on Android 13+ in release builds and silently kills the process.
  static Future<void> requestPermissions() async {
    if (kIsWeb || Platform.isWindows) return;

    try {
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
    } catch (e, st) {
      AppLogger.error('BirthdayNotification: requestPermissions failed', e, st);
    }
  }

  static Future<void> _schedule() async {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
        tz.local, now.year, _birthdayMonth, _birthdayDay, _notifyHour, _notifyMinute);
    if (!next.isAfter(now)) {
      // Today is June 3 and 09:00 has already passed — fire immediately.
      if (now.month == _birthdayMonth && now.day == _birthdayDay) {
        await _plugin.show(
          _notificationId,
          'Happy Birthday, Sthandwa sami! 🎂',
          'Wishing you the most wonderful day! ❤️',
          _details,
        );
        AppLogger.info('BirthdayNotification: shown immediately (missed scheduled time)');
      }
      next = tz.TZDateTime(tz.local, now.year + 1, _birthdayMonth, _birthdayDay,
          _notifyHour, _notifyMinute);
    }

    await _plugin.zonedSchedule(
      _notificationId,
      'Happy Birthday, Sthandwa sami! 🎂',
      'Wishing you the most wonderful day! ❤️',
      next,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    AppLogger.info('BirthdayNotification: scheduled for $next');
  }
}

/// WorkManager background task that fires the birthday notification even
/// when the app has never been opened or the exact alarm was killed by the OS.
class BirthdayWorker {
  static const taskName = 'birthday_notify';

  /// Registers a one-off WorkManager task to fire on the next June 3 at 09:00.
  /// Uses [ExistingWorkPolicy.keep] so repeated app opens don't reset the delay.
  static void schedule() {
    final now = DateTime.now();
    var target = DateTime(
        now.year, _birthdayMonth, _birthdayDay, _notifyHour, _notifyMinute);
    if (!target.isAfter(now)) {
      target = DateTime(now.year + 1, _birthdayMonth, _birthdayDay,
          _notifyHour, _notifyMinute);
    }
    Workmanager().registerOneOffTask(
      taskName,
      taskName,
      initialDelay: target.difference(now),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.not_required),
    );
  }

  /// Called from [callbackDispatcher] in main.dart when WorkManager fires the task.
  static Future<bool> run() async {
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      final now = DateTime.now();
      if (now.month == _birthdayMonth &&
          now.day == _birthdayDay &&
          (now.hour > _notifyHour ||
              (now.hour == _notifyHour && now.minute >= _notifyMinute))) {
        await _plugin.show(
          _notificationId,
          'Happy Birthday, Sthandwa sami! 🎂',
          'Wishing you the most wonderful day! ❤️',
          _details,
        );
        AppLogger.info('BirthdayWorker: notification shown via background task');
      }
      // Schedule for the following year so the task is self-sustaining.
      schedule();
      return true;
    } catch (e, st) {
      await AppLogger.error('BirthdayWorker: run failed', e, st);
      return false;
    }
  }
}
