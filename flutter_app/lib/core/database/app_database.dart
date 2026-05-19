import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'daos/artworks_dao.dart';
import 'daos/photos_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

// ── Tables ───────────────────────────────────────────────────────────────────

class Artworks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant(''))();
  IntColumn get year => integer().nullable()();
  TextColumn get type => text().withDefault(const Constant(''))();
  TextColumn get medium => text().withDefault(const Constant(''))();
  RealColumn get heightCm => real().nullable()();
  RealColumn get widthCm => real().nullable()();
  RealColumn get depthCm => real().nullable()();
  TextColumn get location => text().withDefault(const Constant(''))();
  IntColumn get acquisitionDate => integer().nullable()(); // Unix ms
  TextColumn get currency => text().withDefault(const Constant(''))();
  RealColumn get purchasePrice => real().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get condition => text().withDefault(const Constant(''))();
  TextColumn get provenance => text().withDefault(const Constant(''))();
  TextColumn get photoPath => text().withDefault(const Constant(''))();
  TextColumn get certificatePath => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch)();
}

class ArtworkPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get artworkId => integer().references(Artworks, #id, onDelete: KeyAction.cascade)();
  TextColumn get photoPath => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get currency => text().withDefault(const Constant('EUR'))();
  TextColumn get nextcloudUrl => text().withDefault(const Constant(''))();
  TextColumn get nextcloudUsername => text().withDefault(const Constant(''))();
  TextColumn get nextcloudPath => text().withDefault(const Constant('ArtworksManager'))();
  TextColumn get nextcloudCertFingerprint => text().withDefault(const Constant(''))();
  IntColumn get nextcloudKeepExports => integer().withDefault(const Constant(5))();
  IntColumn get lastSyncAt => integer().nullable()(); // Unix ms
  TextColumn get lastSyncError => text().nullable()();
  BoolColumn get autoSyncEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get autoSyncIntervalHours => integer().withDefault(const Constant(24))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ─────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [Artworks, ArtworkPhotos, Settings],
  daos: [ArtworksDao, PhotosDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(settings, settings.autoSyncEnabled);
        await m.addColumn(settings, settings.autoSyncIntervalHours);
      }
      if (from < 3) {
        await m.addColumn(settings, settings.lastSyncError);
      }
      if (from < 4) {
        await m.database.customStatement(
            'ALTER TABLE settings DROP COLUMN nextcloud_password');
      }
      if (from < 5) {
        await m.addColumn(artworks, artworks.condition);
        await m.addColumn(artworks, artworks.provenance);
      }
    },
  );

  /// Opens a direct (non-background-isolate) connection for use in WorkManager
  /// background tasks, which are already running in their own isolate.
  static Future<AppDatabase> openForIsolate() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'artworks.db'));
    return AppDatabase.forTesting(DatabaseConnection(NativeDatabase(file)));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'artworks.db'));
    return NativeDatabase.createInBackground(file);
  });
}
