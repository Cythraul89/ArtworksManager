import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:artworks_manager/core/services/nextcloud_service.dart';

void main() {
  group('NcResult', () {
    test('NcSuccess carries value', () {
      const r = NcSuccess<int>(42);
      expect(r, isA<NcResult<int>>());
      expect(r.value, 42);
    });

    test('NcSuccess works with void type', () {
      const r = NcSuccess<void>(null);
      expect(r, isA<NcResult<void>>());
    });

    test('NcFailure carries message', () {
      const r = NcFailure<void>('something went wrong');
      expect(r, isA<NcResult<void>>());
      expect(r.message, 'something went wrong');
    });

    test('NcTransient is NcResult', () {
      const r = NcTransient<void>();
      expect(r, isA<NcResult<void>>());
    });
  });

  group('NextcloudService — HTTP behaviour', () {
    HttpServer? server;
    late NextcloudService svc;
    late String url;

    setUp(() {
      svc = NextcloudService();
    });

    tearDown(() async {
      await server?.close(force: true);
      server = null;
    });

    Future<void> startServer(void Function(HttpRequest) handler) async {
      server = await HttpServer.bind('127.0.0.1', 0);
      url = 'http://127.0.0.1:${server!.port}';
      server!.listen(handler);
    }

    // ── verifyCredentials ────────────────────────────────────────────────────

    test('verifyCredentials returns NcSuccess on HTTP 200', () async {
      await startServer((req) {
        req.response
          ..statusCode = 200
          ..close();
      });

      final result = await svc.verifyCredentials(url, 'user', 'pass');
      expect(result, isA<NcSuccess<void>>());
    });

    test('verifyCredentials returns NcFailure with "Invalid credentials" on HTTP 401', () async {
      await startServer((req) {
        req.response
          ..statusCode = 401
          ..close();
      });

      final result = await svc.verifyCredentials(url, 'user', 'wrongpass');
      expect(result, isA<NcFailure<void>>());
      expect((result as NcFailure).message, 'Invalid credentials');
    });

    test('verifyCredentials returns NcFailure on HTTP 500', () async {
      await startServer((req) {
        req.response
          ..statusCode = 500
          ..close();
      });

      final result = await svc.verifyCredentials(url, 'user', 'pass');
      expect(result, isA<NcFailure<void>>());
    });

    test('verifyCredentials returns NcTransient on connection refused', () async {
      // Grab a free port then immediately release it so nothing listens there.
      final tmp = await HttpServer.bind('127.0.0.1', 0);
      final port = tmp.port;
      await tmp.close(force: true);

      final result = await svc.verifyCredentials('http://127.0.0.1:$port', 'u', 'p');
      expect(result, isA<NcTransient<void>>());
    });

    // ── listFiles ────────────────────────────────────────────────────────────

    test('listFiles returns NcSuccess and only .zip hrefs from PROPFIND 207', () async {
      await startServer((req) async {
        req.response
          ..statusCode = 207
          ..headers.contentType = ContentType('text', 'xml', charset: 'utf-8')
          ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/remote.php/dav/files/user/ArtworksManager/</d:href>
  </d:response>
  <d:response>
    <d:href>/remote.php/dav/files/user/ArtworksManager/artworks_20240101_120000.zip</d:href>
  </d:response>
  <d:response>
    <d:href>/remote.php/dav/files/user/ArtworksManager/artworks_20240202_080000.zip</d:href>
  </d:response>
  <d:response>
    <d:href>/remote.php/dav/files/user/ArtworksManager/readme.txt</d:href>
  </d:response>
</d:multistatus>''');
        await req.response.close();
      });

      final result = await svc.listFiles(url, 'user', 'pass', 'ArtworksManager');
      expect(result, isA<NcSuccess<List<String>>>());
      final files = (result as NcSuccess<List<String>>).value;
      expect(files.length, 2);
      expect(files.any((f) => f.endsWith('artworks_20240101_120000.zip')), isTrue);
      expect(files.any((f) => f.endsWith('artworks_20240202_080000.zip')), isTrue);
      expect(files.any((f) => f.endsWith('readme.txt')), isFalse);
      // Directory href (no .zip) must be excluded too
      expect(files.any((f) => f.endsWith('/')), isFalse);
    });

    test('listFiles returns NcSuccess with empty list when no .zip files', () async {
      await startServer((req) async {
        req.response
          ..statusCode = 207
          ..headers.contentType = ContentType('text', 'xml', charset: 'utf-8')
          ..write('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/remote.php/dav/files/user/ArtworksManager/</d:href>
  </d:response>
</d:multistatus>''');
        await req.response.close();
      });

      final result = await svc.listFiles(url, 'user', 'pass', 'ArtworksManager');
      expect(result, isA<NcSuccess<List<String>>>());
      expect((result as NcSuccess<List<String>>).value, isEmpty);
    });

    test('listFiles returns NcFailure on non-207 response', () async {
      await startServer((req) {
        req.response
          ..statusCode = 404
          ..close();
      });

      final result = await svc.listFiles(url, 'user', 'pass', 'ArtworksManager');
      expect(result, isA<NcFailure<List<String>>>());
      expect((result as NcFailure).message, contains('404'));
    });

    // ── uploadBackup ─────────────────────────────────────────────────────────

    test('uploadBackup returns NcSuccess on HTTP 201', () async {
      await startServer((req) {
        req.response
          ..statusCode = 201
          ..close();
      });

      final bytes = Uint8List.fromList([0x50, 0x4B, 0x05, 0x06]); // minimal ZIP end-of-central-dir
      final result = await svc.uploadBackup(url, 'user', 'pass', 'ArtworksManager/backup.zip', bytes);
      expect(result, isA<NcSuccess<void>>());
    });

    test('uploadBackup returns NcSuccess on HTTP 204', () async {
      await startServer((req) {
        // MKCOL → 201, PUT → 204
        req.response
          ..statusCode = req.method == 'PUT' ? 204 : 201
          ..close();
      });

      final result = await svc.uploadBackup(url, 'user', 'pass', 'ArtworksManager/backup.zip', Uint8List(0));
      expect(result, isA<NcSuccess<void>>());
    });

    test('uploadBackup returns NcFailure with storage message on HTTP 507', () async {
      await startServer((req) {
        req.response
          ..statusCode = req.method == 'PUT' ? 507 : 201
          ..close();
      });

      final result = await svc.uploadBackup(url, 'user', 'pass', 'ArtworksManager/backup.zip', Uint8List(0));
      expect(result, isA<NcFailure<void>>());
      expect((result as NcFailure).message, 'Insufficient storage on server');
    });
  });
}
