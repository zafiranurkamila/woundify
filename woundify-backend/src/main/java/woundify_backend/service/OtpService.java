package woundify_backend.service;

import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import woundify_backend.dto.SendOtpRequest;
import woundify_backend.dto.VerifyOtpRequest;
import woundify_backend.model.OtpToken;
import woundify_backend.repository.OtpTokenRepository;
import java.time.LocalDateTime;
import java.util.Random;

@Service
public class OtpService {

    private final OtpTokenRepository otpTokenRepository;
    private final JavaMailSender mailSender;
    private static final int OTP_VALIDITY_MINUTES = 10;

    public OtpService(OtpTokenRepository otpTokenRepository, JavaMailSender mailSender) {
        this.otpTokenRepository = otpTokenRepository;
        this.mailSender = mailSender;
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

    private void sendOtpEmail(String email, String code) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom("noreply@woundify.com");
            message.setTo(email);
            message.setSubject("Kode OTP Woundify - Verifikasi Email");
            message.setText("Kode OTP Anda: " + code + "\n\nKode ini berlaku selama 10 menit.");
            mailSender.send(message);
        } catch (Exception e) {
            throw new RuntimeException("Gagal mengirim OTP: " + e.getMessage());
        }
    }
}
