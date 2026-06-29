import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_service.dart';

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({Key? key}) : super(key: key);

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _historyController = TextEditingController();

  String _gender = 'MALE';
  String _diabetesType = 'TYPE_2';
  DateTime? _birthDate;
  bool _isLoading = false;

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 50)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((selectedDate) {
      if (selectedDate == null) return;
      setState(() => _birthDate = selectedDate);
    });
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate() || _birthDate == null) {
      if (_birthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap pilih tanggal lahir.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.createPatient(
        _nameController.text.trim(),
        _gender,
        _birthDate!,
        _diabetesType,
        _historyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pasien berhasil didaftarkan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pendaftaran gagal: ${e.toString()}')),
        );
      }
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
        title: const Text('Registrasi Pasien', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E88E5),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Pasien',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        labelStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF1E88E5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Harap masukkan nama pasien';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Gender selection
                    const Text('Jenis Kelamin', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'MALE',
                          groupValue: _gender,
                          activeColor: const Color(0xFF1E88E5),
                          onChanged: (value) => setState(() => _gender = value!),
                        ),
                        const Text('Laki-laki', style: TextStyle(color: Colors.black87)),
                        const SizedBox(width: 24),
                        Radio<String>(
                          value: 'FEMALE',
                          groupValue: _gender,
                          activeColor: const Color(0xFF1E88E5),
                          onChanged: (value) => setState(() => _gender = value!),
                        ),
                        const Text('Perempuan', style: TextStyle(color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Birth date picker
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tileColor: Colors.white,
                      leading: const Icon(Icons.calendar_month, color: Color(0xFF1E88E5)),
                      title: Text(
                        _birthDate == null
                            ? 'Pilih Tanggal Lahir'
                            : 'Tanggal Lahir: ${DateFormat('yyyy-MM-dd').format(_birthDate!)}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down, color: Color(0xFF1E88E5)),
                      onTap: _presentDatePicker,
                    ),
                    const SizedBox(height: 16),
                    // Diabetes Type
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.white,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _diabetesType,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Klasifikasi Diabetes',
                          labelStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: const Icon(Icons.medical_services_outlined, color: Color(0xFF1E88E5)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TYPE_1', child: Text('Diabetes Tipe 1', style: TextStyle(color: Colors.black87))),
                          DropdownMenuItem(value: 'TYPE_2', child: Text('Diabetes Tipe 2', style: TextStyle(color: Colors.black87))),
                          DropdownMenuItem(value: 'GESTATIONAL', child: Text('Diabetes Gestasional', style: TextStyle(color: Colors.black87))),
                          DropdownMenuItem(value: 'OTHER', child: Text('Lainnya / Sekunder', style: TextStyle(color: Colors.black87))),
                        ],
                        onChanged: (value) => setState(() => _diabetesType = value!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Medical History
                    TextFormField(
                      controller: _historyController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        labelText: 'Riwayat Medis Luka & Komorbiditas',
                        labelStyle: const TextStyle(color: Colors.black54),
                        alignLabelWithHint: true,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF1E88E5).withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Registrasi Pasien', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
