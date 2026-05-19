import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/models/artwork_constants.dart';
import '../../core/models/currency.dart';
import '../../core/services/app_logger.dart';
import '../../core/widgets/photo_strip.dart';

const _uuid = Uuid();

class AddEditScreen extends ConsumerStatefulWidget {
  const AddEditScreen({super.key, this.artworkId});
  final int? artworkId;

  @override
  ConsumerState<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends ConsumerState<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Text controllers
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _year = TextEditingController();
  final _height = TextEditingController();
  final _width = TextEditingController();
  final _depth = TextEditingController();
  final _location = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _provenance = TextEditingController();

  // Dropdown / picker state
  String _type = '';
  String _medium = '';
  String _condition = '';
  Currency _currency = Currency.eur;
  DateTime? _acquisitionDate;
  String _photoPath = '';
  String _certificatePath = '';

  // Additional photos: (existingRecord?, localPath)
  final _photoItems = <({ArtworkPhoto? record, String path})>[];
  final _photosToDelete = <ArtworkPhoto>[];

  bool get _isEdit => widget.artworkId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForEdit());
    }
  }

  Future<void> _loadForEdit() async {
    final db = ref.read(databaseProvider);
    final artwork = await db.artworksDao.getById(widget.artworkId!);
    if (!mounted || artwork == null) return;
    _prefill(artwork);
    final photos = await db.photosDao.getForArtwork(widget.artworkId!);
    if (!mounted) return;
    setState(() {
      _photoItems
        ..clear()
        ..addAll(photos.map((p) => (record: p, path: p.photoPath)));
    });
  }

  @override
  void dispose() {
    for (final c in [_title, _artist, _year, _height, _width, _depth, _location, _price, _description, _provenance]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscard(context);
        if (leave && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Artwork' : 'Add Artwork'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main photo
                _PhotoPicker(
                  path: _photoPath,
                  onPick: _pickMainPhoto,
                  onRemove: () => setState(() => _photoPath = ''),
                ),
                const SizedBox(height: 16),

                // Required fields
                _field(_title, 'Title *',
                    validator: (v) => (v?.trim().isEmpty ?? true) ? 'Title is required' : null),
                _field(_artist, 'Artist'),
                _field(_year, 'Year',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

                // Type, medium & condition
                _dropdown('Type', artworkTypes, _type, (v) => setState(() => _type = v ?? '')),
                _dropdown('Medium', artworkMediums, _medium, (v) => setState(() => _medium = v ?? '')),
                _dropdown('Condition', artworkConditions, _condition, (v) => setState(() => _condition = v ?? '')),

                // Dimensions
                _sectionLabel('Dimensions (cm)'),
                Row(children: [
                  Expanded(child: _field(_height, 'Height', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_width, 'Width', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 8),
                  Expanded(child: _field(_depth, 'Depth', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ]),

                _field(_location, 'Location'),

                // Acquisition date
                _DatePicker(
                  date: _acquisitionDate,
                  onPick: (d) => setState(() => _acquisitionDate = d),
                  onClear: () => setState(() => _acquisitionDate = null),
                ),
                const SizedBox(height: 8),

                // Currency + price
                Row(children: [
                  SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<Currency>(
                      key: ValueKey(_currency),
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: Currency.values
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.code)))
                          .toList(),
                      onChanged: (v) => setState(() => _currency = v ?? Currency.eur),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      _price,
                      'Purchase price',
                      prefixText: _currency.symbol,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),

                _field(_description, 'Description', maxLines: 4),
                _field(_provenance, 'Provenance / ownership history', maxLines: 4),

                // Certificate
                _CertificatePicker(
                  path: _certificatePath,
                  onPick: _pickCertificate,
                  onRemove: () => setState(() => _certificatePath = ''),
                ),

                // Additional photos
                const SizedBox(height: 8),
                _sectionLabel('Additional Photos'),
                const SizedBox(height: 8),
                PhotoStrip(
                  paths: _photoItems.map((e) => e.path).toList(),
                  onDelete: (i) => setState(() {
                    final item = _photoItems.removeAt(i);
                    if (item.record != null) _photosToDelete.add(item.record!);
                  }),
                  onAdd: _pickAdditionalPhoto,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? prefixText,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            prefixText: prefixText,
          ),
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
        ),
      );

  Widget _dropdown(
    String label,
    List<String> options,
    String current,
    void Function(String?) onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          key: ValueKey(current),
          initialValue: current.isEmpty ? null : current,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('—')),
            ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
          ],
          onChanged: onChanged,
        ),
      );

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      );

  // ── Prefill ────────────────────────────────────────────────────────────────

  void _prefill(Artwork a) {
    _title.text = a.title;
    _artist.text = a.artist;
    _year.text = a.year?.toString() ?? '';
    _type = a.type;
    _medium = a.medium;
    _height.text = a.heightCm?.toString() ?? '';
    _width.text = a.widthCm?.toString() ?? '';
    _depth.text = a.depthCm?.toString() ?? '';
    _location.text = a.location;
    _price.text = a.purchasePrice?.toString() ?? '';
    _description.text = a.description;
    _provenance.text = a.provenance;
    _condition = a.condition;
    _currency = Currency.fromCode(a.currency.isEmpty ? 'EUR' : a.currency);
    _acquisitionDate = a.acquisitionDate != null
        ? DateTime.fromMillisecondsSinceEpoch(a.acquisitionDate!)
        : null;
    _photoPath = a.photoPath;
    _certificatePath = a.certificatePath;
  }

  // ── Photo picking ──────────────────────────────────────────────────────────

  Future<void> _pickMainPhoto() async {
    final path = await _pickImage();
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _pickAdditionalPhoto() async {
    final path = await _pickImage();
    if (path != null) {
      setState(() => _photoItems.add((record: null, path: path)));
    }
  }

  Future<String?> _pickImage() async {
    final source = await _askPhotoSource();
    if (source == null) return null;
    if (!await _requestPermission(source)) return null;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return null;

    try {
      return await _copyToArtworksDir(picked.path, extension: 'jpg');
    } catch (e, st) {
      await AppLogger.error('AddEdit: failed to copy photo', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save photo — check storage')),
        );
      }
      return null;
    }
  }

  Future<bool> _requestPermission(ImageSource source) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(source == ImageSource.camera
            ? 'Camera permission denied'
            : 'Gallery permission denied'),
        action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
      ));
    }
    return false;
  }

  Future<ImageSource?> _askPhotoSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final src = result.files.first.path;
    if (src == null) return;
    try {
      final dest = await _copyToArtworksDir(src, extension: 'pdf', prefix: 'cert_');
      setState(() => _certificatePath = dest);
    } catch (e, st) {
      await AppLogger.error('AddEdit: failed to copy certificate', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save certificate — check storage')),
        );
      }
    }
  }

  // Throws on I/O failure so callers can show a meaningful SnackBar.
  Future<String> _copyToArtworksDir(
    String src, {
    required String extension,
    String prefix = '',
  }) async {
    final dir = Directory(p.join(
      (await getApplicationDocumentsDirectory()).path,
      'artworks',
    ))..createSync(recursive: true);
    final dest = File(p.join(dir.path,
        '$prefix${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.$extension'));
    await File(src).copy(dest.path);
    return dest.path;
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final companion = ArtworksCompanion(
        id: _isEdit ? Value(widget.artworkId!) : const Value.absent(),
        title: Value(_title.text.trim()),
        artist: Value(_artist.text.trim()),
        year: Value(int.tryParse(_year.text)),
        type: Value(_type),
        medium: Value(_medium),
        heightCm: Value(double.tryParse(_height.text)),
        widthCm: Value(double.tryParse(_width.text)),
        depthCm: Value(double.tryParse(_depth.text)),
        location: Value(_location.text.trim()),
        acquisitionDate: Value(_acquisitionDate?.millisecondsSinceEpoch),
        currency: Value(_currency.code),
        purchasePrice: Value(double.tryParse(_price.text)),
        description: Value(_description.text.trim()),
        condition: Value(_condition),
        provenance: Value(_provenance.text.trim()),
        photoPath: Value(_photoPath),
        certificatePath: Value(_certificatePath),
      );

      var savedId = 0;
      await db.transaction(() async {
        if (_isEdit) {
          await db.artworksDao.updateArtwork(companion);
          savedId = widget.artworkId!;
        } else {
          savedId = await db.artworksDao.insertArtwork(companion);
        }
        for (final photo in _photosToDelete) {
          await db.photosDao.deleteById(photo.id);
        }
        for (var i = 0; i < _photoItems.length; i++) {
          final item = _photoItems[i];
          if (item.record == null) {
            await db.photosDao.insert(ArtworkPhotosCompanion(
              artworkId: Value(savedId),
              photoPath: Value(item.path),
              sortOrder: Value(i),
            ));
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artwork saved')),
        );
        context.go('/collection/artwork/$savedId');
      }
    } catch (e, st) {
      await AppLogger.error('AddEdit: failed to save artwork', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final hasContent = _title.text.isNotEmpty ||
        _artist.text.isNotEmpty ||
        _description.text.isNotEmpty ||
        _provenance.text.isNotEmpty ||
        _photoPath.isNotEmpty ||
        _photoItems.isNotEmpty;
    if (!hasContent) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard changes?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard')),
        ],
      ),
    );
    return result ?? false;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.path, required this.onPick, required this.onRemove});

  final String path;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: path.isNotEmpty
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path), fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.close),
                        onPressed: onRemove,
                      ),
                    ),
                  ],
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 48),
                    SizedBox(height: 8),
                    Text('Add cover photo'),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({required this.date, required this.onPick, required this.onClear});

  final DateTime? date;
  final void Function(DateTime) onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(date),
      readOnly: true,
      initialValue: date != null ? DateFormat('dd MMM yyyy').format(date!) : '',
      decoration: InputDecoration(
        labelText: 'Acquisition date',
        border: const OutlineInputBorder(),
        suffixIcon: date != null
            ? IconButton(icon: const Icon(Icons.close), onPressed: onClear)
            : const Icon(Icons.calendar_today_outlined),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(1000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}

class _CertificatePicker extends StatelessWidget {
  const _CertificatePicker({
    required this.path,
    required this.onPick,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.attach_file),
        label: const Text('Attach certificate (PDF)'),
        onPressed: onPick,
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.picture_as_pdf_outlined),
      title: Text(p.basename(path), overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Remove',
        onPressed: onRemove,
      ),
    );
  }
}

