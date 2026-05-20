import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/currency.dart';
import '../../core/services/sync_worker.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 600
            ? _buildWide(context, additionalPhotos)
            : _buildNarrow(context, additionalPhotos),
      ),
    );
  }

  List<String> _allPhotos(List<String> additional) => [
        if (artwork.photoPath.isNotEmpty) artwork.photoPath,
        ...additional,
      ];

  void _showFullscreen(BuildContext context, List<String> paths, int index) {
    if (paths.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullscreenViewer(paths: paths, initialIndex: index),
    );
  }

  Widget _buildNarrow(BuildContext context, List<String> additionalPhotos) {
    final allPhotos = _allPhotos(additionalPhotos);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (artwork.photoPath.isNotEmpty)
            GestureDetector(
              onTap: () => _showFullscreen(context, allPhotos, 0),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(
                  File(artwork.photoPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image_outlined, size: 64)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _infoWidgets(context),
            ),
          ),
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
          if (additionalPhotos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text('Photos', style: Theme.of(context).textTheme.labelLarge),
            ),
            PhotoStrip(
              paths: additionalPhotos,
              onTap: (i) => _showFullscreen(
                context,
                allPhotos,
                artwork.photoPath.isNotEmpty ? i + 1 : i,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context, List<String> additionalPhotos) {
    final allPhotos = _allPhotos(additionalPhotos);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: artwork.photoPath.isNotEmpty
                ? () => _showFullscreen(context, allPhotos, 0)
                : null,
            child: artwork.photoPath.isNotEmpty
                ? Image.file(
                    File(artwork.photoPath),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 64, color: Theme.of(context).colorScheme.outline),
                    ),
                  )
                : Center(
                    child: Icon(Icons.image_outlined,
                        size: 64, color: Theme.of(context).colorScheme.outline),
                  ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._infoWidgets(context),
                if (artwork.certificatePath.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('View Certificate'),
                    onPressed: () => _openCertificate(context, artwork.certificatePath),
                  ),
                ],
                if (additionalPhotos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Photos', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  PhotoStrip(
                    paths: additionalPhotos,
                    onTap: (i) => _showFullscreen(
                      context,
                      allPhotos,
                      artwork.photoPath.isNotEmpty ? i + 1 : i,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _infoWidgets(BuildContext context) {
    return [
      Text(artwork.title, style: Theme.of(context).textTheme.headlineSmall),
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
      _row(context, 'Condition', artwork.condition),
      _row(context, 'Location', artwork.location),
      _row(context, 'Dimensions', _dims()),
      _row(context, 'Acquired', _acquired()),
      _row(context, 'Description', artwork.description),
      _row(context, 'Provenance', artwork.provenance),
    ];
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

  String _fmt(double v) {
    if (!v.isFinite) return '?';
    final t = v.truncateToDouble();
    return v == t ? t.toInt().toString() : v.toString();
  }

  void _openCertificate(BuildContext context, String path) async {
    if (!File(path).existsSync()) {
      if (!context.mounted) return;
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
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete artwork'),
        content: Text('Delete "${artwork.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogCtx).colorScheme.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref
                  .read(databaseProvider)
                  .artworksDao
                  .deleteArtwork(artwork.id);
              unawaited(triggerAutoBackup(ref.read(databaseProvider)));
              if (context.mounted) context.go('/collection');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Fullscreen photo viewer ───────────────────────────────────────────────────

class _FullscreenViewer extends StatefulWidget {
  const _FullscreenViewer({required this.paths, required this.initialIndex});
  final List<String> paths;
  final int initialIndex;

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black87,
      child: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.paths.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(widget.paths[i]),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 64),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (widget.paths.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.paths.length, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

