import 'package:flutter/material.dart';
import '../api_service.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _strController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  String _selectedRole = 'NURSE';

  // Pilihan pekerjaan: value = enum backend, label = teks Indonesia
  static const Map<String, String> _roles = {
    'NURSE': 'Perawat',
    'DOCTOR': 'Dokter',
    'RESEARCHER': 'Peneliti',
    'LAB_ADMIN': 'Admin Laboratorium',
    'HOSPITAL_ADMIN': 'Admin Rumah Sakit',
  };

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _strController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.register(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        _selectedRole,
        strNumber: _selectedRole == 'DOCTOR' ? _strController.text.trim() : null,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: _emailController.text,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Akun Woundify'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text('Buat akun baru untuk menggunakan Woundify'),
              SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Nama tidak boleh kosong' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Email tidak boleh kosong';
                  if (!value!.contains('@')) return 'Email tidak valid';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) =>
                    (value?.length ?? 0) < 6 ? 'Password minimal 6 karakter' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: _roles.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
                decoration: InputDecoration(
                  labelText: 'Pekerjaan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              if (_selectedRole == 'DOCTOR') ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _strController,
                  decoration: InputDecoration(
                    labelText: 'Nomor STR / SIP',
                    helperText: 'Wajib untuk verifikasi tenaga medis (Dokter)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.verified_user),
                  ),
                  validator: (value) {
                    if (_selectedRole == 'DOCTOR' && (value?.trim().isEmpty ?? true)) {
                      return 'Nomor STR/SIP wajib diisi untuk Dokter';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Daftar'),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun? '),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
