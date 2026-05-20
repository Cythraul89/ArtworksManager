import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:artworks_manager/core/services/exchange_rate_service.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this._tempPath, this._docsPath);
  final String _tempPath;
  final String _docsPath;

  @override
  Future<String?> getTemporaryPath() async => _tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docsPath;
}

void main() {
  late Directory tempDir;
  late Directory docsDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('artworks_er_temp_');
    docsDir = Directory.systemTemp.createTempSync('artworks_er_docs_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path, docsDir.path);
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
    docsDir.deleteSync(recursive: true);
  });

  setUp(() {
    for (final f in tempDir.listSync()) {
      f.deleteSync(recursive: true);
    }
  });

  group('ExchangeRateService.cacheModifiedTime', () {
    test('returns null when no cache file exists', () async {
      final result = await ExchangeRateService().cacheModifiedTime('EUR');
      expect(result, isNull);
    });

    test('returns null for unknown base even when other caches exist', () async {
      final file = File(p.join(tempDir.path, 'rates_EUR.json'));
      await file.writeAsString(jsonEncode({'USD': 1.1}));

      final result = await ExchangeRateService().cacheModifiedTime('NOK');
      expect(result, isNull);
    });

    test('returns DateTime after cache file is written', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final file = File(p.join(tempDir.path, 'rates_USD.json'));
      await file.writeAsString(jsonEncode({'EUR': 0.9, 'USD': 1.0}));

      final result = await ExchangeRateService().cacheModifiedTime('USD');
      expect(result, isNotNull);
      expect(result!.isAfter(before), isTrue);
    });

    test('is keyed by currency base', () async {
      final eurFile = File(p.join(tempDir.path, 'rates_EUR.json'));
      await eurFile.writeAsString(jsonEncode({'USD': 1.1}));

      final eur = await ExchangeRateService().cacheModifiedTime('EUR');
      final usd = await ExchangeRateService().cacheModifiedTime('USD');
      final nok = await ExchangeRateService().cacheModifiedTime('NOK');

      expect(eur, isNotNull);
      expect(usd, isNull);
      expect(nok, isNull);
    });
  });

  group('ExchangeRateService.fetchRates', () {
    HttpServer? server;

    tearDown(() async {
      await server?.close(force: true);
      server = null;
    });

    Future<ExchangeRateService> startServer(
        void Function(HttpRequest) handler) async {
      server = await HttpServer.bind('127.0.0.1', 0);
      server!.listen(handler);
      return ExchangeRateService(apiBase: 'http://127.0.0.1:${server!.port}');
    }

    test('returns rates map on successful response', () async {
      final svc = await startServer((req) async {
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'base': 'EUR',
            'rates': {'USD': 1.1, 'NOK': 11.5, 'ZAR': 20.0},
          }))
          ..close();
      });

      final rates = await svc.fetchRates('EUR');
      expect(rates, isNotNull);
      expect(rates!['EUR'], 1.0);
      expect(rates['USD'], closeTo(1.1, 0.001));
      expect(rates['NOK'], closeTo(11.5, 0.001));
    });

    test('writes cache file after successful fetch', () async {
      final svc = await startServer((req) async {
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'base': 'USD',
            'rates': {'EUR': 0.9},
          }))
          ..close();
      });

      await svc.fetchRates('USD');
      final cacheFile = File(p.join(tempDir.path, 'rates_USD.json'));
      expect(cacheFile.existsSync(), isTrue);
      final cached = jsonDecode(cacheFile.readAsStringSync()) as Map;
      expect(cached['USD'], 1.0);
      expect(cached['EUR'], closeTo(0.9, 0.001));
    });

    test('falls back to disk cache on network failure', () async {
      // Write a fresh cache file.
      final cacheFile = File(p.join(tempDir.path, 'rates_EUR.json'));
      await cacheFile.writeAsString(jsonEncode({'EUR': 1.0, 'USD': 1.05}));

      // Bind a port then immediately close it so connections are refused.
      final refusedServer = await HttpServer.bind('127.0.0.1', 0);
      final port = refusedServer.port;
      await refusedServer.close(force: true);

      final svc = ExchangeRateService(apiBase: 'http://127.0.0.1:$port');
      final rates = await svc.fetchRates('EUR');
      expect(rates, isNotNull);
      expect(rates!['USD'], closeTo(1.05, 0.001));
    });

    test('returns null when network fails and no cache exists', () async {
      final refusedServer = await HttpServer.bind('127.0.0.1', 0);
      final port = refusedServer.port;
      await refusedServer.close(force: true);

      final svc = ExchangeRateService(apiBase: 'http://127.0.0.1:$port');
      final rates = await svc.fetchRates('ZAR');
      expect(rates, isNull);
    });

    test('falls back to cache on non-200 status', () async {
      final cacheFile = File(p.join(tempDir.path, 'rates_NOK.json'));
      await cacheFile.writeAsString(jsonEncode({'NOK': 1.0, 'EUR': 0.087}));

      final svc = await startServer((req) async {
        req.response
          ..statusCode = 503
          ..close();
      });

      final rates = await svc.fetchRates('NOK');
      expect(rates, isNotNull);
      expect(rates!['EUR'], closeTo(0.087, 0.001));
    });
  });
}
