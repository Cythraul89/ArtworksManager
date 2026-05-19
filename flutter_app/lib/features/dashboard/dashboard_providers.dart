import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

final artworkCountProvider = StreamProvider<int>(
    (ref) => ref.watch(databaseProvider).artworksDao.watchCount());

final recentArtworksProvider = StreamProvider<List<Artwork>>(
    (ref) => ref.watch(databaseProvider).artworksDao.watchRecent());

final mediumCountsProvider =
    StreamProvider<List<({String medium, int count})>>(
        (ref) => ref.watch(databaseProvider).artworksDao.watchMediumCounts());

final topArtistsProvider =
    StreamProvider<List<({String artist, int count})>>(
        (ref) => ref.watch(databaseProvider).artworksDao.watchTopArtists());

final priceTotalsProvider =
    StreamProvider<List<({String currency, double total})>>(
        (ref) => ref.watch(databaseProvider).artworksDao.watchPriceTotals());
