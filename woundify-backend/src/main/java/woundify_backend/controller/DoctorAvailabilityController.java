package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import woundify_backend.dto.AvailabilityCreateRequest;
import woundify_backend.dto.AvailabilityResponse;
import woundify_backend.model.User;
import woundify_backend.service.DoctorAvailabilityService;
import woundify_backend.service.UserService;

import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/availability")
public class DoctorAvailabilityController {

    private final DoctorAvailabilityService availabilityService;
    private final UserService userService;

    public DoctorAvailabilityController(DoctorAvailabilityService availabilityService, UserService userService) {
        this.availabilityService = availabilityService;
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<AvailabilityResponse> addSlot(@RequestBody AvailabilityCreateRequest request, Principal principal) {
        return ResponseEntity.ok(availabilityService.addSlot(resolveUser(principal), request.getSlotDateTime()));
    }

    // Slot kosong (belum dipakai) milik seorang dokter — dipakai perawat saat memilih jadwal rujukan
    @GetMapping("/doctor/{doctorId}")
    public ResponseEntity<List<AvailabilityResponse>> getFreeSlots(@PathVariable UUID doctorId) {
        return ResponseEntity.ok(availabilityService.getFreeSlots(doctorId));
    }

    // Semua jadwal milik dokter yang sedang login (untuk halaman profil/jadwal dokter)
    @GetMapping("/me")
    public ResponseEntity<List<AvailabilityResponse>> getMySlots(Principal principal) {
        return ResponseEntity.ok(availabilityService.getMySlots(resolveUser(principal)));
    }

    @DeleteMapping("/{slotId}")
    public ResponseEntity<Map<String, String>> deleteSlot(@PathVariable UUID slotId, Principal principal) {
        availabilityService.deleteSlot(slotId, resolveUser(principal));
        return ResponseEntity.ok(Map.of("message", "Jadwal berhasil dihapus"));
    }

    private User resolveUser(Principal principal) {
        if (principal == null) {
            throw new RuntimeException("Sesi tidak valid. Silakan login ulang.");
        }
        return userService.findByEmail(principal.getName())
                .orElseThrow(() -> new RuntimeException("Pengguna tidak ditemukan"));
    }
}
