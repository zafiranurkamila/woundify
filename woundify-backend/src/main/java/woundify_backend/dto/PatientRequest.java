package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PatientRequest {
    private String name;
    private String gender; // MALE, FEMALE
    private LocalDate birthDate;
    private String diabetesType; // TYPE_1, TYPE_2, GESTATIONAL, OTHER
    private String medicalHistory;
}
