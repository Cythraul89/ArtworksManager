import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

final artworkByIdProvider = StreamProvider.family<Artwork?, int>((ref, id) {
  return ref.watch(databaseProvider).artworksDao.watchById(id);
});

final photosByArtworkProvider =
    StreamProvider.family<List<ArtworkPhoto>, int>((ref, id) {
  return ref.watch(databaseProvider).photosDao.watchForArtwork(id);
});
