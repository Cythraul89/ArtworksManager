import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import '../database/app_database.dart';
import 'backup_service.dart';
import 'nextcloud_service.dart';
import 'secure_credentials_service.dart';

class SyncWorker {
  static const taskName = 'nc_auto_backup';

  static Future<bool> run() async {
    final db = AppDatabase();
    try {
      final s = await db.settingsDao.get();
      if (!s.autoSyncEnabled) return true;
      if (s.nextcloudUrl.isEmpty || s.nextcloudUsername.isEmpty) return true;

      final password = await SecureCredentialsService.readPassword();
      if (password.isEmpty) return true;

      final artworks = await db.artworksDao.getAll();
      final photosByArtwork = <int, List<ArtworkPhoto>>{};
      for (final a in artworks) {
        photosByArtwork[a.id] = await db.photosDao.getForArtwork(a.id);
      }

      final bytes = await BackupService().exportToZip(artworks, photosByArtwork);
      final remotePath = '${s.nextcloudPath}/${BackupService.generateFilename()}';
      final pin = s.nextcloudCertFingerprint.isEmpty ? null : s.nextcloudCertFingerprint;

      final nc = NextcloudService();
      final result = await nc.uploadBackup(
        s.nextcloudUrl, s.nextcloudUsername, password,
        remotePath, bytes, pinnedFingerprint: pin,
      );

      if (result is! NcSuccess) return false;

      await db.settingsDao.save(SettingsCompanion(
        lastSyncAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));

      await _pruneOldBackups(nc, s, password, pin);
      return true;
    } catch (_) {
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
      await nc.deleteFile(
        s.nextcloudUrl, s.nextcloudUsername, password,
        '${s.nextcloudPath}/${p.basename(href)}',
        pinnedFingerprint: pin,
      );
    }
  }
}
