package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import woundify_backend.dto.WoundFollowUpRequest;
import woundify_backend.dto.WoundFollowUpResponse;
import woundify_backend.model.User;
import woundify_backend.service.UserService;
import woundify_backend.service.WoundFollowUpService;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/follow-ups")
public class WoundFollowUpController {

    private final WoundFollowUpService followUpService;
    private final UserService userService;

    public WoundFollowUpController(WoundFollowUpService followUpService, UserService userService) {
        this.followUpService = followUpService;
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<WoundFollowUpResponse> createFollowUp(@RequestBody WoundFollowUpRequest request, Principal principal) {
        User currentUser = userService.findByEmail(principal.getName())
                .orElseThrow(() -> new RuntimeException("Authenticated user not found"));
        return ResponseEntity.ok(followUpService.createFollowUp(request, currentUser));
    }

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<WoundFollowUpResponse>> getPatientFollowUps(@PathVariable UUID patientId) {
        return ResponseEntity.ok(followUpService.getPatientFollowUps(patientId));
    }
}
