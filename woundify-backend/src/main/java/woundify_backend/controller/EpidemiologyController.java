package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import woundify_backend.model.EpidemiologyData;
import woundify_backend.service.EpidemiologyService;
import java.util.List;

@RestController
@RequestMapping("/api/epidemiology")
public class EpidemiologyController {

    private final EpidemiologyService epidemiologyService;

    public EpidemiologyController(EpidemiologyService epidemiologyService) {
        this.epidemiologyService = epidemiologyService;
    }

    @GetMapping
    public ResponseEntity<List<EpidemiologyData>> getAllEpidemiologyData() {
        return ResponseEntity.ok(epidemiologyService.getAllEpidemiologyData());
    }

    @GetMapping("/region/{region}")
    public ResponseEntity<List<EpidemiologyData>> getEpidemiologyByRegion(@PathVariable String region) {
        return ResponseEntity.ok(epidemiologyService.getEpidemiologyByRegion(region));
    }
}
