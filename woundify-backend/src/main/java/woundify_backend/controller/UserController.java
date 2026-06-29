package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import woundify_backend.dto.DoctorSummaryResponse;
import woundify_backend.service.UserService;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/doctors")
    public ResponseEntity<List<DoctorSummaryResponse>> getDoctors() {
        return ResponseEntity.ok(userService.getDoctors());
    }
}
