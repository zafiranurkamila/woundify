package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import woundify_backend.dto.PatientRequest;
import woundify_backend.dto.PatientResponse;
import woundify_backend.model.User;
import woundify_backend.service.PatientService;
import woundify_backend.service.UserService;
import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/patients")
public class PatientController {

    private final PatientService patientService;
    private final UserService userService;

    public PatientController(PatientService patientService, UserService userService) {
        this.patientService = patientService;
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<PatientResponse> createPatient(@RequestBody PatientRequest request, Principal principal) {
        User currentUser = userService.findByEmail(principal.getName())
                .orElseThrow(() -> new RuntimeException("Authenticated user not found"));
        return ResponseEntity.ok(patientService.createPatient(request, currentUser));
    }

    @GetMapping
    public ResponseEntity<List<PatientResponse>> getAllPatients() {
        return ResponseEntity.ok(patientService.getAllPatients());
    }

    @GetMapping("/{id}")
    public ResponseEntity<PatientResponse> getPatientById(@PathVariable UUID id) {
        return ResponseEntity.ok(patientService.getPatientById(id));
    }
}
