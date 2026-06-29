import 'package:flutter/material.dart';
import '../models.dart';
import '../api_service.dart';
import 'patient_form_screen.dart';
import 'lab_input_screen.dart';
import 'patient_detail_screen.dart';
import 'epidemiology_trends_screen.dart';
import 'validation_analytics_screen.dart';
import 'login_screen.dart';
import 'doctor_referral_inbox_screen.dart';

class HomeScreen extends StatefulWidget {
  final User currentUser;
  const HomeScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  List<Patient> _patients = [];
  bool _isLoading = true;
  int _currentNavIndex = 0;
  InstitutionalImpactSummary? _impactSummary;

  String _formatRole(String role) {
    final cleanRole = role.toUpperCase();
    if (cleanRole == 'DOCTOR' || cleanRole == 'HEALTH_PROFESSIONAL') {
      return 'Health Professionals';
    } else if (cleanRole == 'NURSE') {
      return 'Nurse';
    } else if (cleanRole == 'ADMIN') {
      return 'Admin';
    }
    return role;
  }

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _fetchImpactSummary();
  }

  void _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getPatients();
      setState(() => _patients = list);
    } catch (e) {
      // Handle or log error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _fetchImpactSummary() async {
    try {
      final summary = await _apiService.getImpactSummary();
      if (mounted) setState(() => _impactSummary = summary);
    } catch (e) {
      // Best-effort widget; dashboard still works without it.
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        content: Text(content, style: const TextStyle(color: Color(0xFF475569), height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildPatientListPage();
      case 2:
        return _buildProfilePage();
      default:
        return _buildHomePage();
    }
  }

  // ──────────────────────────────────────────────
  // HOME PAGE (Beranda)
  // ──────────────────────────────────────────────
  Widget _buildHomePage() {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : RefreshIndicator(
              color: const Color(0xFF1E88E5),
              backgroundColor: Colors.white,
              onRefresh: () async => _fetchPatients(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile Header ──
                    _buildProfileHeader(),

                    // ── Main CTA Banner ──
                    _buildMainBanner(),

                    const SizedBox(height: 24),

                    // ── Feature Icon Grid ──
                    _buildFeatureGrid(),

                    const SizedBox(height: 24),

                    // ── Recent Activity Carousel ──
                    _buildRecentActivitySection(),

                    const SizedBox(height: 24),

                    // ── Highlighted Patient Card ──
                    _buildHighlightedPatientSection(),

                    const SizedBox(height: 24),

                    // ── Institutional Impact / ROI Summary ──
                    _buildImpactSummarySection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Profile Header (like Halodoc top bar) ──
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.currentUser.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentUser.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  _formatRole(widget.currentUser.role),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Notification bell
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 22),
                  color: const Color(0xFF64748B),
                  onPressed: () => _showInfoDialog(
                    'Notifikasi',
                    _impactSummary != null && _impactSummary!.highRiskCasesDetected > 0
                        ? 'Ada ${_impactSummary!.highRiskCasesDetected} kasus risiko komplikasi tinggi yang perlu ditinjau.'
                        : 'Belum ada notifikasi baru.',
                  ),
                ),
                if (_impactSummary != null && _impactSummary!.highRiskCasesDetected > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
          // Logout
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 22),
              color: const Color(0xFF64748B),
              onPressed: _handleLogout,
              tooltip: 'Keluar',
            ),
          ),
        ],
      ),
    );
  }

  // ── Main CTA Banner (Halodoc "Coins / Top Up" style) ──
  Widget _buildMainBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E88E5).withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_patients.length} Pasien Aktif',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Total pasien yang sedang dipantau',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientFormScreen()),
              ).then((_) => _fetchPatients()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E88E5),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18),
                  SizedBox(width: 4),
                  Text('Pasien Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Institutional Impact / ROI Summary ──
  Widget _buildImpactSummarySection() {
    final summary = _impactSummary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.insights_rounded, color: Color(0xFF1E88E5), size: 18),
                SizedBox(width: 8),
                Text(
                  'Dampak Institusi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildImpactStat(
                    'Pasien Diskrining',
                    '${summary.totalPatientsScreened}',
                    const Color(0xFF1E88E5),
                  ),
                ),
                Expanded(
                  child: _buildImpactStat(
                    'Kasus Risiko Tinggi',
                    '${summary.highRiskCasesDetected}',
                    const Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildImpactStat(
                    'Est. Amputasi Dicegah',
                    '${summary.estimatedAmputationsPrevented}',
                    const Color(0xFF43A047),
                  ),
                ),
                Expanded(
                  child: _buildImpactStat(
                    'Est. Jam Kerja Dihemat',
                    summary.estimatedHoursSaved.toStringAsFixed(1),
                    const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Estimasi berbasis literatur prevalensi luka kaki diabetik & deteksi dini risiko komplikasi. Bukan klaim klinis individual.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ── Feature Icon Grid (4 columns, like Halodoc) ──
  Widget _buildFeatureGrid() {
    final isDoctor = widget.currentUser.role.toUpperCase() == 'DOCTOR';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildFeatureIcon(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Pasien Baru',
              color: const Color(0xFF1E88E5),
              bgColor: const Color(0xFFE3F2FD),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientFormScreen()),
              ).then((_) => _fetchPatients()),
            ),
            _buildFeatureIcon(
              icon: Icons.document_scanner_rounded,
              label: 'Input Lab',
              color: const Color(0xFF1565C0),
              bgColor: const Color(0xFFBBDEFB),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LabInputScreen()),
              ),
            ),
            _buildFeatureIcon(
              icon: Icons.map_rounded,
              label: 'Epidemiologi',
              color: const Color(0xFF0D47A1),
              bgColor: const Color(0xFFE8EAF6),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EpidemiologyTrendsScreen()),
              ),
            ),
            _buildFeatureIcon(
              icon: isDoctor ? Icons.fact_check_rounded : Icons.rate_review_rounded,
              label: isDoctor ? 'Rujukan Masuk' : 'Survei Validasi',
              color: const Color(0xFF2E7D32),
              bgColor: const Color(0xFFE8F5E9),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => isDoctor
                      ? DoctorReferralInboxScreen(currentUser: widget.currentUser)
                      : const ValidationAnalyticsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIcon({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header with "Lihat Semua" link (shared style) ──
  Widget _sectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'Lihat Semua',
            style: TextStyle(fontSize: 13, color: Color(0xFF1E88E5), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _emptyPatientsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.people_outline_rounded, size: 28, color: Color(0xFF90CAF9)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada pasien terdaftar',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tambahkan pasien baru untuk memulai',
            style: TextStyle(color: Color(0xFFBDC7D6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Recent Activity Carousel (Halodoc "My Appointment" style) ──
  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Aktivitas Terbaru', () => setState(() => _currentNavIndex = 1)),
          const SizedBox(height: 12),
          if (_patients.isEmpty)
            _emptyPatientsCard()
          else
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _patients.length > 5 ? 5 : _patients.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final patient = _patients[index];
                  final isMale = patient.gender == 'MALE';
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailScreen(patient: patient, currentUser: widget.currentUser),
                      ),
                    ),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isMale ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isMale ? Icons.male_rounded : Icons.female_rounded,
                                  color: isMale ? const Color(0xFF1E88E5) : const Color(0xFFEC407A),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  patient.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _miniChip(Icons.medical_information_outlined, patient.diabetesType.replaceAll('_', ' '), const Color(0xFFE65100), const Color(0xFFFFF3E0)),
                              _miniChip(Icons.person_outline_rounded, patient.createdByName, const Color(0xFF43A047), const Color(0xFFE8F5E9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Highlighted Patient Card (Halodoc "Top Doctor" style) ──
  Widget _buildHighlightedPatientSection() {
    if (_patients.isEmpty) return const SizedBox.shrink();
    final patient = _patients.first;
    final isMale = patient.gender == 'MALE';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Pasien Perlu Perhatian', () => setState(() => _currentNavIndex = 1)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isMale ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isMale ? Icons.male_rounded : Icons.female_rounded,
                        color: isMale ? const Color(0xFF1E88E5) : const Color(0xFFEC407A),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            patient.diabetesType.replaceAll('_', ' '),
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.priority_high_rounded, size: 12, color: Color(0xFFE65100)),
                          SizedBox(width: 2),
                          Text('Pantau', style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailScreen(patient: patient, currentUser: widget.currentUser),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lihat Detail Pasien', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // PATIENT LIST PAGE (Riwayat)
  // ──────────────────────────────────────────────
  Widget _buildPatientListPage() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Semua Pasien',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                GestureDetector(
                  onTap: _fetchPatients,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF1E88E5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
                : _patients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.people_outline_rounded, size: 32, color: Color(0xFF90CAF9)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada pasien terdaftar',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          final isMale = patient.gender == 'MALE';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isMale ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isMale ? Icons.male_rounded : Icons.female_rounded,
                                  color: isMale ? const Color(0xFF1E88E5) : const Color(0xFFEC407A),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                patient.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Text(
                                '${patient.diabetesType.replaceAll('_', ' ')} • ${patient.createdByName}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF1E88E5), size: 20),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PatientDetailScreen(
                                      patient: patient,
                                      currentUser: widget.currentUser,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // PROFILE PAGE (Profil)
  // ──────────────────────────────────────────────
  Widget _buildProfilePage() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.currentUser.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.currentUser.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRole(widget.currentUser.role),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.currentUser.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Profile Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileMenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Info Akun',
                      subtitle: widget.currentUser.email,
                      onTap: () => _showInfoDialog(
                        'Info Akun',
                        'Nama: ${widget.currentUser.name}\n'
                            'Email: ${widget.currentUser.email}\n'
                            'Peran: ${_formatRole(widget.currentUser.role)}',
                      ),
                    ),
                    _divider(),
                    _buildProfileMenuItem(
                      icon: Icons.shield_outlined,
                      label: 'Keamanan',
                      subtitle: 'Kata sandi & autentikasi',
                      onTap: () => _showInfoDialog(
                        'Keamanan',
                        'Pengaturan kata sandi dan autentikasi dua faktor akan tersedia pada rilis mendatang. '
                            'Untuk saat ini, hubungi admin institusi Anda untuk reset kata sandi.',
                      ),
                    ),
                    _divider(),
                    _buildProfileMenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Bantuan',
                      subtitle: 'FAQ & kontak dukungan',
                      onTap: () => _showInfoDialog(
                        'Bantuan',
                        'Butuh bantuan? Hubungi tim dukungan Woundify melalui email support@woundify.id '
                            'atau tanyakan pada admin institusi Anda.',
                      ),
                    ),
                    _divider(),
                    _buildProfileMenuItem(
                      icon: Icons.info_outline_rounded,
                      label: 'Tentang Woundify',
                      subtitle: 'Versi 1.0.0',
                      onTap: () => _showInfoDialog(
                        'Tentang Woundify',
                        'Woundify v1.0.0\n\n'
                            'Platform identifikasi bakteri & penilaian risiko luka kaki diabetik berbasis AI, '
                            'untuk membantu tenaga kesehatan mengambil keputusan klinis lebih cepat dan akurat.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Keluar dari Akun'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF5350),
                    side: const BorderSide(color: Color(0xFFEF5350), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF1E88E5), size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return const Divider(height: 1, indent: 72, endIndent: 16, color: Color(0xFFF1F5F9));
  }

  // ──────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR
  // ──────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex < 2 ? _currentNavIndex : 3,
          onTap: (index) {
            if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LabInputScreen()));
              return;
            }
            setState(() => _currentNavIndex = index == 3 ? 2 : index);
          },
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF1E88E5),
          unselectedItemColor: const Color(0xFFB0BEC5),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner_outlined),
              activeIcon: Icon(Icons.document_scanner_rounded),
              label: 'Input Lab',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
