import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/services/exchange_rate_service.dart';
import '../settings/settings_providers.dart';

final artworkCountProvider = StreamProvider<int>(
    (ref) => ref.watch(databaseProvider).artworksDao.watchCount());

final recentArtworksProvider = StreamProvider<List<Artwork>>(
    (ref) => ref.watch(databaseProvider).artworksDao.watchRecent());

final mediumCountsProvider =
    StreamProvider<List<({String medium, int count})>>(
        (ref) => ref.watch(databaseProvider).artworksDao.watchMediumCounts());

final topArtistsProvider =
    StreamProvider<List<({String artist, int count})>>(
        (ref) => ref.watch(databaseProvider).artworksDao.watchTopArtists());

final priceTotalsProvider =
    StreamProvider<List<({String currency, double total})>>(
        (ref) => ref.watch(databaseProvider).artworksDao.watchPriceTotals());

/// Live ECB exchange rates via Frankfurter API. Cached per base currency for the app session.
final exchangeRatesProvider =
    FutureProvider.family<Map<String, double>?, String>(
        (ref, base) => ExchangeRateService.fetchRates(base));

/// Unified portfolio value converted to the user's default currency.
///
/// - Returns `AsyncLoading` while DB totals or (when needed) exchange rates load.
/// - Returns `AsyncData(null)` when rates are unavailable — callers fall back to
///   per-currency display.
/// - Returns `AsyncData(0.0)` when no artwork has a price.
final portfolioValueProvider =
    Provider<({AsyncValue<double?> value, String currency})>((ref) {
  final currency =
      ref.watch(settingsProvider).valueOrNull?.currency ?? 'EUR';
  final totalsAsync = ref.watch(priceTotalsProvider);
  final ratesAsync = ref.watch(exchangeRatesProvider(currency));

  final value = totalsAsync.when(
    loading: () => const AsyncValue<double?>.loading(),
    error: (e, s) => AsyncValue<double?>.error(e, s),
    data: (totals) {
      if (totals.isEmpty) return const AsyncValue<double?>.data(null);

      // All prices already in the default currency — no network call needed.
      if (totals.every((t) => t.currency == currency)) {
        return AsyncValue<double?>.data(
            totals.fold<double>(0.0, (s, t) => s + t.total));
      }

      // Multi-currency: convert everything to the default currency.
      // Frankfurter rates[code] = units of `code` per 1 unit of `base`,
      // so amount_in_code / rate = amount_in_base.
      return ratesAsync.when(
        loading: () => const AsyncValue<double?>.loading(),
        error: (_, __) => const AsyncValue<double?>.data(null),
        data: (rates) {
          if (rates == null) return const AsyncValue<double?>.data(null);
          var sum = 0.0;
          for (final t in totals) {
            final rate = rates[t.currency];
            if (rate != null && rate > 0) sum += t.total / rate;
          }
          return AsyncValue<double?>.data(sum);
        },
      );
    },
  );

  return (value: value, currency: currency);
});
