package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class WoundFollowUpRequest {
    private UUID patientId;
    private String status; // IMPROVING, STABLE, WORSENING, HEALED
    private String notes;
}
