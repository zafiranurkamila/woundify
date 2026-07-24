package woundify_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import woundify_backend.model.OtpToken;
import java.util.Optional;
import java.util.UUID;

public interface OtpTokenRepository extends JpaRepository<OtpToken, UUID> {
    Optional<OtpToken> findByEmailAndCodeAndUsedFalse(String email, String code);
    Optional<OtpToken> findByEmail(String email);
    void deleteByEmail(String email);
}
