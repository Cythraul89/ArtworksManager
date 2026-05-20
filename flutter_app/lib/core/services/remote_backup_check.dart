import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_provider.dart';
import 'app_logger.dart';
import 'nextcloud_service.dart';
import 'secure_credentials_service.dart';

/// Holds a remote backup that is newer than the last local sync.
/// Set to non-null by [checkForNewBackup]; cleared by the shell dialog.
final pendingRestoreProvider = StateProvider<BackupInfo?>((ref) => null);

/// Checks Nextcloud for a backup newer than the last local sync.
/// If one is found, sets [pendingRestoreProvider] so the shell can show a dialog.
/// Safe to call fire-and-forget; swallows all errors.
Future<void> checkForNewBackup(WidgetRef ref) async {
  try {
    final db = ref.read(databaseProvider);
    final s = await db.settingsDao.get();
    if (s.nextcloudUrl.isEmpty || s.nextcloudUsername.isEmpty) return;
    final password = await SecureCredentialsService.readPassword();
    if (password.isEmpty) return;

    final result = await NextcloudService().findLatestBackup(
      s.nextcloudUrl, s.nextcloudUsername, password, s.nextcloudPath,
      pinnedFingerprint: s.nextcloudCertFingerprint,
    );
    if (result is! NcSuccess<BackupInfo?> || result.value == null) return;

    final backup = result.value!;
    if (s.lastSyncAt != null) {
      final lastSync = DateTime.fromMillisecondsSinceEpoch(s.lastSyncAt!);
      if (!backup.backupDate.isAfter(lastSync)) return;
    }

    ref.read(pendingRestoreProvider.notifier).state = backup;
  } catch (e, st) {
    await AppLogger.error('checkForNewBackup: failed', e, st);
  }
}
