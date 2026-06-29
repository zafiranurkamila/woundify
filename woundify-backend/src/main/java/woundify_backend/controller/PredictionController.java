package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import woundify_backend.service.AiIntegrationService;
import java.util.Map;

@RestController
@RequestMapping("/api/predictions")
public class PredictionController {

    private final AiIntegrationService aiIntegrationService;

    public PredictionController(AiIntegrationService aiIntegrationService) {
        this.aiIntegrationService = aiIntegrationService;
    }

    @GetMapping("/evaluation")
    public ResponseEntity<Map<String, Object>> getAiModelEvaluation() {
        return ResponseEntity.ok(aiIntegrationService.getAiEvaluation());
    }
}
