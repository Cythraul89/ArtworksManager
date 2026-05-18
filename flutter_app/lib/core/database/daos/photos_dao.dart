import 'package:drift/drift.dart';
import '../app_database.dart';

part 'photos_dao.g.dart';

@DriftAccessor(tables: [ArtworkPhotos])
class PhotosDao extends DatabaseAccessor<AppDatabase> with _$PhotosDaoMixin {
  PhotosDao(super.db);

  Stream<List<ArtworkPhoto>> watchForArtwork(int artworkId) =>
      (select(artworkPhotos)
            ..where((t) => t.artworkId.equals(artworkId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<List<ArtworkPhoto>> getForArtwork(int artworkId) =>
      (select(artworkPhotos)
            ..where((t) => t.artworkId.equals(artworkId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Future<List<ArtworkPhoto>> getAll() => select(artworkPhotos).get();

  Future<int> insert(ArtworkPhotosCompanion photo) =>
      into(artworkPhotos).insert(photo);

  Future<void> insertAll(List<ArtworkPhotosCompanion> photos) =>
      batch((b) => b.insertAll(artworkPhotos, photos));

  Future<int> deleteById(int id) =>
      (delete(artworkPhotos)..where((t) => t.id.equals(id))).go();

  Future<int> deleteForArtwork(int artworkId) =>
      (delete(artworkPhotos)..where((t) => t.artworkId.equals(artworkId))).go();

  Future<void> deleteAll() => delete(artworkPhotos).go();
}
