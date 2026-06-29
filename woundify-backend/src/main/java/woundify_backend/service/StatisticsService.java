package woundify_backend.service;

import org.springframework.stereotype.Service;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class StatisticsService {

    private final AiIntegrationService aiIntegrationService;

    public StatisticsService(AiIntegrationService aiIntegrationService) {
        this.aiIntegrationService = aiIntegrationService;
    }

    public Map<String, Object> calculateDescriptiveStats(List<Double> data) {
        Map<String, Object> body = new HashMap<>();
        body.put("data", data);
        return aiIntegrationService.callStatisticsEndpoint("descriptive", body);
    }

    public Map<String, Object> calculateNormality(List<Double> data) {
        Map<String, Object> body = new HashMap<>();
        body.put("data", data);
        return aiIntegrationService.callStatisticsEndpoint("normality", body);
    }

    public Map<String, Object> calculateCorrelation(List<Double> x, List<Double> y) {
        Map<String, Object> body = new HashMap<>();
        body.put("x", x);
        body.put("y", y);
        return aiIntegrationService.callStatisticsEndpoint("correlation", body);
    }

    public Map<String, Object> calculateLinearRegression(List<Double> x, List<Double> y) {
        Map<String, Object> body = new HashMap<>();
        body.put("x", x);
        body.put("y", y);
        return aiIntegrationService.callStatisticsEndpoint("regression-linear", body);
    }

    public Map<String, Object> calculateLogisticRegression(List<List<Double>> X, List<Integer> y) {
        Map<String, Object> body = new HashMap<>();
        body.put("X", X);
        body.put("y", y);
        return aiIntegrationService.callStatisticsEndpoint("regression-logistic", body);
    }

    public Map<String, Object> calculateTTest(List<Double> group1, List<Double> group2, boolean paired) {
        Map<String, Object> body = new HashMap<>();
        body.put("group1", group1);
        body.put("group2", group2);
        body.put("paired", paired);
        return aiIntegrationService.callStatisticsEndpoint("t-test", body);
    }

    public Map<String, Object> calculateReliability(List<List<Double>> matrix) {
        Map<String, Object> body = new HashMap<>();
        body.put("matrix", matrix);
        return aiIntegrationService.callStatisticsEndpoint("reliability", body);
    }

    public Map<String, Object> calculateValidity(List<List<Double>> matrix) {
        Map<String, Object> body = new HashMap<>();
        body.put("matrix", matrix);
        return aiIntegrationService.callStatisticsEndpoint("validity", body);
    }
}
