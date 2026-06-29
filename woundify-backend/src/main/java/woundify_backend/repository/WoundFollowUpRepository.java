package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import woundify_backend.model.WoundFollowUp;

import java.util.List;
import java.util.UUID;

@Repository
public interface WoundFollowUpRepository extends JpaRepository<WoundFollowUp, UUID> {
    List<WoundFollowUp> findByPatientIdOrderByRecordedAtDesc(UUID patientId);
}
