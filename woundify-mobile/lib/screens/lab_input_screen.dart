import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../api_service.dart';
import 'prediction_result_screen.dart';

class LabInputScreen extends StatefulWidget {
  final Patient? preSelectedPatient;
  const LabInputScreen({Key? key, this.preSelectedPatient}) : super(key: key);

  @override
  State<LabInputScreen> createState() => _LabInputScreenState();
}

class _LabInputScreenState extends State<LabInputScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  List<Patient> _patients = [];
  Patient? _selectedPatient;
  File? _selectedImage;

  // Lab parameters
  final _morphologyController = TextEditingController();
  final _cultureResultController = TextEditingController();
  final _susceptibilityController = TextEditingController();
  final _ocrRawController = TextEditingController();

  String _gramStain = 'GRAM_NEGATIVE';
  String _indole = 'NEGATIVE';
  String _mr = 'NEGATIVE';
  String _vp = 'NEGATIVE';
  String _citrate = 'NEGATIVE';
  String _macconkey = 'LACTOSE_FERMENTER';
  String _colonyTexture = 'MUCOID';
  String _colonySize = 'MEDIUM';
  String _h2s = 'NEGATIVE';
  String _motil = 'NEGATIVE';
  String _urease = 'NEGATIVE';
  int _tsi = 3; // 0=Acid/Acid+Gas, 1=Acid/Acid no gas, 2=Acid/Alkali+H2S, 3=Alkali/Alkali
  int _emb = 0; // 0=Colorless, 1=Merah Muda, 2=Hijau Metalik
  String _nas = 'NEGATIVE';
  bool _noSignificantGrowth = false;

  bool _isLoading = false;
  bool _isOcrLoading = false;

  String get _draftKey =>
      'lab_draft_${widget.preSelectedPatient?.id ?? 'general'}';

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.preSelectedPatient;
    if (_selectedPatient == null) {
      _fetchPatients();
    }
    _restoreDraft();
    _attachDraftListeners();
  }

  @override
  void dispose() {
    _morphologyController.dispose();
    _cultureResultController.dispose();
    _susceptibilityController.dispose();
    _ocrRawController.dispose();
    super.dispose();
  }

  void _attachDraftListeners() {
    _morphologyController.addListener(_saveDraft);
    _cultureResultController.addListener(_saveDraft);
    _susceptibilityController.addListener(_saveDraft);
    _ocrRawController.addListener(_saveDraft);
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_draftKey, [
      _selectedPatient?.id ?? '',
      _morphologyController.text,
      _cultureResultController.text,
      _susceptibilityController.text,
      _ocrRawController.text,
      _gramStain,
      _indole,
      _mr,
      _vp,
      _citrate,
      _macconkey,
      _colonyTexture,
      _colonySize,
      _h2s,
      _motil,
      _urease,
      _tsi.toString(),
      _emb.toString(),
      _nas,
    ]);
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_draftKey);
    if (saved == null || saved.length < 19) {
      return;
    }

    setState(() {
      _morphologyController.text = saved[1];
      _cultureResultController.text = saved[2];
      _susceptibilityController.text = saved[3];
      _ocrRawController.text = saved[4];
      _gramStain = saved[5];
      _indole = saved[6];
      _mr = saved[7];
      _vp = saved[8];
      _citrate = saved[9];
      _macconkey = saved[10];
      _colonyTexture = saved[11];
      _colonySize = saved[12];
      _h2s = saved[13];
      _motil = saved[14];
      _urease = saved[15];
      _tsi = int.tryParse(saved[16]) ?? 3;
      _emb = int.tryParse(saved[17]) ?? 0;
      _nas = saved[18];
    });
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  void _fetchPatients() async {
    try {
      final list = await _apiService.getPatients();
      setState(() {
        _patients = list;
        if (_selectedPatient == null && list.isNotEmpty) {
          _selectedPatient = list.first;
        }
      });
      _saveDraft();
    } catch (e) {
      // Log error
    }
  }

  void _triggerOcr(File file) async {
    setState(() => _isOcrLoading = true);
    try {
      final data = await _apiService.scanLabSheetOcr(file);
      
      setState(() {
        _gramStain = data['gram_stain'] ?? 'GRAM_NEGATIVE';
        _indole = data['imvic_indole'] ?? 'NEGATIVE';
        _mr = data['imvic_methyl_red'] ?? 'NEGATIVE';
        _vp = data['imvic_voges_proskauer'] ?? 'NEGATIVE';
        _citrate = data['imvic_citrate'] ?? 'NEGATIVE';
        _macconkey = data['macconkey'] ?? 'LACTOSE_FERMENTER';
        _h2s = data['h2s'] ?? 'NEGATIVE';
        _motil = data['motil'] ?? 'NEGATIVE';
        _urease = data['urease'] ?? 'NEGATIVE';
        _tsi = (data['tsi'] is int) ? data['tsi'] : 3;
        _emb = (data['emb'] is int) ? data['emb'] : 0;
        _nas = data['nas'] ?? 'NEGATIVE';
        _colonyTexture = data['colony_texture'] ?? 'MUCOID';
        _colonySize = data['colony_size'] ?? 'MEDIUM';
        _morphologyController.text = data['colony_morphology'] ?? '';
        _cultureResultController.text = data['culture_result'] ?? '';
        _ocrRawController.text = 'OCR processed from ${file.path.split('/').last}';
        
        if (data['antibiotic_susceptibility'] != null) {
          _susceptibilityController.text = data['antibiotic_susceptibility'].toString();
        }
      });
      _saveDraft();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OCR Selesai! Parameter berhasil diisi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses OCR: ${e.toString()}')),
      );
    } finally {
      setState(() => _isOcrLoading = false);
    }
  }

  void _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;
    
    final file = File(pickedFile.path);
    setState(() => _selectedImage = file);
    _saveDraft();
    _triggerOcr(file);
  }

  void _submitAnalysis() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih pasien terlebih dahulu.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final payload = {
        'patientId': _selectedPatient!.id,
        'woundPhotoUrl': _selectedImage?.path ?? '',
        'colonyMorphology': _morphologyController.text.trim(),
        'gramStain': _gramStain,
        'imvicIndole': _indole,
        'imvicMethylRed': _mr,
        'imvicVogesProskauer': _vp,
        'imvicCitrate': _citrate,
        'cultureResult': _cultureResultController.text.trim(),
        'antibioticSusceptibility': _susceptibilityController.text.trim().isEmpty 
            ? '{}' 
            : _susceptibilityController.text.trim(),
        'ocrRawText': _ocrRawController.text.trim(),
        'macconkey': _macconkey,
        'colonyTexture': _colonyTexture,
        'colonySize': _colonySize,
        'noSignificantGrowth': _noSignificantGrowth,
        'h2s': _h2s,
        'motil': _motil,
        'urease': _urease,
        'tsi': _tsi,
        'emb': _emb,
        'nas': _nas,
      };

      final result = await _apiService.saveLabResult(payload);
      await _clearDraft();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PredictionResultScreen(labResult: result),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analisis gagal: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Data Mikrobiologi', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E88E5),
        elevation: 0,
      ),
      body: _isLoading || _isOcrLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1E88E5)),
                  const SizedBox(height: 16),
                  Text(
                    _isOcrLoading ? 'Gemini AI sedang membaca lembar lab...' : 'Menjalankan AI Pengenalan Bakteri...',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Selection
                    const Text('Pasien', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    if (widget.preSelectedPatient != null)
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFBBDEFB))),
                        elevation: 2,
                        child: ListTile(
                          title: Text(widget.preSelectedPatient!.name, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                          subtitle: Text('Tipe Diabetes: ${widget.preSelectedPatient!.diabetesType.replaceAll('_', ' ')}', style: const TextStyle(color: Colors.black54)),
                          leading: const Icon(Icons.person, color: Color(0xFF1E88E5)),
                        ),
                      )
                    else
                      Theme(
                        data: Theme.of(context).copyWith(canvasColor: Colors.white),
                        child: DropdownButtonFormField<Patient>(
                          value: _selectedPatient,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Pilih Pasien',
                            hintStyle: const TextStyle(color: Colors.black54),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2)),
                          ),
                          items: _patients.map((p) {
                            return DropdownMenuItem(value: p, child: Text(p.name, style: const TextStyle(color: Colors.black87)));
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedPatient = value);
                            _saveDraft();
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // OCR Scan Button
                    const Text('Deteksi Lembar Lab (OCR)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Kamera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E88E5),
                              elevation: 2,
                              side: const BorderSide(color: Color(0xFFBBDEFB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galeri'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1565C0),
                              elevation: 2,
                              side: const BorderSide(color: Color(0xFFBBDEFB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 8),
                      Text('File terpilih: ${_selectedImage!.path.split('/').last}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                    const SizedBox(height: 24),

                    const Divider(color: Colors.black12),
                    const SizedBox(height: 12),
                    const Text('Temuan Mikrobiologis (Manual/Verifikasi OCR)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                    const SizedBox(height: 16),

                    // No significant growth toggle
                    Container(
                      decoration: BoxDecoration(
                        color: _noSignificantGrowth ? const Color(0xFFE8F5E9) : Colors.white,
                        border: Border.all(color: _noSignificantGrowth ? const Color(0xFF43A047) : Colors.black12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CheckboxListTile(
                        value: _noSignificantGrowth,
                        activeColor: const Color(0xFF43A047),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Tidak ada pertumbuhan bakteri bermakna',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Centang jika kultur tidak menunjukkan koloni bakteri signifikan (mis. luka sudah sembuh / flora normal kulit). Hasil Gram dan IMViC di bawah akan diabaikan.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        onChanged: (value) {
                          setState(() => _noSignificantGrowth = value ?? false);
                          _saveDraft();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gram Stain selection
                    const Text('Hasil Pewarnaan Gram', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Wrap(
                      spacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: 'GRAM_POSITIVE',
                              groupValue: _gramStain,
                              activeColor: const Color(0xFF1E88E5),
                              onChanged: (value) {
                                setState(() => _gramStain = value!);
                                _saveDraft();
                              },
                            ),
                            const Text('Gram-Positif (+)', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: 'GRAM_NEGATIVE',
                              groupValue: _gramStain,
                              activeColor: const Color(0xFFD32F2F),
                              onChanged: (value) {
                                setState(() => _gramStain = value!);
                                _saveDraft();
                              },
                            ),
                            const Text('Gram-Negatif (-)', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // IMViC Parameters
                    const Text('Panel Biokimia IMViC', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    _buildImvicSelector('Indole (I)', _indole, (val) => setState(() => _indole = val)),
                    _buildImvicSelector('Methyl Red (M)', _mr, (val) => setState(() => _mr = val)),
                    _buildImvicSelector('Voges-Proskauer (Vi)', _vp, (val) => setState(() => _vp = val)),
                    _buildImvicSelector('Citrate Utilization (C)', _citrate, (val) => setState(() => _citrate = val)),
                    const SizedBox(height: 16),

                    // Additional biochemical tests
                    const Text('Uji Biokimia Tambahan', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    _buildImvicSelector('H2S (SSA)', _h2s, (val) => setState(() => _h2s = val)),
                    _buildImvicSelector('Motilitas', _motil, (val) => setState(() => _motil = val)),
                    _buildImvicSelector('Urease', _urease, (val) => setState(() => _urease = val)),
                    _buildImvicSelector('NAS (Pertumbuhan)', _nas, (val) => setState(() => _nas = val)),
                    const SizedBox(height: 16),

                    // EMB (3 options)
                    const Text('Eosin Methylene Blue (EMB)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip('Colorless', _emb == 0, () => setState(() => _emb = 0)),
                        _buildChoiceChip('Merah Muda', _emb == 1, () => setState(() => _emb = 1)),
                        _buildChoiceChip('Hijau Metalik', _emb == 2, () => setState(() => _emb = 2)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // TSI (4 options)
                    const Text('Triple Sugar Iron (TSI)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip('Acid/Acid, Gas (+), H2S (-)', _tsi == 0, () => setState(() => _tsi = 0)),
                        _buildChoiceChip('Acid/Acid, Gas (-), H2S (-)', _tsi == 1, () => setState(() => _tsi = 1)),
                        _buildChoiceChip('Acid/Alkali, H2S (+)', _tsi == 2, () => setState(() => _tsi = 2)),
                        _buildChoiceChip('Alkali/Alkali (Non-fermenter)', _tsi == 3, () => setState(() => _tsi = 3)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // MacConkey selection
                    const Text('MacConkey Agar', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Lactose Fermenter'),
                          selected: _macconkey == 'LACTOSE_FERMENTER',
                          selectedColor: const Color(0xFFE3F2FD),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _macconkey == 'LACTOSE_FERMENTER' ? const Color(0xFF1E88E5) : Colors.black12),
                          labelStyle: TextStyle(color: _macconkey == 'LACTOSE_FERMENTER' ? const Color(0xFF1E88E5) : Colors.black54),
                          onSelected: (selected) {
                            if (selected) setState(() => _macconkey = 'LACTOSE_FERMENTER');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Non-Lactose Fermenter'),
                          selected: _macconkey == 'NON_LACTOSE_FERMENTER',
                          selectedColor: const Color(0xFFE3F2FD),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _macconkey == 'NON_LACTOSE_FERMENTER' ? const Color(0xFF1E88E5) : Colors.black12),
                          labelStyle: TextStyle(color: _macconkey == 'NON_LACTOSE_FERMENTER' ? const Color(0xFF1E88E5) : Colors.black54),
                          onSelected: (selected) {
                            if (selected) setState(() => _macconkey = 'NON_LACTOSE_FERMENTER');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Colony Texture selection
                    const Text('Tekstur Koloni', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Mucoid'),
                          selected: _colonyTexture == 'MUCOID',
                          selectedColor: const Color(0xFFE3F2FD),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _colonyTexture == 'MUCOID' ? const Color(0xFF1E88E5) : Colors.black12),
                          labelStyle: TextStyle(color: _colonyTexture == 'MUCOID' ? const Color(0xFF1E88E5) : Colors.black54),
                          onSelected: (selected) {
                            if (selected) setState(() => _colonyTexture = 'MUCOID');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Non-Mucoid'),
                          selected: _colonyTexture == 'NON_MUCOID',
                          selectedColor: const Color(0xFFE3F2FD),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _colonyTexture == 'NON_MUCOID' ? const Color(0xFF1E88E5) : Colors.black12),
                          labelStyle: TextStyle(color: _colonyTexture == 'NON_MUCOID' ? const Color(0xFF1E88E5) : Colors.black54),
                          onSelected: (selected) {
                            if (selected) setState(() => _colonyTexture = 'NON_MUCOID');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Colony Size selection
                    const Text('Ukuran Koloni', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Kecil'),
                          selected: _colonySize == 'SMALL',
                          selectedColor: const Color(0xFFE3F2FD),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _colonySize == 'SMALL' ? const Color(0xFF1E88E5) : Colors.black12),
                          labelStyle: TextStyle(color: _colonySize == 'SMALL' ? const Color(0xFF1E88E5) : Colors.black54),
                          onSelected: (selected) {
                            if (selected) setState(() => _colonySize = 'SMALL');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Sedang'),
                          selected: _colonySize == 'MEDIUM',
                          selectedColor: const Color(0xFFE3F2FD),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _colonySize == 'MEDIUM' ? const Color(0xFF1E88E5) : Colors.black12),
                          labelStyle: TextStyle(color: _colonySize == 'MEDIUM' ? const Color(0xFF1E88E5) : Colors.black54),
                          onSelected: (selected) {
                            if (selected) setState(() => _colonySize = 'MEDIUM');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Besar'),
                          selected: _colonySize == 'LARGE',
                          selectedColor: const Color(0xFFE3F2FD),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _colonySize == 'LARGE' ? const Color(0xFF1E88E5) : Colors.black12),
                          labelStyle: TextStyle(color: _colonySize == 'LARGE' ? const Color(0xFF1E88E5) : Colors.black54),
                          onSelected: (selected) {
                            if (selected) setState(() => _colonySize = 'LARGE');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _morphologyController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Morfologi Koloni (Bentuk, Hemolisis, Pigmen)',
                        labelStyle: const TextStyle(color: Colors.black54),
                        hintText: 'mis. kuning emas, sirkuler, beta-hemolitik',
                        hintStyle: const TextStyle(color: Colors.black26),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Detail morfologi wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _cultureResultController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Dugaan Mikroorganisme (Hasil Kultur)',
                        labelStyle: const TextStyle(color: Colors.black54),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _susceptibilityController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Kerentanan Antibiotik / Antibiogram',
                        labelStyle: const TextStyle(color: Colors.black54),
                        hintText: 'mis. {"Ciprofloxacin": "SUSCEPTIBLE"}',
                        hintStyle: const TextStyle(color: Colors.black26),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitAnalysis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF1E88E5).withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Verifikasi & Mulai Analisis AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFE3F2FD),
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? const Color(0xFF1E88E5) : Colors.black12),
      labelStyle: TextStyle(color: selected ? const Color(0xFF1E88E5) : Colors.black54, fontSize: 12),
      onSelected: (value) {
        if (value) onTap();
      },
    );
  }

  Widget _buildImvicSelector(String title, String currentValue, Function(String) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Positif (+)'),
                selected: currentValue == 'POSITIVE',
                selectedColor: const Color(0xFFE3F2FD),
                backgroundColor: Colors.white,
                side: BorderSide(color: currentValue == 'POSITIVE' ? const Color(0xFF1E88E5) : Colors.black12),
                labelStyle: TextStyle(color: currentValue == 'POSITIVE' ? const Color(0xFF1E88E5) : Colors.black54),
                onSelected: (selected) {
                  if (selected) onChange('POSITIVE');
                },
              ),
              ChoiceChip(
                label: const Text('Negatif (-)'),
                selected: currentValue == 'NEGATIVE',
                selectedColor: const Color(0xFFFFEBEE),
                backgroundColor: Colors.white,
                side: BorderSide(color: currentValue == 'NEGATIVE' ? const Color(0xFFD32F2F) : Colors.black12),
                labelStyle: TextStyle(color: currentValue == 'NEGATIVE' ? const Color(0xFFD32F2F) : Colors.black54),
                onSelected: (selected) {
                  if (selected) onChange('NEGATIVE');
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}
