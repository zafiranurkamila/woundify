package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import woundify_backend.dto.ChatMessageResponse;
import woundify_backend.dto.ChatSendRequest;
import woundify_backend.model.User;
import woundify_backend.service.ChatService;
import woundify_backend.service.UserService;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatService chatService;
    private final UserService userService;

    public ChatController(ChatService chatService, UserService userService) {
        this.chatService = chatService;
        this.userService = userService;
    }

    @PostMapping("/send")
    public ResponseEntity<ChatMessageResponse> send(@RequestBody ChatSendRequest request, Principal principal) {
        User sender = resolveUser(principal);
        return ResponseEntity.ok(chatService.sendMessage(sender, request.getRecipientId(), request.getContent()));
    }

    @GetMapping("/conversation/{peerId}")
    public ResponseEntity<List<ChatMessageResponse>> conversation(@PathVariable UUID peerId, Principal principal) {
        User currentUser = resolveUser(principal);
        return ResponseEntity.ok(chatService.getConversation(currentUser, peerId));
    }

    private User resolveUser(Principal principal) {
        if (principal == null) {
            throw new RuntimeException("Sesi tidak valid. Silakan login ulang.");
        }
        return userService.findByEmail(principal.getName())
                .orElseThrow(() -> new RuntimeException("Pengguna tidak ditemukan"));
    }
}
