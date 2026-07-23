import 'dart:convert';

import 'package:flutter/material.dart';
import '../models.dart';
import '../services/pdf_report_service.dart';
import '../utils/notification_helper.dart';

class PredictionResultScreen extends StatelessWidget {
  final LabResult labResult;
  const PredictionResultScreen({Key? key, required this.labResult}) : super(key: key);

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFD32F2F); // Deep Red
      case 'MEDIUM':
        return const Color(0xFFE65100); // Deep Amber/Orange
      case 'LOW':
      default:
        return const Color(0xFF1E88E5); // Theme Blue
    }
  }

  Widget _buildRiskCard(String title, String level) {
    final color = _getRiskColor(level);
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                level,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pred = labResult.prediction;

    if (pred == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Analisis')),
        body: const Center(child: Text('Tidak ada hasil analisis AI yang tersedia.', style: TextStyle(color: Color(0xFF1E293B)))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Analisis AI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Bagikan Laporan PDF',
            onPressed: () async {
              try {
                await PdfReportService.shareReport(labResult);
              } catch (e) {
                if (context.mounted) {
                  NotificationHelper.error(context, 'Gagal membuat laporan PDF: $e', title: 'PDF Gagal Dibuat');
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header prediction card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFBBDEFB), width: 1.0),
              ),
              color: Colors.white,
              shadowColor: Colors.black.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PREDIKSI BAKTERI PENYEBAB', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Text(
                      pred.predictedBacteria,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tingkat Keyakinan Identifikasi', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                        Text('${(pred.confidenceScore * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                        ),
                        FractionallySizedBox(
                          widthFactor: pred.confidenceScore,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),

            if (pred.lowConfidence) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  border: Border.all(color: const Color(0xFFE65100).withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Keyakinan identifikasi rendah. Data lab belum cukup untuk satu kesimpulan tunggal — sarankan konfirmasi kultur sebelum menentukan terapi.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF7A4100), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (pred.differentialDiagnosis.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diferensial Diagnosis (Top 3)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      ...pred.differentialDiagnosis.map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(d.bacteria, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF1E293B))),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Stack(
                                    children: [
                                      Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4))),
                                      FractionallySizedBox(
                                        widthFactor: d.probability.clamp(0.0, 1.0),
                                        child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFF1E88E5), borderRadius: BorderRadius.circular(4))),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${(d.probability * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],

            if (pred.reasoning.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alasan Prediksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                      const SizedBox(height: 12),
                      ...pred.reasoning.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: Color(0xFF1E88E5)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(r, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Multi-dimensional Risk Profile
            const Text('Penilaian Risiko AI Multi-Dimensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildRiskCard('RISIKO INFEKSI', pred.infectionRiskLevel)),
                Expanded(child: _buildRiskCard('LUKA KRONIS', pred.chronicRiskLevel)),
                Expanded(child: _buildRiskCard('KOMPLIKASI', pred.complicationRiskLevel)),
              ],
            ),
            const SizedBox(height: 24),

            // Clinical Recommendation Box
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Color(0xFF1E88E5)),
                        const SizedBox(width: 8),
                        const Text(
                          'Panduan Terapi Suportif',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E88E5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pred.recommendations,
                      style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Antibiogram
            const Text('Matriks Kerentanan Antibiogram', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prediksi Afinitas Antibiotik berdasarkan profil bakteri:',
                      style: TextStyle(color: Color(0xFF475569), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(4)),
                                child: const Text('OBAT RENTAN', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              const SizedBox(height: 12),
                              ..._buildDrugList(labResult.antibioticSusceptibility, true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(4)),
                                child: const Text('OBAT RESISTEN', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                              const SizedBox(height: 12),
                              ..._buildDrugList(labResult.antibioticSusceptibility, false),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Medical disclaimer
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF475569)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pred.disclaimer,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Export PDF button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await PdfReportService.shareReport(labResult);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal membuat laporan PDF: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Unduh / Bagikan Laporan PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Back button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                  foregroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Kembali ke Dasbor', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDrugList(String raw, bool getSusceptible) {
    final entries = _parseAntibioticMap(raw)
        .where((entry) {
          final val = entry.value.toUpperCase();
          final isSusceptible = val.contains('SUSCEPTIBLE') || val.trim() == 'S';
          final isResistant = val.contains('RESIST') || val.trim() == 'R';
          return getSusceptible ? isSusceptible : isResistant;
        })
        .toList();

    if (entries.isEmpty) {
      return const [
        Text(
          '-',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      ];
    }

    return entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Icon(
              getSusceptible ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: getSusceptible ? const Color(0xFF1E88E5) : const Color(0xFFD32F2F),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${entry.key} (${entry.value})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<MapEntry<String, String>> _parseAntibioticMap(String raw) {
    if (raw.trim().isEmpty || raw.trim() == '{}') {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.entries
            .map((entry) => MapEntry(entry.key, '${entry.value}'))
            .toList();
      }
    } catch (_) {
      // Fallback to plain text format.
    }

    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.contains(':'))
        .map((item) {
          final parts = item.split(':');
          return MapEntry(parts.first.trim(), parts.sublist(1).join(':').trim());
        })
        .toList();
  }
}
