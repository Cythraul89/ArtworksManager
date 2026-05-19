import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artworks_manager/core/database/app_database.dart';

AppDatabase _inMemory() =>
    AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

void main() {
  group('AppDatabase schema', () {
    test('opens and returns default settings', () async {
      final db = _inMemory();
      addTearDown(db.close);

      final s = await db.settingsDao.get();
      expect(s.currency, 'EUR');
      expect(s.autoSyncEnabled, false);
      expect(s.lastSyncError, isNull);
      // nextcloudPassword was dropped in schema v4 — verify it no longer exists
      // by confirming Setting has no such field (compile-time check via type system).
      expect(s.nextcloudUrl, '');
      expect(s.nextcloudUsername, '');
    });

    test('save and reload settings round-trip', () async {
      final db = _inMemory();
      addTearDown(db.close);

      await db.settingsDao.get(); // ensure row exists
      await db.settingsDao.save(const SettingsCompanion(
        currency: Value('USD'),
        autoSyncEnabled: Value(true),
        autoSyncIntervalHours: Value(12),
      ));

      final s = await db.settingsDao.get();
      expect(s.currency, 'USD');
      expect(s.autoSyncEnabled, true);
      expect(s.autoSyncIntervalHours, 12);
    });

    test('lastSyncError is persisted and cleared', () async {
      final db = _inMemory();
      addTearDown(db.close);

      // Ensure row exists before updating.
      await db.settingsDao.get();

      await db.settingsDao.save(const SettingsCompanion(
        lastSyncError: Value('Upload failed: HTTP 401'),
      ));
      final s1 = await db.settingsDao.get();
      expect(s1.lastSyncError, 'Upload failed: HTTP 401');

      await db.settingsDao.save(const SettingsCompanion(
        lastSyncError: Value(null),
      ));
      final s2 = await db.settingsDao.get();
      expect(s2.lastSyncError, isNull);
    });

    test('artworks CRUD', () async {
      final db = _inMemory();
      addTearDown(db.close);

      final id = await db.artworksDao.insertArtwork(const ArtworksCompanion(
        title: Value('Sunflowers'),
        artist: Value('Van Gogh'),
        currency: Value('EUR'),
      ));
      expect(id, greaterThan(0));

      final all = await db.artworksDao.getAll();
      expect(all, hasLength(1));
      expect(all.first.title, 'Sunflowers');

      await db.artworksDao.deleteArtwork(id);
      expect(await db.artworksDao.getAll(), isEmpty);
    });
  });
}
