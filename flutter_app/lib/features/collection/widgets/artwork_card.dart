import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';

class ArtworkCard extends StatelessWidget {
  const ArtworkCard({
    super.key,
    required this.artwork,
    required this.onTap,
    this.isGrid = true,
  });

  final Artwork artwork;
  final VoidCallback onTap;
  final bool isGrid;

  @override
  Widget build(BuildContext context) =>
      isGrid ? _GridCard(artwork: artwork, onTap: onTap) : _ListTile(artwork: artwork, onTap: onTap);
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.artwork, required this.onTap});

  final Artwork artwork;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Photo(path: artwork.photoPath, fit: BoxFit.cover, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (artwork.artist.isNotEmpty)
                    Text(
                      artwork.artist,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (artwork.year != null)
                    Text(
                      artwork.year.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  if (artwork.condition.isNotEmpty)
                    _ConditionLabel(condition: artwork.condition),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.artwork, required this.onTap});

  final Artwork artwork;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _Photo(path: artwork.photoPath, fit: BoxFit.cover),
        ),
      ),
      title: Text(artwork.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: (artwork.artist.isNotEmpty || artwork.condition.isNotEmpty)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (artwork.artist.isNotEmpty)
                  Text(artwork.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (artwork.condition.isNotEmpty)
                  _ConditionLabel(condition: artwork.condition),
              ],
            )
          : null,
      trailing: artwork.year != null
          ? Text(
              artwork.year.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.path, required this.fit, this.width});

  final String path;
  final BoxFit fit;
  final double? width;

  @override
  Widget build(BuildContext context) {
    if (path.isNotEmpty) {
      return Image.file(
        File(path),
        fit: fit,
        width: width,
        errorBuilder: (_, __, ___) => _Placeholder(),
      );
    }
    return _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: 36,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _ConditionLabel extends StatelessWidget {
  const _ConditionLabel({required this.condition});
  final String condition;

  Color _color() => switch (condition) {
        'Excellent' => Colors.green.shade600,
        'Good' => Colors.blue.shade600,
        'Fair' => Colors.orange.shade700,
        'Poor' => Colors.red.shade700,
        _ => Colors.grey.shade600,
      };

  @override
  Widget build(BuildContext context) {
    return Text(
      condition,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _color(),
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
