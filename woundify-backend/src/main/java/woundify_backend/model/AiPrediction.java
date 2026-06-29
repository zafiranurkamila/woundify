package woundify_backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "ai_predictions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiPrediction {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "laboratory_result_id", nullable = false)
    private LaboratoryResult laboratoryResult;

    @Column(name = "predicted_bacteria", nullable = false)
    private String predictedBacteria;

    @Enumerated(EnumType.STRING)
    @Column(name = "infection_risk_level", nullable = false)
    private RiskLevel infectionRiskLevel;

    @Enumerated(EnumType.STRING)
    @Column(name = "chronic_risk_level", nullable = false)
    private RiskLevel chronicRiskLevel;

    @Enumerated(EnumType.STRING)
    @Column(name = "complication_risk_level", nullable = false)
    private RiskLevel complicationRiskLevel;

    @Column(name = "confidence_score", nullable = false)
    private Double confidenceScore;

    @Column(columnDefinition = "TEXT")
    private String recommendations;

    @Column(name = "differential_diagnosis_json", columnDefinition = "TEXT")
    private String differentialDiagnosisJson;

    @Column(name = "reasoning_json", columnDefinition = "TEXT")
    private String reasoningJson;

    @Column(name = "low_confidence")
    private Boolean lowConfidence;

    @Column(name = "predicted_at", nullable = false, updatable = false)
    private LocalDateTime predictedAt;

    @PrePersist
    protected void onCreate() {
        predictedAt = LocalDateTime.now();
    }

    public enum RiskLevel {
        LOW,
        MEDIUM,
        HIGH
    }
}
