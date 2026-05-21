import 'dart:io';
import 'package:flutter/material.dart';

/// Horizontal scrolling strip of photo thumbnails.
///
/// Pass [onDelete] to show a delete badge on each thumbnail (edit mode).
/// Pass [onAdd] to show a trailing "+" button.
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({
    super.key,
    required this.paths,
    this.onDelete,
    this.onAdd,
    this.onTap,
    this.size = 80,
  });

  final List<String> paths;
  final void Function(int index)? onDelete;
  final VoidCallback? onAdd;
  final void Function(int index)? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty && onAdd == null) return const SizedBox.shrink();

    return SizedBox(
      height: size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: paths.length + (onAdd != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == paths.length) return _AddButton(size: size, onTap: onAdd!);
          return _Thumbnail(
            path: paths[i],
            size: size,
            onDelete: onDelete != null ? () => onDelete!(i) : null,
            onTap: onTap != null ? () => onTap!(i) : null,
          );
        },
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.path,
    required this.size,
    this.onDelete,
    this.onTap,
  });

  final String path;
  final double size;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context),
            ),
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.broken_image_outlined),
      );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.add_photo_alternate_outlined,
            color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
