package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InstitutionalImpactSummary {
    private long totalPatientsScreened;
    private long totalLabResultsAnalyzed;
    private long highRiskCasesDetected;
    private long lowConfidenceCasesFlaggedForCulture;
    private long referralsApproved;
    private long estimatedAmputationsPrevented;
    private double estimatedHoursSaved;
}
