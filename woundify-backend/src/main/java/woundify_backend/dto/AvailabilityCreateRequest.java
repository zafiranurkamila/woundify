package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AvailabilityCreateRequest {
    // ISO-8601 lokal, contoh: "2026-08-01T09:00:00"
    private String slotDateTime;
}
