package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import woundify_backend.model.AiPrediction;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AiPredictionRepository extends JpaRepository<AiPrediction, UUID> {
    Optional<AiPrediction> findByLaboratoryResultId(UUID laboratoryResultId);

    long countByComplicationRiskLevel(AiPrediction.RiskLevel level);

    long countByInfectionRiskLevel(AiPrediction.RiskLevel level);

    long countByLowConfidenceTrue();
}
