package woundify_backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "epidemiology_data")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EpidemiologyData {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bacterial_profile_id", nullable = false)
    private BacterialProfile bacterialProfile;

    @Column(name = "patient_region", nullable = false)
    private String patientRegion;

    @Column(name = "infection_date", nullable = false)
    private LocalDate infectionDate;

    @Column(name = "case_count", nullable = false)
    private Integer caseCount;

    @Column(name = "antibiotic_resistance_rate", nullable = false)
    private Double antibioticResistanceRate;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
