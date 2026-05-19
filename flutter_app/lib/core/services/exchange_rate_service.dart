import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Fetches live exchange rates from the Frankfurter API (ECB data, free, no key).
/// Rates are cached to disk for up to 24 hours; stale cache is returned on
/// network failure so the dashboard stays usable offline.
class ExchangeRateService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Future<File> _cacheFile(String base) async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'rates_$base.json'));
  }

  static Future<Map<String, double>?> _readCache(String base) async {
    try {
      final file = await _cacheFile(base);
      if (!file.existsSync()) { return null; }
      if (DateTime.now().difference(file.lastModifiedSync()) >
          const Duration(hours: 24)) { return null; }
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(
      String base, Map<String, double> rates) async {
    try {
      final file = await _cacheFile(base);
      await file.writeAsString(jsonEncode(rates));
    } catch (_) {}
  }

  /// Returns a map of currency code → units per 1 [base] currency unit.
  /// Falls back to a disk-cached result (up to 24 h old) on network failure.
  static Future<Map<String, double>?> fetchRates(String base) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        'https://api.frankfurter.app/latest',
        queryParameters: {'base': base},
      );
      if (resp.statusCode != 200 || resp.data == null) {
        return await _readCache(base);
      }
      final rates = resp.data!['rates'] as Map<String, dynamic>?;
      if (rates == null) return await _readCache(base);
      final result = <String, double>{base: 1.0};
      rates.forEach((k, v) {
        if (v is num) result[k] = v.toDouble();
      });
      await _writeCache(base, result);
      return result;
    } catch (_) {
      return await _readCache(base);
    }
  }
}
