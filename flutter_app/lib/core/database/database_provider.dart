import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Singleton database instance. Closed automatically when the provider is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
