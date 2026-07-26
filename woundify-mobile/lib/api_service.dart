import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  static const String baseUrl = 'https://woundify-production.up.railway.app'; // Railway serves HTTPS; http:// is blocked by Android cleartext policy
  String? _token;

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
  /// Returns null if there is no saved session.
  Future<User?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userStr = prefs.getString('auth_user');
    if (token == null || userStr == null) return null;
    _token = token;
    return User.fromJson(jsonDecode(userStr), token: token);
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

  Future<User> register(String email, String password, String name, String role, {String? strNumber}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        if (strNumber != null && strNumber.isNotEmpty) 'strNumber': strNumber,
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
  /// to a generic message when the body isn't the expected shape.
  String _extractMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return fallback;
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
      throw Exception('Failed to create patient: ${response.body}');
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
      throw Exception('Failed to save laboratory record: ${response.body}');
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

  Future<List<ReferralRecord>> getPatientReferrals(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/referrals/patient/$patientId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => ReferralRecord.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch patient referrals: ${response.body}');
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
    throw Exception('Failed to fetch incoming referrals: ${response.body}');
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
    throw Exception('Failed to verify referral: ${response.body}');
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
      throw Exception('Cronbach alpha computation failed');
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
      throw Exception('Pearson validity computation failed');
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
