import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models.dart';
import '../utils/notification_helper.dart';

/// Halaman profil pengguna + pengelolaan jadwal ketersediaan (slot tanggal & jam)
/// untuk menerima rujukan. Tersedia untuk semua role.
class ProfileScheduleScreen extends StatefulWidget {
  final User currentUser;
  const ProfileScheduleScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ProfileScheduleScreen> createState() => _ProfileScheduleScreenState();
}

class _ProfileScheduleScreenState extends State<ProfileScheduleScreen> {
  final _apiService = ApiService();
  List<AvailabilitySlot> _slots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);
    try {
      final slots = await _apiService.getMyAvailability();
      if (mounted) setState(() => _slots = slots);
    } catch (e) {
      if (mounted) {
        NotificationHelper.error(context, e.toString().replaceAll('Exception:', '').trim(), title: 'Gagal Memuat Jadwal');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _formatRole(String role) {
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

  String _displayName() {
    final name = widget.currentUser.name.trim();
    if (widget.currentUser.role.toUpperCase() == 'DOCTOR' && !name.toLowerCase().startsWith('dr')) {
      return 'dr. $name';
    }
    return name;
  }

  Future<void> _addSlot() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    final slotDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    try {
      await _apiService.addAvailability(slotDateTime);
      if (!mounted) return;
      NotificationHelper.success(context, 'Jadwal ${_formatDateTime(slotDateTime)} ditambahkan.', title: 'Jadwal Ditambahkan');
      await _loadSlots();
    } catch (e) {
      if (!mounted) return;
      NotificationHelper.error(context, e.toString().replaceAll('Exception:', '').trim(), title: 'Gagal Menambah Jadwal');
    }
  }

  Future<void> _deleteSlot(AvailabilitySlot slot) async {
    try {
      await _apiService.deleteAvailability(slot.id);
      if (!mounted) return;
      await _loadSlots();
    } catch (e) {
      if (!mounted) return;
      NotificationHelper.error(context, e.toString().replaceAll('Exception:', '').trim(), title: 'Gagal Menghapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Jadwal Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSlot,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSlots,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Kartu profil
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3F2FD), width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF1E88E5),
                    child: Text(
                      widget.currentUser.name.isNotEmpty ? widget.currentUser.name.substring(0, 1).toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_displayName(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_formatRole(widget.currentUser.role),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 6),
                        Text(widget.currentUser.email,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Jadwal Ketersediaan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            const Text('Tanggal & jam kosong Anda untuk menerima rujukan pasien.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_slots.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Belum ada jadwal. Tap "Tambah Jadwal" untuk menyediakan slot.',
                    style: TextStyle(color: Color(0xFF64748B))),
              )
            else
              ..._slots.map((slot) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        slot.booked ? Icons.event_busy : Icons.event_available,
                        color: slot.booked ? const Color(0xFFEF5350) : const Color(0xFF2E7D32),
                      ),
                      title: Text(_formatDateTime(slot.slotDateTime),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(slot.booked ? 'Sudah dipakai rujukan' : 'Tersedia',
                          style: TextStyle(color: slot.booked ? const Color(0xFFEF5350) : const Color(0xFF2E7D32))),
                      trailing: slot.booked
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFB71C1C)),
                              onPressed: () => _deleteSlot(slot),
                            ),
                    ),
                  )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
