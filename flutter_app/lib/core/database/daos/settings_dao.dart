import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../models/artwork_constants.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Returns the single Settings row, inserting defaults if it does not yet exist.
  Future<Setting> get() async {
    final row = await (select(settings)..where((t) => t.id.equals(1))).getSingleOrNull();
    if (row != null) return row;
    await into(settings).insert(const SettingsCompanion());
    return (select(settings)..where((t) => t.id.equals(1))).getSingle();
  }

  /// Reactive stream of the Settings row. Emits a default value before the
  /// row is first written (e.g. on a fresh install before [get] is called).
  Stream<Setting> watch() {
    return (select(settings)..where((t) => t.id.equals(1)))
        .watchSingleOrNull()
        .map((s) => s ?? const Setting(id: 1, currency: 'EUR', nextcloudUrl: '', nextcloudUsername: '', nextcloudPath: kDefaultRemotePath, nextcloudTrustSelfSigned: false, nextcloudKeepExports: 5, lastSyncAt: null, lastSyncError: null, autoSyncEnabled: false, autoSyncIntervalHours: 24, themeMode: 'system', nextcloudCertFingerprint: null));
  }

  /// Partial update — only the fields present in [companion] are written.
  /// Calls [get] first to ensure the row exists.
  Future<void> save(SettingsCompanion companion) async {
    await get(); // ensure row exists before update
    await (update(settings)..where((t) => t.id.equals(1))).write(companion);
  }
}
