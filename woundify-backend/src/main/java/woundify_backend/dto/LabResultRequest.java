package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LabResultRequest {
    private UUID patientId;
    private String woundPhotoUrl;
    private String colonyMorphology;
    private String gramStain;
    private String imvicIndole;
    private String imvicMethylRed;
    private String imvicVogesProskauer;
    private String imvicCitrate;
    private String cultureResult;
    private String antibioticSusceptibility; // JSON format mapping
    private String ocrRawText;
    private String macconkey;
    private String colonyTexture;
    private String colonySize;
    private Boolean noSignificantGrowth;
    private String h2s;
    private String motil;
    private String urease;
    private Integer tsi;
    private Integer emb;
    private String nas;
}
