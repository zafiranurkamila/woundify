package woundify_backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import woundify_backend.dto.AvailabilityResponse;
import woundify_backend.model.DoctorAvailability;
import woundify_backend.model.User;
import woundify_backend.repository.DoctorAvailabilityRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class DoctorAvailabilityService {

    private final DoctorAvailabilityRepository repository;

    public DoctorAvailabilityService(DoctorAvailabilityRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public AvailabilityResponse addSlot(User doctor, String slotDateTimeIso) {
        LocalDateTime dateTime;
        try {
            dateTime = LocalDateTime.parse(slotDateTimeIso);
        } catch (Exception e) {
            throw new RuntimeException("Format tanggal/jam tidak valid.");
        }
        if (dateTime.isBefore(LocalDateTime.now())) {
            throw new RuntimeException("Jadwal tidak boleh di waktu yang sudah lewat.");
        }
        DoctorAvailability slot = DoctorAvailability.builder()
                .doctor(doctor)
                .slotDateTime(dateTime)
                .booked(false)
                .build();
        return mapToResponse(repository.save(slot));
    }

    @Transactional(readOnly = true)
    public List<AvailabilityResponse> getFreeSlots(UUID doctorId) {
        return repository
                .findByDoctorIdAndBookedFalseAndSlotDateTimeAfterOrderBySlotDateTimeAsc(doctorId, LocalDateTime.now())
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AvailabilityResponse> getMySlots(User doctor) {
        return repository.findByDoctorIdOrderBySlotDateTimeAsc(doctor.getId())
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteSlot(UUID slotId, User doctor) {
        DoctorAvailability slot = repository.findById(slotId)
                .orElseThrow(() -> new RuntimeException("Jadwal tidak ditemukan."));
        if (!slot.getDoctor().getId().equals(doctor.getId())) {
            throw new RuntimeException("Anda hanya dapat menghapus jadwal milik sendiri.");
        }
        if (slot.isBooked()) {
            throw new RuntimeException("Jadwal yang sudah dipakai rujukan tidak dapat dihapus.");
        }
        repository.delete(slot);
    }

    private AvailabilityResponse mapToResponse(DoctorAvailability slot) {
        return AvailabilityResponse.builder()
                .id(slot.getId())
                .doctorId(slot.getDoctor().getId())
                .doctorName(slot.getDoctor().getName())
                .slotDateTime(slot.getSlotDateTime())
                .booked(slot.isBooked())
                .build();
    }
}
