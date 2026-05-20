import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/currency.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/pdf_exporter.dart';
import 'settings_providers.dart';

const _themeModes = [
  ('system', 'System', Icons.brightness_auto_outlined),
  ('light', 'Light', Icons.light_mode_outlined),
  ('dark', 'Dark', Icons.dark_mode_outlined),
];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (setting) => ListView(
          children: [
            _SectionLabel('Preferences'),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Default currency'),
              subtitle: Text(
                  '${Currency.fromCode(setting.currency).symbol}  ${setting.currency}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickCurrency(context, ref, setting),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto_outlined),
              title: const Text('Theme'),
              subtitle: Text(_themeModes
                  .firstWhere((t) => t.$1 == setting.themeMode,
                      orElse: () => _themeModes.first)
                  .$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickTheme(context, ref, setting),
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange_outlined),
              title: const Text('Exchange rates'),
              subtitle: const Text('Live ECB rates'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/rates'),
            ),
            const Divider(indent: 16, endIndent: 16),
            _SectionLabel('Export'),
            _PdfExportTile(currency: setting.currency),
            const Divider(indent: 16, endIndent: 16),
            _SectionLabel('Backup & Sync'),
            ListTile(
              leading: const Icon(Icons.folder_zip_outlined),
              title: const Text('Local backup'),
              subtitle: const Text('Save or restore a local ZIP backup'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/backup'),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Nextcloud'),
              subtitle: Text(
                setting.nextcloudUrl.isEmpty
                    ? 'Not configured'
                    : setting.nextcloudUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/nextcloud'),
            ),
            if (setting.lastSyncAt != null)
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Last backup'),
                subtitle: Text(
                  DateFormat('dd MMM yyyy · HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(setting.lastSyncAt!),
                  ),
                ),
              ),
            if (setting.lastSyncError != null)
              ListTile(
                leading: Icon(Icons.sync_problem_outlined,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Last sync failed',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                ),
                subtitle: Text(
                  setting.lastSyncError!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                dense: true,
                onTap: () => context.go('/settings/nextcloud'),
              )
            else if (_isSyncOverdue(setting))
              ListTile(
                leading: Icon(Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: Text(
                  setting.lastSyncAt == null
                      ? 'Auto-backup never ran'
                      : 'Auto-backup is overdue',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                ),
                subtitle: const Text('Open Nextcloud settings to check'),
                dense: true,
                onTap: () => context.go('/settings/nextcloud'),
              ),
            const Divider(indent: 16, endIndent: 16),
            _SectionLabel('Diagnostics'),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('App logs'),
              subtitle: const Text('View and export diagnostic logs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/settings/logs'),
            ),
            const Divider(indent: 16, endIndent: 16),
            _SectionLabel('About'),
            _AboutTile(),
          ],
        ),
      ),
    );
  }

  bool _isSyncOverdue(Setting s) {
    if (!s.autoSyncEnabled) return false;
    if (s.lastSyncAt == null) return true;
    final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(s.lastSyncAt!));
    return age > Duration(hours: s.autoSyncIntervalHours * 2);
  }

  void _pickCurrency(
      BuildContext context, WidgetRef ref, Setting setting) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Default currency',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...Currency.values.map((c) => ListTile(
                        leading: Text(c.symbol,
                            style: Theme.of(ctx).textTheme.titleMedium),
                        title: Text(c.code),
                        trailing: setting.currency == c.code
                            ? Icon(Icons.check,
                                color: Theme.of(ctx).colorScheme.primary)
                            : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          try {
                            await ref.read(databaseProvider).settingsDao.save(
                                  SettingsCompanion(currency: Value(c.code)),
                                );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save: $e')),
                              );
                            }
                          }
                        },
                      )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickTheme(BuildContext context, WidgetRef ref, Setting setting) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Theme', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final (mode, label, icon) in _themeModes)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: setting.themeMode == mode
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(databaseProvider).settingsDao.save(
                        SettingsCompanion(themeMode: Value(mode)),
                      );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── PDF export tile ───────────────────────────────────────────────────────────

class _PdfExportTile extends ConsumerStatefulWidget {
  const _PdfExportTile({required this.currency});
  final String currency;

  @override
  ConsumerState<_PdfExportTile> createState() => _PdfExportTileState();
}

class _PdfExportTileState extends ConsumerState<_PdfExportTile> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final artworks =
          await ref.read(databaseProvider).artworksDao.getAll();
      if (artworks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No artworks to export')),
          );
        }
        return;
      }
      await AppLogger.info(
          'PdfExporter: exporting ${artworks.length} artworks');
      final bytes = await PdfExporter(defaultCurrencyCode: widget.currency)
          .generate(artworks);
      final filename =
          'artworks_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e, st) {
      await AppLogger.error('PdfExporter: export failed', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      title: const Text('Export to PDF'),
      subtitle: const Text('One page per artwork'),
      trailing: _busy ? null : const Icon(Icons.chevron_right),
      onTap: _busy ? null : _export,
    );
  }
}

// ── About tile ────────────────────────────────────────────────────────────────

class _AboutTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider);
    final String? version = info.maybeWhen(
      data: (p) => '${p.version}+${p.buildNumber}',
      orElse: () => null,
    );
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('AWoMa'),
      subtitle: Text(version ?? 'Loading…'),
      onTap: () => showLicensePage(
        context: context,
        applicationName: 'AWoMa',
        applicationVersion: version,
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
