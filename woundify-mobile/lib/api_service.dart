import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  static const String baseUrl = 'https://woundify-production.up.railway.app'; // Railway serves HTTPS; http:// is blocked by Android cleartext policy
  String? _token;

  /// Navigator global agar bisa pindah ke layar login dari mana saja saat sesi berakhir.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Messenger global untuk menampilkan pesan bersih (mis. "Sesi berakhir").
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Dipasang oleh main.dart untuk menangani sesi berakhir (bersihkan sesi + ke login).
  static void Function()? onSessionExpired;
  static bool _handlingSessionExpiry = false;

  Future<Map<String, String>> _getHeaders() async {
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
    }
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(user.toJson()));
  }

  /// Restores the logged-in user from storage (for auto-login on app start).
  /// Returns null if there is no saved session or the token has expired.
  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userStr = prefs.getString('auth_user');
    if (token == null || userStr == null) return null;
    // Jangan auto-login dengan token kadaluarsa (menghindari "Sesi tidak valid")
    if (_isTokenExpired(token)) {
      await logout();
      return null;
    }
    _token = token;
    return User.fromJson(jsonDecode(userStr), token: token);
  }

  /// Membaca klaim `exp` dari payload JWT secara lokal (tanpa memanggil server).
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final map = jsonDecode(utf8.decode(base64.decode(payload)));
      final exp = map['exp'];
      if (exp is! int) return false; // tak bisa tentukan → anggap masih valid
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp < nowSec;
    } catch (_) {
      return false; // gagal parse → jangan paksa logout
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  // --- AUTHENTICATION ---
  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final user = User.fromJson(data);
      await _saveToken(user.token!);
      await _saveUser(user);
      return user;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<User> register(String email, String password, String name, String role, {String? strNumber, String? institution}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        if (strNumber != null && strNumber.isNotEmpty) 'strNumber': strNumber,
        if (institution != null && institution.isNotEmpty) 'institution': institution,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_extractMessage(response.body, fallback: 'Registrasi gagal'));
    }
  }

  /// Deletes the account for [email] so the same email can be re-registered
  /// (e.g. to try a different role). Clears the local session afterwards.
  Future<void> deleteAccount(String email) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/auth/account?email=${Uri.encodeComponent(email)}'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      await logout();
    } else {
      throw Exception(_extractMessage(response.body, fallback: 'Gagal menghapus akun'));
    }
  }

  /// Pulls the human-readable {"message": ...} the backend returns, falling back
  /// to a generic message when the body isn't the expected shape. Also detects an
  /// expired session and triggers a clean auto-logout instead of showing raw text.
  String _extractMessage(String body, {required String fallback}) {
    String msg = fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        msg = decoded['message'].toString();
      }
    } catch (_) {}
    if (_looksLikeSessionExpired(body) || _looksLikeSessionExpired(msg)) {
      _triggerSessionExpired();
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    }
    return msg;
  }

  bool _looksLikeSessionExpired(String text) {
    final t = text.toLowerCase();
    return t.contains('sesi tidak valid') ||
        t.contains('login ulang') ||
        t.contains('sesi anda telah berakhir');
  }

  /// Bersihkan sesi lokal lalu arahkan ke layar login (sekali saja).
  void _triggerSessionExpired() {
    if (_handlingSessionExpiry) return;
    _handlingSessionExpiry = true;
    logout();
    final cb = onSessionExpired;
    if (cb != null) cb();
    // izinkan lagi setelah transisi selesai
    Future.delayed(const Duration(seconds: 2), () => _handlingSessionExpiry = false);
  }

  Future<void> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP: ${response.body}');
    }
  }

  Future<User> verifyOtp(String email, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('OTP verification failed: ${response.body}');
    }
  }

  // --- PATIENTS ---
  Future<List<Patient>> getPatients() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/patients'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => Patient.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch patients');
    }
  }

  Future<Patient> createPatient(String name, String gender, DateTime birthDate, String diabetesType, String medicalHistory) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/patients'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'gender': gender,
        'birthDate': birthDate.toIso8601String().split('T')[0],
        'diabetesType': diabetesType,
        'medicalHistory': medicalHistory,
      }),
    );

    if (response.statusCode == 200) {
      return Patient.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_extractMessage(response.body, fallback: 'Gagal mendaftarkan pasien'));
    }
  }

  // --- LAB RESULTS & OCR ---
  Future<Map<String, dynamic>> scanLabSheetOcr(File file) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/lab-results/ocr'));
    final tokenHeaders = await _getHeaders();
    if (tokenHeaders.containsKey('Authorization')) {
      request.headers['Authorization'] = tokenHeaders['Authorization']!;
    }
    
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('OCR upload failed: ${response.body}');
    }
  }

  Future<LabResult> saveLabResult(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/lab-results'),
      headers: await _getHeaders(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return LabResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_extractMessage(response.body, fallback: 'Gagal menyimpan hasil laboratorium'));
    }
  }

  Future<List<LabResult>> getPatientHistory(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/lab-results/patient/$patientId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => LabResult.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch patient history');
    }
  }

  // --- REFERRALS ---
  Future<List<DoctorSummary>> getDoctors() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/doctors'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => DoctorSummary.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch doctors: ${response.body}');
  }

  /// All users across roles as referral targets (not just doctors).
  Future<List<DoctorSummary>> getReferralTargets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users/referral-targets'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => DoctorSummary.fromJson(json)).toList();
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal memuat daftar tujuan rujukan'));
  }

  Future<ReferralRecord> createReferral({
    required String patientId,
    required String targetDoctorId,
    required String reason,
    String clinicalNotes = '',
    String? availabilitySlotId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/referrals'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'patientId': patientId,
        'targetDoctorId': targetDoctorId,
        'reason': reason,
        'clinicalNotes': clinicalNotes,
        if (availabilitySlotId != null) 'availabilitySlotId': availabilitySlotId,
      }),
    );

    if (response.statusCode == 200) {
      return ReferralRecord.fromJson(jsonDecode(response.body));
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal membuat rujukan'));
  }

  // --- DOCTOR AVAILABILITY (jadwal kosong dokter untuk rujukan) ---
  Future<AvailabilitySlot> addAvailability(DateTime slotDateTime) async {
    // Kirim ISO tanpa zona (LocalDateTime di backend), detik dinolkan
    final iso = slotDateTime.toIso8601String().split('.').first;
    final response = await http.post(
      Uri.parse('$baseUrl/api/availability'),
      headers: await _getHeaders(),
      body: jsonEncode({'slotDateTime': iso}),
    );
    if (response.statusCode == 200) {
      return AvailabilitySlot.fromJson(jsonDecode(response.body));
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal menambah jadwal'));
  }

  Future<List<AvailabilitySlot>> getMyAvailability() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/availability/me'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((j) => AvailabilitySlot.fromJson(j)).toList();
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal memuat jadwal'));
  }

  Future<List<AvailabilitySlot>> getDoctorFreeSlots(String doctorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/availability/doctor/$doctorId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((j) => AvailabilitySlot.fromJson(j)).toList();
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal memuat jadwal dokter'));
  }

  Future<void> deleteAvailability(String slotId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/availability/$slotId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception(_extractMessage(response.body, fallback: 'Gagal menghapus jadwal'));
    }
  }

  // --- CHAT ---
  Future<ChatMessage> sendMessage(String recipientId, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/chat/send'),
      headers: await _getHeaders(),
      body: jsonEncode({'recipientId': recipientId, 'content': content}),
    );
    if (response.statusCode == 200) {
      return ChatMessage.fromJson(jsonDecode(response.body));
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal mengirim pesan'));
  }

  Future<int> getUnreadChatCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/chat/unread'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['unread'] ?? 0) is int ? data['unread'] : int.tryParse('${data['unread']}') ?? 0;
    }
    return 0;
  }

  Future<List<ChatMessage>> getConversation(String peerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/chat/conversation/$peerId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((j) => ChatMessage.fromJson(j)).toList();
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal memuat percakapan'));
  }

  Future<List<ReferralRecord>> getPatientReferrals(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/referrals/patient/$patientId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => ReferralRecord.fromJson(json)).toList();
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal memuat rujukan pasien'));
  }

  Future<List<ReferralRecord>> getIncomingReferrals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/referrals/incoming'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => ReferralRecord.fromJson(json)).toList();
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal memuat rujukan masuk'));
  }

  Future<ReferralRecord> verifyReferral({
    required String referralId,
    required bool approved,
    String verificationNote = '',
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/referrals/$referralId/verify'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'approved': approved,
        'verificationNote': verificationNote,
      }),
    );

    if (response.statusCode == 200) {
      return ReferralRecord.fromJson(jsonDecode(response.body));
    }
    throw Exception(_extractMessage(response.body, fallback: 'Gagal memverifikasi rujukan'));
  }

  // --- WOUND FOLLOW-UP (treatment outcome tracking) ---
  Future<WoundFollowUp> createFollowUp({
    required String patientId,
    required String status,
    String notes = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/follow-ups'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'patientId': patientId,
        'status': status,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      return WoundFollowUp.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to record follow-up: ${response.body}');
  }

  Future<List<WoundFollowUp>> getPatientFollowUps(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/follow-ups/patient/$patientId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => WoundFollowUp.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch follow-up history');
  }

  // --- DASHBOARD / INSTITUTIONAL IMPACT ---
  Future<InstitutionalImpactSummary> getImpactSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard/impact-summary'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return InstitutionalImpactSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch impact summary');
    }
  }

  // --- EPIDEMIOLOGY ---
  Future<List<EpidemiologyRecord>> getEpidemiologyData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/epidemiology'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => EpidemiologyRecord.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch epidemiology data');
    }
  }

  // --- STATISTICAL ANALYSIS & VALIDATION ---
  Future<Map<String, dynamic>> calculateCronbachAlpha(List<List<double>> matrix) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/statistics/reliability'),
      headers: await _getHeaders(),
      body: jsonEncode({'matrix': matrix}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_extractMessage(response.body, fallback: 'Perhitungan reliabilitas gagal'));
    }
  }

  Future<Map<String, dynamic>> calculatePearsonValidity(List<List<double>> matrix) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/statistics/validity'),
      headers: await _getHeaders(),
      body: jsonEncode({'matrix': matrix}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_extractMessage(response.body, fallback: 'Perhitungan validitas gagal'));
    }
  }

  Future<Map<String, dynamic>> getModelEvaluation() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/predictions/evaluation'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to retrieve model evaluation metrics');
    }
  }
}
