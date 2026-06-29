package woundify_backend.service;

import org.springframework.stereotype.Service;
import woundify_backend.dto.PatientRequest;
import woundify_backend.dto.PatientResponse;
import woundify_backend.model.Patient;
import woundify_backend.model.User;
import woundify_backend.repository.PatientRepository;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class PatientService {

    private final PatientRepository patientRepository;

    public PatientService(PatientRepository patientRepository) {
        this.patientRepository = patientRepository;
    }

    public PatientResponse createPatient(PatientRequest request, User currentUser) {
        Patient patient = Patient.builder()
                .name(request.getName())
                .gender(Patient.Gender.valueOf(request.getGender().toUpperCase()))
                .birthDate(request.getBirthDate())
                .diabetesType(Patient.DiabetesType.valueOf(request.getDiabetesType().toUpperCase()))
                .medicalHistory(request.getMedicalHistory())
                .createdBy(currentUser)
                .build();

        Patient saved = patientRepository.save(patient);
        return mapToResponse(saved);
    }

    public List<PatientResponse> getAllPatients() {
        return patientRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public PatientResponse getPatientById(UUID id) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Patient not found with id: " + id));
        return mapToResponse(patient);
    }

    public Patient getPatientEntityById(UUID id) {
        return patientRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Patient not found with id: " + id));
    }

    private PatientResponse mapToResponse(Patient patient) {
        return PatientResponse.builder()
                .id(patient.getId())
                .name(patient.getName())
                .gender(patient.getGender().name())
                .birthDate(patient.getBirthDate())
                .diabetesType(patient.getDiabetesType().name())
                .medicalHistory(patient.getMedicalHistory())
                .createdById(patient.getCreatedBy().getId())
                .createdByName(patient.getCreatedBy().getName())
                .createdAt(patient.getCreatedAt())
                .build();
    }
}
