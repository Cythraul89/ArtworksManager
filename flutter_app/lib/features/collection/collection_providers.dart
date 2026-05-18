import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

enum SortBy { dateAdded, title, artist, year }

class CollectionFilter {
  final String search;
  final String medium;
  final SortBy sortBy;
  final bool isGrid;

  const CollectionFilter({
    this.search = '',
    this.medium = '',
    this.sortBy = SortBy.dateAdded,
    this.isGrid = true,
  });

  CollectionFilter copyWith({
    String? search,
    String? medium,
    SortBy? sortBy,
    bool? isGrid,
  }) =>
      CollectionFilter(
        search: search ?? this.search,
        medium: medium ?? this.medium,
        sortBy: sortBy ?? this.sortBy,
        isGrid: isGrid ?? this.isGrid,
      );
}

final collectionFilterProvider =
    StateProvider<CollectionFilter>((_) => const CollectionFilter());

/// All artworks filtered and sorted client-side from the DB stream.
final filteredArtworksProvider = StreamProvider<List<Artwork>>((ref) {
  final db = ref.watch(databaseProvider);
  final filter = ref.watch(collectionFilterProvider);

  return db.artworksDao.watchAll().map((list) {
    var result = list;

    if (filter.search.isNotEmpty) {
      final q = filter.search.toLowerCase();
      result = result
          .where((a) =>
              a.title.toLowerCase().contains(q) ||
              a.artist.toLowerCase().contains(q) ||
              a.medium.toLowerCase().contains(q))
          .toList();
    }

    if (filter.medium.isNotEmpty) {
      result = result.where((a) => a.medium == filter.medium).toList();
    }

    switch (filter.sortBy) {
      case SortBy.title:
        result = [...result]..sort((a, b) => a.title.compareTo(b.title));
      case SortBy.artist:
        result = [...result]..sort((a, b) => a.artist.compareTo(b.artist));
      case SortBy.year:
        result = [...result]
          ..sort((a, b) => (b.year ?? 0).compareTo(a.year ?? 0));
      case SortBy.dateAdded:
        break; // already sorted by createdAt DESC from the DAO
    }

    return result;
  });
});

final distinctMediumsProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.artworksDao.watchDistinctMediums();
});
