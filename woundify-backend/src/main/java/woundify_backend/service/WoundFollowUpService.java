package woundify_backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import woundify_backend.dto.WoundFollowUpRequest;
import woundify_backend.dto.WoundFollowUpResponse;
import woundify_backend.model.Patient;
import woundify_backend.model.User;
import woundify_backend.model.WoundFollowUp;
import woundify_backend.repository.WoundFollowUpRepository;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class WoundFollowUpService {

    private final WoundFollowUpRepository followUpRepository;
    private final PatientService patientService;

    public WoundFollowUpService(WoundFollowUpRepository followUpRepository, PatientService patientService) {
        this.followUpRepository = followUpRepository;
        this.patientService = patientService;
    }

    @Transactional
    public WoundFollowUpResponse createFollowUp(WoundFollowUpRequest request, User currentUser) {
        if (request.getPatientId() == null) {
            throw new RuntimeException("Pasien wajib dipilih");
        }
        if (request.getStatus() == null || request.getStatus().isBlank()) {
            throw new RuntimeException("Status tindak lanjut wajib diisi");
        }

        Patient patient = patientService.getPatientEntityById(request.getPatientId());

        WoundFollowUp followUp = WoundFollowUp.builder()
                .patient(patient)
                .status(WoundFollowUp.Status.valueOf(request.getStatus().toUpperCase()))
                .notes(request.getNotes() == null ? "" : request.getNotes().trim())
                .recordedBy(currentUser)
                .build();

        return mapToResponse(followUpRepository.save(followUp));
    }

    @Transactional(readOnly = true)
    public List<WoundFollowUpResponse> getPatientFollowUps(UUID patientId) {
        return followUpRepository.findByPatientIdOrderByRecordedAtDesc(patientId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private WoundFollowUpResponse mapToResponse(WoundFollowUp followUp) {
        return WoundFollowUpResponse.builder()
                .id(followUp.getId())
                .patientId(followUp.getPatient().getId())
                .status(followUp.getStatus().name())
                .notes(followUp.getNotes())
                .recordedById(followUp.getRecordedBy().getId())
                .recordedByName(followUp.getRecordedBy().getName())
                .recordedAt(followUp.getRecordedAt())
                .build();
    }
}
