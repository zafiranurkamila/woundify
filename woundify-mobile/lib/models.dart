class InstitutionalImpactSummary {
  final int totalPatientsScreened;
  final int totalLabResultsAnalyzed;
  final int highRiskCasesDetected;
  final int lowConfidenceCasesFlaggedForCulture;
  final int referralsApproved;
  final int estimatedAmputationsPrevented;
  final double estimatedHoursSaved;

  InstitutionalImpactSummary({
    required this.totalPatientsScreened,
    required this.totalLabResultsAnalyzed,
    required this.highRiskCasesDetected,
    required this.lowConfidenceCasesFlaggedForCulture,
    required this.referralsApproved,
    required this.estimatedAmputationsPrevented,
    required this.estimatedHoursSaved,
  });

  factory InstitutionalImpactSummary.fromJson(Map<String, dynamic> json) {
    return InstitutionalImpactSummary(
      totalPatientsScreened: json['totalPatientsScreened'] ?? 0,
      totalLabResultsAnalyzed: json['totalLabResultsAnalyzed'] ?? 0,
      highRiskCasesDetected: json['highRiskCasesDetected'] ?? 0,
      lowConfidenceCasesFlaggedForCulture: json['lowConfidenceCasesFlaggedForCulture'] ?? 0,
      referralsApproved: json['referralsApproved'] ?? 0,
      estimatedAmputationsPrevented: json['estimatedAmputationsPrevented'] ?? 0,
      estimatedHoursSaved: (json['estimatedHoursSaved'] ?? 0.0).toDouble(),
    );
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? token;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      token: token ?? json['token'],
    );
  }
}

class Patient {
  final String id;
  final String name;
  final String gender;
  final DateTime birthDate;
  final String diabetesType;
  final String medicalHistory;
  final String createdByName;
  final DateTime createdAt;

  Patient({
    required this.id,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.diabetesType,
    required this.medicalHistory,
    required this.createdByName,
    required this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? 'MALE',
      birthDate: DateTime.parse(json['birthDate'] ?? DateTime.now().toIso8601String()),
      diabetesType: json['diabetesType'] ?? 'TYPE_2',
      medicalHistory: json['medicalHistory'] ?? '',
      createdByName: json['createdByName'] ?? 'System',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class LabResult {
  final String id;
  final String patientId;
  final String patientName;
  final String? woundPhotoUrl;
  final String colonyMorphology;
  final String gramStain;
  final String imvicIndole;
  final String imvicMethylRed;
  final String imvicVogesProskauer;
  final String imvicCitrate;
  final String cultureResult;
  final String antibioticSusceptibility;
  final String ocrRawText;
  final String checkedByName;
  final DateTime createdAt;
  final Prediction? prediction;
  final String? macconkey;
  final String? ssAgar;
  final String? colonyTexture;
  final String? colonySize;

  LabResult({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.woundPhotoUrl,
    required this.colonyMorphology,
    required this.gramStain,
    required this.imvicIndole,
    required this.imvicMethylRed,
    required this.imvicVogesProskauer,
    required this.imvicCitrate,
    required this.cultureResult,
    required this.antibioticSusceptibility,
    required this.ocrRawText,
    required this.checkedByName,
    required this.createdAt,
    this.prediction,
    this.macconkey,
    this.ssAgar,
    this.colonyTexture,
    this.colonySize,
  });

  factory LabResult.fromJson(Map<String, dynamic> json) {
    return LabResult(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      patientName: json['patientName'] ?? '',
      woundPhotoUrl: json['woundPhotoUrl'],
      colonyMorphology: json['colonyMorphology'] ?? '',
      gramStain: json['gramStain'] ?? 'GRAM_NEGATIVE',
      imvicIndole: json['imvicIndole'] ?? 'NEGATIVE',
      imvicMethylRed: json['imvicMethylRed'] ?? 'NEGATIVE',
      imvicVogesProskauer: json['imvicVogesProskauer'] ?? 'NEGATIVE',
      imvicCitrate: json['imvicCitrate'] ?? 'NEGATIVE',
      cultureResult: json['cultureResult'] ?? '',
      antibioticSusceptibility: json['antibioticSusceptibility'] ?? '{}',
      ocrRawText: json['ocrRawText'] ?? '',
      checkedByName: json['checkedByName'] ?? 'System',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      prediction: json['prediction'] != null ? Prediction.fromJson(json['prediction']) : null,
      macconkey: json['macconkey'],
      ssAgar: json['ssAgar'],
      colonyTexture: json['colonyTexture'],
      colonySize: json['colonySize'],
    );
  }
}

class DifferentialDiagnosis {
  final String bacteria;
  final double probability;

  DifferentialDiagnosis({required this.bacteria, required this.probability});

  factory DifferentialDiagnosis.fromJson(Map<String, dynamic> json) {
    return DifferentialDiagnosis(
      bacteria: json['bacteria'] ?? 'Unknown',
      probability: (json['probability'] ?? 0.0).toDouble(),
    );
  }
}

class Prediction {
  final String id;
  final String predictedBacteria;
  final String infectionRiskLevel;
  final String chronicRiskLevel;
  final String complicationRiskLevel;
  final double confidenceScore;
  final String recommendations;
  final List<DifferentialDiagnosis> differentialDiagnosis;
  final List<String> reasoning;
  final bool lowConfidence;
  final String disclaimer;
  final DateTime predictedAt;

  Prediction({
    required this.id,
    required this.predictedBacteria,
    required this.infectionRiskLevel,
    required this.chronicRiskLevel,
    required this.complicationRiskLevel,
    required this.confidenceScore,
    required this.recommendations,
    required this.differentialDiagnosis,
    required this.reasoning,
    required this.lowConfidence,
    required this.disclaimer,
    required this.predictedAt,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'] ?? '',
      predictedBacteria: json['predictedBacteria'] ?? 'Unknown',
      infectionRiskLevel: json['infectionRiskLevel'] ?? 'LOW',
      chronicRiskLevel: json['chronicRiskLevel'] ?? 'LOW',
      complicationRiskLevel: json['complicationRiskLevel'] ?? 'LOW',
      confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      recommendations: json['recommendations'] ?? '',
      differentialDiagnosis: ((json['differentialDiagnosis'] ?? []) as List)
          .map((item) => DifferentialDiagnosis.fromJson(item))
          .toList(),
      reasoning: ((json['reasoning'] ?? []) as List).map((item) => '$item').toList(),
      lowConfidence: json['lowConfidence'] ?? false,
      disclaimer: json['disclaimer'] ??
          'Alat bantu keputusan klinis, bukan diagnosis. Konfirmasi dengan kultur laboratorium.',
      predictedAt: DateTime.parse(json['predictedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class EpidemiologyRecord {
  final String id;
  final String bacteriaName;
  final String region;
  final DateTime date;
  final int cases;
  final double resistanceRate;

  EpidemiologyRecord({
    required this.id,
    required this.bacteriaName,
    required this.region,
    required this.date,
    required this.cases,
    required this.resistanceRate,
  });

  factory EpidemiologyRecord.fromJson(Map<String, dynamic> json) {
    return EpidemiologyRecord(
      id: json['id'] ?? '',
      bacteriaName: json['bacterialProfile'] != null ? json['bacterialProfile']['name'] ?? 'Unknown' : 'Unknown',
      region: json['patientRegion'] ?? 'Jakarta',
      date: DateTime.parse(json['infectionDate'] ?? DateTime.now().toIso8601String()),
      cases: json['caseCount'] ?? 0,
      resistanceRate: (json['antibioticResistanceRate'] ?? 0.0).toDouble(),
    );
  }
}

class DoctorSummary {
  final String id;
  final String name;
  final String email;
  final String role;

  DoctorSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory DoctorSummary.fromJson(Map<String, dynamic> json) {
    return DoctorSummary(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'DOCTOR',
    );
  }
}

class ReferralRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String requestedById;
  final String requestedByName;
  final String targetDoctorId;
  final String targetDoctorName;
  final String targetDoctorEmail;
  final String reason;
  final String clinicalNotes;
  final String status;
  final String verificationNote;
  final String? verifiedById;
  final String? verifiedByName;
  final DateTime? requestedAt;
  final DateTime? verifiedAt;

  ReferralRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.requestedById,
    required this.requestedByName,
    required this.targetDoctorId,
    required this.targetDoctorName,
    required this.targetDoctorEmail,
    required this.reason,
    required this.clinicalNotes,
    required this.status,
    required this.verificationNote,
    this.verifiedById,
    this.verifiedByName,
    this.requestedAt,
    this.verifiedAt,
  });

  factory ReferralRecord.fromJson(Map<String, dynamic> json) {
    return ReferralRecord(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName'] ?? '',
      requestedById: json['requestedById']?.toString() ?? '',
      requestedByName: json['requestedByName'] ?? '',
      targetDoctorId: json['targetDoctorId']?.toString() ?? '',
      targetDoctorName: json['targetDoctorName'] ?? '',
      targetDoctorEmail: json['targetDoctorEmail'] ?? '',
      reason: json['reason'] ?? '',
      clinicalNotes: json['clinicalNotes'] ?? '',
      status: json['status'] ?? 'PENDING',
      verificationNote: json['verificationNote'] ?? '',
      verifiedById: json['verifiedById']?.toString(),
      verifiedByName: json['verifiedByName'],
      requestedAt: json['requestedAt'] != null ? DateTime.tryParse(json['requestedAt']) : null,
      verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt']) : null,
    );
  }
}

class WoundFollowUp {
  final String id;
  final String patientId;
  final String status; // IMPROVING, STABLE, WORSENING, HEALED
  final String notes;
  final String recordedById;
  final String recordedByName;
  final DateTime? recordedAt;

  WoundFollowUp({
    required this.id,
    required this.patientId,
    required this.status,
    required this.notes,
    required this.recordedById,
    required this.recordedByName,
    this.recordedAt,
  });

  factory WoundFollowUp.fromJson(Map<String, dynamic> json) {
    return WoundFollowUp(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      status: json['status'] ?? 'STABLE',
      notes: json['notes'] ?? '',
      recordedById: json['recordedById']?.toString() ?? '',
      recordedByName: json['recordedByName'] ?? '',
      recordedAt: json['recordedAt'] != null ? DateTime.tryParse(json['recordedAt']) : null,
    );
  }
}
