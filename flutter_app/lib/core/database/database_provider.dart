import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Application-wide database singleton. Not autoDispose so the connection
/// stays open for the app's lifetime. In tests, override this provider
/// with AppDatabase.forTesting(connection) via ProviderScope overrides.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
