package woundify_backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import woundify_backend.model.OtpToken;
import woundify_backend.repository.OtpTokenRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Random;

@Service
public class OtpService {

    private final OtpTokenRepository otpTokenRepository;
    private final RestTemplate restTemplate = new RestTemplate();
    private static final int OTP_VALIDITY_MINUTES = 10;
    private static final String BREVO_ENDPOINT = "https://api.brevo.com/v3/smtp/email";

    @Value("${brevo.api-key:}")
    private String brevoApiKey;

    @Value("${brevo.sender-email:woundifyme@gmail.com}")
    private String senderEmail;

    @Value("${brevo.sender-name:Woundify}")
    private String senderName;

    public OtpService(OtpTokenRepository otpTokenRepository) {
        this.otpTokenRepository = otpTokenRepository;
    }

    public void sendOtp(String email) {
        String code = generateOtpCode();
        LocalDateTime expiresAt = LocalDateTime.now().plusMinutes(OTP_VALIDITY_MINUTES);

        OtpToken otp = OtpToken.builder()
                .email(email)
                .code(code)
                .expiresAt(expiresAt)
                .used(false)
                .build();

        otpTokenRepository.deleteByEmail(email);
        otpTokenRepository.save(otp);

        sendOtpEmail(email, code);
    }

    public boolean verifyOtp(String email, String code) {
        var otp = otpTokenRepository.findByEmailAndCodeAndUsedFalse(email, code)
                .orElseThrow(() -> new RuntimeException("OTP tidak valid atau sudah digunakan"));

        if (otp.isExpired()) {
            throw new RuntimeException("OTP sudah kadaluarsa");
        }

        otp.setUsed(true);
        otpTokenRepository.save(otp);
        return true;
    }

    private String generateOtpCode() {
        return String.format("%06d", new Random().nextInt(1000000));
    }

    /**
     * Sends the OTP via Brevo's HTTP API (port 443) instead of SMTP, because
     * Railway blocks outbound SMTP ports (25/465/587).
     */
    private void sendOtpEmail(String email, String code) {
        if (brevoApiKey == null || brevoApiKey.isBlank()) {
            throw new RuntimeException("BREVO_API_KEY belum diset di environment Railway");
        }
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("api-key", brevoApiKey);
            headers.set("accept", "application/json");

            Map<String, Object> body = Map.of(
                    "sender", Map.of("name", senderName, "email", senderEmail),
                    "to", List.of(Map.of("email", email)),
                    "subject", "Kode OTP Woundify - Verifikasi Email",
                    "textContent", "Kode OTP Anda: " + code + "\n\nKode ini berlaku selama 10 menit."
            );

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
            restTemplate.postForEntity(BREVO_ENDPOINT, request, String.class);
        } catch (Exception e) {
            throw new RuntimeException("Gagal mengirim OTP via Brevo: " + e.getMessage());
        }
    }
}
