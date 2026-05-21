import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/currency.dart';
import '../dashboard/dashboard_providers.dart';
import 'settings_providers.dart';

class ExchangeRatesScreen extends ConsumerWidget {
  const ExchangeRatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(settingsProvider).valueOrNull?.currency ?? 'EUR';
    final ratesAsync = ref.watch(exchangeRatesProvider(base));
    final cacheAsync = ref.watch(ratesCacheTimeProvider(base));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange rates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: ratesAsync.isLoading
                ? null
                : () {
                    ref.invalidate(exchangeRatesProvider(base));
                    ref.invalidate(ratesCacheTimeProvider(base));
                  },
          ),
        ],
      ),
      body: ratesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rates) {
          if (rates == null || rates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('No exchange rate data available'),
                  const SizedBox(height: 4),
                  Text('Check your internet connection',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ],
              ),
            );
          }

          final timestamp = cacheAsync.valueOrNull;
          final timeLabel = timestamp != null
              ? 'Live · ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)}'
              : null;

          final entries = Currency.values
              .where((c) => c.code != base && rates.containsKey(c.code))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Rates relative to $base',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) {
                    final c = entries[i];
                    final rate = rates[c.code]!;
                    final reciprocal = rate > 0 ? 1.0 / rate : 0.0;
                    return ListTile(
                      title: Text('1 ${c.code} = ${_fmt(reciprocal)} $base'),
                      subtitle: timeLabel != null
                          ? Text(timeLabel,
                              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(ctx).colorScheme.outline,
                                  ))
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(double v) {
    if (v == 0) return '—';
    if (v >= 100) return v.toStringAsFixed(2);
    return v.toStringAsFixed(4);
  }
}
