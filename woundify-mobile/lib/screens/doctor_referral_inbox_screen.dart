import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models.dart';

class DoctorReferralInboxScreen extends StatefulWidget {
  final User currentUser;

  const DoctorReferralInboxScreen({
    Key? key,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<DoctorReferralInboxScreen> createState() =>
      _DoctorReferralInboxScreenState();
}

class _DoctorReferralInboxScreenState extends State<DoctorReferralInboxScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<ReferralRecord> _incoming = [];

  @override
  void initState() {
    super.initState();
    _loadReferrals();
  }

  Future<void> _loadReferrals() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getIncomingReferrals();
      if (!mounted) return;
      setState(() => _incoming = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil rujukan masuk: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verify(ReferralRecord referral, bool approved) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(approved ? 'Setujui Rujukan' : 'Tolak Rujukan'),
            content: TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan verifikasi (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Kirim'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await _apiService.verifyReferral(
        referralId: referral.id,
        approved: approved,
        verificationNote: noteController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi tersimpan.')),
      );
      _loadReferrals();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal verifikasi: $e')),
      );
    }
  }

  Widget _statusChip(String status) {
    final upper = status.toUpperCase();
    if (upper == 'APPROVED') {
      return _chip('APPROVED', const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
    }
    if (upper == 'REJECTED') {
      return _chip('REJECTED', const Color(0xFFFFEBEE), const Color(0xFFC62828));
    }
    return _chip('PENDING', const Color(0xFFFFF3E0), const Color(0xFFB45309));
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rujukan Masuk Dokter'),
        actions: [
          IconButton(
            onPressed: _loadReferrals,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incoming.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada rujukan masuk.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _incoming.length,
                  itemBuilder: (context, index) {
                    final referral = _incoming[index];
                    final isPending = referral.status.toUpperCase() == 'PENDING';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  referral.patientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              _statusChip(referral.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Diajukan oleh: ${referral.requestedByName}'),
                          Text('Alasan: ${referral.reason}'),
                          if (referral.clinicalNotes.isNotEmpty)
                            Text('Catatan klinis: ${referral.clinicalNotes}'),
                          if (referral.verificationNote.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Catatan verifikasi: ${referral.verificationNote}',
                                style: const TextStyle(color: Color(0xFF475569)),
                              ),
                            ),
                          if (isPending) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _verify(referral, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC62828),
                                      side: const BorderSide(color: Color(0xFFC62828)),
                                    ),
                                    child: const Text('Tolak'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _verify(referral, true),
                                    child: const Text('Setujui'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
