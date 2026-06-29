import 'package:flutter/material.dart';
import '../api_service.dart';

class ValidationAnalyticsScreen extends StatefulWidget {
  const ValidationAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<ValidationAnalyticsScreen> createState() => _ValidationAnalyticsScreenState();
}

class _ValidationAnalyticsScreenState extends State<ValidationAnalyticsScreen> {
  final _apiService = ApiService();
  final _matrixController = TextEditingController();
  bool _isLoading = false;

  // Question lists for usability validation
  final List<String> _questions = [
    "Q1: Woundify is easy to use for bacterial identification.",
    "Q2: The AI risk prediction outcomes are clear and easy to interpret.",
    "Q3: The OCR scan correctly extracts data from laboratory reports.",
    "Q4: The clinical recommendations are helpful for treatment decision-making.",
    "Q5: I would recommend Woundify to other clinical practitioners."
  ];

  double? _cronbachAlpha;
  String _alphaInterpretation = '';
  int _kItems = 0;
  int _sampleSize = 0;

  List<Map<String, dynamic>> _itemValidity = [];
  bool _validated = false;

  @override
  void dispose() {
    _matrixController.dispose();
    super.dispose();
  }

  List<List<double>> _parseMatrix(String raw) {
    final rows = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (rows.isEmpty) {
      throw Exception('Matrix respon wajib diisi.');
    }

    final matrix = <List<double>>[];
    for (final row in rows) {
      final cols = row
          .split(',')
          .map((col) => col.trim())
          .where((col) => col.isNotEmpty)
          .toList();

      if (cols.length != _questions.length) {
        throw Exception('Setiap baris wajib berisi ${_questions.length} skor.');
      }

      final parsed = cols.map((col) => double.parse(col)).toList();
      matrix.add(parsed);
    }

    return matrix;
  }

  void _runValidation() async {
    late List<List<double>> matrix;
    try {
      matrix = _parseMatrix(_matrixController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Calculate Cronbach Alpha (Reliability)
      final reliabilityRes = await _apiService.calculateCronbachAlpha(matrix);
      // 2. Calculate Pearson Validity (Item-Total Correlation)
      final validityRes = await _apiService.calculatePearsonValidity(matrix);

      setState(() {
        _cronbachAlpha = (reliabilityRes['alpha'] as num).toDouble();
        _alphaInterpretation = reliabilityRes['interpretation'] ?? '';
        _kItems = reliabilityRes['k_items'] ?? 5;
        _sampleSize = reliabilityRes['respondents'] ?? matrix.length;
        
        final List<dynamic> itemsList = validityRes['items'] ?? [];
        _itemValidity = itemsList.map((item) => Map<String, dynamic>.from(item)).toList();
        
        _validated = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Validation error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validasi Produk & Kegunaan', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E88E5),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paket Validasi Produk Woundify',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Melakukan validasi reliabilitas (Alpha Cronbach) dan pengujian validitas butir (korelasi Pearson) pada survei kebergunaan sistem.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Survey details card
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFBBDEFB)),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Item Kuesioner Kebergunaan Aktif (Model TAM)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          ..._questions.map((q) => Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Text(q, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              )),
                          const SizedBox(height: 12),
                          const Text(
                            'Masukkan data survei nyata (format CSV per baris). Contoh: 5,4,4,5,5',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF1E88E5)),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _matrixController,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Matrix respon (tanpa dummy)',
                              hintText: '5,4,4,5,5\n4,3,4,4,4',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Trigger button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _runValidation,
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Jalankan Validasi Statistik', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF1E88E5).withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_validated) ...[
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 12),
                    const Text('1. Indeks Reliabilitas (Alpha Cronbach)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _cronbachAlpha! >= 0.7 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          foregroundColor: _cronbachAlpha! >= 0.7 ? const Color(0xFF43A047) : const Color(0xFFD32F2F),
                          child: Icon(_cronbachAlpha! >= 0.7 ? Icons.gpp_good : Icons.gpp_bad),
                        ),
                        title: Text(
                          'Skor Alpha: ${_cronbachAlpha!.toStringAsFixed(3)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        subtitle: Text('Status: $_alphaInterpretation', style: const TextStyle(color: Colors.black54)),
                        trailing: Text('k = $_kItems item', style: const TextStyle(color: Color(0xFF1E88E5))),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('2. Matriks Validitas Item (Nilai r Pearson)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _itemValidity.length,
                      itemBuilder: (context, index) {
                        final item = _itemValidity[index];
                        final rVal = (item['r_xy'] as num).toDouble();
                        final isValid = item['is_valid'] as bool;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE2E8F0))),
                          child: ListTile(
                            dense: true,
                            title: Text('Pertanyaan Q${item['item_index']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            subtitle: Text('r_xy = ${rVal.toStringAsFixed(3)} (p-value: ${(item['p_value'] as num).toStringAsExponential(2)})', style: const TextStyle(color: Colors.black54)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isValid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isValid ? 'VALID' : 'TIDAK VALID',
                                style: TextStyle(
                                  color: isValid ? const Color(0xFF43A047) : const Color(0xFFD32F2F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ]
                ],
              ),
            ),
    );
  }
}
