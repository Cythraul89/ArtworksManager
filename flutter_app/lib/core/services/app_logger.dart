import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Simple append-only file logger.
/// All writes are fire-and-forget (errors are silently ignored so logging
/// never crashes the app). The file is trimmed to [_maxLines] after each write.
class AppLogger {
  static const _maxLines = 2000;
  static const _fileName = 'app_logs.txt';

  static Future<File> _logFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<void> _append(String level, String message) async {
    try {
      final file = await _logFile();
      final ts = DateTime.now().toIso8601String();
      await file.writeAsString('[$ts] [$level] $message\n',
          mode: FileMode.append, flush: true);
      await _trim(file);
    } catch (_) {}
  }

  static Future<void> _trim(File file) async {
    try {
      final lines = await file.readAsLines();
      if (lines.length > _maxLines) {
        await file.writeAsString(
            '${lines.skip(lines.length - _maxLines).join('\n')}\n');
      }
    } catch (_) {}
  }

  static Future<void> info(String message) => _append('INFO ', message);
  static Future<void> warn(String message) => _append('WARN ', message);

  static Future<void> error(String message, [Object? err, StackTrace? st]) {
    final parts = <String>[message];
    if (err != null) parts.add(err.toString());
    if (st != null) {
      parts.add(st.toString().split('\n').take(6).join('\n    '));
    }
    return _append('ERROR', parts.join('\n  '));
  }

  /// Returns recent entries newest-first, up to [lines] entries.
  static Future<List<String>> readRecent({int lines = 300}) async {
    try {
      final file = await _logFile();
      if (!file.existsSync()) return [];
      final all = await file.readAsLines();
      return all.reversed.take(lines).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns the log file, or null if it doesn't exist yet.
  static Future<File?> getFile() async {
    try {
      final file = await _logFile();
      return file.existsSync() ? file : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final file = await _logFile();
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }
}
