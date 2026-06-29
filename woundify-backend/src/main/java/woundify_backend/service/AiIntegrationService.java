package woundify_backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;
import java.util.Map;

@Service
public class AiIntegrationService {

    @Value("${woundify.ai.endpoint:http://localhost:8000}")
    private String aiEndpoint;

    private final RestTemplate restTemplate = new RestTemplate();

    public Map<String, Object> performOcr(MultipartFile file) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            ByteArrayResource fileResource = new ByteArrayResource(file.getBytes()) {
                @Override
                public String getFilename() {
                    return file.getOriginalFilename() != null ? file.getOriginalFilename() : "image.jpg";
                }
            };
            body.add("file", fileResource);

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(
                aiEndpoint + "/api/ocr", 
                requestEntity, 
                Map.class
            );
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException("OCR service call failed: " + e.getMessage(), e);
        }
    }

    public Map<String, Object> getPrediction(Map<String, Object> requestData) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(requestData, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(
                aiEndpoint + "/api/predict", 
                requestEntity, 
                Map.class
            );
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException("AI prediction call failed: " + e.getMessage(), e);
        }
    }

    public Map<String, Object> getAiEvaluation() {
        try {
            ResponseEntity<Map> response = restTemplate.getForEntity(
                aiEndpoint + "/api/ai/evaluation", 
                Map.class
            );
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException("AI evaluation call failed: " + e.getMessage(), e);
        }
    }

    public Map<String, Object> callStatisticsEndpoint(String subPath, Object requestBody) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Object> requestEntity = new HttpEntity<>(requestBody, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(
                aiEndpoint + "/api/statistics/" + subPath, 
                requestEntity, 
                Map.class
            );
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException("Statistics call failed: " + e.getMessage(), e);
        }
    }
}
