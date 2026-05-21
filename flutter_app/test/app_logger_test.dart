import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:artworks_manager/core/services/app_logger.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this._docsPath);
  final String _docsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => _docsPath;
}

void main() {
  late Directory docsDir;

  setUpAll(() {
    docsDir = Directory.systemTemp.createTempSync('artworks_logger_docs_');
    PathProviderPlatform.instance = _FakePathProvider(docsDir.path);
  });

  tearDownAll(() {
    docsDir.deleteSync(recursive: true);
  });

  setUp(() async {
    await AppLogger.clear();
  });

  group('AppLogger', () {
    test('getFile returns null before any writes', () async {
      final f = await AppLogger.getFile();
      expect(f, isNull);
    });

    test('info writes a line containing the message and INFO level', () async {
      await AppLogger.info('hello world');
      final f = await AppLogger.getFile();
      expect(f, isNotNull);
      final content = await f!.readAsString();
      expect(content, contains('[INFO ]'));
      expect(content, contains('hello world'));
    });

    test('warn writes a line containing the message and WARN level', () async {
      await AppLogger.warn('something off');
      final lines = await AppLogger.readRecent();
      expect(lines, isNotEmpty);
      expect(lines.first, contains('[WARN ]'));
      expect(lines.first, contains('something off'));
    });

    test('error writes message plus error object', () async {
      final err = Exception('boom');
      await AppLogger.error('oops', err);
      final lines = await AppLogger.readRecent();
      expect(lines, isNotEmpty);
      // Multi-line error entries split across readAsLines(); join to check both.
      final joined = lines.join('\n');
      expect(joined, contains('[ERROR]'));
      expect(joined, contains('boom'));
    });

    test('readRecent returns entries newest-first', () async {
      await AppLogger.info('first');
      await AppLogger.info('second');
      await AppLogger.info('third');

      final lines = await AppLogger.readRecent();
      expect(lines.first, contains('third'));
      expect(lines.last, contains('first'));
    });

    test('readRecent respects lines limit', () async {
      for (var i = 0; i < 10; i++) {
        await AppLogger.info('line $i');
      }
      final lines = await AppLogger.readRecent(lines: 3);
      expect(lines.length, 3);
      expect(lines.first, contains('line 9'));
    });

    test('readRecent returns empty list when file does not exist', () async {
      final lines = await AppLogger.readRecent();
      expect(lines, isEmpty);
    });

    test('getFile returns non-null after a write', () async {
      await AppLogger.warn('any');
      final f = await AppLogger.getFile();
      expect(f, isNotNull);
      expect(f!.existsSync(), isTrue);
    });

    test('clear deletes the log file', () async {
      await AppLogger.info('to be cleared');
      expect(await AppLogger.getFile(), isNotNull);

      await AppLogger.clear();
      expect(await AppLogger.getFile(), isNull);

      final logFile = File(p.join(docsDir.path, 'app_logs.txt'));
      expect(logFile.existsSync(), isFalse);
    });

    test('clear is a no-op when file does not exist', () async {
      await AppLogger.clear();
      expect(await AppLogger.getFile(), isNull);
    });
  });
}
