package woundify_backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import woundify_backend.dto.ChatMessageResponse;
import woundify_backend.model.ChatMessage;
import woundify_backend.model.User;
import woundify_backend.repository.ChatMessageRepository;
import woundify_backend.repository.UserRepository;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private final ChatMessageRepository chatRepository;
    private final UserRepository userRepository;

    public ChatService(ChatMessageRepository chatRepository, UserRepository userRepository) {
        this.chatRepository = chatRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public ChatMessageResponse sendMessage(User sender, UUID recipientId, String content) {
        if (content == null || content.isBlank()) {
            throw new RuntimeException("Pesan tidak boleh kosong.");
        }
        if (recipientId == null || recipientId.equals(sender.getId())) {
            throw new RuntimeException("Penerima pesan tidak valid.");
        }
        User recipient = userRepository.findById(recipientId)
                .orElseThrow(() -> new RuntimeException("Penerima tidak ditemukan."));

        ChatMessage message = ChatMessage.builder()
                .sender(sender)
                .recipient(recipient)
                .content(content.trim())
                .build();
        return mapToResponse(chatRepository.save(message));
    }

    @Transactional
    public List<ChatMessageResponse> getConversation(User currentUser, UUID peerId) {
        // Tandai pesan dari lawan bicara sebagai sudah dibaca saat percakapan dibuka
        List<ChatMessage> unread = chatRepository.findBySenderIdAndRecipientIdAndReadFalse(peerId, currentUser.getId());
        if (!unread.isEmpty()) {
            unread.forEach(m -> m.setRead(true));
            chatRepository.saveAll(unread);
        }
        return chatRepository.findConversation(currentUser.getId(), peerId)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(User currentUser) {
        return chatRepository.countByRecipientIdAndReadFalse(currentUser.getId());
    }

    private ChatMessageResponse mapToResponse(ChatMessage m) {
        return ChatMessageResponse.builder()
                .id(m.getId())
                .senderId(m.getSender().getId())
                .senderName(m.getSender().getName())
                .recipientId(m.getRecipient().getId())
                .recipientName(m.getRecipient().getName())
                .content(m.getContent())
                .sentAt(m.getSentAt())
                .build();
    }
}
