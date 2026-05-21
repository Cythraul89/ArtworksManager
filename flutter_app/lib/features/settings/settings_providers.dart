import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

final settingsProvider = StreamProvider<Setting>(
    (ref) => ref.watch(databaseProvider).settingsDao.watch());

final packageInfoProvider =
    FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(settingsProvider).valueOrNull?.themeMode ?? 'system';
  return switch (mode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});
