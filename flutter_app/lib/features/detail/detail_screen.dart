import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/currency.dart';
import '../../core/widgets/photo_strip.dart';
import 'detail_providers.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.artworkId});
  final int artworkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artworkAsync = ref.watch(artworkByIdProvider(artworkId));

    return artworkAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (artwork) {
        if (artwork == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Artwork not found')),
          );
        }
        return _DetailBody(artwork: artwork, ref: ref);
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.artwork, required this.ref});

  final Artwork artwork;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(photosByArtworkProvider(artwork.id));
    final additionalPhotos =
        photosAsync.valueOrNull?.map((p) => p.photoPath).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(artwork.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.go('/collection/edit/${artwork.id}'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main photo
            if (artwork.photoPath.isNotEmpty)
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(
                  File(artwork.photoPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image_outlined, size: 64)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + artist/year
                  Text(artwork.title,
                      style: Theme.of(context).textTheme.headlineSmall),
                  if (artwork.artist.isNotEmpty || artwork.year != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (artwork.artist.isNotEmpty) artwork.artist,
                        if (artwork.year != null) artwork.year.toString(),
                      ].join('  ·  '),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  _row(context, 'Type', artwork.type),
                  _row(context, 'Medium', artwork.medium),
                  _row(context, 'Location', artwork.location),
                  _row(context, 'Dimensions', _dims()),
                  _row(context, 'Acquired', _acquired()),
                  _row(context, 'Description', artwork.description),
                ],
              ),
            ),

            // Certificate
            if (artwork.certificatePath.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('View Certificate'),
                  onPressed: () => _openCertificate(context, artwork.certificatePath),
                ),
              ),
            ],

            // Additional photos
            if (additionalPhotos.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Text('Photos',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              PhotoStrip(paths: additionalPhotos),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _dims() {
    final parts = <String>[];
    if (artwork.heightCm != null) parts.add(_fmt(artwork.heightCm!));
    if (artwork.widthCm != null) parts.add(_fmt(artwork.widthCm!));
    if (artwork.depthCm != null) parts.add(_fmt(artwork.depthCm!));
    if (parts.isEmpty) return '';
    return '${parts.join(' × ')} cm';
  }

  String _acquired() {
    final parts = <String>[];
    if (artwork.acquisitionDate != null) {
      parts.add(DateFormat('dd MMM yyyy')
          .format(DateTime.fromMillisecondsSinceEpoch(artwork.acquisitionDate!)));
    }
    if (artwork.purchasePrice != null) {
      final symbol = Currency.fromCode(artwork.currency).symbol;
      parts.add('$symbol${artwork.purchasePrice!.toStringAsFixed(2)}');
    }
    return parts.join('  ·  ');
  }

  String _fmt(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  void _openCertificate(BuildContext context, String path) async {
    if (!File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate file not found')),
      );
      return;
    }
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open PDF: ${result.message}')),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete artwork'),
        content: Text('Delete "${artwork.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(databaseProvider)
                  .artworksDao
                  .deleteArtwork(artwork.id);
              if (context.mounted) context.go('/collection');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

