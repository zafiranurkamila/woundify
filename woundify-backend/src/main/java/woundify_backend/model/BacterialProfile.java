package woundify_backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

@Entity
@Table(name = "bacterial_profiles")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BacterialProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(unique = true, nullable = false)
    private String name;

    @Column(name = "gram_stain_characteristic", nullable = false)
    private String gramStainCharacteristic;

    @Column(nullable = false)
    private String shape;

    @Column(name = "imvic_indole", nullable = false)
    private String imvicIndole;

    @Column(name = "imvic_methyl_red", nullable = false)
    private String imvicMethylRed;

    @Column(name = "imvic_voges_proskauer", nullable = false)
    private String imvicVogesProskauer;

    @Column(name = "imvic_citrate", nullable = false)
    private String imvicCitrate;

    @Column(name = "colony_morphology", columnDefinition = "TEXT")
    private String colonyMorphology;

    @Enumerated(EnumType.STRING)
    @Column(name = "risk_level", nullable = false)
    private RiskLevel riskLevel;

    @Column(columnDefinition = "TEXT")
    private String description;

    public enum RiskLevel {
        LOW,
        MEDIUM,
        HIGH
    }
}
