package woundify_backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

@Component
public class JwtTokenProvider {

    @Value("${jwt.secret:woundify-super-secret-key-12345678901234567890-woundify}")
    private String jwtSecret;

    @Value("${jwt.expiration-ms:86400000}") // 24 Hours
    private long jwtExpirationMs;

    public String generateToken(String email, String role) {
        try {
            long now = System.currentTimeMillis();
            long expiry = now + jwtExpirationMs;

            // 1. Header
            String header = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
            String encodedHeader = base64UrlEncode(header.getBytes(StandardCharsets.UTF_8));

            // 2. Payload
            String payload = String.format("{\"sub\":\"%s\",\"role\":\"%s\",\"iat\":%d,\"exp\":%d}", 
                    email, role, now / 1000, expiry / 1000);
            String encodedPayload = base64UrlEncode(payload.getBytes(StandardCharsets.UTF_8));

            // 3. Signature
            String message = encodedHeader + "." + encodedPayload;
            String signature = hmacSha256(message, jwtSecret);

            return message + "." + signature;
        } catch (Exception e) {
            throw new RuntimeException("Error generating JWT token", e);
        }
    }

    public boolean validateToken(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) return false;

            String header = parts[0];
            String payload = parts[1];
            String signature = parts[2];

            // Recompute signature
            String message = header + "." + payload;
            String expectedSignature = hmacSha256(message, jwtSecret);

            if (!expectedSignature.equals(signature)) return false;

            // Check expiration
            String decodedPayload = new String(Base64.getUrlDecoder().decode(payload), StandardCharsets.UTF_8);
            long exp = extractExpClaim(decodedPayload);
            long now = System.currentTimeMillis() / 1000;

            return exp > now;
        } catch (Exception e) {
            return false;
        }
    }

    public String getUsernameFromToken(String token) {
        try {
            String[] parts = token.split("\\.");
            String decodedPayload = new String(Base64.getUrlDecoder().decode(parts[1]), StandardCharsets.UTF_8);
            return extractClaim(decodedPayload, "sub");
        } catch (Exception e) {
            return null;
        }
    }

    public String getRoleFromToken(String token) {
        try {
            String[] parts = token.split("\\.");
            String decodedPayload = new String(Base64.getUrlDecoder().decode(parts[1]), StandardCharsets.UTF_8);
            return extractClaim(decodedPayload, "role");
        } catch (Exception e) {
            return null;
        }
    }

    private String base64UrlEncode(byte[] input) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(input);
    }

    private String hmacSha256(String message, String secret) throws NoSuchAlgorithmException, InvalidKeyException {
        Mac sha256Hmac = Mac.getInstance("HmacSHA256");
        SecretKeySpec secretKey = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
        sha256Hmac.init(secretKey);
        byte[] hash = sha256Hmac.doFinal(message.getBytes(StandardCharsets.UTF_8));
        return base64UrlEncode(hash);
    }

    private long extractExpClaim(String payloadJson) {
        String claim = extractClaim(payloadJson, "exp");
        return claim != null ? Long.parseLong(claim) : 0L;
    }

    private String extractClaim(String json, String claimName) {
        String pattern = "\"" + claimName + "\":\"";
        int start = json.indexOf(pattern);
        if (start != -1) {
            start += pattern.length();
            int end = json.indexOf("\"", start);
            return json.substring(start, end);
        } else {
            // Try numeric (for exp, iat)
            String numericPattern = "\"" + claimName + "\":";
            int numStart = json.indexOf(numericPattern);
            if (numStart != -1) {
                numStart += numericPattern.length();
                int numEnd = json.indexOf(",", numStart);
                if (numEnd == -1) numEnd = json.indexOf("}", numStart);
                return json.substring(numStart, numEnd).trim();
            }
        }
        return null;
    }
}
