package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PatientResponse {
    private UUID id;
    private String name;
    private String gender;
    private LocalDate birthDate;
    private String diabetesType;
    private String medicalHistory;
    private UUID createdById;
    private String createdByName;
    private LocalDateTime createdAt;
}
