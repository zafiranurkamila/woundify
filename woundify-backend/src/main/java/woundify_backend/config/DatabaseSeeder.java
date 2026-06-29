package woundify_backend.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import woundify_backend.model.BacterialProfile;
import woundify_backend.model.EpidemiologyData;
import woundify_backend.repository.BacterialProfileRepository;
import woundify_backend.repository.EpidemiologyDataRepository;

import java.time.LocalDate;
import java.util.List;

@Component
public class DatabaseSeeder implements CommandLineRunner {

    private final BacterialProfileRepository profileRepository;
    private final EpidemiologyDataRepository epidemiologyRepository;

    public DatabaseSeeder(BacterialProfileRepository profileRepository,
                          EpidemiologyDataRepository epidemiologyRepository) {
        this.profileRepository = profileRepository;
        this.epidemiologyRepository = epidemiologyRepository;
    }

    @Override
    public void run(String... args) throws Exception {
        if (profileRepository.count() > 0) {
            return; // Already seeded
        }

        // 1. Seed Bacterial Profiles
        BacterialProfile staph = BacterialProfile.builder()
                .name("Staphylococcus aureus")
                .gramStainCharacteristic("GRAM_POSITIVE")
                .shape("COCCUS")
                .imvicIndole("NEGATIVE")
                .imvicMethylRed("POSITIVE")
                .imvicVogesProskauer("POSITIVE")
                .imvicCitrate("NEGATIVE")
                .colonyMorphology("Golden yellow colonies, circular, beta-hemolytic on blood agar")
                .riskLevel(BacterialProfile.RiskLevel.HIGH)
                .description("A major cause of diabetic foot infections. Forms biofilm, leading to chronic infections and high risk of complications.")
                .build();

        BacterialProfile pseudomonas = BacterialProfile.builder()
                .name("Pseudomonas aeruginosa")
                .gramStainCharacteristic("GRAM_NEGATIVE")
                .shape("BACILLUS")
                .imvicIndole("NEGATIVE")
                .imvicMethylRed("NEGATIVE")
                .imvicVogesProskauer("NEGATIVE")
                .imvicCitrate("POSITIVE")
                .colonyMorphology("Large, flat, greenish colonies with grape-like sweet odor")
                .riskLevel(BacterialProfile.RiskLevel.HIGH)
                .description("Opportunistic gram-negative pathogen. Frequently found in chronic wounds, highly resistant to many standard antibiotics.")
                .build();

        BacterialProfile ecoli = BacterialProfile.builder()
                .name("Escherichia coli")
                .gramStainCharacteristic("GRAM_NEGATIVE")
                .shape("BACILLUS")
                .imvicIndole("POSITIVE")
                .imvicMethylRed("POSITIVE")
                .imvicVogesProskauer("NEGATIVE")
                .imvicCitrate("NEGATIVE")
                .colonyMorphology("Metallic green sheen on EMB agar, flat, pink colonies on MacConkey")
                .riskLevel(BacterialProfile.RiskLevel.MEDIUM)
                .description("Gram-negative rod, standard member of human microflora but can cause deep wound infections in compromised patients.")
                .build();

        BacterialProfile klebsiella = BacterialProfile.builder()
                .name("Klebsiella pneumoniae")
                .gramStainCharacteristic("GRAM_NEGATIVE")
                .shape("BACILLUS")
                .imvicIndole("NEGATIVE")
                .imvicMethylRed("NEGATIVE")
                .imvicVogesProskauer("POSITIVE")
                .imvicCitrate("POSITIVE")
                .colonyMorphology("Mucoid, pink colonies on MacConkey agar")
                .riskLevel(BacterialProfile.RiskLevel.HIGH)
                .description("Encapsulated gram-negative rod, high risk of multidrug resistance (ESBL/KPC).")
                .build();

        profileRepository.saveAll(List.of(staph, pseudomonas, ecoli, klebsiella));

        // 2. Seed Epidemiology Data
        LocalDate now = LocalDate.now();
        
        epidemiologyRepository.saveAll(List.of(
            EpidemiologyData.builder()
                .bacterialProfile(staph)
                .patientRegion("Jakarta")
                .infectionDate(now.minusMonths(1))
                .caseCount(145)
                .antibioticResistanceRate(0.42) // 42% Methicillin Resistance
                .build(),
            EpidemiologyData.builder()
                .bacterialProfile(pseudomonas)
                .patientRegion("Jakarta")
                .infectionDate(now.minusMonths(1))
                .caseCount(98)
                .antibioticResistanceRate(0.31) // 31% Cipro Resistance
                .build(),
            EpidemiologyData.builder()
                .bacterialProfile(staph)
                .patientRegion("Surabaya")
                .infectionDate(now.minusMonths(1))
                .caseCount(112)
                .antibioticResistanceRate(0.38)
                .build(),
            EpidemiologyData.builder()
                .bacterialProfile(pseudomonas)
                .patientRegion("Surabaya")
                .infectionDate(now.minusMonths(1))
                .caseCount(85)
                .antibioticResistanceRate(0.28)
                .build()
        ));
    }
}
