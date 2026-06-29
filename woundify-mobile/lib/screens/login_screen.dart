import 'package:flutter/material.dart';
import '../api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen(currentUser: user)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative blobs (top-left and bottom-right), like the reference design
          Positioned(
            top: -60,
            left: -60,
            child: _blob(180, const Color(0xFFE3F2FD)),
          ),
          Positioned(
            top: 20,
            left: -90,
            child: _blob(120, const Color(0xFFBBDEFB).withOpacity(0.6)),
          ),
          Positioned(
            bottom: -70,
            right: -70,
            child: _blob(200, const Color(0xFFE3F2FD)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Image.asset('assets/logo.png', height: 120, errorBuilder: (context, error, stackTrace) => const Icon(Icons.healing_rounded, size: 120, color: Color(0xFF1E88E5))),
                      const SizedBox(height: 12),
                      const Text(
                        'WOUNDIFY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E88E5),
                          letterSpacing: 1.2,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Selamat Datang',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Masuk untuk memantau risiko infeksi bakteri pada luka kaki diabetik',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 28),
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC2185B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC2185B).withOpacity(0.5)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFC2185B), fontSize: 13),
                          ),
                        ),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          labelText: 'Alamat Email',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1E88E5)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap masukkan email Anda';
                          }
                          if (!value.contains('@')) {
                            return 'Masukkan alamat email yang valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1E88E5)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF94A3B8)),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap masukkan kata sandi Anda';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(0xFF1E88E5).withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.login_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: Colors.white,
                              title: const Text('Catatan Registrasi', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                              content: const Text(
                                'Untuk membuat akun baru, silakan hubungi administrator sistem.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          );
                        },
                        child: const Text('Belum punya akun? Hubungi Admin', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
