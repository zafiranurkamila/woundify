package woundify_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RegisterRequest {
    private String email;
    private String password;
    private String name;
    private String role; // NURSE, DOCTOR, RESEARCHER, LAB_ADMIN, HOSPITAL_ADMIN
    private String strNumber; // Nomor STR/SIP — wajib jika role = DOCTOR
    private String institution; // Asal instansi (RS/klinik) untuk isolasi data
}
