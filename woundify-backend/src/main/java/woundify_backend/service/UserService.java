package woundify_backend.service;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import woundify_backend.dto.AuthRequest;
import woundify_backend.dto.AuthResponse;
import woundify_backend.dto.DoctorSummaryResponse;
import woundify_backend.dto.RegisterRequest;
import org.springframework.transaction.annotation.Transactional;
import woundify_backend.model.User;
import woundify_backend.repository.UserRepository;
import woundify_backend.repository.OtpTokenRepository;
import woundify_backend.repository.PatientRepository;
import woundify_backend.config.JwtTokenProvider;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class UserService implements UserDetailsService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final OtpService otpService;
    private final OtpTokenRepository otpTokenRepository;
    private final PatientRepository patientRepository;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtTokenProvider tokenProvider,
                       OtpService otpService, OtpTokenRepository otpTokenRepository, PatientRepository patientRepository) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
        this.otpService = otpService;
        this.otpTokenRepository = otpTokenRepository;
        this.patientRepository = patientRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));

        return new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getPassword(),
                Collections.singletonList(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_" + user.getRole().name()))
        );
    }

    public User register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already in use");
        }

        User.Role role = User.Role.NURSE;
        try {
            role = User.Role.valueOf(request.getRole().toUpperCase());
        } catch (Exception e) {
            // Fallback to NURSE role
        }

        // Dokter wajib menyertakan nomor STR/SIP sebagai verifikasi tenaga medis
        String strNumber = null;
        if (role == User.Role.DOCTOR) {
            if (request.getStrNumber() == null || request.getStrNumber().isBlank()) {
                throw new RuntimeException("Nomor STR/SIP wajib diisi untuk pendaftaran sebagai Dokter.");
            }
            strNumber = request.getStrNumber().trim();
        }

        User user = User.builder()
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .name(request.getName())
                .role(role)
                .strNumber(strNumber)
                .isVerified(false)
                .build();

        User savedUser = userRepository.save(user);
        otpService.sendOtp(request.getEmail());
        return savedUser;
    }

    /**
     * Menghapus akun berdasarkan email, sehingga email tersebut bisa didaftarkan
     * ulang (mis. untuk mencoba role berbeda). Akun yang sudah memiliki data pasien
     * tidak bisa dihapus untuk menjaga integritas data.
     */
    @Transactional
    public void deleteAccount(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Akun tidak ditemukan."));

        if (patientRepository.countByCreatedBy(user) > 0) {
            throw new RuntimeException("Akun ini memiliki data pasien sehingga tidak dapat dihapus. Gunakan email lain untuk pengujian.");
        }

        otpTokenRepository.deleteByEmail(email);
        userRepository.delete(user);
    }

    public User verifyEmail(String email, String otpCode) {
        otpService.verifyOtp(email, otpCode);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setVerified(true);
        return userRepository.save(user);
    }

    public AuthResponse login(AuthRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid credentials"));

        if (!user.isVerified()) {
            throw new RuntimeException("Email belum diverifikasi. Silakan cek email Anda untuk kode OTP.");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new RuntimeException("Invalid credentials");
        }

        String token = tokenProvider.generateToken(user.getEmail(), user.getRole().name());

        return new AuthResponse(
                token,
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getRole().name()
        );
    }

    public Optional<User> findByEmail(String email) {
        return userRepository.findByEmail(email);
    }

    public List<DoctorSummaryResponse> getDoctors() {
        return userRepository.findByRoleOrderByNameAsc(User.Role.DOCTOR)
                .stream()
                .map(user -> DoctorSummaryResponse.builder()
                        .id(user.getId())
                        .name(user.getName())
                        .email(user.getEmail())
                        .role(user.getRole().name())
                        .build())
                .collect(Collectors.toList());
    }
}
