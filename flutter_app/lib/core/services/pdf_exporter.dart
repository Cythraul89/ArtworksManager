import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../database/app_database.dart';
import '../models/currency.dart';
import 'app_logger.dart';

/// Generates a single-page-per-artwork A4 PDF of the collection.
///
/// Photos are loaded via Flutter's image stack (so EXIF orientation is
/// automatically applied) and embedded at up to 220pt height.
class PdfExporter {
  // Colours match the app's Material seed colour and the Kotlin reference.
  static const _primaryColor  = PdfColor.fromInt(0xFF5C6BC0);
  static const _subtitleColor = PdfColor.fromInt(0xFF6E6E73);
  static const _dividerColor  = PdfColor.fromInt(0xFFE0DED9);

  final String defaultCurrencyCode;

  const PdfExporter({required this.defaultCurrencyCode});

  /// Generates the PDF and returns the raw bytes.
  Future<Uint8List> generate(List<Artwork> artworks) async {
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansRegular(),
        bold: await PdfGoogleFonts.notoSansBold(),
      ),
    );

    for (final artwork in artworks) {
      pw.ImageProvider? photo;
      if (artwork.photoPath.isNotEmpty) {
        final file = File(artwork.photoPath);
        if (file.existsSync()) {
          try {
            // flutterImageProvider decodes via Flutter's image pipeline,
            // which respects EXIF orientation on Android and iOS.
            photo = await flutterImageProvider(FileImage(file));
          } catch (e) {
            await AppLogger.warn(
                'PdfExporter: skipping photo for "${artwork.title}": $e');
          }
        }
      }
      doc.addPage(_buildPage(artwork, photo));
    }

    await AppLogger.info(
        'PdfExporter: generated ${artworks.length} pages');
    return doc.save();
  }

  pw.Page _buildPage(Artwork a, pw.ImageProvider? photo) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context ctx) {
        final rows = <pw.Widget>[];

        // ── Photo ──────────────────────────────────────────────────────────
        if (photo != null) {
          rows.add(pw.Align(
            alignment: pw.Alignment.topLeft,
            child: pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(maxHeight: 220),
              child: pw.Image(photo, fit: pw.BoxFit.contain),
            ),
          ));
          rows.add(pw.SizedBox(height: 16));
        }

        // ── Title ──────────────────────────────────────────────────────────
        rows.add(pw.Text(
          a.title,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ));
        rows.add(pw.SizedBox(height: 6));

        // ── Artist · Year ──────────────────────────────────────────────────
        final subParts = <String>[
          if (a.artist.isNotEmpty) a.artist,
          if (a.year != null) a.year.toString(),
        ];
        if (subParts.isNotEmpty) {
          rows.add(pw.Text(
            subParts.join('  ·  '),
            style: const pw.TextStyle(fontSize: 13, color: _subtitleColor),
          ));
          rows.add(pw.SizedBox(height: 10));
        }

        // ── Divider ────────────────────────────────────────────────────────
        rows.add(pw.Divider(color: _dividerColor, thickness: 1));
        rows.add(pw.SizedBox(height: 8));

        // ── Fields ─────────────────────────────────────────────────────────
        void field(String label, String? value) {
          if (value == null || value.trim().isEmpty) return;
          rows.add(pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 100,
                child: pw.Text(label,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Expanded(
                child: pw.Text(value,
                    style: const pw.TextStyle(fontSize: 11)),
              ),
            ],
          ));
          rows.add(pw.SizedBox(height: 5));
        }

        field('Type', a.type.isNotEmpty ? a.type : null);
        field('Medium', a.medium.isNotEmpty ? a.medium : null);
        field('Condition', a.condition.isNotEmpty ? a.condition : null);

        final dimParts = <String>[
          if (a.heightCm != null) fmtDim(a.heightCm!),
          if (a.widthCm != null) fmtDim(a.widthCm!),
          if (a.depthCm != null) fmtDim(a.depthCm!),
        ];
        if (dimParts.isNotEmpty) {
          field('Dimensions', '${dimParts.join(' × ')} cm');
        }

        field('Location', a.location.isNotEmpty ? a.location : null);

        if (a.acquisitionDate != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(a.acquisitionDate!);
          field('Acquired', DateFormat('dd MMM yyyy').format(dt));
        }

        if (a.purchasePrice != null) {
          final code = a.currency.isNotEmpty ? a.currency : defaultCurrencyCode;
          final symbol = Currency.fromCode(code).symbol;
          field('Price',
              '$symbol${NumberFormat('#,##0.00').format(a.purchasePrice)}');
        }

        field('Description',
            a.description.isNotEmpty ? a.description : null);
        field('Provenance',
            a.provenance.isNotEmpty ? a.provenance : null);

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }

  static final _trailingZeros = RegExp(r'0+$');
  static final _trailingDot = RegExp(r'\.$');

  // Formats a dimension value: integers without decimals, others with 1dp.
  static String fmtDim(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1).replaceAll(_trailingZeros, '').replaceAll(_trailingDot, '');
  }
}
