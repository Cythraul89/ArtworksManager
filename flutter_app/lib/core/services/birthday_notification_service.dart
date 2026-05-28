import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

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
      if (Platform.isAndroid) BirthdayWorker.schedule();
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

  static const _details = NotificationDetails(
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

  static Future<void> _schedule() async {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, 5, 28, 17, 15);
    if (!next.isAfter(now)) {
      // Today is May 28 and 17:15 has already passed — fire immediately.
      if (now.month == 5 && now.day == 28) {
        await _plugin.show(
          _id,
          'Happy Birthday, Sthandwa sami! 🎂',
          'Wishing you the most wonderful day! ❤️',
          _details,
        );
        AppLogger.info('BirthdayNotification: shown immediately (missed scheduled time)');
      }
      next = tz.TZDateTime(tz.local, now.year + 1, 5, 28, 9, 0);
    }

    await _plugin.zonedSchedule(
      _id,
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

  /// Registers a one-off WorkManager task to fire on the next May 28 at 09:00.
  /// Uses [ExistingWorkPolicy.keep] so repeated app opens don't reset the delay.
  static void schedule() {
    final now = DateTime.now();
    var target = DateTime(now.year, 5, 28, 17, 15);
    if (!target.isAfter(now)) {
      target = DateTime(now.year + 1, 5, 28, 9, 0);
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
      if (now.month == 5 && now.day == 28 &&
          (now.hour > 17 || (now.hour == 17 && now.minute >= 15))) {
        await _plugin.show(
          _id,
          'Happy Birthday, Sthandwa sami! 🎂',
          'Wishing you the most wonderful day! ❤️',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
        await AppLogger.info('BirthdayWorker: notification shown via background task');
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
