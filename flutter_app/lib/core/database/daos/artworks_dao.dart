import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../models/artwork_constants.dart';

part 'artworks_dao.g.dart';

@DriftAccessor(tables: [Artworks, ArtworkPhotos])
class ArtworksDao extends DatabaseAccessor<AppDatabase> with _$ArtworksDaoMixin {
  ArtworksDao(super.db);

  // ── Reactive streams ──────────────────────────────────────────────────────

  Stream<List<Artwork>> watchAll() =>
      (select(artworks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Stream<List<Artwork>> watchAllSorted(SortBy sortBy) {
    return (select(artworks)
          ..orderBy([
            (t) => switch (sortBy) {
                  SortBy.dateAdded => OrderingTerm.desc(t.createdAt),
                  SortBy.title => OrderingTerm.asc(t.title),
                  SortBy.artist => OrderingTerm.asc(t.artist),
                  SortBy.year => OrderingTerm.desc(t.year),
                }
          ]))
        .watch();
  }

  Stream<Artwork?> watchById(int id) =>
      (select(artworks)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<int> watchCount() {
    final countExpr = artworks.id.count();
    return (selectOnly(artworks)..addColumns([countExpr]))
        .watchSingle()
        .map((r) => r.read(countExpr) ?? 0);
  }

  Stream<List<Artwork>> watchRecent({int limit = 8}) =>
      (select(artworks)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  Stream<List<({String medium, int count})>> watchMediumCounts() {
    final countExpr = artworks.id.count();
    return (selectOnly(artworks)
          ..addColumns([artworks.medium, countExpr])
          ..where(artworks.medium.isNotValue(''))
          ..groupBy([artworks.medium])
          ..orderBy([OrderingTerm.desc(countExpr)]))
        .watch()
        .map((rows) => rows
            .map((r) => (medium: r.read(artworks.medium)!, count: r.read(countExpr)!))
            .toList());
  }

  Stream<List<({String artist, int count})>> watchTopArtists({int limit = 5}) {
    final countExpr = artworks.id.count();
    return (selectOnly(artworks)
          ..addColumns([artworks.artist, countExpr])
          ..where(artworks.artist.isNotValue(''))
          ..groupBy([artworks.artist])
          ..orderBy([OrderingTerm.desc(countExpr)])
          ..limit(limit))
        .watch()
        .map((rows) => rows
            .map((r) => (artist: r.read(artworks.artist)!, count: r.read(countExpr)!))
            .toList());
  }

  Stream<List<({String currency, double total})>> watchPriceTotals() {
    final sumExpr = artworks.purchasePrice.sum();
    return (selectOnly(artworks)
          ..addColumns([artworks.currency, sumExpr])
          ..where(artworks.purchasePrice.isNotNull())
          ..groupBy([artworks.currency])
          ..orderBy([OrderingTerm.desc(sumExpr)]))
        .watch()
        .map((rows) => rows
            .map((r) => (currency: r.read(artworks.currency)!, total: r.read(sumExpr) ?? 0.0))
            .toList());
  }

  Stream<List<String>> watchDistinctMediums() =>
      (selectOnly(artworks, distinct: true)
            ..addColumns([artworks.medium])
            ..where(artworks.medium.isNotValue(''))
            ..orderBy([OrderingTerm.asc(artworks.medium)]))
          .watch()
          .map((rows) => rows.map((r) => r.read(artworks.medium)!).toList());

  // ── One-shot reads ────────────────────────────────────────────────────────

  Future<Artwork?> getById(int id) =>
      (select(artworks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Artwork>> getAll() =>
      (select(artworks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<int> insertArtwork(ArtworksCompanion artwork) =>
      into(artworks).insert(artwork);

  Future<void> updateArtwork(ArtworksCompanion artwork) =>
      (update(artworks)..where((t) => t.id.equals(artwork.id.value))).write(artwork);

  Future<int> deleteArtwork(int id) =>
      (delete(artworks)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(artworks).go();

  Future<void> replaceAll(
    List<ArtworksCompanion> rows,
    List<ArtworkPhotosCompanion> photos,
  ) async {
    await transaction(() async {
      await delete(artworkPhotos).go(); // explicit clear (FK cascade is inert without the PRAGMA)
      await deleteAll();
      await batch((b) => b.insertAll(artworks, rows));
      if (photos.isNotEmpty) {
        await batch((b) => b.insertAll(artworkPhotos, photos));
      }
    });
  }
}
