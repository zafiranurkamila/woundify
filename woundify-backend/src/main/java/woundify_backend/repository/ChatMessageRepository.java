package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import woundify_backend.model.ChatMessage;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {

    @Query("SELECT m FROM ChatMessage m WHERE (m.sender.id = :a AND m.recipient.id = :b) "
            + "OR (m.sender.id = :b AND m.recipient.id = :a) ORDER BY m.sentAt ASC")
    List<ChatMessage> findConversation(@Param("a") UUID a, @Param("b") UUID b);

    long countByRecipientIdAndReadFalse(UUID recipientId);

    List<ChatMessage> findBySenderIdAndRecipientIdAndReadFalse(UUID senderId, UUID recipientId);
}
