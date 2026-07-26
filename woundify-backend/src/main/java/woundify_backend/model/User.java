package woundify_backend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @NotBlank
    @Email
    @Column(unique = true, nullable = false)
    private String email;

    @NotBlank
    @Column(nullable = false)
    private String password;

    @NotBlank
    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    // Nomor STR/SIP — wajib diisi untuk pendaftaran sebagai DOCTOR (verifikasi tenaga medis)
    @Column(name = "str_number")
    private String strNumber;

    @Column(name = "is_verified", nullable = false)
    private boolean isVerified = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum Role {
        NURSE,
        DOCTOR,
        RESEARCHER,
        LAB_ADMIN,
        HOSPITAL_ADMIN,
        // Nilai lama dipertahankan agar baris data lama tetap terbaca (backward-compatible)
        ADMIN,
        HEALTH_PROFESSIONAL
    }
}
