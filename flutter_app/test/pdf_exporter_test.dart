import 'package:flutter_test/flutter_test.dart';

import 'package:artworks_manager/core/models/currency.dart';
import 'package:artworks_manager/core/services/pdf_exporter.dart';

void main() {
  group('Currency', () {
    test('fromCode returns correct enum for each supported code', () {
      expect(Currency.fromCode('EUR'), Currency.eur);
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode('NOK'), Currency.nok);
      expect(Currency.fromCode('ZAR'), Currency.zar);
      expect(Currency.fromCode('GBP'), Currency.gbp);
      expect(Currency.fromCode('CHF'), Currency.chf);
      expect(Currency.fromCode('SEK'), Currency.sek);
    });

    test('fromCode falls back to EUR for unknown codes', () {
      expect(Currency.fromCode(''), Currency.eur);
      expect(Currency.fromCode('XYZ'), Currency.eur);
    });

    test('symbols are correct', () {
      expect(Currency.eur.symbol, '€');
      expect(Currency.usd.symbol, '\$');
      expect(Currency.gbp.symbol, '£');
      expect(Currency.jpy.symbol, '¥');
      expect(Currency.chf.symbol, 'CHF');
      expect(Currency.nok.symbol, 'NOK');
      expect(Currency.sek.symbol, 'SEK');
      expect(Currency.zar.symbol, 'ZAR');
    });

    test('codes are correct', () {
      expect(Currency.eur.code, 'EUR');
      expect(Currency.usd.code, 'USD');
      expect(Currency.nok.code, 'NOK');
      expect(Currency.zar.code, 'ZAR');
    });
  });

  group('PdfExporter.fmtDim', () {
    test('integer values are rendered without decimal point', () {
      expect(PdfExporter.fmtDim(0.0), '0');
      expect(PdfExporter.fmtDim(1.0), '1');
      expect(PdfExporter.fmtDim(30.0), '30');
      expect(PdfExporter.fmtDim(100.0), '100');
      expect(PdfExporter.fmtDim(1000.0), '1000');
    });

    test('fractional values show one decimal place', () {
      expect(PdfExporter.fmtDim(0.5), '0.5');
      expect(PdfExporter.fmtDim(10.5), '10.5');
      expect(PdfExporter.fmtDim(99.9), '99.9');
    });

    test('values round to one decimal place', () {
      expect(PdfExporter.fmtDim(1.14), '1.1');
      expect(PdfExporter.fmtDim(1.16), '1.2');
    });

    test('value that rounds to an integer drops the decimal', () {
      // 1.04 toStringAsFixed(1) → "1.0"; regex strips trailing zero and dot → "1"
      expect(PdfExporter.fmtDim(1.04), '1');
    });
  });
}
