import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:workmanager/workmanager.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/artwork_constants.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/nextcloud_service.dart';
import '../../core/services/secure_credentials_service.dart';
import '../../core/services/sync_worker.dart';
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
  bool _autoSync = false;
  int _syncIntervalHours = 24;
  int _androidSdkInt = 0;
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
    }).catchError((Object e, StackTrace st) {
      AppLogger.error('NextcloudScreen: failed to load password', e, st);
    });
    if (Platform.isAndroid) {
      DeviceInfoPlugin().androidInfo.then((info) {
        if (mounted) setState(() => _androidSdkInt = info.version.sdkInt);
      }).catchError((Object e, StackTrace st) {
        AppLogger.error('NextcloudScreen: failed to get device info', e, st);
      });
    }
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
    setState(() {
      _keepExports = s.nextcloudKeepExports;
      _autoSync = s.autoSyncEnabled;
      _syncIntervalHours = s.autoSyncIntervalHours;
    });
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
              final urlErr = _urlError(_urlCtrl.text.trim());
              if (urlErr != null) { _setMsg(urlErr, isError: true); return; }
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
          if (Platform.isAndroid) ...[
            const SizedBox(height: 8),
            _autoSyncSection(),
          ],
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
          OutlinedButton.icon(
            icon: _op == _Op.restoring
                ? const _Spinner()
                : const Icon(Icons.cloud_download_outlined),
            label: const Text('Restore from cloud'),
            onPressed: busy ? null : _restoreFromCloud,
          ),
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

  Widget _autoSyncSection() {
    final supported = _androidSdkInt >= 33;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-backup'),
          subtitle: Text(supported
              ? 'Periodic Nextcloud backup in the background'
              : Platform.isAndroid
                  ? 'Requires Android 13 or later (not supported on this device)'
                  : 'Available on Android 13+ only'),
          value: supported && _autoSync,
          onChanged: supported ? (v) => setState(() => _autoSync = v) : null,
        ),
        if (supported && _autoSync)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              children: [
                const Text('Interval'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _syncIntervalHours,
                  items: const [
                    DropdownMenuItem(value: 24, child: Text('Daily')),
                    DropdownMenuItem(value: 48, child: Text('Every 2 days')),
                    DropdownMenuItem(value: 168, child: Text('Weekly')),
                  ],
                  onChanged: (v) => setState(() => _syncIntervalHours = v ?? 24),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    try {
      final path = _pathCtrl.text.trim().isEmpty
          ? kDefaultRemotePath
          : _pathCtrl.text.trim();
      await SecureCredentialsService.writePassword(_passwordCtrl.text);
      await ref.read(databaseProvider).settingsDao.save(SettingsCompanion(
            nextcloudUrl: Value(_urlCtrl.text.trim()),
            nextcloudUsername: Value(_usernameCtrl.text.trim()),
            nextcloudPath: Value(path),
            nextcloudCertFingerprint: Value(_fingerprintCtrl.text.trim()),
            nextcloudKeepExports: Value(_keepExports),
            autoSyncEnabled: Value(_autoSync),
            autoSyncIntervalHours: Value(_syncIntervalHours),
          ));
      await _scheduleOrCancelSync(path);
    } catch (e, st) {
      await AppLogger.error('NextcloudScreen: failed to save settings', e, st);
      if (mounted) _setMsg('Failed to save settings: $e', isError: true);
    }
  }

  Future<void> _scheduleOrCancelSync(String remotePath) async {
    if (_androidSdkInt < 33) return;
    try {
      if (_autoSync && _urlCtrl.text.trim().isNotEmpty) {
        await Workmanager().registerPeriodicTask(
          SyncWorker.taskName,
          SyncWorker.taskName,
          frequency: Duration(hours: _syncIntervalHours),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
      } else {
        await Workmanager().cancelByUniqueName(SyncWorker.taskName);
      }
    } catch (e, st) {
      await AppLogger.error('NextcloudScreen: WorkManager scheduling failed', e, st);
    }
  }

  String? _pin(Setting s) =>
      s.nextcloudCertFingerprint.isNotEmpty ? s.nextcloudCertFingerprint : null;

  /// Returns an error message if [url] is non-empty but malformed, else null.
  String? _urlError(String url) {
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return 'Enter a valid URL';
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'URL must start with https://';
    }
    return null;
  }

  Future<void> _testConnection() async {
    final urlErr = _urlError(_urlCtrl.text.trim());
    if (urlErr != null) { _setMsg(urlErr, isError: true); return; }
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
        await AppLogger.info('NextcloudScreen: test connection succeeded for ${s.nextcloudUrl}');
        _setMsg('Connected successfully', isError: false);
      case NcFailure(:final message):
        await AppLogger.warn('NextcloudScreen: test connection failed — $message');
        _setMsg('Failed: $message', isError: true);
      case NcTransient():
        await AppLogger.warn('NextcloudScreen: test connection transient error (${s.nextcloudUrl})');
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
      await AppLogger.info('NextcloudScreen: manual backup started');
      final db = ref.read(databaseProvider);
      final artworks = await db.artworksDao.getAll();
      final allPhotos = await db.photosDao.getAll();
      final photosByArtwork = <int, List<ArtworkPhoto>>{};
      for (final ph in allPhotos) {
        photosByArtwork.putIfAbsent(ph.artworkId, () => []).add(ph);
      }
      final bytes =
          await BackupService().exportToZip(artworks, photosByArtwork);
      final filename = '${s.nextcloudPath}/${BackupService.generateFilename()}';
      final nc = NextcloudService();
      final result = await nc.uploadBackup(
        s.nextcloudUrl, s.nextcloudUsername, _passwordCtrl.text,
        filename, bytes,
        pinnedFingerprint: _pin(s),
      );
      if (!mounted) return;
      switch (result) {
        case NcSuccess():
          await AppLogger.info('NextcloudScreen: manual backup succeeded — $filename');
          await _pruneOldBackups(nc, s);
          await db.settingsDao.save(SettingsCompanion(
            lastSyncAt: Value(DateTime.now().millisecondsSinceEpoch),
            lastSyncError: const Value(null),
          ));
          _setMsg('Backup complete', isError: false);
        case NcFailure(:final message):
          await AppLogger.error('NextcloudScreen: manual backup failed — $message');
          _setMsg('Upload failed: $message', isError: true);
        case NcTransient():
          await AppLogger.warn('NextcloudScreen: manual backup transient error');
          _setMsg('Network error during upload', isError: true);
      }
    } catch (e, st) {
      await AppLogger.error('NextcloudScreen: manual backup exception', e, st);
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
    final files = [...result.value]..sort();
    if (files.length <= s.nextcloudKeepExports) return;
    for (final href in files.sublist(0, files.length - s.nextcloudKeepExports)) {
      final del = await nc.deleteFile(
        s.nextcloudUrl, s.nextcloudUsername, _passwordCtrl.text,
        '${s.nextcloudPath}/${p.basename(href)}',
        pinnedFingerprint: _pin(s),
      );
      if (del is! NcSuccess) {
        await AppLogger.warn('NextcloudScreen: could not prune $href');
      }
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
