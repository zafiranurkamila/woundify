package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import woundify_backend.dto.ReferralCreateRequest;
import woundify_backend.dto.ReferralResponse;
import woundify_backend.dto.ReferralVerifyRequest;
import woundify_backend.model.User;
import woundify_backend.service.ReferralService;
import woundify_backend.service.UserService;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/referrals")
public class ReferralController {

    private final ReferralService referralService;
    private final UserService userService;
    private static final Logger logger = LoggerFactory.getLogger(ReferralController.class);

    public ReferralController(ReferralService referralService, UserService userService) {
        this.referralService = referralService;
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<ReferralResponse> createReferral(@RequestBody ReferralCreateRequest request, Principal principal) {
        User currentUser = resolveUser(principal);
        return ResponseEntity.ok(referralService.createReferral(request, currentUser));
    }

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<ReferralResponse>> getPatientReferrals(@PathVariable UUID patientId) {
        return ResponseEntity.ok(referralService.getPatientReferrals(patientId));
    }

    @GetMapping("/incoming")
    public ResponseEntity<List<ReferralResponse>> getIncomingReferrals(Principal principal) {
        return ResponseEntity.ok(referralService.getIncomingReferralsForDoctor(resolveUser(principal)));
    }

    @PatchMapping("/{referralId}/verify")
    public ResponseEntity<ReferralResponse> verifyReferral(@PathVariable UUID referralId,
                                                           @RequestBody ReferralVerifyRequest request,
                                                           Principal principal) {
        return ResponseEntity.ok(referralService.verifyReferral(referralId, request, resolveUser(principal)));
    }

    private User resolveUser(Principal principal) {
        if (principal == null) {
            throw new RuntimeException("Sesi tidak valid. Silakan login ulang.");
        }
        return userService.findByEmail(principal.getName())
                .orElseThrow(() -> new RuntimeException("Sesi tidak valid. Silakan login ulang."));
    }
}
