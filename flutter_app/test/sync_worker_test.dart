import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:artworks_manager/core/database/app_database.dart';
import 'package:artworks_manager/core/services/backup_service.dart';
import 'package:artworks_manager/core/services/nextcloud_service.dart';
import 'package:artworks_manager/core/services/sync_worker.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/tmp/sw_test_docs';
}

class _FakeBackupService extends BackupService {
  Uint8List returnBytes = Uint8List(0);

  @override
  Future<Uint8List> exportToZip(
    List<Artwork> artworks,
    Map<int, List<ArtworkPhoto>> photosByArtwork,
  ) async =>
      returnBytes;
}

class _FakeNextcloudService extends NextcloudService {
  // Responses to inject
  NcResult<void> uploadResult = const NcSuccess(null);
  NcResult<List<String>> listResult = const NcSuccess([]);
  NcResult<void> deleteResult = const NcSuccess(null);

  final List<String> deletedPaths = [];

  @override
  Future<NcResult<void>> uploadBackup(
    String serverUrl,
    String username,
    String password,
    String remotePath,
    Uint8List bytes, {
    String? pinnedFingerprint,
  }) async =>
      uploadResult;

  @override
  Future<NcResult<List<String>>> listFiles(
    String serverUrl,
    String username,
    String password,
    String remoteDir, {
    String? pinnedFingerprint,
  }) async =>
      listResult;

  @override
  Future<NcResult<void>> deleteFile(
    String serverUrl,
    String username,
    String password,
    String remotePath, {
    String? pinnedFingerprint,
  }) async {
    deletedPaths.add(remotePath);
    return deleteResult;
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

AppDatabase _inMemory() =>
    AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

/// Returns default settings with Nextcloud configured and auto-sync enabled.
Future<Setting> _configuredSettings(AppDatabase db) async {
  await db.settingsDao.get(); // create default row
  await db.settingsDao.save(const SettingsCompanion(
    autoSyncEnabled: Value(true),
    nextcloudUrl: Value('http://nc.local'),
    nextcloudUsername: Value('user'),
    nextcloudPath: Value('ArtworksManager'),
    nextcloudKeepExports: Value(3),
  ));
  return db.settingsDao.get();
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProvider();
  });

  group('runSyncTask', () {
    test('returns true and skips when auto-sync is disabled', () async {
      final db = _inMemory();
      addTearDown(db.close);
      await db.settingsDao.get(); // ensure row
      final s = await db.settingsDao.get();
      // autoSyncEnabled defaults to false
      expect(s.autoSyncEnabled, isFalse);

      final result = await runSyncTask(
        db: db,
        backupService: _FakeBackupService(),
        nextcloudService: _FakeNextcloudService(),
        settings: s,
        password: 'pw',
      );
      expect(result, isTrue);
    });

    test('returns true and skips when nextcloud URL is empty', () async {
      final db = _inMemory();
      addTearDown(db.close);
      await db.settingsDao.get();
      await db.settingsDao.save(const SettingsCompanion(
        autoSyncEnabled: Value(true),
        nextcloudUrl: Value(''),
        nextcloudUsername: Value(''),
      ));
      final s = await db.settingsDao.get();

      final result = await runSyncTask(
        db: db,
        backupService: _FakeBackupService(),
        nextcloudService: _FakeNextcloudService(),
        settings: s,
        password: 'pw',
      );
      expect(result, isTrue);
    });

    test('returns true and skips when password is empty', () async {
      final db = _inMemory();
      addTearDown(db.close);
      final s = await _configuredSettings(db);

      final result = await runSyncTask(
        db: db,
        backupService: _FakeBackupService(),
        nextcloudService: _FakeNextcloudService(),
        settings: s,
        password: '',
      );
      expect(result, isTrue);
    });

    test('returns true and records lastSyncAt on successful upload', () async {
      final db = _inMemory();
      addTearDown(db.close);
      final s = await _configuredSettings(db);
      final nc = _FakeNextcloudService()
        ..uploadResult = const NcSuccess(null)
        ..listResult = const NcSuccess([]);

      final before = DateTime.now().millisecondsSinceEpoch;
      final result = await runSyncTask(
        db: db,
        backupService: _FakeBackupService(),
        nextcloudService: nc,
        settings: s,
        password: 'secret',
      );
      expect(result, isTrue);

      final updated = await db.settingsDao.get();
      expect(updated.lastSyncAt, isNotNull);
      expect(updated.lastSyncAt! >= before, isTrue);
      expect(updated.lastSyncError, isNull);
    });

    test('returns false and records error on upload failure', () async {
      final db = _inMemory();
      addTearDown(db.close);
      final s = await _configuredSettings(db);
      final nc = _FakeNextcloudService()
        ..uploadResult = const NcFailure('Server error');

      final result = await runSyncTask(
        db: db,
        backupService: _FakeBackupService(),
        nextcloudService: nc,
        settings: s,
        password: 'secret',
      );
      expect(result, isFalse);

      final updated = await db.settingsDao.get();
      expect(updated.lastSyncError, 'Server error');
    });

    test('returns false and records error on transient failure', () async {
      final db = _inMemory();
      addTearDown(db.close);
      final s = await _configuredSettings(db);
      final nc = _FakeNextcloudService()..uploadResult = const NcTransient();

      final result = await runSyncTask(
        db: db,
        backupService: _FakeBackupService(),
        nextcloudService: nc,
        settings: s,
        password: 'pw',
      );
      expect(result, isFalse);
      final updated = await db.settingsDao.get();
      expect(updated.lastSyncError, 'Transient network error');
    });

    test('prunes old backups when count exceeds keepExports', () async {
      final db = _inMemory();
      addTearDown(db.close);
      await db.settingsDao.get();
      await db.settingsDao.save(const SettingsCompanion(
        autoSyncEnabled: Value(true),
        nextcloudUrl: Value('http://nc.local'),
        nextcloudUsername: Value('user'),
        nextcloudPath: Value('ArtworksManager'),
        nextcloudKeepExports: Value(2),
      ));
      final s = await db.settingsDao.get();

      final nc = _FakeNextcloudService()
        ..uploadResult = const NcSuccess(null)
        ..listResult = const NcSuccess([
          '/remote.php/dav/files/user/ArtworksManager/artworks_20240101_000000.zip',
          '/remote.php/dav/files/user/ArtworksManager/artworks_20240102_000000.zip',
          '/remote.php/dav/files/user/ArtworksManager/artworks_20240103_000000.zip',
        ]);

      await runSyncTask(
        db: db,
        backupService: _FakeBackupService(),
        nextcloudService: nc,
        settings: s,
        password: 'pw',
      );

      // keepExports=2, 3 files listed → 1 oldest should be deleted
      expect(nc.deletedPaths.length, 1);
      expect(nc.deletedPaths.first,
          contains('artworks_20240101_000000.zip'));
    });

    test('clears lastSyncError on successful upload', () async {
      final db = _inMemory();
      addTearDown(db.close);
      await db.settingsDao.get();
      await db.settingsDao.save(const SettingsCompanion(
        autoSyncEnabled: Value(true),
        nextcloudUrl: Value('http://nc.local'),
        nextcloudUsername: Value('user'),
        nextcloudPath: Value('ArtworksManager'),
        lastSyncError: Value('previous error'),
      ));
      final s = await db.settingsDao.get();

      final nc = _FakeNextcloudService()
        ..uploadResult = const NcSuccess(null)
        ..listResult = const NcSuccess([]);

      await runSyncTask(
        db: db,
        backupService: _FakeBackupService(),
        nextcloudService: nc,
        settings: s,
        password: 'pw',
      );

      final updated = await db.settingsDao.get();
      expect(updated.lastSyncError, isNull);
    });
  });
}
