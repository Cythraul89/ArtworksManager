import 'package:drift/drift.dart';
import '../app_database.dart';

part 'artworks_dao.g.dart';

@DriftAccessor(tables: [Artworks, ArtworkPhotos])
class ArtworksDao extends DatabaseAccessor<AppDatabase> with _$ArtworksDaoMixin {
  ArtworksDao(super.db);

  // ── Streams ─────────────────────────────────────────────────────────────

  Stream<List<Artwork>> watchAll() =>
      (select(artworks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Stream<Artwork?> watchById(int id) =>
      (select(artworks)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<int> watchCount() =>
      (selectOnly(artworks)..addColumns([artworks.id.count()]))
          .map((r) => r.read(artworks.id.count()) ?? 0)
          .watchSingle();

  Stream<List<Artwork>> watchRecent({int limit = 8}) =>
      (select(artworks)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .watch();

  Stream<List<TypedResult>> watchMediumCounts() {
    final count = artworks.id.count();
    return (selectOnly(artworks)
          ..addColumns([artworks.medium, count])
          ..where(artworks.medium.isNotValue(''))
          ..groupBy([artworks.medium])
          ..orderBy([OrderingTerm.desc(count)]))
        .watch();
  }

  Stream<List<TypedResult>> watchTopArtists({int limit = 5}) {
    final count = artworks.id.count();
    return (selectOnly(artworks)
          ..addColumns([artworks.artist, count])
          ..where(artworks.artist.isNotValue(''))
          ..groupBy([artworks.artist])
          ..orderBy([OrderingTerm.desc(count)])
          ..limit(limit))
        .watch();
  }

  Stream<List<TypedResult>> watchPriceTotals() {
    final sum = artworks.purchasePrice.sum();
    return (selectOnly(artworks)
          ..addColumns([artworks.currency, sum])
          ..where(artworks.purchasePrice.isNotNull())
          ..groupBy([artworks.currency])
          ..orderBy([OrderingTerm.desc(sum)]))
        .watch();
  }

  Stream<List<String>> watchDistinctMediums() =>
      (selectOnly(artworks, distinct: true)
            ..addColumns([artworks.medium])
            ..where(artworks.medium.isNotValue(''))
            ..orderBy([OrderingTerm.asc(artworks.medium)]))
          .map((r) => r.read(artworks.medium)!)
          .watch();

  // ── One-shot ─────────────────────────────────────────────────────────────

  Future<Artwork?> getById(int id) =>
      (select(artworks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Artwork>> getAll() =>
      (select(artworks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<int> insertArtwork(ArtworksCompanion artwork) =>
      into(artworks).insert(artwork);

  Future<bool> updateArtwork(ArtworksCompanion artwork) =>
      update(artworks).replace(artwork);

  Future<int> deleteArtwork(int id) =>
      (delete(artworks)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(artworks).go();

  Future<void> replaceAll(List<ArtworksCompanion> rows) async {
    await deleteAll();
    await batch((b) => b.insertAll(artworks, rows));
  }
}
