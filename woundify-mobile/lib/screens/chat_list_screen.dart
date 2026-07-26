import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';
import 'chat_thread_screen.dart';

/// Daftar kontak (semua pengguna lintas role) untuk memulai chat.
class ChatListScreen extends StatefulWidget {
  final User currentUser;
  const ChatListScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _apiService = ApiService();
  List<DoctorSummary> _contacts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final all = await _apiService.getReferralTargets();
      if (!mounted) return;
      setState(() {
        _contacts = all.where((c) => c.id != widget.currentUser.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'DOCTOR':
        return 'Dokter';
      case 'NURSE':
        return 'Perawat';
      case 'RESEARCHER':
        return 'Peneliti';
      case 'LAB_ADMIN':
        return 'Admin Laboratorium';
      case 'HOSPITAL_ADMIN':
        return 'Admin Rumah Sakit';
      default:
        return role;
    }
  }

  String _display(DoctorSummary c) {
    final name = c.name.trim();
    if (c.role.toUpperCase() == 'DOCTOR' && !name.toLowerCase().startsWith('dr')) {
      return 'dr. $name';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _contacts.isEmpty
                  ? const Center(
                      child: Text('Belum ada pengguna lain untuk diajak chat.',
                          style: TextStyle(color: Color(0xFF64748B))))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _contacts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = _contacts[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1E88E5),
                              child: Text(
                                c.name.isNotEmpty ? c.name.substring(0, 1).toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(_display(c), style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(_roleLabel(c.role)),
                            trailing: const Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF1E88E5)),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatThreadScreen(currentUser: widget.currentUser, peer: c),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
