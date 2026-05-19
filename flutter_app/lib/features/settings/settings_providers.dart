import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

final settingsProvider = StreamProvider<Setting>(
    (ref) => ref.watch(databaseProvider).settingsDao.watch());
