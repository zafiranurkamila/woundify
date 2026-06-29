package woundify_backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import woundify_backend.service.StatisticsService;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/statistics")
public class StatisticsController {

    private final StatisticsService statisticsService;

    public StatisticsController(StatisticsService statisticsService) {
        this.statisticsService = statisticsService;
    }

    @PostMapping("/descriptive")
    public ResponseEntity<Map<String, Object>> getDescriptiveStats(@RequestBody Map<String, List<Double>> request) {
        return ResponseEntity.ok(statisticsService.calculateDescriptiveStats(request.get("data")));
    }

    @PostMapping("/normality")
    public ResponseEntity<Map<String, Object>> getNormalityTest(@RequestBody Map<String, List<Double>> request) {
        return ResponseEntity.ok(statisticsService.calculateNormality(request.get("data")));
    }

    @PostMapping("/correlation")
    public ResponseEntity<Map<String, Object>> getCorrelationTest(@RequestBody Map<String, List<Double>> request) {
        return ResponseEntity.ok(statisticsService.calculateCorrelation(request.get("x"), request.get("y")));
    }

    @PostMapping("/regression-linear")
    public ResponseEntity<Map<String, Object>> getLinearRegression(@RequestBody Map<String, List<Double>> request) {
        return ResponseEntity.ok(statisticsService.calculateLinearRegression(request.get("x"), request.get("y")));
    }

    @SuppressWarnings("unchecked")
    @PostMapping("/regression-logistic")
    public ResponseEntity<Map<String, Object>> getLogisticRegression(@RequestBody Map<String, Object> request) {
        List<List<Double>> X = (List<List<Double>>) request.get("X");
        List<Integer> y = (List<Integer>) request.get("y");
        return ResponseEntity.ok(statisticsService.calculateLogisticRegression(X, y));
    }

    @SuppressWarnings("unchecked")
    @PostMapping("/t-test")
    public ResponseEntity<Map<String, Object>> getTTest(@RequestBody Map<String, Object> request) {
        List<Double> group1 = (List<Double>) request.get("group1");
        List<Double> group2 = (List<Double>) request.get("group2");
        Boolean paired = (Boolean) request.getOrDefault("paired", false);
        return ResponseEntity.ok(statisticsService.calculateTTest(group1, group2, paired));
    }

    @PostMapping("/reliability")
    public ResponseEntity<Map<String, Object>> getReliabilityTest(@RequestBody Map<String, List<List<Double>>> request) {
        return ResponseEntity.ok(statisticsService.calculateReliability(request.get("matrix")));
    }

    @PostMapping("/validity")
    public ResponseEntity<Map<String, Object>> getValidityTest(@RequestBody Map<String, List<List<Double>>> request) {
        return ResponseEntity.ok(statisticsService.calculateValidity(request.get("matrix")));
    }
}
