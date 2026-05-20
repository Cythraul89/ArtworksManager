import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/backup_service.dart';

class LocalBackupScreen extends ConsumerStatefulWidget {
  const LocalBackupScreen({super.key});

  @override
  ConsumerState<LocalBackupScreen> createState() => _LocalBackupScreenState();
}

class _LocalBackupScreenState extends ConsumerState<LocalBackupScreen> {
  bool _exporting = false;
  bool _restoring = false;
  String? _message;
  bool _messageIsError = false;

  void _setMsg(String msg, {required bool isError}) {
    if (mounted) setState(() { _message = msg; _messageIsError = isError; });
  }

  @override
  Widget build(BuildContext context) {
    final busy = _exporting || _restoring;
    return Scaffold(
      appBar: AppBar(title: const Text('Local backup')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          FilledButton.icon(
            icon: _exporting
                ? const _Spinner(bright: true)
                : const Icon(Icons.download_outlined),
            label: const Text('Save backup'),
            onPressed: busy ? null : _exportBackup,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: _restoring
                ? const _Spinner()
                : const Icon(Icons.folder_open_outlined),
            label: const Text('Restore from file'),
            onPressed: busy ? null : _restoreFromFile,
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            _Banner(message: _message!, isError: _messageIsError),
          ],
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    setState(() { _exporting = true; _message = null; });
    try {
      final db = ref.read(databaseProvider);
      final artworks = await db.artworksDao.getAll();
      if (artworks.isEmpty) {
        _setMsg('No artworks to backup', isError: false);
        return;
      }
      final allPhotos = await db.photosDao.getAll();
      final photosByArtwork = <int, List<ArtworkPhoto>>{};
      for (final ph in allPhotos) {
        photosByArtwork.putIfAbsent(ph.artworkId, () => []).add(ph);
      }
      final bytes = await BackupService().exportToZip(artworks, photosByArtwork);
      final filename = BackupService.generateFilename();
      await AppLogger.info('LocalBackupScreen: exporting $filename');
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup',
        fileName: filename,
        bytes: bytes,
      );
      if (!mounted) return;
      if (path != null) {
        _setMsg('Backup saved', isError: false);
      }
    } catch (e, st) {
      await AppLogger.error('LocalBackupScreen: export failed', e, st);
      if (mounted) _setMsg('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _restoreFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null || !mounted) return;
    final confirmed = await _confirmReplace();
    if (confirmed != true || !mounted) return;
    setState(() { _restoring = true; _message = null; });
    try {
      final bytes = await File(path).readAsBytes();
      final data = await BackupService().importFromBytes(bytes);
      await ref
          .read(databaseProvider)
          .artworksDao
          .replaceAll(data.artworks, data.photos);
      if (mounted) {
        setState(() => _restoring = false);
        _setMsg(
            'Restore complete – ${data.artworks.length} artworks imported',
            isError: false);
      }
    } catch (e, st) {
      await AppLogger.error('LocalBackupScreen: restore failed', e, st);
      if (mounted) {
        setState(() => _restoring = false);
        _setMsg('Restore failed: $e', isError: true);
      }
    }
  }

  Future<bool?> _confirmReplace() => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Replace all artworks?'),
          content: const Text(
              'All current artworks will be permanently deleted and replaced by the backup.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.bright = false});
  final bool bright;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: bright ? Theme.of(context).colorScheme.onPrimary : null,
        ),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer;
    final textColor = isError
        ? Theme.of(context).colorScheme.onErrorContainer
        : Theme.of(context).colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: textColor,
              size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: textColor))),
        ],
      ),
    );
  }
}
