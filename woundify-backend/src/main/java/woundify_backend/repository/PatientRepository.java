package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import woundify_backend.model.Patient;
import woundify_backend.model.User;
import java.util.List;
import java.util.UUID;

@Repository
public interface PatientRepository extends JpaRepository<Patient, UUID> {
    long countByCreatedBy(User createdBy);

    // Isolasi data per instansi: pasien hanya terlihat oleh pengguna dari instansi yang sama
    List<Patient> findByCreatedBy_Institution(String institution);
    List<Patient> findByCreatedBy_InstitutionIsNull();
}
