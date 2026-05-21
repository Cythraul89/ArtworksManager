import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:artworks_manager/core/database/app_database.dart';
import 'package:artworks_manager/core/services/backup_service.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String docsPath;
  _FakePathProvider(this.docsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

Artwork _artwork({
  int id = 1,
  String title = 'Test',
  String artist = '',
  String medium = '',
  String currency = 'EUR',
  String condition = '',
  String provenance = '',
}) =>
    Artwork(
      id: id,
      title: title,
      artist: artist,
      year: null,
      type: '',
      medium: medium,
      heightCm: null,
      widthCm: null,
      depthCm: null,
      location: '',
      acquisitionDate: null,
      currency: currency,
      purchasePrice: null,
      description: '',
      condition: condition,
      provenance: provenance,
      photoPath: '',
      certificatePath: '',
      createdAt: 0,
    );

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('BackupService.generateFilename', () {
    test('starts with artworks_ and ends with .zip', () {
      final name = BackupService.generateFilename();
      expect(name, startsWith('artworks_'));
      expect(name, endsWith('.zip'));
    });

    test('two calls within a second produce different names', () async {
      final a = BackupService.generateFilename();
      await Future<void>.delayed(const Duration(seconds: 1));
      final b = BackupService.generateFilename();
      expect(a, isNot(equals(b)));
    });
  });

  group('BackupService export/import', () {
    test('exportToZip embeds artworks.json with correct metadata', () async {
      final artwork = _artwork(id: 7, title: 'Mona Lisa', artist: 'Da Vinci');
      final bytes = await BackupService().exportToZip([artwork], {});

      final archive = ZipDecoder().decodeBytes(bytes);
      final jsonFile =
          archive.files.firstWhere((f) => f.name == 'artworks.json');
      final root =
          jsonDecode(utf8.decode(jsonFile.content as List<int>)) as Map;

      expect(root['artworks'], hasLength(1));
      expect(root['artworks'][0]['id'], 7);
      expect(root['artworks'][0]['title'], 'Mona Lisa');
      expect(root['artworks'][0]['artist'], 'Da Vinci');
    });

    test('round-trip preserves artwork fields', () async {
      final artwork = _artwork(
          id: 42, title: 'Starry Night', artist: 'Van Gogh', medium: 'Oil');
      final bytes = await BackupService().exportToZip([artwork], {});
      final data = await BackupService().importFromBytes(bytes);

      expect(data.artworks, hasLength(1));
      final a = data.artworks.first;
      expect(a.title.value, 'Starry Night');
      expect(a.artist.value, 'Van Gogh');
      expect(a.medium.value, 'Oil');
    });

    test('round-trip preserves condition and provenance', () async {
      final artwork = _artwork(
        id: 99,
        title: 'Sunflowers',
        condition: 'Good',
        provenance: 'Purchased from Sotheby\'s, 2020',
      );
      final bytes = await BackupService().exportToZip([artwork], {});
      final data = await BackupService().importFromBytes(bytes);

      final a = data.artworks.first;
      expect(a.condition.value, 'Good');
      expect(a.provenance.value, 'Purchased from Sotheby\'s, 2020');
    });

    test('round-trip with multiple artworks preserves count', () async {
      final artworks = List.generate(
          5, (i) => _artwork(id: i + 1, title: 'Artwork $i'));
      final bytes = await BackupService().exportToZip(artworks, {});
      final data = await BackupService().importFromBytes(bytes);

      expect(data.artworks, hasLength(5));
    });

    test('importFromBytes throws on invalid bytes', () async {
      final bad = Uint8List.fromList([0, 1, 2, 3]);
      expect(
        () => BackupService().importFromBytes(bad),
        throwsA(anything),
      );
    });

    test('importFromBytes throws when artworks.json is missing', () async {
      final archive = Archive();
      archive.addFile(ArchiveFile(
          'other.txt', 4, utf8.encode('test')));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive) ?? []);

      expect(
        () => BackupService().importFromBytes(bytes),
        throwsA(isA<Exception>()),
      );
    });
  });
}
