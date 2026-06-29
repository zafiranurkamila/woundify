package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import woundify_backend.dto.InstitutionalImpactSummary;
import woundify_backend.service.ImpactSummaryService;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final ImpactSummaryService impactSummaryService;

    public DashboardController(ImpactSummaryService impactSummaryService) {
        this.impactSummaryService = impactSummaryService;
    }

    @GetMapping("/impact-summary")
    public ResponseEntity<InstitutionalImpactSummary> getImpactSummary() {
        return ResponseEntity.ok(impactSummaryService.getImpactSummary());
    }
}
