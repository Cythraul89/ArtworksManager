import 'package:drift/drift.dart';
import '../app_database.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<Setting> get() async {
    final row = await (select(settings)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row != null) return row;
    await into(settings).insert(const SettingsCompanion());
    return (select(settings)..where((t) => t.id.equals(1))).getSingle();
  }

  Stream<Setting> watch() {
    return (select(settings)..where((t) => t.id.equals(1)))
        .watchSingleOrNull()
        .map((s) => s ?? const Setting(id: 1, currency: 'EUR', nextcloudUrl: '', nextcloudUsername: '', nextcloudPassword: '', nextcloudPath: 'ArtworksManager', nextcloudCertFingerprint: '', nextcloudKeepExports: 5, lastSyncAt: null));
  }

  Future<void> save(SettingsCompanion companion) =>
      (update(settings)..where((t) => t.id.equals(1))).write(companion);
}
