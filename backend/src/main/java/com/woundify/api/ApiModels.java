package com.woundify;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

record LoginRequest(@NotBlank String username, @NotBlank String password) {
}

record LoginResponse(String token, String username, List<String> roles) {
}

record CreatePatientRequest(
        @NotBlank String fullName,
        @NotBlank String medicalRecordNumber,
        @Min(0) @Max(120) int age,
        @NotBlank String sex,
        @NotBlank String diabetesType,
        @NotBlank String woundLocation,
        @NotBlank String woundStage,
        String notes) {
}

record PatientResponse(
        String id,
        String fullName,
        String medicalRecordNumber,
        int age,
        String sex,
        String diabetesType,
        String woundLocation,
        String woundStage,
        String notes,
        Instant createdAt,
        Instant updatedAt) {
}

record LabResultRequest(
        @NotBlank String patientId,
        @NotBlank String gramStain,
        @NotBlank String colonyMorphology,
        @NotBlank String indole,
        @NotBlank String methylRed,
        @NotBlank String vogesProskauer,
        @NotBlank String citrate,
        @NotBlank String cultureResult,
        @NotBlank String antibioticSensitivity,
        String imageUrl) {
}

record LabResultResponse(
        String id,
        String patientId,
        String gramStain,
        String colonyMorphology,
        String indole,
        String methylRed,
        String vogesProskauer,
        String citrate,
        String cultureResult,
        String antibioticSensitivity,
        String imageUrl,
        Instant createdAt) {
}

record AiAnalysisRequest(
        @NotBlank String gramStain,
        @NotBlank String colonyMorphology,
        @NotBlank String indole,
        @NotBlank String methylRed,
        @NotBlank String vogesProskauer,
        @NotBlank String citrate,
        @NotBlank String cultureResult,
        @NotBlank String antibioticSensitivity,
        String woundNotes) {
}

record AiPrediction(
        List<String> possibleBacteria,
        String infectionRisk,
        String chronicWoundRisk,
        String complicationRisk,
        String antibioticResistanceRisk,
        double confidence,
        String recommendation,
        Map<String, Object> rationale) {
}

record DashboardSummary(
        long patients,
        long labResults,
        long highRiskCases,
        long predictedResistanceCases,
        String topBacteria) {
}

final class WoundifyStore {

    private final AtomicLong patientSequence = new AtomicLong(1000);
    private final AtomicLong labSequence = new AtomicLong(5000);
    private final Map<String, PatientRecord> patients = new ConcurrentHashMap<>();
    private final Map<String, LabRecord> labResults = new ConcurrentHashMap<>();
    private final Map<String, String> authUsers = Map.of("clinician@example.com", "woundify123");

    WoundifyStore() {
        seed();
    }

    boolean isValidUser(String username, String password) {
        return authUsers.containsKey(username) && authUsers.get(username).equals(password);
    }

    List<PatientResponse> listPatients() {
        return patients.values().stream()
                .sorted((left, right) -> right.updatedAt.compareTo(left.updatedAt))
                .map(PatientRecord::toResponse)
                .collect(Collectors.toList());
    }

    List<LabResultResponse> listLabResults() {
        return labResults.values().stream()
                .sorted((left, right) -> right.createdAt.compareTo(left.createdAt))
                .map(LabRecord::toResponse)
                .collect(Collectors.toList());
    }

    PatientResponse createPatient(CreatePatientRequest request) {
        String id = "PAT-" + patientSequence.incrementAndGet();
        Instant now = Instant.now();
        PatientRecord record = new PatientRecord(
                id,
                request.fullName(),
                request.medicalRecordNumber(),
                request.age(),
                request.sex(),
                request.diabetesType(),
                request.woundLocation(),
                request.woundStage(),
                normalizeNullable(request.notes()),
                now,
                now);
        patients.put(id, record);
        return record.toResponse();
    }

    PatientResponse getPatient(String patientId) {
        PatientRecord record = patients.get(patientId);
        if (record == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Patient not found");
        }
        return record.toResponse();
    }

    List<LabResultResponse> listLabResultsByPatient(String patientId) {
        if (!patients.containsKey(patientId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Patient not found");
        }
        return labResults.values().stream()
                .filter(lab -> lab.patientId.equals(patientId))
                .sorted((left, right) -> right.createdAt.compareTo(left.createdAt))
                .map(LabRecord::toResponse)
                .collect(Collectors.toList());
    }

    LabResultResponse saveLabResult(LabResultRequest request) {
        PatientRecord patient = patients.get(request.patientId());
        if (patient == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Patient not found");
        }
        String id = "LAB-" + labSequence.incrementAndGet();
        Instant now = Instant.now();
        LabRecord record = new LabRecord(
                id,
                request.patientId(),
                normalize(request.gramStain()),
                normalize(request.colonyMorphology()),
                normalize(request.indole()),
                normalize(request.methylRed()),
                normalize(request.vogesProskauer()),
                normalize(request.citrate()),
                normalize(request.cultureResult()),
                normalize(request.antibioticSensitivity()),
                normalizeNullable(request.imageUrl()),
                now);
        labResults.put(id, record);
        patients.put(patient.id, patient.withUpdatedAt(now));
        return record.toResponse();
    }

    AiPrediction analyze(AiAnalysisRequest request) {
        String gram = normalize(request.gramStain());
        String morphology = normalize(request.colonyMorphology());
        String indole = normalize(request.indole());
        String methylRed = normalize(request.methylRed());
        String vogesProskauer = normalize(request.vogesProskauer());
        String citrate = normalize(request.citrate());
        String culture = normalize(request.cultureResult());
        String sensitivity = normalize(request.antibioticSensitivity());
        String notes = normalizeNullable(request.woundNotes());

        List<String> candidates = new ArrayList<>();
        double confidence = 0.55;

        if (containsAny(gram, "negative") && isPositive(indole) && isPositive(methylRed) && isNegative(vogesProskauer) && isNegative(citrate)) {
            candidates.add("Escherichia coli");
            confidence += 0.25;
        }
        if (containsAny(gram, "negative") && isPositive(citrate) && isPositive(vogesProskauer)) {
            candidates.add("Klebsiella pneumoniae");
            candidates.add("Enterobacter cloacae");
            confidence += 0.2;
        }
        if (containsAny(gram, "positive") && containsAny(morphology, "cluster", "grape", "staph")) {
            candidates.add("Staphylococcus aureus");
            confidence += 0.2;
        }
        if (containsAny(gram, "positive") && containsAny(morphology, "chain", "strepto")) {
            candidates.add("Streptococcus spp.");
            confidence += 0.15;
        }
        if (candidates.isEmpty()) {
            candidates.add("Mixed bacterial profile");
        }

        boolean severeWords = containsAny(notes, "necrotic", "pus", "foul", "fever", "amputation", "sepsis")
                || containsAny(culture, "heavy", "moderate growth", "positive")
                || containsAny(sensitivity, "resistant", "esbl", "mrsa");

        String infectionRisk = severeWords ? "high" : containsAny(gram, "positive", "negative") ? "medium" : "low";
        String chronicRisk = containsAny(notes, "chronic", "non-healing", "ulcer", "diabetic") ? "high" : "medium";
        String complicationRisk = severeWords ? "high" : "medium";
        String resistanceRisk = containsAny(sensitivity, "resistant", "esbl", "mrsa", "multidrug") ? "high"
                : containsAny(sensitivity, "intermediate") ? "medium" : "low";

        double riskBoost = switch (infectionRisk) {
            case "high" -> 0.15;
            case "medium" -> 0.08;
            default -> 0.0;
        };
        confidence = Math.min(0.97, confidence + riskBoost);

        String recommendation = buildRecommendation(infectionRisk, resistanceRisk, chronicRisk);
        Map<String, Object> rationale = new LinkedHashMap<>();
        rationale.put("gramStain", gram);
        rationale.put("morphology", morphology);
        rationale.put("imvic", Map.of(
                "indole", indole,
                "methylRed", methylRed,
                "vogesProskauer", vogesProskauer,
                "citrate", citrate));
        rationale.put("cultureResult", culture);
        rationale.put("antibioticSensitivity", sensitivity);

        return new AiPrediction(candidates, infectionRisk, chronicRisk, complicationRisk, resistanceRisk, round(confidence), recommendation, rationale);
    }

    DashboardSummary dashboardSummary() {
        long highRiskCases = labResults.values().stream()
                .map(LabRecord::combinedText)
                .filter(text -> containsAny(text, "resistant", "esbl", "mrsa", "pus", "necrotic", "sepsis"))
                .count();
        long predictedResistanceCases = labResults.values().stream()
                .map(LabRecord::combinedText)
                .filter(text -> containsAny(text, "resistant", "esbl", "mrsa", "multidrug"))
                .count();
        String topBacteria = labResults.values().stream()
                .map(LabRecord::suggestedBacteria)
                .filter(text -> !text.isBlank())
                .collect(Collectors.groupingBy(text -> text, Collectors.counting()))
                .entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("Not enough data");

        return new DashboardSummary(patients.size(), labResults.size(), highRiskCases, predictedResistanceCases, topBacteria);
    }

    private void seed() {
        PatientResponse patient = createPatient(new CreatePatientRequest(
                "Ayu Pratama",
                "RM-2026-001",
                58,
                "Female",
                "Type 2",
                "Left foot",
                "Stage 3",
                "Ulcer with mild discharge and delayed healing"));
        saveLabResult(new LabResultRequest(
                patient.id(),
                "Gram negative rods",
                "Large moist colonies",
                "Positive",
                "Positive",
                "Negative",
                "Negative",
                "Heavy growth of enteric bacteria",
                "Sensitive to ciprofloxacin, resistant to ampicillin",
                null));
        createPatient(new CreatePatientRequest(
                "Budi Santoso",
                "RM-2026-002",
                64,
                "Male",
                "Type 2",
                "Right heel",
                "Stage 2",
                "Chronic wound with intermittent pain"));
    }

    private String buildRecommendation(String infectionRisk, String resistanceRisk, String chronicRisk) {
        if ("high".equals(infectionRisk) || "high".equals(resistanceRisk)) {
            return "Perlu evaluasi klinis lanjutan, konfirmasi kultur, dan review sensitivitas antibiotik sebelum terapi definitif.";
        }
        if ("high".equals(chronicRisk)) {
            return "Pantau luka secara berkala, optimalkan kontrol glikemik, dan pertimbangkan evaluasi lanjutan bila perbaikan lambat.";
        }
        return "Temuan awal mengarah ke risiko sedang, lanjutkan monitoring dan verifikasi laboratorium.";
    }

    private static String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private static String normalizeNullable(String value) {
        return value == null ? "" : value.trim();
    }

    private static boolean isPositive(String value) {
        return containsAny(value, "positive", "pos", "+", "reactive", "yes");
    }

    private static boolean isNegative(String value) {
        return containsAny(value, "negative", "neg", "-", "non reactive", "no");
    }

    private static boolean containsAny(String value, String... tokens) {
        if (value == null) {
            return false;
        }
        String lower = value.toLowerCase(Locale.ROOT);
        for (String token : tokens) {
            if (lower.contains(token.toLowerCase(Locale.ROOT))) {
                return true;
            }
        }
        return false;
    }

    private static double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    private record PatientRecord(
            String id,
            String fullName,
            String medicalRecordNumber,
            int age,
            String sex,
            String diabetesType,
            String woundLocation,
            String woundStage,
            String notes,
            Instant createdAt,
            Instant updatedAt) {

        PatientRecord withUpdatedAt(Instant newUpdatedAt) {
            return new PatientRecord(id, fullName, medicalRecordNumber, age, sex, diabetesType, woundLocation, woundStage, notes, createdAt, newUpdatedAt);
        }

        PatientResponse toResponse() {
            return new PatientResponse(id, fullName, medicalRecordNumber, age, sex, diabetesType, woundLocation, woundStage, notes, createdAt, updatedAt);
        }
    }

    private record LabRecord(
            String id,
            String patientId,
            String gramStain,
            String colonyMorphology,
            String indole,
            String methylRed,
            String vogesProskauer,
            String citrate,
            String cultureResult,
            String antibioticSensitivity,
            String imageUrl,
            Instant createdAt) {

        LabResultResponse toResponse() {
            return new LabResultResponse(id, patientId, gramStain, colonyMorphology, indole, methylRed, vogesProskauer, citrate, cultureResult, antibioticSensitivity, imageUrl, createdAt);
        }

        String combinedText() {
            return String.join(" ", gramStain, colonyMorphology, indole, methylRed, vogesProskauer, citrate, cultureResult, antibioticSensitivity).toLowerCase(Locale.ROOT);
        }

        String suggestedBacteria() {
            if (containsAny(combinedText(), "escherichia")) {
                return "Escherichia coli";
            }
            if (containsAny(combinedText(), "klebsiella")) {
                return "Klebsiella pneumoniae";
            }
            if (containsAny(combinedText(), "staph")) {
                return "Staphylococcus aureus";
            }
            return "Mixed bacterial profile";
        }
    }
}
