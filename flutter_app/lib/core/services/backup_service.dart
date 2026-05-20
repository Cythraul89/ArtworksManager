import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/app_database.dart';
import 'app_logger.dart';

/// Serialises and deserialises the full artwork collection as a ZIP archive.
///
/// ZIP layout:
///   artworks.json      — all artwork metadata (array)
///   photos/`<filename>`  — all referenced image and certificate files
class BackupService {
  /// Exports [artworks] and their [photos] to a ZIP in memory.
  Future<Uint8List> exportToZip(
    List<Artwork> artworks,
    Map<int, List<ArtworkPhoto>> photosByArtwork,
  ) async {
    final archive = Archive();

    // Build artworks.json
    final artworksList = artworks.map((a) {
      final additionalPhotos = (photosByArtwork[a.id] ?? []).map((p) => {
        'photo': p.photoPath.isNotEmpty ? _filename(p.photoPath) : '',
        'sortOrder': p.sortOrder,
      }).toList();

      return {
        'id': a.id,
        'title': a.title,
        if (a.artist.isNotEmpty) 'artist': a.artist,
        if (a.year != null) 'year': a.year,
        if (a.type.isNotEmpty) 'type': a.type,
        if (a.medium.isNotEmpty) 'medium': a.medium,
        if (a.heightCm != null) 'heightCm': a.heightCm,
        if (a.widthCm != null) 'widthCm': a.widthCm,
        if (a.depthCm != null) 'depthCm': a.depthCm,
        if (a.location.isNotEmpty) 'location': a.location,
        if (a.acquisitionDate != null)
          'acquisitionDate': _formatDate(a.acquisitionDate!),
        if (a.currency.isNotEmpty) 'currency': a.currency,
        if (a.purchasePrice != null) 'purchasePrice': a.purchasePrice,
        if (a.description.isNotEmpty) 'description': a.description,
        if (a.condition.isNotEmpty) 'condition': a.condition,
        if (a.provenance.isNotEmpty) 'provenance': a.provenance,
        if (a.photoPath.isNotEmpty) 'photo': _filename(a.photoPath),
        if (a.certificatePath.isNotEmpty) 'certificate': _filename(a.certificatePath),
        'createdAt': _formatIso(a.createdAt),
        if (additionalPhotos.isNotEmpty) 'additionalPhotos': additionalPhotos,
      };
    }).toList();

    final jsonBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert({'artworks': artworksList}),
    );
    archive.addFile(ArchiveFile('artworks.json', jsonBytes.length, jsonBytes));

    // Collect all referenced file paths
    final referencedPaths = <String>{};
    for (final a in artworks) {
      if (a.photoPath.isNotEmpty) referencedPaths.add(a.photoPath);
      if (a.certificatePath.isNotEmpty) referencedPaths.add(a.certificatePath);
      for (final ph in photosByArtwork[a.id] ?? []) {
        if (ph.photoPath.isNotEmpty) referencedPaths.add(ph.photoPath);
      }
    }

    final missingPaths = <String>[];
    for (final path in referencedPaths) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile('photos/${_filename(path)}', bytes.length, bytes));
      } else {
        missingPaths.add(path);
      }
    }
    if (missingPaths.isNotEmpty) {
      await AppLogger.warn(
          'BackupService: ${missingPaths.length} file(s) missing during export: ${missingPaths.join(', ')}');
      throw Exception(
          '${missingPaths.length} referenced file(s) not found: ${missingPaths.join(', ')}');
    }

    return Uint8List.fromList(ZipEncoder().encode(archive) ?? []);
  }

  /// Imports a ZIP produced by [exportToZip] and returns the parsed data.
  Future<BackupData> importFromBytes(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    final artworksDir = await _artworksDir();
    final canonicalBase = '${artworksDir.path}${Platform.pathSeparator}';

    // Extract photos first
    final extractedFiles = <String, String>{};
    for (final file in archive.files) {
      if (file.name.startsWith('photos/') && file.isFile) {
        final filename = p.basename(file.name);
        final dest = File(p.join(artworksDir.path, filename));
        // ZIP slip protection
        if ((await dest.canonicalPath).startsWith(canonicalBase)) {
          await dest.writeAsBytes(file.content as List<int>);
          extractedFiles[filename] = dest.path;
        }
      }
    }

    // Parse artworks.json
    final jsonEntry =
        archive.files.where((f) => f.name == 'artworks.json').firstOrNull;
    if (jsonEntry == null) {
      await AppLogger.error('BackupService: artworks.json not found in ZIP');
      throw Exception('Invalid backup: artworks.json not found');
    }
    final jsonStr = utf8.decode(jsonEntry.content as List<int>);
    final root = jsonDecode(jsonStr);
    if (root is! Map<String, dynamic>) {
      await AppLogger.error('BackupService: unexpected JSON root type (${root.runtimeType})');
      throw Exception('Invalid backup: unexpected JSON root type');
    }
    final array = root['artworks'];
    if (array is! List) {
      await AppLogger.error('BackupService: missing artworks array in JSON');
      throw Exception('Invalid backup: missing artworks array');
    }

    final artworks = <ArtworksCompanion>[];
    final photos = <ArtworkPhotosCompanion>[];

    for (final item in array) {
      if (item is! Map<String, dynamic>) continue;
      final o = item;
      final id = o['id'];
      if (id is! int) continue;

      artworks.add(ArtworksCompanion(
        id: Value(id),
        title: Value((o['title'] as String?) ?? ''),
        artist: Value((o['artist'] as String?) ?? ''),
        year: Value(o['year'] as int?),
        type: Value((o['type'] as String?) ?? ''),
        medium: Value((o['medium'] as String?) ?? ''),
        heightCm: Value((o['heightCm'] as num?)?.toDouble()),
        widthCm: Value((o['widthCm'] as num?)?.toDouble()),
        depthCm: Value((o['depthCm'] as num?)?.toDouble()),
        location: Value((o['location'] as String?) ?? ''),
        acquisitionDate: Value(_parseDate(o['acquisitionDate'] as String?)),
        currency: Value((o['currency'] as String?) ?? ''),
        purchasePrice: Value((o['purchasePrice'] as num?)?.toDouble()),
        description: Value((o['description'] as String?) ?? ''),
        condition: Value((o['condition'] as String?) ?? ''),
        provenance: Value((o['provenance'] as String?) ?? ''),
        photoPath: Value(extractedFiles[o['photo'] as String? ?? ''] ?? ''),
        certificatePath:
            Value(extractedFiles[o['certificate'] as String? ?? ''] ?? ''),
        createdAt: Value(_parseIso(o['createdAt'] as String?)),
      ));

      final additionalPhotos = o['additionalPhotos'];
      if (additionalPhotos is List) {
        for (var j = 0; j < additionalPhotos.length; j++) {
          final ph = additionalPhotos[j];
          if (ph is! Map<String, dynamic>) continue;
          final path = extractedFiles[ph['photo'] as String? ?? ''] ?? '';
          if (path.isNotEmpty) {
            photos.add(ArtworkPhotosCompanion(
              artworkId: Value(id),
              photoPath: Value(path),
              sortOrder: Value(ph['sortOrder'] as int? ?? j),
            ));
          }
        }
      }
    }

    return BackupData(artworks: artworks, photos: photos);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns a timestamped filename for a new backup, e.g. `artworks_20240115_142305.zip`.
  static String generateFilename() =>
      'artworks_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.zip';

  Future<Directory> _artworksDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'artworks'));
    await dir.create(recursive: true);
    return dir;
  }

  String _filename(String path) => p.basename(path);

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatIso(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

  int? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s)?.millisecondsSinceEpoch;
  }

  int _parseIso(String? s) {
    if (s == null || s.isEmpty) return DateTime.now().millisecondsSinceEpoch;
    return DateTime.tryParse(s)?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
  }
}

class BackupData {
  final List<ArtworksCompanion> artworks;
  final List<ArtworkPhotosCompanion> photos;
  const BackupData({required this.artworks, required this.photos});
}

extension on File {
  Future<String> get canonicalPath => resolveSymbolicLinks();
}
