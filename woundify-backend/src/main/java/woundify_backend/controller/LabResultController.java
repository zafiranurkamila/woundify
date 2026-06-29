package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import woundify_backend.dto.LabResultRequest;
import woundify_backend.dto.LabResultResponse;
import woundify_backend.model.User;
import woundify_backend.service.LabResultService;
import woundify_backend.service.UserService;
import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/lab-results")
public class LabResultController {

    private final LabResultService labResultService;
    private final UserService userService;
    private static final Logger logger = LoggerFactory.getLogger(LabResultController.class);

    public LabResultController(LabResultService labResultService, UserService userService) {
        this.labResultService = labResultService;
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<LabResultResponse> createLabResult(@RequestBody LabResultRequest request, Principal principal) {
        try {
            String principalName = principal != null ? principal.getName() : "anonymous";
            logger.info("Received createLabResult request for patientId={} by principal={}", request.getPatientId(), principalName);
            User currentUser = userService.findByEmail(principalName)
                    .orElseThrow(() -> new RuntimeException("Authenticated user not found"));
            LabResultResponse response = labResultService.createLabResult(request, currentUser);
            logger.info("Lab result saved id={} for patientId={}", response.getId(), response.getPatientId());
            return ResponseEntity.ok(response);
        } catch (Exception ex) {
            logger.error("Error creating lab result: {}", ex.getMessage(), ex);
            throw ex;
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<LabResultResponse> getLabResultById(@PathVariable UUID id) {
        return ResponseEntity.ok(labResultService.getLabResultById(id));
    }

    @GetMapping("/patient/{patientId}")
    public ResponseEntity<List<LabResultResponse>> getPatientLabHistory(@PathVariable UUID patientId) {
        return ResponseEntity.ok(labResultService.getPatientLabHistory(patientId));
    }

    @PostMapping("/ocr")
    public ResponseEntity<Map<String, Object>> processLabOcr(@RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(labResultService.processLabOcr(file));
    }
}
