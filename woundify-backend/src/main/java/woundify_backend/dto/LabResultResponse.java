package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LabResultResponse {
    private UUID id;
    private UUID patientId;
    private String patientName;
    private String woundPhotoUrl;
    private String colonyMorphology;
    private String gramStain;
    private String imvicIndole;
    private String imvicMethylRed;
    private String imvicVogesProskauer;
    private String imvicCitrate;
    private String cultureResult;
    private String antibioticSusceptibility;
    private String ocrRawText;
    private String macconkey;
    private String colonyTexture;
    private String colonySize;
    private UUID checkedById;
    private String checkedByName;
    private LocalDateTime createdAt;
    
    // Prediction data nested for convenient response
    private PredictionResponse prediction;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PredictionResponse {
        private UUID id;
        private String predictedBacteria;
        private String infectionRiskLevel;
        private String chronicRiskLevel;
        private String complicationRiskLevel;
        private Double confidenceScore;
        private String recommendations;
        private List<DifferentialItem> differentialDiagnosis;
        private List<String> reasoning;
        private Boolean lowConfidence;
        private String disclaimer;
        private LocalDateTime predictedAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DifferentialItem {
        private String bacteria;
        private Double probability;
    }
}
