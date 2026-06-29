import 'package:flutter/material.dart';
import '../models.dart';
import '../api_service.dart';

class EpidemiologyTrendsScreen extends StatefulWidget {
  const EpidemiologyTrendsScreen({Key? key}) : super(key: key);

  @override
  State<EpidemiologyTrendsScreen> createState() => _EpidemiologyTrendsScreenState();
}

class _EpidemiologyTrendsScreenState extends State<EpidemiologyTrendsScreen> {
  final _apiService = ApiService();
  List<EpidemiologyRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEpidemiology();
  }

  void _fetchEpidemiology() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getEpidemiologyData();
      setState(() {
        _records = data;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _records = [];
        _errorMessage = 'Data epidemiologi tidak tersedia: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group records by region
    final Map<String, List<EpidemiologyRecord>> regionalData = {};
    for (var r in _records) {
      regionalData.putIfAbsent(r.region, () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tren Epidemiologi',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E88E5),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : RefreshIndicator(
              color: const Color(0xFF1E88E5),
              backgroundColor: Colors.white,
              onRefresh: () async => _fetchEpidemiology(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Peta Surveilans Infeksi Bakteri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Mengagregasi data lab untuk melacak kepadatan transmisi dan pola resistensi antibiotik.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Data epidemiologi belum tersedia. Tarik ke bawah untuk memuat ulang.',
                                style: TextStyle(color: Color(0xFFC62828), fontSize: 12, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Case Study/Clinical Insights Card
                    Card(
                      elevation: 4,
                      shadowColor: const Color(0xFF1E88E5).withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFBBDEFB), width: 1.5),
                      ),
                      color: const Color(0xFFE3F2FD),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics_rounded, color: Color(0xFF1565C0)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Insight Tren Kedaerahan (Studi Kasus)',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: Color(0xFF90CAF9)),
                            const Text(
                              'Analisis Pola Diet & Wilayah (Jakarta vs Malang):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D47A1)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Data menunjukkan kasus infeksi bakteri di Jakarta jauh lebih padat dibandingkan kota kecil seperti Malang. Berdasarkan temuan klinis, perbedaan tren kedaerahan ini dapat dipengaruhi faktor gaya hidup perkotaan, di mana konsumsi glukosa/makanan manis di Jakarta lebih tinggi dibanding Malang yang memiliki pola makan pedesaan/lokal yang lebih segar dan sehat.',
                              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF1A237E)),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Rekomendasi Langkah Intervensi Preventif:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D47A1)),
                            ),
                            const SizedBox(height: 6),
                            const BulletItem(
                              text: 'Pasien Jakarta: Monitoring ketat asupan glukosa, edukasi pengurangan makanan manis, serta koordinasi dengan supermarket untuk pelabelan informasi glukosa.',
                            ),
                            const BulletItem(
                              text: 'Pasien Malang: Intervensi difokuskan pada pembersihan luka higienis dan perawatan klinis primer, dikarenakan faktor metabolik asupan gula cenderung lebih rendah.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (regionalData.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Belum ada data epidemiologi yang tersimpan di backend.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      )
                    else
                    // Regional breakdown
                    ...regionalData.entries.map((entry) {
                      final region = entry.key;
                      final records = entry.value;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFBBDEFB), width: 1.0),
                        ),
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.04),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Color(0xFF1E88E5)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Wilayah: $region',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: Colors.black12),
                              
                              // Visual bar charts for cases
                              const Text('Kepadatan Infeksi (Kasus Terisolasi)', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 12),
                              ...records.map((r) {
                                final maxCases = 150.0;
                                final widthPercent = (r.cases / maxCases).clamp(0.0, 1.0);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.bacteriaName,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFF1E293B)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${r.cases} kasus', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Stack(
                                        children: [
                                          Container(
                                            height: 12,
                                            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(6)),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: widthPercent,
                                            child: Container(
                                              height: 12,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 16),
                              // Visual line representation of resistance rate
                              const Text('Tingkat Resistensi Multidrug (MDR) Diprediksi', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                              const SizedBox(height: 12),
                              ...records.map((r) {
                                final ratePercent = r.resistanceRate.clamp(0.0, 1.0);
                                final color = ratePercent > 0.30 ? const Color(0xFFD32F2F) : const Color(0xFFE65100);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Status resistensi ${r.bacteriaName}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('${(r.resistanceRate * 100).toStringAsFixed(0)}% MDR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Stack(
                                        children: [
                                          Container(
                                            height: 8,
                                            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: ratePercent,
                                            child: Container(
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
    );
  }
}

class BulletItem extends StatelessWidget {
  final String text;
  const BulletItem({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF1A237E)),
            ),
          ),
        ],
      ),
    );
  }
}
