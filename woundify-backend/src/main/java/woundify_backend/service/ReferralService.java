package woundify_backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import woundify_backend.dto.ReferralCreateRequest;
import woundify_backend.dto.ReferralResponse;
import woundify_backend.dto.ReferralVerifyRequest;
import woundify_backend.model.DoctorAvailability;
import woundify_backend.model.Patient;
import woundify_backend.model.PatientReferral;
import woundify_backend.model.User;
import woundify_backend.repository.DoctorAvailabilityRepository;
import woundify_backend.repository.PatientReferralRepository;
import woundify_backend.repository.UserRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ReferralService {

    private final PatientReferralRepository referralRepository;
    private final PatientService patientService;
    private final UserRepository userRepository;
    private final DoctorAvailabilityRepository availabilityRepository;

    public ReferralService(PatientReferralRepository referralRepository,
                           PatientService patientService,
                           UserRepository userRepository,
                           DoctorAvailabilityRepository availabilityRepository) {
        this.referralRepository = referralRepository;
        this.patientService = patientService;
        this.userRepository = userRepository;
        this.availabilityRepository = availabilityRepository;
    }

    @Transactional
    public ReferralResponse createReferral(ReferralCreateRequest request, User currentUser) {
        if (request.getPatientId() == null || request.getTargetDoctorId() == null) {
            throw new RuntimeException("Patient dan dokter tujuan wajib dipilih");
        }
        if (request.getReason() == null || request.getReason().isBlank()) {
            throw new RuntimeException("Alasan rujukan wajib diisi");
        }

        Patient patient = patientService.getPatientEntityById(request.getPatientId());
        User targetDoctor = userRepository.findById(request.getTargetDoctorId())
                .orElseThrow(() -> new RuntimeException("Tujuan rujukan tidak ditemukan"));

        // Jika perawat memilih slot jadwal dokter, tandai slot terpakai & simpan waktu janji temu
        LocalDateTime appointmentAt = null;
        if (request.getAvailabilitySlotId() != null) {
            DoctorAvailability slot = availabilityRepository.findById(request.getAvailabilitySlotId())
                    .orElseThrow(() -> new RuntimeException("Jadwal yang dipilih tidak ditemukan."));
            if (!slot.getDoctor().getId().equals(targetDoctor.getId())) {
                throw new RuntimeException("Jadwal tidak sesuai dengan dokter tujuan.");
            }
            if (slot.isBooked()) {
                throw new RuntimeException("Jadwal sudah dipakai rujukan lain. Silakan pilih jadwal lain.");
            }
            slot.setBooked(true);
            availabilityRepository.save(slot);
            appointmentAt = slot.getSlotDateTime();
        }

        PatientReferral referral = PatientReferral.builder()
                .patient(patient)
                .requestedBy(currentUser)
                .targetDoctor(targetDoctor)
                .reason(request.getReason().trim())
                .clinicalNotes(request.getClinicalNotes() == null ? "" : request.getClinicalNotes().trim())
                .status(PatientReferral.Status.PENDING)
                .appointmentAt(appointmentAt)
                .build();

        return mapToResponse(referralRepository.save(referral));
    }

    @Transactional(readOnly = true)
    public List<ReferralResponse> getPatientReferrals(UUID patientId) {
        return referralRepository.findByPatientIdOrderByRequestedAtDesc(patientId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ReferralResponse> getIncomingReferralsForDoctor(User doctor) {
        return referralRepository.findByTargetDoctorIdOrderByRequestedAtDesc(doctor.getId())
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public ReferralResponse verifyReferral(UUID referralId, ReferralVerifyRequest request, User doctor) {
        PatientReferral referral = referralRepository.findById(referralId)
                .orElseThrow(() -> new RuntimeException("Rujukan tidak ditemukan"));

        if (!referral.getTargetDoctor().getId().equals(doctor.getId())) {
            throw new RuntimeException("Hanya dokter tujuan yang dapat memverifikasi rujukan");
        }

        if (referral.getStatus() != PatientReferral.Status.PENDING) {
            throw new RuntimeException("Rujukan sudah diverifikasi");
        }

        referral.setStatus(request.isApproved() ? PatientReferral.Status.APPROVED : PatientReferral.Status.REJECTED);
        referral.setVerificationNote(request.getVerificationNote() == null ? "" : request.getVerificationNote().trim());
        referral.setVerifiedBy(doctor);
        referral.setVerifiedAt(LocalDateTime.now());

        return mapToResponse(referralRepository.save(referral));
    }

    private ReferralResponse mapToResponse(PatientReferral referral) {
        return ReferralResponse.builder()
                .id(referral.getId())
                .patientId(referral.getPatient().getId())
                .patientName(referral.getPatient().getName())
                .requestedById(referral.getRequestedBy().getId())
                .requestedByName(referral.getRequestedBy().getName())
                .targetDoctorId(referral.getTargetDoctor().getId())
                .targetDoctorName(referral.getTargetDoctor().getName())
                .targetDoctorEmail(referral.getTargetDoctor().getEmail())
                .reason(referral.getReason())
                .clinicalNotes(referral.getClinicalNotes())
                .status(referral.getStatus().name())
                .verificationNote(referral.getVerificationNote())
                .verifiedById(referral.getVerifiedBy() != null ? referral.getVerifiedBy().getId() : null)
                .verifiedByName(referral.getVerifiedBy() != null ? referral.getVerifiedBy().getName() : null)
                .requestedAt(referral.getRequestedAt())
                .verifiedAt(referral.getVerifiedAt())
                .appointmentAt(referral.getAppointmentAt())
                .build();
    }
}
