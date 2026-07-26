package woundify_backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Slot jadwal kosong (tanggal + jam) yang disediakan seorang dokter untuk
 * menerima rujukan pasien. Ketika sebuah slot dipilih saat pengajuan rujukan,
 * slot ditandai booked=true sehingga tidak bisa dipilih lagi.
 */
@Entity
@Table(name = "doctor_availability")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DoctorAvailability {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "doctor_id", nullable = false)
    private User doctor;

    @Column(name = "slot_date_time", nullable = false)
    private LocalDateTime slotDateTime;

    @Column(name = "is_booked", nullable = false)
    private boolean booked = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
