import 'package:dio/dio.dart';

/// Fetches live exchange rates from the Frankfurter API (ECB data, free, no key).
class ExchangeRateService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Returns a map of currency code → units per 1 [base] currency unit.
  /// Returns null on network failure (caller should show cached/offline fallback).
  static Future<Map<String, double>?> fetchRates(String base) async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        'https://api.frankfurter.app/latest',
        queryParameters: {'base': base},
      );
      if (resp.statusCode != 200 || resp.data == null) return null;
      final rates = resp.data!['rates'] as Map<String, dynamic>?;
      if (rates == null) return null;
      final result = <String, double>{base: 1.0};
      rates.forEach((k, v) {
        if (v is num) result[k] = v.toDouble();
      });
      return result;
    } catch (_) {
      return null;
    }
  }
}
