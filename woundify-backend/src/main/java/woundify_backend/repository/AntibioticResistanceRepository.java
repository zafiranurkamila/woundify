package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import woundify_backend.model.AntibioticResistance;
import java.util.List;
import java.util.UUID;

@Repository
public interface AntibioticResistanceRepository extends JpaRepository<AntibioticResistance, UUID> {
    List<AntibioticResistance> findByBacterialProfileId(UUID bacterialProfileId);
}
