import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/artwork_constants.dart';

class CollectionFilter {
  final String search;
  final String medium;
  final String condition;
  final SortBy sortBy;
  final bool isGrid;

  const CollectionFilter({
    this.search = '',
    this.medium = '',
    this.condition = '',
    this.sortBy = SortBy.dateAdded,
    this.isGrid = true,
  });

  CollectionFilter copyWith({
    String? search,
    String? medium,
    String? condition,
    SortBy? sortBy,
    bool? isGrid,
  }) =>
      CollectionFilter(
        search: search ?? this.search,
        medium: medium ?? this.medium,
        condition: condition ?? this.condition,
        sortBy: sortBy ?? this.sortBy,
        isGrid: isGrid ?? this.isGrid,
      );
}

final collectionFilterProvider =
    StateProvider<CollectionFilter>((_) => const CollectionFilter());

final filteredArtworksProvider = StreamProvider<List<Artwork>>((ref) {
  final filter = ref.watch(collectionFilterProvider);
  final db = ref.watch(databaseProvider);
  return db.artworksDao.watchAllSorted(filter.sortBy).map((list) {
    var result = list;
    if (filter.medium.isNotEmpty) {
      result = result.where((a) => a.medium == filter.medium).toList();
    }
    if (filter.condition.isNotEmpty) {
      result = result.where((a) => a.condition == filter.condition).toList();
    }
    if (filter.search.isNotEmpty) {
      final q = filter.search.toLowerCase();
      result = result
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.artist.toLowerCase().contains(q) ||
              a.medium.toLowerCase().contains(q))
          .toList();
    }
    return result;
  });
});

final distinctMediumsProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.artworksDao.watchDistinctMediums();
});
