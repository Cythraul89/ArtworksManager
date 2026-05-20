import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';
import 'core/services/sync_worker.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == SyncWorker.taskName) return SyncWorker.run();
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // workmanager only supports Android; calling initialize() on other platforms
  // throws MissingPluginException and crashes the app at startup.
  if (Platform.isAndroid) {
    await Workmanager().initialize(callbackDispatcher);
  }
  runApp(const ProviderScope(child: ArtworksManagerApp()));
}
