import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/artwork_constants.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/nextcloud_service.dart';
import '../../core/services/secure_credentials_service.dart';
import '../settings/settings_providers.dart';

enum _Op { idle, testing, backing, restoring }

enum _SyncChoice { restore, upload }

class NextcloudScreen extends ConsumerStatefulWidget {
  const NextcloudScreen({super.key});

  @override
  ConsumerState<NextcloudScreen> createState() => _NextcloudScreenState();
}

class _NextcloudScreenState extends ConsumerState<NextcloudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pathCtrl = TextEditingController();
  int _keepExports = 5;
  bool _autoSync = false;
  bool _obscurePassword = true;
  bool _loaded = false;
  bool _connectionVerified = false;
  String? _certFingerprint;
  _Op _op = _Op.idle;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    SecureCredentialsService.readPassword().then((pw) {
      if (mounted) setState(() => _passwordCtrl.text = pw);
    }).catchError((Object e, StackTrace st) {
      AppLogger.error('NextcloudScreen: failed to load password', e, st);
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  void _prefill(Setting s) {
    _loaded = true;
    _urlCtrl.text = s.nextcloudUrl;
    _usernameCtrl.text = s.nextcloudUsername;
    _pathCtrl.text = s.nextcloudPath;
    _certFingerprint = s.nextcloudCertFingerprint;
    setState(() {
      _keepExports = s.nextcloudKeepExports;
      _autoSync = s.autoSyncEnabled;
      // Credentials were saved only after a successful test, so treat stored
      // credentials as already verified when reopening the screen.
      _connectionVerified =
          s.nextcloudUrl.isNotEmpty && s.nextcloudUsername.isNotEmpty;
    });
  }

  void _invalidateVerification() {
    if (_connectionVerified) setState(() => _connectionVerified = false);
  }

  void _setMsg(String msg, {required bool isError}) {
    if (mounted) setState(() { _message = msg; _messageIsError = isError; });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    settings.whenData((s) { if (!_loaded) _prefill(s); });
    final lastSyncMs = settings.valueOrNull?.lastSyncAt;

    final busy = _op != _Op.idle;

    return Scaffold(
      appBar: AppBar(title: const Text('Nextcloud Sync')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Credentials ──────────────────────────────────────────────────
            _formField(_urlCtrl, 'Server URL',
                hint: 'https://cloud.example.com',
                keyboardType: TextInputType.url,
                onChanged: (_) => _invalidateVerification(),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null),
            _formField(_usernameCtrl, 'Username',
                onChanged: (_) => _invalidateVerification(),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null),
            _pwField(),
            _formField(_pathCtrl, 'Upload path', hint: kDefaultRemotePath),

            // ── Inline status ─────────────────────────────────────────────────
            if (_message != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _messageIsError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 16,
                    color: _messageIsError
                        ? Theme.of(context).colorScheme.error
                        : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _messageIsError
                            ? Theme.of(context).colorScheme.error
                            : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (lastSyncMs != null) ...[
              const SizedBox(height: 2),
              Text(
                'Last auto-sync: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(lastSyncMs))}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],

            const Divider(height: 32),

            // ── Actions ───────────────────────────────────────────────────────
            OutlinedButton(
              onPressed: busy ? null : _testConnection,
              child: _op == _Op.testing
                  ? const _Spinner()
                  : const Text('Test connection'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: _op == _Op.backing
                  ? const _Spinner()
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Backup to Nextcloud now'),
              onPressed: (busy || !_connectionVerified) ? null : _backupNow,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: _op == _Op.restoring
                  ? const _Spinner()
                  : const Icon(Icons.cloud_download_outlined),
              label: const Text('Restore from cloud'),
              onPressed: (busy || !_connectionVerified) ? null : _restoreFromCloud,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: (busy || !_connectionVerified) ? null : _saveAndSync,
              child: _op == _Op.idle
                  ? const Text('Confirm & connect')
                  : const _Spinner(bright: true),
            ),
            if (!_connectionVerified) ...[
              const SizedBox(height: 4),
              Text(
                'Test the connection before saving',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],

            const Divider(height: 32),

            // ── Advanced ──────────────────────────────────────────────────────
            Text('Advanced',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
            const SizedBox(height: 8),
            _keepRow(),
            const SizedBox(height: 4),
            _autoSyncSection(),
          ],
        ),
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────

  Widget _formField(
    TextEditingController ctrl,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
        ),
      );

  Widget _pwField() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          onChanged: (_) => _invalidateVerification(),
          decoration: InputDecoration(
            labelText: 'Password / app token',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility
                  : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _keepExports++),
          ),
        ],
      );

  Widget _autoSyncSection() => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Auto-backup'),
        subtitle:
            const Text('Backup when artworks are added, edited or deleted'),
        value: _autoSync,
        onChanged: (v) => setState(() => _autoSync = v),
      );

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _testConnection() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final url = _urlCtrl.text.trim();
    setState(() { _op = _Op.testing; _message = null; });

    final nc = NextcloudService();

    // 1. Probe certificate
    final certResult = await nc.fetchCertificateInfo(url);
    if (!mounted) return;

    switch (certResult) {
      case NcFailure(:final message):
        setState(() => _op = _Op.idle);
        _setMsg('Cannot reach server: $message', isError: true);
        return;
      case NcTransient():
        setState(() => _op = _Op.idle);
        _setMsg('Network error — check URL and connection', isError: true);
        return;
      case NcSuccess(:final value):
        if (value != null) {
          // Untrusted cert — show dialog
          final approved = await _showCertDialog(value);
          if (!mounted) return;
          if (approved != true) {
            setState(() => _op = _Op.idle);
            _setMsg('Certificate not trusted — connection cancelled', isError: true);
            return;
          }
          _certFingerprint = value.fingerprint;
        }
    }

    // 2. Verify credentials
    final result = await nc.verifyCredentials(
      url, _usernameCtrl.text.trim(), _passwordCtrl.text,
      pinnedFingerprint: _certFingerprint,
    );
    if (!mounted) return;
    setState(() => _op = _Op.idle);

    switch (result) {
      case NcSuccess():
        await AppLogger.info('NextcloudScreen: test connection succeeded for $url');
        setState(() => _connectionVerified = true);
        _setMsg('Connected successfully', isError: false);
      case NcFailure(:final message):
        await AppLogger.warn('NextcloudScreen: test connection failed — $message');
        setState(() => _connectionVerified = false);
        _setMsg('Failed: $message', isError: true);
      case NcTransient():
        setState(() => _connectionVerified = false);
        _setMsg('Network error – check URL and connection', isError: true);
    }
  }

  Future<bool?> _showCertDialog(CertificateInfo info) => showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Untrusted certificate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'This server uses a certificate not trusted by the system.'),
                const SizedBox(height: 12),
                _certRow('Subject', info.subject),
                _certRow('Issuer', info.issuer),
                _certRow('Valid until',
                    info.validUntil.toIso8601String().substring(0, 10)),
                _certRow('SHA-256', info.fingerprint),
                const SizedBox(height: 12),
                const Text(
                    'Only trust this certificate if you have verified '
                    'the fingerprint matches your server.',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Reject')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Trust & pin')),
          ],
        ),
      );

  Widget _certRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 80,
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
                child: Text(value,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11))),
          ],
        ),
      );

  Future<void> _save() async {
    final path = _pathCtrl.text.trim().isEmpty
        ? kDefaultRemotePath
        : _pathCtrl.text.trim();
    await SecureCredentialsService.writePassword(_passwordCtrl.text);
    await ref.read(databaseProvider).settingsDao.save(SettingsCompanion(
          nextcloudUrl: Value(_urlCtrl.text.trim()),
          nextcloudUsername: Value(_usernameCtrl.text.trim()),
          nextcloudPath: Value(path),
          nextcloudCertFingerprint: Value(_certFingerprint),
          nextcloudKeepExports: Value(_keepExports),
          autoSyncEnabled: Value(_autoSync),
        ));
  }

  /// Save credentials then check for an existing server backup and offer
  /// to restore it or upload the current data.
  Future<void> _saveAndSync() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await _save();
      if (!mounted) return;

      final url = _urlCtrl.text.trim();
      final path = _pathCtrl.text.trim().isEmpty ? kDefaultRemotePath : _pathCtrl.text.trim();
      final nc = NextcloudService();

      final backupResult = await nc.findLatestBackup(
        url, _usernameCtrl.text.trim(), _passwordCtrl.text, path,
        pinnedFingerprint: _certFingerprint,
      );
      if (!mounted) return;

      // If the backup check failed (network error) skip the dialog and just close.
      if (backupResult is! NcSuccess<BackupInfo?>) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final remoteBackup = backupResult.value;
      final choice = await _showSyncChoiceDialog(remoteBackup);
      if (!mounted) return;

      if (choice == _SyncChoice.restore && remoteBackup != null) {
        await _doRestore(url, _usernameCtrl.text.trim(), path,
            remoteBackup.remotePath);
      } else if (choice == _SyncChoice.upload) {
        await _doBackup(url, _usernameCtrl.text.trim(), path);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      await AppLogger.error('NextcloudScreen: save failed', e, st);
      if (mounted) _setMsg('Failed to save: $e', isError: true);
    }
  }

  Future<_SyncChoice?> _showSyncChoiceDialog(BackupInfo? remote) =>
      showDialog<_SyncChoice>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(remote != null
              ? 'Server backup found'
              : 'Connected to Nextcloud'),
          content: Text(remote != null
              ? 'A backup from '
                  '${DateFormat('dd MMM yyyy').format(remote.backupDate)} '
                  'was found on your Nextcloud.\n\n'
                  'Restore from server, or upload your current data?'
              : 'No existing backup was found on the server.\n\n'
                  'Upload a backup of your current data now?'),
          actions: remote != null
              ? [
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(ctx, _SyncChoice.upload),
                    child: const Text('Upload current'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(ctx, _SyncChoice.restore),
                    child: const Text('Restore from server'),
                  ),
                ]
              : [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Later')),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(ctx, _SyncChoice.upload),
                    child: const Text('Upload now'),
                  ),
                ],
        ),
      );

  Future<void> _backupNow() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final path = _pathCtrl.text.trim().isEmpty ? kDefaultRemotePath : _pathCtrl.text.trim();
    setState(() { _op = _Op.backing; _message = null; });
    await _doBackup(url, _usernameCtrl.text.trim(), path);
    if (mounted) setState(() => _op = _Op.idle);
  }

  Future<void> _doBackup(String url, String username, String path) async {
    try {
      await AppLogger.info('NextcloudScreen: backup started');
      final db = ref.read(databaseProvider);
      final artworks = await db.artworksDao.getAll();
      final allPhotos = await db.photosDao.getAll();
      final photosByArtwork = <int, List<ArtworkPhoto>>{};
      for (final ph in allPhotos) {
        photosByArtwork.putIfAbsent(ph.artworkId, () => []).add(ph);
      }
      final bytes = await BackupService().exportToZip(artworks, photosByArtwork);
      final filename = '$path/${BackupService.generateFilename()}';
      final nc = NextcloudService();
      final result = await nc.uploadBackup(
        url, username, _passwordCtrl.text,
        filename, bytes,
        pinnedFingerprint: _certFingerprint,
      );
      if (!mounted) return;
      switch (result) {
        case NcSuccess():
          await AppLogger.info('NextcloudScreen: backup succeeded');
          await _pruneOldBackups(nc, url, username, path);
          await db.settingsDao.save(SettingsCompanion(
            lastSyncAt: Value(DateTime.now().millisecondsSinceEpoch),
            lastSyncError: const Value(null),
          ));
          _setMsg('Backup complete', isError: false);
        case NcFailure(:final message):
          await AppLogger.error('NextcloudScreen: backup failed — $message');
          _setMsg('Upload failed: $message', isError: true);
        case NcTransient():
          _setMsg('Network error during upload', isError: true);
      }
    } catch (e, st) {
      await AppLogger.error('NextcloudScreen: backup exception', e, st);
      if (mounted) _setMsg('Error: $e', isError: true);
    }
  }

  Future<void> _pruneOldBackups(
      NextcloudService nc, String url, String username, String remotePath) async {
    final result = await nc.listFiles(url, username, _passwordCtrl.text,
        remotePath, pinnedFingerprint: _certFingerprint);
    if (result is! NcSuccess<List<String>>) return;
    final files = [...result.value]..sort();
    if (files.length <= _keepExports) return;
    for (final href in files.sublist(0, files.length - _keepExports)) {
      final del = await nc.deleteFile(url, username, _passwordCtrl.text,
          '$remotePath/${p.basename(href)}',
          pinnedFingerprint: _certFingerprint);
      if (del is! NcSuccess) {
        await AppLogger.warn('NextcloudScreen: could not prune $href');
      }
    }
  }

  Future<void> _restoreFromCloud() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final path = _pathCtrl.text.trim().isEmpty ? kDefaultRemotePath : _pathCtrl.text.trim();
    setState(() { _op = _Op.restoring; _message = null; });
    final nc = NextcloudService();
    final listResult = await nc.listFiles(
      url, _usernameCtrl.text.trim(), _passwordCtrl.text, path,
      pinnedFingerprint: _certFingerprint,
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
        final files = [...value]..sort();
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
        await _doRestore(url, _usernameCtrl.text.trim(), path, selected);
        if (mounted) setState(() => _op = _Op.idle);
    }
  }

  Future<void> _doRestore(
      String url, String username, String remoteDir, String selectedHref) async {
    final nc = NextcloudService();
    final dlResult = await nc.downloadFile(
      url, username, _passwordCtrl.text,
      '$remoteDir/${p.basename(selectedHref)}',
      pinnedFingerprint: _certFingerprint,
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

  Future<bool?> _confirmReplace() => showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Replace all artworks?'),
          content: const Text(
              'All current artworks will be permanently deleted and replaced by the backup.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogCtx).colorScheme.error),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );

  Future<void> _applyRestore(Uint8List bytes) async {
    try {
      final data = await BackupService().importFromBytes(bytes);
      final db = ref.read(databaseProvider);
      await db.artworksDao.replaceAll(data.artworks, data.photos);
      await db.settingsDao.save(SettingsCompanion(
        lastSyncAt: Value(DateTime.now().millisecondsSinceEpoch),
        lastSyncError: const Value(null),
      ));
      if (mounted) {
        setState(() => _op = _Op.idle);
        _setMsg('Restore complete – ${data.artworks.length} artworks imported',
            isError: false);
      }
    } catch (e, st) {
      await AppLogger.error('NextcloudScreen: restore failed', e, st);
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
