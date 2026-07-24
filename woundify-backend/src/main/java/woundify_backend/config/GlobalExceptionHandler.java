package woundify_backend.config;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

/**
 * Temporary debug handler: surfaces the real exception type and message in the
 * JSON response so failures (e.g. mail send) are visible from the client,
 * instead of a generic "Internal Server Error".
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleAny(Exception ex) {
        Map<String, Object> body = new HashMap<>();
        body.put("exception", ex.getClass().getName());
        body.put("message", ex.getMessage());
        Throwable cause = ex.getCause();
        if (cause != null) {
            body.put("cause", cause.getClass().getName());
            body.put("causeMessage", cause.getMessage());
        }
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body);
    }
}
