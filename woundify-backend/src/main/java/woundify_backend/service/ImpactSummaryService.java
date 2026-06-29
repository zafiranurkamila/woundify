package woundify_backend.service;

import org.springframework.stereotype.Service;
import woundify_backend.dto.InstitutionalImpactSummary;
import woundify_backend.model.AiPrediction;
import woundify_backend.model.PatientReferral;
import woundify_backend.repository.AiPredictionRepository;
import woundify_backend.repository.LaboratoryResultRepository;
import woundify_backend.repository.PatientReferralRepository;
import woundify_backend.repository.PatientRepository;

@Service
public class ImpactSummaryService {

    // Heuristics derived from the diabetic foot ulcer literature this product targets:
    // ~30% of high-complication-risk wounds progress to amputation without early intervention,
    // and a manual microbiology workup (IMViC + risk scoring) takes a tech ~20 minutes vs instant AI inference.
    private static final double AMPUTATION_PREVENTION_RATE = 0.30;
    private static final double MINUTES_SAVED_PER_ANALYSIS = 20.0;

    private final PatientRepository patientRepository;
    private final LaboratoryResultRepository laboratoryResultRepository;
    private final AiPredictionRepository aiPredictionRepository;
    private final PatientReferralRepository patientReferralRepository;

    public ImpactSummaryService(PatientRepository patientRepository,
                                 LaboratoryResultRepository laboratoryResultRepository,
                                 AiPredictionRepository aiPredictionRepository,
                                 PatientReferralRepository patientReferralRepository) {
        this.patientRepository = patientRepository;
        this.laboratoryResultRepository = laboratoryResultRepository;
        this.aiPredictionRepository = aiPredictionRepository;
        this.patientReferralRepository = patientReferralRepository;
    }

    public InstitutionalImpactSummary getImpactSummary() {
        long totalPatients = patientRepository.count();
        long totalLabResults = laboratoryResultRepository.count();
        long highRiskCases = aiPredictionRepository.countByComplicationRiskLevel(AiPrediction.RiskLevel.HIGH);
        long lowConfidenceCases = aiPredictionRepository.countByLowConfidenceTrue();
        long referralsApproved = patientReferralRepository.countByStatus(PatientReferral.Status.APPROVED);

        long estimatedAmputationsPrevented = Math.round(highRiskCases * AMPUTATION_PREVENTION_RATE);
        double estimatedHoursSaved = (totalLabResults * MINUTES_SAVED_PER_ANALYSIS) / 60.0;

        return InstitutionalImpactSummary.builder()
                .totalPatientsScreened(totalPatients)
                .totalLabResultsAnalyzed(totalLabResults)
                .highRiskCasesDetected(highRiskCases)
                .lowConfidenceCasesFlaggedForCulture(lowConfidenceCases)
                .referralsApproved(referralsApproved)
                .estimatedAmputationsPrevented(estimatedAmputationsPrevented)
                .estimatedHoursSaved(estimatedHoursSaved)
                .build();
    }
}
