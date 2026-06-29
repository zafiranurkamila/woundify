package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import woundify_backend.model.PatientReferral;

import java.util.List;
import java.util.UUID;

@Repository
public interface PatientReferralRepository extends JpaRepository<PatientReferral, UUID> {
    List<PatientReferral> findByPatientIdOrderByRequestedAtDesc(UUID patientId);

    List<PatientReferral> findByTargetDoctorIdOrderByRequestedAtDesc(UUID doctorId);

    long countByStatus(PatientReferral.Status status);
}
