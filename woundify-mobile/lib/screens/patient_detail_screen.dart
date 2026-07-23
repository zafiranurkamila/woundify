import 'dart:convert';

import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models.dart';
import '../utils/notification_helper.dart';
import 'lab_input_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  final User currentUser;

  const PatientDetailScreen({
    Key? key,
    required this.patient,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSubmittingReferral = false;

  List<LabResult> _labHistory = [];
  List<ReferralRecord> _referrals = [];
  List<DoctorSummary> _doctors = [];
  List<WoundFollowUp> _followUps = [];
  bool _isSubmittingFollowUp = false;

  bool get _isDoctor => widget.currentUser.role.toUpperCase() == 'DOCTOR';
  LabResult? get _latestLab => _labHistory.isEmpty ? null : _labHistory.first;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = <Future<dynamic>>[
        _apiService.getPatientHistory(widget.patient.id),
        _apiService.getPatientReferrals(widget.patient.id),
        _apiService.getPatientFollowUps(widget.patient.id),
      ];

      if (!_isDoctor) {
        futures.add(_apiService.getDoctors());
      }

      final results = await Future.wait(futures);
      if (!mounted) return;

      setState(() {
        _labHistory = results[0] as List<LabResult>;
        _referrals = results[1] as List<ReferralRecord>;
        _followUps = results[2] as List<WoundFollowUp>;
        _doctors = !_isDoctor && results.length > 3
            ? results[3] as List<DoctorSummary>
            : [];
      });
    } catch (e) {
      if (!mounted) return;
      NotificationHelper.error(context, 'Gagal memuat detail pasien: $e', title: 'Error Memuat Data');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateAge(DateTime birthDate) {
    return DateTime.now().difference(birthDate).inDays ~/ 365;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openReferralDialog() async {
    if (_doctors.isEmpty) {
      NotificationHelper.warning(context, 'Dokter belum tersedia untuk dirujuk.', title: 'Tidak Ada Dokter');
      return;
    }

    final reasonController = TextEditingController();
    final noteController = TextEditingController();
    DoctorSummary selectedDoctor = _doctors.first;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajukan Rujukan Ke Dokter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DoctorSummary>(
                    value: selectedDoctor,
                    decoration: const InputDecoration(
                      labelText: 'Dokter Tujuan',
                      border: OutlineInputBorder(),
                    ),
                    items: _doctors
                        .map(
                          (doctor) => DropdownMenuItem<DoctorSummary>(
                            value: doctor,
                            child: Text('${doctor.name} (${doctor.email})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        modalSetState(() => selectedDoctor = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alasan Rujukan',
                      hintText: 'Tuliskan alasan klinis rujukan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Tambahan',
                      hintText: 'Opsional',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmittingReferral
                          ? null
                          : () async {
                              if (reasonController.text.trim().isEmpty) {
                                NotificationHelper.warning(context, 'Alasan rujukan wajib diisi.', title: 'Form Tidak Lengkap');
                                return;
                              }
                              Navigator.pop(context, true);
                            },
                      child: const Text('Ajukan Rujukan'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (submitted != true) return;

    setState(() => _isSubmittingReferral = true);
    try {
      await _apiService.createReferral(
        patientId: widget.patient.id,
        targetDoctorId: selectedDoctor.id,
        reason: reasonController.text.trim(),
        clinicalNotes: noteController.text.trim(),
      );
      if (!mounted) return;
      NotificationHelper.success(context, 'Rujukan berhasil diajukan dan menunggu verifikasi dokter.', title: 'Rujukan Dikirim');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      NotificationHelper.error(context, 'Gagal ajukan rujukan: $e', title: 'Gagal Mengirim Rujukan');
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReferral = false);
      }
    }
  }

  Future<void> _verifyReferral(ReferralRecord referral, bool approved) async {
    final noteController = TextEditingController();
    final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(approved ? 'Setujui Rujukan' : 'Tolak Rujukan'),
            content: TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan Verifikasi (opsional)',
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

    if (!shouldContinue) return;

    try {
      await _apiService.verifyReferral(
        referralId: referral.id,
        approved: approved,
        verificationNote: noteController.text.trim(),
      );
      if (!mounted) return;
      NotificationHelper.success(context, 'Verifikasi rujukan berhasil disimpan.', title: 'Rujukan Diverifikasi');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      NotificationHelper.error(context, 'Gagal verifikasi rujukan: $e', title: 'Gagal Verifikasi');
    }
  }

  String _followUpStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'IMPROVING':
        return 'Membaik';
      case 'WORSENING':
        return 'Memburuk';
      case 'HEALED':
        return 'Sembuh';
      case 'STABLE':
      default:
        return 'Stagnan';
    }
  }

  Color _followUpStatusColor(String status, {bool background = false}) {
    switch (status.toUpperCase()) {
      case 'IMPROVING':
        return background ? const Color(0xFFE8F5E9) : const Color(0xFF2E7D32);
      case 'WORSENING':
        return background ? const Color(0xFFFFEBEE) : const Color(0xFFC62828);
      case 'HEALED':
        return background ? const Color(0xFFE3F2FD) : const Color(0xFF1E88E5);
      case 'STABLE':
      default:
        return background ? const Color(0xFFFFF3E0) : const Color(0xFFB45309);
    }
  }

  IconData _followUpStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'IMPROVING':
        return Icons.trending_up_rounded;
      case 'WORSENING':
        return Icons.trending_down_rounded;
      case 'HEALED':
        return Icons.check_circle_rounded;
      case 'STABLE':
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Future<void> _openFollowUpDialog() async {
    final noteController = TextEditingController();
    String selectedStatus = 'STABLE';

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catat Tindak Lanjut Luka',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Progres penyembuhan luka sejak kunjungan terakhir',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['IMPROVING', 'STABLE', 'WORSENING', 'HEALED'].map((status) {
                      final selected = selectedStatus == status;
                      final color = _followUpStatusColor(status);
                      return ChoiceChip(
                        avatar: Icon(_followUpStatusIcon(status), size: 16, color: selected ? Colors.white : color),
                        label: Text(_followUpStatusLabel(status)),
                        selected: selected,
                        selectedColor: color,
                        backgroundColor: _followUpStatusColor(status, background: true),
                        labelStyle: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w600),
                        onSelected: (value) {
                          if (value) modalSetState(() => selectedStatus = status);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Klinis',
                      hintText: 'Opsional — mis. ukuran luka, eksudat, keluhan pasien',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Simpan Tindak Lanjut'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (submitted != true) return;

    setState(() => _isSubmittingFollowUp = true);
    try {
      await _apiService.createFollowUp(
        patientId: widget.patient.id,
        status: selectedStatus,
        notes: noteController.text.trim(),
      );
      if (!mounted) return;
      NotificationHelper.success(context, 'Tindak lanjut luka berhasil dicatat.', title: 'Tindak Lanjut Tersimpan');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      NotificationHelper.error(context, 'Gagal mencatat tindak lanjut: $e', title: 'Gagal Menyimpan');
    } finally {
      if (mounted) {
        setState(() => _isSubmittingFollowUp = false);
      }
    }
  }

  Widget _buildFollowUpTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSubmittingFollowUp ? null : _openFollowUpDialog,
            icon: const Icon(Icons.add_chart_rounded),
            label: const Text('Catat Tindak Lanjut'),
          ),
        ),
        const SizedBox(height: 12),
        _buildWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Progres Penyembuhan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (_followUps.isEmpty)
                const Text(
                  'Belum ada catatan tindak lanjut untuk pasien ini.',
                  style: TextStyle(color: Color(0xFF64748B)),
                )
              else
                ..._followUps.map(
                  (followUp) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _followUpStatusIcon(followUp.status),
                              size: 18,
                              color: _followUpStatusColor(followUp.status),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _followUpStatusLabel(followUp.status),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _followUpStatusColor(followUp.status),
                                ),
                              ),
                            ),
                            Text(
                              _formatDateTime(followUp.recordedAt),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        if (followUp.notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(followUp.notes, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Dicatat oleh ${followUp.recordedByName}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<MapEntry<String, String>> _extractSusceptibility(String raw) {
    if (raw.trim().isEmpty || raw.trim() == '{}') {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.entries
            .map((entry) => MapEntry(entry.key, '${entry.value}'.toUpperCase()))
            .toList();
      }
    } catch (_) {
      // Fallback to plain text parsing.
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

  Widget _statusChip(String status) {
    final normalized = status.toUpperCase();
    Color bg = const Color(0xFFFFF3E0);
    Color fg = const Color(0xFFB45309);

    if (normalized == 'APPROVED') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (normalized == 'REJECTED') {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        normalized,
        style: TextStyle(fontWeight: FontWeight.w600, color: fg, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final age = _calculateAge(patient.birthDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Detail Pasien'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: patient.gender == 'MALE'
                              ? const Color(0xFFE3F2FD)
                              : const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          patient.gender == 'MALE'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          color: patient.gender == 'MALE'
                              ? const Color(0xFF1E88E5)
                              : const Color(0xFFEC407A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$age tahun • ${patient.diabetesType.replaceAll('_', ' ')}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LabInputScreen(preSelectedPatient: patient),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.biotech_rounded, size: 18),
                        label: const Text('Input Lab'),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(3),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    labelColor: const Color(0xFF1E88E5),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
                    unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2),
                    tabs: const [
                      Tab(child: Text('Ringkasan', textAlign: TextAlign.center, softWrap: true)),
                      Tab(child: Text('Lab & Obat', textAlign: TextAlign.center, softWrap: true)),
                      Tab(child: Text('Rujukan', textAlign: TextAlign.center, softWrap: true)),
                      Tab(child: Text('Tindak Lanjut', textAlign: TextAlign.center, softWrap: true)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSummaryTab(),
                      _buildLabTab(),
                      _buildReferralTab(),
                      _buildFollowUpTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    final latest = _latestLab;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWhiteCard(
          child: Column(
            children: [
              _dataRow('Nama', widget.patient.name),
              _dataRow('Jenis Kelamin',
                  widget.patient.gender == 'MALE' ? 'Laki-laki' : 'Perempuan'),
              _dataRow(
                  'Tanggal Lahir',
                  '${widget.patient.birthDate.day}/${widget.patient.birthDate.month}/${widget.patient.birthDate.year}'),
              _dataRow('Tipe Diabetes',
                  widget.patient.diabetesType.replaceAll('_', ' ')),
              _dataRow('Riwayat Medis',
                  widget.patient.medicalHistory.isEmpty ? '-' : widget.patient.medicalHistory),
              _dataRow('Didaftarkan oleh', widget.patient.createdByName),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Hasil Lab Terakhir',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (latest == null)
                const Text(
                  'Belum ada hasil lab tersimpan.',
                  style: TextStyle(color: Color(0xFF64748B)),
                )
              else ...[
                _dataRow('Tanggal', _formatDateTime(latest.createdAt)),
                _dataRow('Hasil Kultur',
                    latest.cultureResult.isEmpty ? '-' : latest.cultureResult),
                _dataRow('Gram', latest.gramStain),
                _dataRow('Pemeriksa', latest.checkedByName),
                if (latest.prediction != null)
                  _dataRow('Prediksi Bakteri',
                      latest.prediction!.predictedBacteria),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabTab() {
    final latest = _latestLab;
    final susceptibility = latest == null
        ? <MapEntry<String, String>>[]
        : _extractSusceptibility(latest.antibioticSusceptibility);

    final susceptible = susceptibility
        .where((entry) =>
            entry.value.contains('SUSCEPTIBLE') || entry.value.trim() == 'S')
        .toList();

    final resistant = susceptibility
        .where((entry) =>
            entry.value.contains('RESIST') || entry.value.trim() == 'R')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rekomendasi Obat Berdasarkan Input Lab',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (latest == null)
                const Text(
                  'Belum ada data lab untuk menghasilkan rekomendasi obat.',
                  style: TextStyle(color: Color(0xFF64748B)),
                )
              else if (susceptibility.isEmpty)
                Text(
                  latest.prediction?.recommendations.isNotEmpty == true
                      ? latest.prediction!.recommendations
                      : 'Belum ada data antibiogram terstruktur di hasil lab terakhir.',
                  style: const TextStyle(color: Color(0xFF475569), height: 1.4),
                )
              else ...[
                const Text(
                  'Obat rentan (lebih direkomendasikan):',
                  style: TextStyle(
                      color: Color(0xFF1E88E5), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (susceptible.isEmpty)
                  const Text('-', style: TextStyle(color: Color(0xFF64748B)))
                else
                  ...susceptible.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${entry.key} (${entry.value})'),
                    ),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Obat resisten (hindari):',
                  style: TextStyle(
                      color: Color(0xFFC62828), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (resistant.isEmpty)
                  const Text('-', style: TextStyle(color: Color(0xFF64748B)))
                else
                  ...resistant.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${entry.key} (${entry.value})'),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Hasil Lab',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (_labHistory.isEmpty)
                const Text(
                  'Belum ada riwayat hasil lab.',
                  style: TextStyle(color: Color(0xFF64748B)),
                )
              else
                ..._labHistory.map(
                  (lab) => Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTime(lab.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lab.cultureResult.isEmpty
                              ? 'Kultur: -'
                              : 'Kultur: ${lab.cultureResult}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('Gram: ${lab.gramStain}'),
                        if (lab.prediction != null)
                          Text(
                            'Prediksi AI: ${lab.prediction!.predictedBacteria}',
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferralTab() {
    final pendingForDoctor = _referrals
        .where((r) =>
            r.targetDoctorId == widget.currentUser.id &&
            r.status.toUpperCase() == 'PENDING')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_isDoctor)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingReferral ? null : _openReferralDialog,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Ajukan Rujukan Ke Dokter'),
            ),
          ),
        if (!_isDoctor) const SizedBox(height: 12),
        _buildWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isDoctor ? 'Rujukan Masuk Untuk Anda' : 'Riwayat Rujukan Pasien',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (_referrals.isEmpty)
                const Text(
                  'Belum ada rujukan untuk pasien ini.',
                  style: TextStyle(color: Color(0xFF64748B)),
                )
              else
                ..._referrals.map(
                  (referral) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                referral.targetDoctorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            _statusChip(referral.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Alasan: ${referral.reason}'),
                        if (referral.clinicalNotes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Catatan: ${referral.clinicalNotes}'),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          'Diajukan oleh ${referral.requestedByName} • ${_formatDateTime(referral.requestedAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (referral.verificationNote.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Catatan verifikasi: ${referral.verificationNote}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        if (_isDoctor &&
                            referral.targetDoctorId == widget.currentUser.id &&
                            referral.status.toUpperCase() == 'PENDING')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _verifyReferral(referral, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFC62828),
                                      side: const BorderSide(
                                        color: Color(0xFFC62828),
                                      ),
                                    ),
                                    child: const Text('Tolak'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _verifyReferral(referral, true),
                                    child: const Text('Setujui'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (_isDoctor && pendingForDoctor.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Tidak ada rujukan pending untuk diverifikasi.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
