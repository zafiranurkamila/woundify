package woundify_backend.service;

import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import woundify_backend.dto.LabResultRequest;
import woundify_backend.dto.LabResultResponse;
import woundify_backend.model.*;
import woundify_backend.repository.AiPredictionRepository;
import woundify_backend.repository.LaboratoryResultRepository;

import java.time.LocalDate;
import java.time.Period;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class LabResultService {

    private static final String AI_DISCLAIMER =
            "Alat bantu keputusan klinis, bukan diagnosis. Konfirmasi dengan kultur laboratorium.";

    private final LaboratoryResultRepository labResultRepository;
    private final AiPredictionRepository predictionRepository;
    private final PatientService patientService;
    private final AiIntegrationService aiIntegrationService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public LabResultService(LaboratoryResultRepository labResultRepository,
                            AiPredictionRepository predictionRepository,
                            PatientService patientService,
                            AiIntegrationService aiIntegrationService) {
        this.labResultRepository = labResultRepository;
        this.predictionRepository = predictionRepository;
        this.patientService = patientService;
        this.aiIntegrationService = aiIntegrationService;
    }

    @Transactional
    public LabResultResponse createLabResult(LabResultRequest request, User currentUser) {
        Patient patient = patientService.getPatientEntityById(request.getPatientId());

        // 1. Save Laboratory Result
        LaboratoryResult labResult = LaboratoryResult.builder()
                .patient(patient)
                .woundPhotoUrl(request.getWoundPhotoUrl())
                .colonyMorphology(request.getColonyMorphology())
                .gramStain(request.getGramStain())
                .imvicIndole(request.getImvicIndole())
                .imvicMethylRed(request.getImvicMethylRed())
                .imvicVogesProskauer(request.getImvicVogesProskauer())
                .imvicCitrate(request.getImvicCitrate())
                .cultureResult(request.getCultureResult())
                .antibioticSusceptibility(request.getAntibioticSusceptibility())
                .ocrRawText(request.getOcrRawText())
                .macconkey(request.getMacconkey())
                .colonyTexture(request.getColonyTexture())
                .colonySize(request.getColonySize())
                .h2s(request.getH2s())
                .motil(request.getMotil())
                .urease(request.getUrease())
                .tsi(request.getTsi())
                .emb(request.getEmb())
                .nas(request.getNas())
                .checkedBy(currentUser)
                .build();

        LaboratoryResult savedLab = labResultRepository.save(labResult);

        AiPrediction savedPred = null;

        // 2. Trigger AI Prediction (best effort)
        try {
            int age = Period.between(patient.getBirthDate(), LocalDate.now()).getYears();
            Map<String, Object> predictionReq = new HashMap<>();
            predictionReq.put("gram_stain", request.getGramStain());
            String shape = "BACILLUS";
            if (request.getColonyMorphology() != null && request.getColonyMorphology().toLowerCase().contains("coccus")) {
                shape = "COCCUS";
            }
            predictionReq.put("shape", shape);
            predictionReq.put("imvic_indole", request.getImvicIndole());
            predictionReq.put("imvic_methyl_red", request.getImvicMethylRed());
            predictionReq.put("imvic_voges_proskauer", request.getImvicVogesProskauer());
            predictionReq.put("imvic_citrate", request.getImvicCitrate());
            predictionReq.put("patient_age", age);
            predictionReq.put("diabetes_type", patient.getDiabetesType().name());
            predictionReq.put("hba1c", 7.8);
            predictionReq.put("macconkey", request.getMacconkey() != null ? request.getMacconkey() : "NON_LACTOSE_FERMENTER");
            predictionReq.put("colony_texture", request.getColonyTexture());
            predictionReq.put("colony_size", request.getColonySize());
            predictionReq.put("no_significant_growth", Boolean.TRUE.equals(request.getNoSignificantGrowth()));
            predictionReq.put("h2s", request.getH2s() != null ? request.getH2s() : "NEGATIVE");
            predictionReq.put("motil", request.getMotil() != null ? request.getMotil() : "NEGATIVE");
            predictionReq.put("urease", request.getUrease() != null ? request.getUrease() : "NEGATIVE");
            predictionReq.put("tsi", request.getTsi() != null ? request.getTsi() : 3);
            predictionReq.put("emb", request.getEmb() != null ? request.getEmb() : 0);
            predictionReq.put("nas", request.getNas() != null ? request.getNas() : "NEGATIVE");

            Map<String, Object> aiResult = aiIntegrationService.getPrediction(predictionReq);

            AiPrediction prediction = AiPrediction.builder()
                    .laboratoryResult(savedLab)
                    .predictedBacteria((String) aiResult.get("predicted_bacteria"))
                    .infectionRiskLevel(AiPrediction.RiskLevel.valueOf(((String) aiResult.get("infection_risk_level")).toUpperCase()))
                    .chronicRiskLevel(AiPrediction.RiskLevel.valueOf(((String) aiResult.get("chronic_risk_level")).toUpperCase()))
                    .complicationRiskLevel(AiPrediction.RiskLevel.valueOf(((String) aiResult.get("complication_risk_level")).toUpperCase()))
                    .confidenceScore(((Number) aiResult.get("confidence_score")).doubleValue())
                    .recommendations((String) aiResult.get("recommendations"))
                    .differentialDiagnosisJson(toJson(aiResult.get("differential_diagnosis")))
                    .reasoningJson(toJson(aiResult.get("prediction_reasoning")))
                    .lowConfidence(Boolean.TRUE.equals(aiResult.get("low_confidence")))
                    .build();

            savedPred = predictionRepository.save(prediction);
        } catch (Exception ignored) {
            // Keep lab data persisted even when AI service is unavailable.
        }

        return mapToResponse(savedLab, savedPred);
    }

    @Transactional(readOnly = true)
    public LabResultResponse getLabResultById(UUID id) {
        LaboratoryResult result = labResultRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Lab result not found with id: " + id));
        AiPrediction prediction = predictionRepository.findByLaboratoryResultId(id).orElse(null);
        return mapToResponse(result, prediction);
    }

    @Transactional(readOnly = true)
    public List<LabResultResponse> getPatientLabHistory(UUID patientId) {
        return labResultRepository.findByPatientIdOrderByCreatedAtDesc(patientId).stream()
                .map(res -> {
                    AiPrediction pred = predictionRepository.findByLaboratoryResultId(res.getId()).orElse(null);
                    return mapToResponse(res, pred);
                })
                .collect(Collectors.toList());
    }

    public Map<String, Object> processLabOcr(MultipartFile file) {
        return aiIntegrationService.performOcr(file);
    }

    private String toJson(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception e) {
            return null;
        }
    }

    private List<LabResultResponse.DifferentialItem> parseDifferential(String json) {
        if (json == null) {
            return Collections.emptyList();
        }
        try {
            List<Map<String, Object>> raw = objectMapper.readValue(json, new TypeReference<List<Map<String, Object>>>() {});
            return raw.stream()
                    .map(item -> LabResultResponse.DifferentialItem.builder()
                            .bacteria((String) item.get("bacteria"))
                            .probability(((Number) item.get("probability")).doubleValue())
                            .build())
                    .collect(Collectors.toList());
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private List<String> parseReasoning(String json) {
        if (json == null) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private LabResultResponse mapToResponse(LaboratoryResult result, AiPrediction prediction) {
        LabResultResponse.PredictionResponse predResponse = null;
        if (prediction != null) {
            predResponse = LabResultResponse.PredictionResponse.builder()
                    .id(prediction.getId())
                    .predictedBacteria(prediction.getPredictedBacteria())
                    .infectionRiskLevel(prediction.getInfectionRiskLevel().name())
                    .chronicRiskLevel(prediction.getChronicRiskLevel().name())
                    .complicationRiskLevel(prediction.getComplicationRiskLevel().name())
                    .confidenceScore(prediction.getConfidenceScore())
                    .recommendations(prediction.getRecommendations())
                    .differentialDiagnosis(parseDifferential(prediction.getDifferentialDiagnosisJson()))
                    .reasoning(parseReasoning(prediction.getReasoningJson()))
                    .lowConfidence(prediction.getLowConfidence())
                    .disclaimer(AI_DISCLAIMER)
                    .predictedAt(prediction.getPredictedAt())
                    .build();
        }

        return LabResultResponse.builder()
                .id(result.getId())
                .patientId(result.getPatient().getId())
                .patientName(result.getPatient().getName())
                .woundPhotoUrl(result.getWoundPhotoUrl())
                .colonyMorphology(result.getColonyMorphology())
                .gramStain(result.getGramStain())
                .imvicIndole(result.getImvicIndole())
                .imvicMethylRed(result.getImvicMethylRed())
                .imvicVogesProskauer(result.getImvicVogesProskauer())
                .imvicCitrate(result.getImvicCitrate())
                .cultureResult(result.getCultureResult())
                .antibioticSusceptibility(result.getAntibioticSusceptibility())
                .ocrRawText(result.getOcrRawText())
                .macconkey(result.getMacconkey())
                .colonyTexture(result.getColonyTexture())
                .colonySize(result.getColonySize())
                .checkedById(result.getCheckedBy() != null ? result.getCheckedBy().getId() : null)
                .checkedByName(result.getCheckedBy() != null ? result.getCheckedBy().getName() : "System")
                .createdAt(result.getCreatedAt())
                .prediction(predResponse)
                .build();
    }
}
