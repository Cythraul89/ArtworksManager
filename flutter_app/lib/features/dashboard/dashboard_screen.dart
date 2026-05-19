import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/currency.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(artworkCountProvider).valueOrNull;

    if (count == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (count == 0) return _buildEmpty(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatsSection(count: count),
            const SizedBox(height: 20),
            const _MediumSection(),
            const SizedBox(height: 20),
            const _ArtistSection(),
            const SizedBox(height: 20),
            const _RecentSection(),
          ],
        ),
      ),
    );
  }

  Scaffold _buildEmpty(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette_outlined,
                size: 80, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Your collection is empty',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Start by adding your first artwork',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add artwork'),
              onPressed: () => context.go('/collection/add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatsSection extends ConsumerWidget {
  const _StatsSection({required this.count});
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(priceTotalsProvider).valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(context,
            icon: Icons.photo_library_outlined,
            label: 'Total artworks',
            value: '$count'),
        ...totals.map((t) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _card(context,
                  icon: Icons.payments_outlined,
                  label: 'Total value · ${t.currency}',
                  value:
                      '${Currency.fromCode(t.currency).symbol}${NumberFormat('#,##0.00').format(t.total)}'),
            )),
      ],
    );
  }

  Widget _card(BuildContext context,
      {required IconData icon,
      required String label,
      required String value}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        )),
                Text(value,
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Medium breakdown ──────────────────────────────────────────────────────────

class _MediumSection extends ConsumerWidget {
  const _MediumSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediums = ref.watch(mediumCountsProvider).valueOrNull ?? [];
    if (mediums.isEmpty) return const SizedBox.shrink();

    final maxCount =
        mediums.map((m) => m.count).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Medium', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...mediums.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(m.medium,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: m.count / maxCount,
                        minHeight: 12,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${m.count}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Top artists ───────────────────────────────────────────────────────────────

class _ArtistSection extends ConsumerWidget {
  const _ArtistSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(topArtistsProvider).valueOrNull ?? [];
    if (artists.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Artists', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        ...artists.asMap().entries.map((e) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '${e.key + 1}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer),
                ),
              ),
              title: Text(e.value.artist),
              trailing: Text(
                '${e.value.count}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            )),
      ],
    );
  }
}

// ── Recent artworks ───────────────────────────────────────────────────────────

class _RecentSection extends ConsumerWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworks = ref.watch(recentArtworksProvider).valueOrNull ?? [];
    if (artworks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent', style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              onPressed: () => context.go('/collection'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: artworks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final a = artworks[i];
              return GestureDetector(
                onTap: () => context.go('/collection/artwork/${a.id}'),
                child: SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: a.photoPath.isNotEmpty
                              ? Image.file(File(a.photoPath),
                                  fit: BoxFit.cover,
                                  width: 120,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholder(context))
                              : _placeholder(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a.title,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.image_outlined,
              color: Theme.of(context).colorScheme.outline),
        ),
      );
}
