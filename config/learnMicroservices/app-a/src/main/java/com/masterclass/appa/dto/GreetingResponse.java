package com.masterclass.appa.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for greeting endpoint
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GreetingResponse {
    private String message;
    private String appName;
    private String description;
    private String environment;
    private LocalDateTime timestamp;
}
