import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import '../database/app_database.dart';
import 'app_logger.dart';
import 'backup_service.dart';
import 'nextcloud_service.dart';
import 'secure_credentials_service.dart';

/// Core sync logic extracted for testability.
/// Returns true on success or graceful skip; false on upload failure.
Future<bool> runSyncTask({
  required AppDatabase db,
  required BackupService backupService,
  required NextcloudService nextcloudService,
  required Setting settings,
  required String password,
}) async {
  await AppLogger.info('SyncWorker: task started');

  if (!settings.autoSyncEnabled) {
    await AppLogger.info('SyncWorker: auto-sync disabled — skipping');
    return true;
  }
  if (settings.nextcloudUrl.isEmpty || settings.nextcloudUsername.isEmpty) {
    await AppLogger.warn('SyncWorker: Nextcloud not configured — skipping');
    return true;
  }
  if (password.isEmpty) {
    await AppLogger.warn('SyncWorker: no password stored — skipping');
    return true;
  }

  final artworks = await db.artworksDao.getAll();
  final photosByArtwork = <int, List<ArtworkPhoto>>{};
  for (final a in artworks) {
    photosByArtwork[a.id] = await db.photosDao.getForArtwork(a.id);
  }

  final bytes = await backupService.exportToZip(artworks, photosByArtwork);
  final filename = BackupService.generateFilename();
  final remotePath = '${settings.nextcloudPath}/$filename';

  await AppLogger.info('SyncWorker: uploading $filename');
  final result = await nextcloudService.uploadBackup(
    settings.nextcloudUrl, settings.nextcloudUsername, password,
    remotePath, bytes,
    pinnedFingerprint: settings.nextcloudCertFingerprint,
  );

  if (result is! NcSuccess) {
    final msg = switch (result) {
      NcFailure(:final message) => message,
      _ => 'Transient network error',
    };
    await AppLogger.error('SyncWorker: upload failed — $msg');
    await db.settingsDao.save(SettingsCompanion(lastSyncError: Value(msg)));
    return false;
  }

  await db.settingsDao.save(SettingsCompanion(
    lastSyncAt: Value(DateTime.now().millisecondsSinceEpoch),
    lastSyncError: const Value(null),
  ));
  await AppLogger.info('SyncWorker: sync completed successfully');

  await _pruneOldBackups(nextcloudService, settings, password, db);
  return true;
}

Future<void> _pruneOldBackups(
  NextcloudService nc,
  Setting s,
  String password,
  AppDatabase db,
) async {
  final result = await nc.listFiles(
    s.nextcloudUrl, s.nextcloudUsername, password,
    s.nextcloudPath,
    pinnedFingerprint: s.nextcloudCertFingerprint,
  );
  if (result is! NcSuccess<List<String>>) return;
  final files = [...result.value]..sort();
  if (files.length <= s.nextcloudKeepExports) return;
  for (final href in files.sublist(0, files.length - s.nextcloudKeepExports)) {
    final del = await nc.deleteFile(
      s.nextcloudUrl, s.nextcloudUsername, password,
      '${s.nextcloudPath}/${p.basename(href)}',
      pinnedFingerprint: s.nextcloudCertFingerprint,
    );
    if (del is! NcSuccess) {
      await AppLogger.warn('SyncWorker: could not prune $href');
    }
  }
}

/// Call after any artwork mutation to trigger a Nextcloud backup if enabled.
/// Fire-and-forget: caller should use unawaited().
Future<void> triggerAutoBackup(AppDatabase db) async {
  try {
    final s = await db.settingsDao.get();
    if (!s.autoSyncEnabled || s.nextcloudUrl.isEmpty || s.nextcloudUsername.isEmpty) return;
    final password = await SecureCredentialsService.readPassword();
    if (password.isEmpty) return;
    await runSyncTask(
      db: db,
      backupService: BackupService(),
      nextcloudService: NextcloudService(),
      settings: s,
      password: password,
    );
  } catch (e, st) {
    await AppLogger.error('AutoBackup: failed', e, st);
  }
}

class SyncWorker {
  static const taskName = 'nc_auto_backup';

  static Future<bool> run() async {
    // openForIsolate() uses NativeDatabase directly (no nested isolate) since
    // WorkManager already dispatches into a background isolate.
    final db = await AppDatabase.openForIsolate();
    try {
      final s = await db.settingsDao.get();
      final password = await SecureCredentialsService.readPassword();
      return await runSyncTask(
        db: db,
        backupService: BackupService(),
        nextcloudService: NextcloudService(),
        settings: s,
        password: password,
      );
    } catch (e, st) {
      await AppLogger.error('SyncWorker: unexpected error', e, st);
      try {
        await db.settingsDao.save(SettingsCompanion(
          lastSyncError: Value('Unexpected error: $e'),
        ));
      } catch (_) {}
      return false;
    } finally {
      await db.close();
    }
  }
}
