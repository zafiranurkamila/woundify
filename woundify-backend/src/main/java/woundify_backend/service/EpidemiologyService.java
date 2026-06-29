package woundify_backend.service;

import org.springframework.stereotype.Service;
import woundify_backend.model.EpidemiologyData;
import woundify_backend.repository.EpidemiologyDataRepository;
import java.util.List;

@Service
public class EpidemiologyService {

    private final EpidemiologyDataRepository epidemiologyRepository;

    public EpidemiologyService(EpidemiologyDataRepository epidemiologyRepository) {
        this.epidemiologyRepository = epidemiologyRepository;
    }

    public List<EpidemiologyData> getAllEpidemiologyData() {
        return epidemiologyRepository.findAll();
    }

    public List<EpidemiologyData> getEpidemiologyByRegion(String region) {
        return epidemiologyRepository.findByPatientRegion(region);
    }

    public EpidemiologyData saveEpidemiologyRecord(EpidemiologyData record) {
        return epidemiologyRepository.save(record);
    }
}
