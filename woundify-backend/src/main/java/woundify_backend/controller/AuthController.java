package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import woundify_backend.dto.AuthRequest;
import woundify_backend.dto.AuthResponse;
import woundify_backend.dto.RegisterRequest;
import woundify_backend.dto.SendOtpRequest;
import woundify_backend.dto.VerifyOtpRequest;
import woundify_backend.model.User;
import woundify_backend.service.UserService;
import woundify_backend.service.OtpService;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final OtpService otpService;

    public AuthController(UserService userService, OtpService otpService) {
        this.userService = userService;
        this.otpService = otpService;
    }

    @PostMapping("/register")
    public ResponseEntity<User> register(@RequestBody RegisterRequest request) {
        return ResponseEntity.ok(userService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody AuthRequest request) {
        return ResponseEntity.ok(userService.login(request));
    }

    @PostMapping("/send-otp")
    public ResponseEntity<Map<String, String>> sendOtp(@RequestBody SendOtpRequest request) {
        otpService.sendOtp(request.getEmail());
        return ResponseEntity.ok(Map.of("message", "OTP telah dikirim ke email Anda"));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<User> verifyOtp(@RequestBody VerifyOtpRequest request) {
        return ResponseEntity.ok(userService.verifyEmail(request.getEmail(), request.getCode()));
    }
}
