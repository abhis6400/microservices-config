package com.masterclass.appa.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Configuration properties for App A
 * Fetched from centralized Config Server
 */
@Component
@ConfigurationProperties(prefix = "app")
@Data
public class AppProperties {
    private String name;
    private String description;
    private String version;
    private String environment;
    private int timeout;
}
