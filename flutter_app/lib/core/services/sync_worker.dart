import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import '../database/app_database.dart';
import 'app_logger.dart';
import 'backup_service.dart';
import 'nextcloud_service.dart';
import 'secure_credentials_service.dart';

class SyncWorker {
  static const taskName = 'nc_auto_backup';

  static Future<bool> run() async {
    // openForIsolate() uses NativeDatabase directly (no nested isolate) since
    // WorkManager already dispatches into a background isolate.
    final db = await AppDatabase.openForIsolate();
    try {
      await AppLogger.info('SyncWorker: task started');
      final s = await db.settingsDao.get();

      if (!s.autoSyncEnabled) {
        await AppLogger.info('SyncWorker: auto-sync disabled — skipping');
        return true;
      }
      if (s.nextcloudUrl.isEmpty || s.nextcloudUsername.isEmpty) {
        await AppLogger.warn('SyncWorker: Nextcloud not configured — skipping');
        return true;
      }

      final password = await SecureCredentialsService.readPassword();
      if (password.isEmpty) {
        await AppLogger.warn('SyncWorker: no password stored — skipping');
        return true;
      }

      final artworks = await db.artworksDao.getAll();
      final photosByArtwork = <int, List<ArtworkPhoto>>{};
      for (final a in artworks) {
        photosByArtwork[a.id] = await db.photosDao.getForArtwork(a.id);
      }

      final bytes = await BackupService().exportToZip(artworks, photosByArtwork);
      final filename = BackupService.generateFilename();
      final remotePath = '${s.nextcloudPath}/$filename';
      final pin = s.nextcloudCertFingerprint.isEmpty ? null : s.nextcloudCertFingerprint;

      await AppLogger.info('SyncWorker: uploading $filename');
      final nc = NextcloudService();
      final result = await nc.uploadBackup(
        s.nextcloudUrl, s.nextcloudUsername, password,
        remotePath, bytes, pinnedFingerprint: pin,
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

      await _pruneOldBackups(nc, s, password, pin);
      return true;
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

  static Future<void> _pruneOldBackups(
    NextcloudService nc,
    Setting s,
    String password,
    String? pin,
  ) async {
    final result = await nc.listFiles(
      s.nextcloudUrl, s.nextcloudUsername, password,
      s.nextcloudPath, pinnedFingerprint: pin,
    );
    if (result is! NcSuccess<List<String>>) return;
    final files = result.value..sort();
    if (files.length <= s.nextcloudKeepExports) return;
    for (final href in files.sublist(0, files.length - s.nextcloudKeepExports)) {
      final del = await nc.deleteFile(
        s.nextcloudUrl, s.nextcloudUsername, password,
        '${s.nextcloudPath}/${p.basename(href)}',
        pinnedFingerprint: pin,
      );
      if (del is! NcSuccess) {
        await AppLogger.warn('SyncWorker: could not prune $href');
      }
    }
  }
}
