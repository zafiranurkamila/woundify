package woundify_backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

@Entity
@Table(name = "antibiotic_resistances")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AntibioticResistance {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bacterial_profile_id", nullable = false)
    private BacterialProfile bacterialProfile;

    @Column(name = "antibiotic_name", nullable = false)
    private String antibioticName;

    @Enumerated(EnumType.STRING)
    @Column(name = "resistance_status", nullable = false)
    private ResistanceStatus resistanceStatus;

    public enum ResistanceStatus {
        SUSCEPTIBLE,
        INTERMEDIATE,
        RESISTANT
    }
}
