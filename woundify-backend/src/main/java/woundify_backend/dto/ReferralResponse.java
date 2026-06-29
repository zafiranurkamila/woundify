package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReferralResponse {
    private UUID id;
    private UUID patientId;
    private String patientName;
    private UUID requestedById;
    private String requestedByName;
    private UUID targetDoctorId;
    private String targetDoctorName;
    private String targetDoctorEmail;
    private String reason;
    private String clinicalNotes;
    private String status;
    private String verificationNote;
    private UUID verifiedById;
    private String verifiedByName;
    private LocalDateTime requestedAt;
    private LocalDateTime verifiedAt;
}
