import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/nextcloud_service.dart';
import '../../core/services/secure_credentials_service.dart';
import '../settings/settings_providers.dart';

enum _Op { idle, testing, backing, restoring }

class NextcloudScreen extends ConsumerStatefulWidget {
  const NextcloudScreen({super.key});

  @override
  ConsumerState<NextcloudScreen> createState() => _NextcloudScreenState();
}

class _NextcloudScreenState extends ConsumerState<NextcloudScreen> {
  final _urlCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pathCtrl = TextEditingController();
  final _fingerprintCtrl = TextEditingController();
  int _keepExports = 5;
  bool _obscurePassword = true;
  bool _loaded = false;
  _Op _op = _Op.idle;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    SecureCredentialsService.readPassword().then((pw) {
      if (mounted) setState(() => _passwordCtrl.text = pw);
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _pathCtrl.dispose();
    _fingerprintCtrl.dispose();
    super.dispose();
  }

  void _prefill(Setting s) {
    _loaded = true;
    _urlCtrl.text = s.nextcloudUrl;
    _usernameCtrl.text = s.nextcloudUsername;
    _pathCtrl.text = s.nextcloudPath;
    _fingerprintCtrl.text = s.nextcloudCertFingerprint;
    setState(() => _keepExports = s.nextcloudKeepExports);
  }

  void _setMsg(String msg, {required bool isError}) {
    if (mounted) setState(() { _message = msg; _messageIsError = isError; });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider).whenData((s) {
      if (!_loaded) _prefill(s);
    });

    final busy = _op != _Op.idle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nextcloud'),
        actions: [
          TextButton(
            onPressed: busy ? null : () async {
              await _save();
              _setMsg('Settings saved', isError: false);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _field(_urlCtrl, 'Server URL', hint: 'https://cloud.example.com'),
          _field(_usernameCtrl, 'Username'),
          _pwField(),
          _field(_pathCtrl, 'Remote path', hint: 'ArtworksManager'),
          _field(_fingerprintCtrl, 'Certificate fingerprint (SHA-256, optional)'),
          const SizedBox(height: 4),
          _keepRow(),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: _op == _Op.testing
                ? const _Spinner()
                : const Icon(Icons.wifi_tethering),
            label: const Text('Test connection'),
            onPressed: busy ? null : _testConnection,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: _op == _Op.backing
                ? const _Spinner(bright: true)
                : const Icon(Icons.cloud_upload_outlined),
            label: const Text('Backup now'),
            onPressed: busy ? null : _backupNow,
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: _op == _Op.restoring
                    ? const _Spinner()
                    : const Icon(Icons.cloud_download_outlined),
                label: const Text('From cloud'),
                onPressed: busy ? null : _restoreFromCloud,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('From file'),
                onPressed: busy ? null : _restoreFromFile,
              ),
            ),
          ]),
          if (_message != null) ...[
            const SizedBox(height: 16),
            _Banner(message: _message!, isError: _messageIsError),
          ],
        ],
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────

  Widget _field(TextEditingController ctrl, String label, {String? hint}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Widget _pwField() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility
                  : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      );

  Widget _keepRow() => Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keep last N backups'),
                Text('Older files are deleted automatically',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed:
                _keepExports > 1 ? () => setState(() => _keepExports--) : null,
          ),
          Text('$_keepExports',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _keepExports++),
          ),
        ],
      );

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final path = _pathCtrl.text.trim().isEmpty
        ? 'ArtworksManager'
        : _pathCtrl.text.trim();
    await SecureCredentialsService.writePassword(_passwordCtrl.text);
    await ref.read(databaseProvider).settingsDao.save(SettingsCompanion(
          nextcloudUrl: Value(_urlCtrl.text.trim()),
          nextcloudUsername: Value(_usernameCtrl.text.trim()),
          nextcloudPassword: const Value(''),
          nextcloudPath: Value(path),
          nextcloudCertFingerprint: Value(_fingerprintCtrl.text.trim()),
          nextcloudKeepExports: Value(_keepExports),
        ));
  }

  String? _pin(Setting s) =>
      s.nextcloudCertFingerprint.isNotEmpty ? s.nextcloudCertFingerprint : null;

  Future<void> _testConnection() async {
    await _save();
    final s = await ref.read(databaseProvider).settingsDao.get();
    if (s.nextcloudUrl.isEmpty) {
      _setMsg('Enter server URL first', isError: true);
      return;
    }
    setState(() { _op = _Op.testing; _message = null; });
    final result = await NextcloudService().verifyCredentials(
      s.nextcloudUrl, s.nextcloudUsername, _passwordCtrl.text,
      pinnedFingerprint: _pin(s),
    );
    if (!mounted) return;
    setState(() => _op = _Op.idle);
    switch (result) {
      case NcSuccess():
        _setMsg('Connected successfully', isError: false);
      case NcFailure(:final message):
        _setMsg('Failed: $message', isError: true);
      case NcTransient():
        _setMsg('Network error – check URL and connection', isError: true);
    }
  }

  Future<void> _backupNow() async {
    await _save();
    final s = await ref.read(databaseProvider).settingsDao.get();
    if (s.nextcloudUrl.isEmpty) {
      _setMsg('Configure Nextcloud connection first', isError: true);
      return;
    }
    setState(() { _op = _Op.backing; _message = null; });
    try {
      final db = ref.read(databaseProvider);
      final artworks = await db.artworksDao.getAll();
      final allPhotos = await db.photosDao.getAll();
      final photosByArtwork = <int, List<ArtworkPhoto>>{};
      for (final ph in allPhotos) {
        photosByArtwork.putIfAbsent(ph.artworkId, () => []).add(ph);
      }
      final bytes =
          await BackupService().exportToZip(artworks, photosByArtwork);
      final filename =
          '${s.nextcloudPath}/artworks_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.zip';
      final nc = NextcloudService();
      final result = await nc.uploadBackup(
        s.nextcloudUrl, s.nextcloudUsername, _passwordCtrl.text,
        filename, bytes,
        pinnedFingerprint: _pin(s),
      );
      if (!mounted) return;
      switch (result) {
        case NcSuccess():
          await _pruneOldBackups(nc, s);
          await db.settingsDao.save(SettingsCompanion(
            lastSyncAt: Value(DateTime.now().millisecondsSinceEpoch),
          ));
          _setMsg('Backup complete', isError: false);
        case NcFailure(:final message):
          _setMsg('Upload failed: $message', isError: true);
        case NcTransient():
          _setMsg('Network error during upload', isError: true);
      }
    } catch (e) {
      if (mounted) _setMsg('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _op = _Op.idle);
    }
  }

  Future<void> _pruneOldBackups(NextcloudService nc, Setting s) async {
    final result = await nc.listFiles(
      s.nextcloudUrl, s.nextcloudUsername, _passwordCtrl.text,
      s.nextcloudPath, pinnedFingerprint: _pin(s),
    );
    if (result is! NcSuccess<List<String>>) return;
    final files = result.value..sort();
    if (files.length <= s.nextcloudKeepExports) return;
    for (final href in files.sublist(0, files.length - s.nextcloudKeepExports)) {
      await nc.deleteFile(
        s.nextcloudUrl, s.nextcloudUsername, _passwordCtrl.text,
        '${s.nextcloudPath}/${p.basename(href)}',
        pinnedFingerprint: _pin(s),
      );
    }
  }

  Future<void> _restoreFromCloud() async {
    await _save();
    final s = await ref.read(databaseProvider).settingsDao.get();
    if (s.nextcloudUrl.isEmpty) {
      _setMsg('Configure Nextcloud connection first', isError: true);
      return;
    }
    setState(() { _op = _Op.restoring; _message = null; });
    final nc = NextcloudService();
    final listResult = await nc.listFiles(
      s.nextcloudUrl, s.nextcloudUsername, _passwordCtrl.text,
      s.nextcloudPath, pinnedFingerprint: _pin(s),
    );
    if (!mounted) return;
    setState(() => _op = _Op.idle);
    switch (listResult) {
      case NcFailure(:final message):
        _setMsg('Could not list backups: $message', isError: true);
        return;
      case NcTransient():
        _setMsg('Network error – check connection', isError: true);
        return;
      case NcSuccess(:final value):
        final files = value..sort();
        if (files.isEmpty) {
          _setMsg('No backups found on Nextcloud', isError: false);
          return;
        }
        if (!mounted) return;
        final selected = await showDialog<String>(
          context: context,
          builder: (_) => _PickerDialog(files: files),
        );
        if (selected == null || !mounted) return;
        final confirmed = await _confirmReplace();
        if (confirmed != true || !mounted) return;
        setState(() { _op = _Op.restoring; _message = null; });
        final dlResult = await nc.downloadFile(
          s.nextcloudUrl, s.nextcloudUsername, _passwordCtrl.text,
          '${s.nextcloudPath}/${p.basename(selected)}',
          pinnedFingerprint: _pin(s),
        );
        if (!mounted) return;
        switch (dlResult) {
          case NcSuccess(:final value):
            await _applyRestore(value);
          case NcFailure(:final message):
            setState(() => _op = _Op.idle);
            _setMsg('Download failed: $message', isError: true);
          case NcTransient():
            setState(() => _op = _Op.idle);
            _setMsg('Network error during download', isError: true);
        }
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
    setState(() { _op = _Op.restoring; _message = null; });
    final bytes = await File(path).readAsBytes();
    await _applyRestore(bytes);
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

  Future<void> _applyRestore(Uint8List bytes) async {
    try {
      final data = await BackupService().importFromBytes(bytes);
      await ref
          .read(databaseProvider)
          .artworksDao
          .replaceAll(data.artworks, data.photos);
      if (mounted) {
        setState(() => _op = _Op.idle);
        _setMsg(
            'Restore complete – ${data.artworks.length} artworks imported',
            isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _op = _Op.idle);
        _setMsg('Restore failed: $e', isError: true);
      }
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(
              isError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: textColor,
              size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: textColor))),
        ],
      ),
    );
  }
}

class _PickerDialog extends StatelessWidget {
  const _PickerDialog({required this.files});
  final List<String> files;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select backup'),
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: files.length,
          itemBuilder: (_, i) {
            // Show newest first
            final href = files[files.length - 1 - i];
            return ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(p.basename(href)),
              onTap: () => Navigator.pop(context, href),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
