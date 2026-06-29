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
public class WoundFollowUpResponse {
    private UUID id;
    private UUID patientId;
    private String status;
    private String notes;
    private UUID recordedById;
    private String recordedByName;
    private LocalDateTime recordedAt;
}
