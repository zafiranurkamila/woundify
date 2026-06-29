package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import woundify_backend.model.EpidemiologyData;
import java.util.List;
import java.util.UUID;

@Repository
public interface EpidemiologyDataRepository extends JpaRepository<EpidemiologyData, UUID> {
    List<EpidemiologyData> findByPatientRegion(String patientRegion);
}
