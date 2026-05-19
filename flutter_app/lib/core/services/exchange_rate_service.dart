import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_logger.dart';

/// Fetches live exchange rates from the Frankfurter API (ECB data, free, no key).
/// Rates are cached to disk for up to 24 hours; stale cache is returned on
/// network failure so the dashboard stays usable offline.
class ExchangeRateService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Future<File> _cacheFile(String base) async {
    final dir = await getTemporaryDirectory();
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
    } catch (e) {
      await AppLogger.warn('ExchangeRateService: failed to read cache for $base: $e');
      return null;
    }
  }

  static Future<void> _writeCache(
      String base, Map<String, double> rates) async {
    try {
      final file = await _cacheFile(base);
      await file.writeAsString(jsonEncode(rates));
    } catch (e) {
      await AppLogger.warn('ExchangeRateService: failed to write cache for $base: $e');
    }
  }

  /// Returns the last-modified time of the on-disk cache for [base], or null
  /// if no cache file exists. Used by the dashboard to show a stale-rates hint.
  static Future<DateTime?> cacheModifiedTime(String base) async {
    try {
      final file = await _cacheFile(base);
      return file.existsSync() ? file.lastModifiedSync() : null;
    } catch (_) {
      return null;
    }
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
        await AppLogger.warn(
            'ExchangeRateService: unexpected status ${resp.statusCode} for $base, using cache');
        return await _readCache(base);
      }
      final rates = resp.data!['rates'] as Map<String, dynamic>?;
      if (rates == null) {
        await AppLogger.warn('ExchangeRateService: missing rates field for $base, using cache');
        return await _readCache(base);
      }
      final result = <String, double>{base: 1.0};
      rates.forEach((k, v) {
        if (v is num) result[k] = v.toDouble();
      });
      await _writeCache(base, result);
      return result;
    } catch (e, st) {
      await AppLogger.error('ExchangeRateService: fetch failed for $base, falling back to cache', e, st);
      return await _readCache(base);
    }
  }
}
