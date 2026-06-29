package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import woundify_backend.model.BacterialProfile;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BacterialProfileRepository extends JpaRepository<BacterialProfile, UUID> {
    Optional<BacterialProfile> findByName(String name);
}
