package com.woundify;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ApiController {

    private final WoundifyStore store;

    public ApiController(WoundifyStore store) {
        this.store = store;
    }

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
                "status", "ok",
                "service", "woundify-backend",
                "patients", store.listPatients().size(),
                "labResults", store.listLabResults().size());
    }

    @PostMapping("/auth/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request) {
        if (!store.isValidUser(request.username(), request.password())) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Username atau password salah");
        }
        return new LoginResponse(
                UUID.randomUUID().toString(),
                request.username(),
                List.of("CLINICIAN"));
    }

    @GetMapping("/patients")
    public List<PatientResponse> patients() {
        return store.listPatients();
    }

    @PostMapping("/patients")
    public PatientResponse createPatient(@Valid @RequestBody CreatePatientRequest request) {
        return store.createPatient(request);
    }

    @GetMapping("/patients/{patientId}")
    public PatientResponse getPatient(@PathVariable String patientId) {
        return store.getPatient(patientId);
    }

    @GetMapping("/patients/{patientId}/lab-results")
    public List<LabResultResponse> labResults(@PathVariable String patientId) {
        return store.listLabResultsByPatient(patientId);
    }

    @PostMapping("/lab-results")
    public LabResultResponse createLabResult(@Valid @RequestBody LabResultRequest request) {
        return store.saveLabResult(request);
    }

    @PostMapping("/ai/analyze")
    public AiPrediction analyze(@Valid @RequestBody AiAnalysisRequest request) {
        return store.analyze(request);
    }

    @GetMapping("/dashboard/summary")
    public DashboardSummary summary() {
        return store.dashboardSummary();
    }

    @GetMapping("/history/{patientId}")
    public List<LabResultResponse> history(@PathVariable String patientId) {
        return store.listLabResultsByPatient(patientId);
    }
}
