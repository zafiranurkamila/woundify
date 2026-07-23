import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models.dart';

class PdfReportService {
  static const PdfColor _blue = PdfColor.fromInt(0xFF1E88E5);
  static const PdfColor _darkSlate = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _gray = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _lightBlue = PdfColor.fromInt(0xFFE3F2FD);
  static const PdfColor _green = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _red = PdfColor.fromInt(0xFFC62828);

  static List<MapEntry<String, String>> _parseSusceptibility(String raw) {
    if (raw.trim().isEmpty || raw.trim() == '{}') return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.entries.map((e) => MapEntry(e.key, '${e.value}'.toUpperCase())).toList();
      }
    } catch (_) {
      // fall through to plain-text parsing
    }
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.contains(':'))
        .map((item) {
          final parts = item.split(':');
          return MapEntry(parts.first.trim(), parts.sublist(1).join(':').trim().toUpperCase());
        })
        .toList();
  }

  static Future<Uint8List> _buildDocument(LabResult labResult) async {
    final doc = pw.Document();
    final pred = labResult.prediction;
    final susceptibility = _parseSusceptibility(labResult.antibioticSusceptibility);
    final susceptible = susceptibility.where((e) => e.value.contains('SUSCEPTIBLE') || e.value == 'S').toList();
    final resistant = susceptibility.where((e) => e.value.contains('RESIST') || e.value == 'R').toList();
    final generatedAt = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _blue, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('WOUNDIFY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _blue)),
              pw.Text('Laporan Analisis Mikrobiologi AI', style: const pw.TextStyle(fontSize: 11, color: _gray)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Dihasilkan otomatis oleh Woundify pada ${_formatDateTime(generatedAt)} — Halaman ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _gray),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 16),
          _sectionTitle('Data Pasien & Pemeriksaan'),
          _kv('Nama Pasien', labResult.patientName),
          _kv('Tanggal Pemeriksaan', _formatDateTime(labResult.createdAt)),
          _kv('Diperiksa oleh', labResult.checkedByName),
          pw.SizedBox(height: 16),

          _sectionTitle('Temuan Mikrobiologis (Input)'),
          _kv('Pewarnaan Gram', labResult.gramStain.replaceAll('_', ' ')),
          _kv('Morfologi Koloni', labResult.colonyMorphology.isEmpty ? '-' : labResult.colonyMorphology),
          _kv('Indole', labResult.imvicIndole),
          _kv('Methyl Red', labResult.imvicMethylRed),
          _kv('Voges-Proskauer', labResult.imvicVogesProskauer),
          _kv('Citrate', labResult.imvicCitrate),
          if (labResult.macconkey != null) _kv('MacConkey', labResult.macconkey!.replaceAll('_', ' ')),
          _kv('Hasil Kultur', labResult.cultureResult.isEmpty ? '-' : labResult.cultureResult),
          pw.SizedBox(height: 16),

          if (pred != null) ...[
            _sectionTitle('Prediksi AI'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: _lightBlue, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(pred.predictedBacteria, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _blue)),
                  pw.SizedBox(height: 4),
                  pw.Text('Tingkat keyakinan: ${(pred.confidenceScore * 100).toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 10, color: _darkSlate)),
                  if (pred.lowConfidence)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        'PERINGATAN: keyakinan identifikasi rendah, sarankan konfirmasi kultur.',
                        style: pw.TextStyle(fontSize: 9, color: _red, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            if (pred.differentialDiagnosis.isNotEmpty) ...[
              pw.Text('Diferensial Diagnosis (Top 3)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _darkSlate)),
              pw.SizedBox(height: 4),
              ...pred.differentialDiagnosis.map(
                (d) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(
                    '${d.bacteria}: ${(d.probability * 100).toStringAsFixed(0)}%',
                    style: const pw.TextStyle(fontSize: 10, color: _darkSlate),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            if (pred.reasoning.isNotEmpty) ...[
              pw.Text('Alasan Prediksi', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _darkSlate)),
              pw.SizedBox(height: 4),
              ...pred.reasoning.map(
                (r) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text('• $r', style: const pw.TextStyle(fontSize: 10, color: _darkSlate)),
                ),
              ),
              pw.SizedBox(height: 10),
            ],

            pw.Text('Penilaian Risiko', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _darkSlate)),
            pw.SizedBox(height: 4),
            _kv('Risiko Infeksi', pred.infectionRiskLevel),
            _kv('Risiko Luka Kronis', pred.chronicRiskLevel),
            _kv('Risiko Komplikasi', pred.complicationRiskLevel),
            pw.SizedBox(height: 10),

            pw.Text('Panduan Terapi Suportif', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _darkSlate)),
            pw.SizedBox(height: 4),
            pw.Text(pred.recommendations, style: const pw.TextStyle(fontSize: 10, color: _darkSlate)),
            pw.SizedBox(height: 16),

            if (susceptibility.isNotEmpty) ...[
              _sectionTitle('Antibiogram'),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: _drugColumn('Rentan', susceptible, _green)),
                  pw.SizedBox(width: 16),
                  pw.Expanded(child: _drugColumn('Resisten', resistant, _red)),
                ],
              ),
              pw.SizedBox(height: 16),
            ],
          ] else
            pw.Text('Belum ada hasil prediksi AI untuk pemeriksaan ini.', style: const pw.TextStyle(fontSize: 10, color: _gray)),

          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFFF1F5F9), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text(
              pred?.disclaimer ?? 'Alat bantu keputusan klinis, bukan diagnosis. Konfirmasi dengan kultur laboratorium.',
              style: pw.TextStyle(fontSize: 9, color: _gray, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _blue)),
    );
  }

  static pw.Widget _kv(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 140, child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _gray))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10, color: _darkSlate))),
        ],
      ),
    );
  }

  static pw.Widget _drugColumn(String title, List<MapEntry<String, String>> drugs, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 4),
        if (drugs.isEmpty)
          pw.Text('-', style: const pw.TextStyle(fontSize: 10, color: _gray))
        else
          ...drugs.map((d) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(d.key, style: const pw.TextStyle(fontSize: 10, color: _darkSlate)),
              )),
      ],
    );
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  /// Opens the native share/print sheet with the generated clinical report PDF.
  static Future<void> shareReport(LabResult labResult) async {
    final bytes = await _buildDocument(labResult);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'woundify-laporan-${labResult.patientName.replaceAll(' ', '_')}.pdf',
    );
  }
}
