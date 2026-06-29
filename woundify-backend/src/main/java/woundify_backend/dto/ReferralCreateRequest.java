package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReferralCreateRequest {
    private UUID patientId;
    private UUID targetDoctorId;
    private String reason;
    private String clinicalNotes;
}
