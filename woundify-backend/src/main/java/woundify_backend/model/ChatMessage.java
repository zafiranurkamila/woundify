package woundify_backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Pesan chat 1-on-1 antar pengguna (lintas role).
 */
@Entity
@Table(name = "chat_messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sender_id", nullable = false)
    private User sender;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    // columnDefinition dengan default agar penambahan kolom pada tabel yang sudah
    // berisi data (ddl-auto=update) tidak gagal karena NOT NULL tanpa default.
    @Column(name = "is_read", columnDefinition = "boolean not null default false")
    private boolean read = false;

    @Column(name = "sent_at", nullable = false, updatable = false)
    private LocalDateTime sentAt;

    @PrePersist
    protected void onCreate() {
        sentAt = LocalDateTime.now();
    }
}
