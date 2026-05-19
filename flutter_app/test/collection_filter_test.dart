import 'package:flutter_test/flutter_test.dart';
import 'package:artworks_manager/core/models/artwork_constants.dart';
import 'package:artworks_manager/features/collection/collection_providers.dart';

void main() {
  group('CollectionFilter', () {
    const base = CollectionFilter();

    test('default values', () {
      expect(base.search, '');
      expect(base.medium, '');
      expect(base.sortBy, SortBy.dateAdded);
      expect(base.isGrid, true);
    });

    test('copyWith changes only specified fields', () {
      final f = base.copyWith(search: 'Monet', sortBy: SortBy.artist);
      expect(f.search, 'Monet');
      expect(f.sortBy, SortBy.artist);
      expect(f.medium, '');
      expect(f.isGrid, true);
    });

    test('copyWith with medium filter', () {
      final f = base.copyWith(medium: 'Oil on canvas');
      expect(f.medium, 'Oil on canvas');
      expect(f.search, '');
    });

    test('copyWith preserves previous values', () {
      final step1 = base.copyWith(search: 'Dali', isGrid: false);
      final step2 = step1.copyWith(medium: 'Watercolor');
      expect(step2.search, 'Dali');
      expect(step2.isGrid, false);
      expect(step2.medium, 'Watercolor');
    });

    test('SortBy has expected values', () {
      expect(SortBy.values, containsAll([
        SortBy.dateAdded,
        SortBy.title,
        SortBy.artist,
        SortBy.year,
      ]));
    });
  });
}
