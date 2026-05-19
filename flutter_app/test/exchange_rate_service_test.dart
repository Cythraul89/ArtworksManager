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

  group('ExchangeRateService', () {
    test('cacheModifiedTime returns null when no cache file exists', () async {
      final result = await ExchangeRateService.cacheModifiedTime('EUR');
      expect(result, isNull);
    });

    test('cacheModifiedTime returns null for unknown base even when other caches exist', () async {
      final file = File(p.join(tempDir.path, 'rates_EUR.json'));
      await file.writeAsString(jsonEncode({'USD': 1.1}));

      final result = await ExchangeRateService.cacheModifiedTime('NOK');
      expect(result, isNull);
    });

    test('cacheModifiedTime returns DateTime after cache file is written', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final file = File(p.join(tempDir.path, 'rates_USD.json'));
      await file.writeAsString(jsonEncode({'EUR': 0.9, 'USD': 1.0}));

      final result = await ExchangeRateService.cacheModifiedTime('USD');
      expect(result, isNotNull);
      expect(result!.isAfter(before), isTrue);
    });

    test('cacheModifiedTime is keyed by currency base', () async {
      final eurFile = File(p.join(tempDir.path, 'rates_EUR.json'));
      await eurFile.writeAsString(jsonEncode({'USD': 1.1}));

      final eur = await ExchangeRateService.cacheModifiedTime('EUR');
      final usd = await ExchangeRateService.cacheModifiedTime('USD');
      final nok = await ExchangeRateService.cacheModifiedTime('NOK');

      expect(eur, isNotNull);
      expect(usd, isNull);
      expect(nok, isNull);
    });
  });
}
