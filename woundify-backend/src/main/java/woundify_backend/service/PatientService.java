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

    /**
     * Mengembalikan pasien milik instansi yang sama dengan pengguna. Data antar
     * instansi (mis. RS A vs RS B) tidak saling terlihat.
     */
    public List<PatientResponse> getPatientsForUser(User user) {
        String institution = user.getInstitution();
        List<Patient> patients = (institution == null || institution.isBlank())
                ? patientRepository.findByCreatedBy_InstitutionIsNull()
                : patientRepository.findByCreatedBy_Institution(institution);
        return patients.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public PatientResponse getPatientById(UUID id, User user) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Patient not found with id: " + id));
        if (!sameInstitution(patient, user)) {
            throw new RuntimeException("Data pasien ini milik instansi lain dan tidak dapat diakses.");
        }
        return mapToResponse(patient);
    }

    private boolean sameInstitution(Patient patient, User user) {
        String owner = patient.getCreatedBy().getInstitution();
        String viewer = user.getInstitution();
        if (owner == null || owner.isBlank()) {
            return viewer == null || viewer.isBlank();
        }
        return owner.equals(viewer);
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
