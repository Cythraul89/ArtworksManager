import 'dart:async' show runZonedGuarded;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'core/services/app_logger.dart';
import 'core/services/birthday_notification_service.dart';
import 'core/services/sync_worker.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == SyncWorker.taskName) return SyncWorker.run();
    if (task == BirthdayWorker.taskName) return BirthdayWorker.run();
    return true;
  });
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(['AWoMa'], '''Copyright (C) 2026 Cythraul89

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/''');
    });
    // workmanager only supports Android; calling initialize() on other platforms
    // throws MissingPluginException and crashes the app at startup.
    if (Platform.isAndroid) {
      await Workmanager().initialize(callbackDispatcher);
    }
    await BirthdayNotificationService.initialize();
    runApp(const ProviderScope(child: ArtworksManagerApp()));
    // Request runtime permissions after the first frame so the Activity is
    // in RESUMED state — calling before runApp() throws SecurityException on
    // Android 13+ and silently kills the process in release builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BirthdayNotificationService.requestPermissions();
    });
  }, (error, stack) {
    AppLogger.error('Unhandled error in main zone', error, stack);
  });
}
