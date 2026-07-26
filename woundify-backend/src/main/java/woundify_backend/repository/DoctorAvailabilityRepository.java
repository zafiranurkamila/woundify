package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import woundify_backend.model.DoctorAvailability;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface DoctorAvailabilityRepository extends JpaRepository<DoctorAvailability, UUID> {

    List<DoctorAvailability> findByDoctorIdOrderBySlotDateTimeAsc(UUID doctorId);

    List<DoctorAvailability> findByDoctorIdAndBookedFalseAndSlotDateTimeAfterOrderBySlotDateTimeAsc(
            UUID doctorId, LocalDateTime after);
}
