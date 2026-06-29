package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import woundify_backend.model.LaboratoryResult;
import java.util.List;
import java.util.UUID;

@Repository
public interface LaboratoryResultRepository extends JpaRepository<LaboratoryResult, UUID> {
    List<LaboratoryResult> findByPatientIdOrderByCreatedAtDesc(UUID patientId);
}
