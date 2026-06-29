package woundify_backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "laboratory_results")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LaboratoryResult {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @Column(name = "wound_photo_url")
    private String woundPhotoUrl;

    @Column(name = "colony_morphology", columnDefinition = "TEXT")
    private String colonyMorphology;

    @Column(name = "gram_stain")
    private String gramStain;

    @Column(name = "imvic_indole")
    private String imvicIndole;

    @Column(name = "imvic_methyl_red")
    private String imvicMethylRed;

    @Column(name = "imvic_voges_proskauer")
    private String imvicVogesProskauer;

    @Column(name = "imvic_citrate")
    private String imvicCitrate;

    @Column(name = "culture_result", columnDefinition = "TEXT")
    private String cultureResult;

    @Column(name = "antibiotic_susceptibility", columnDefinition = "TEXT")
    private String antibioticSusceptibility; // JSON format string mapping drug to resistance

    @Column(name = "ocr_raw_text", columnDefinition = "TEXT")
    private String ocrRawText;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "checked_by")
    private User checkedBy;

    @Column(name = "macconkey")
    private String macconkey;

    @Column(name = "colony_texture")
    private String colonyTexture;

    @Column(name = "colony_size")
    private String colonySize;

    @Column(name = "h2s")
    private String h2s;

    @Column(name = "motil")
    private String motil;

    @Column(name = "urease")
    private String urease;

    @Column(name = "tsi")
    private Integer tsi;

    @Column(name = "emb")
    private Integer emb;

    @Column(name = "nas")
    private String nas;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
