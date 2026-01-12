package com.masterclass.appa.controller;

import com.masterclass.appa.clients.AppBClient;
import com.masterclass.appa.config.AppProperties;
import com.masterclass.appa.dto.GreetingResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * REST Controller for App A
 * 
 * Features:
 * - Configuration management via Spring Cloud Config
 * - Inter-service communication via Feign Client
 */
@RestController
@RequestMapping("")
@Slf4j
public class AppAController {

    @Autowired
    private AppProperties appProperties;
    
    @Autowired
    private AppBClient appBClient;  // ← Feign Client injection

    /**
     * Endpoint 1: Get greeting message
     * Uses configuration properties from Config Server
     */
    @GetMapping("/greeting/{name}")
    public ResponseEntity<GreetingResponse> getGreeting(@PathVariable String name) {
        log.info("Received greeting request for: {}", name);

        GreetingResponse response = GreetingResponse.builder()
            .message("Hello, " + name + "!")
            .appName(appProperties.getName())
            .description(appProperties.getDescription())
            .environment(appProperties.getEnvironment())
            .timestamp(LocalDateTime.now())
            .build();

        return ResponseEntity.ok(response);
    }

    /**
     * Endpoint 2: Get app status
     * Returns configuration and health information
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        log.info("Status check requested");

        Map<String, Object> statusMap = new HashMap<>();
        statusMap.put("appName", appProperties.getName());
        statusMap.put("version", appProperties.getVersion());
        statusMap.put("description", appProperties.getDescription());
        statusMap.put("environment", appProperties.getEnvironment());
        statusMap.put("timeout", appProperties.getTimeout());
        statusMap.put("status", "UP");
        statusMap.put("timestamp", LocalDateTime.now());
        statusMap.put("configSource", "Spring Cloud Config Server");

        return ResponseEntity.ok(statusMap);
    }
    
    // ========== Feign Client: Inter-Service Communication ==========
    
    /**
     * Call App B's status endpoint using Feign Client
     * 
     * Endpoint: GET /api/app-a/call-app-b/status
     * This demonstrates how Feign Client automatically discovers and calls App B
     */
    @GetMapping("/call-app-b/status")
    public ResponseEntity<Map<String, String>> callAppBStatus() {
        log.info("App A calling App B status via Feign Client");
        
        try {
            String response = appBClient.getAppBStatus();
            log.info("Received response from App B: {}", response);
            
            Map<String, String> result = new HashMap<>();
            result.put("caller", "App A");
            result.put("callee", "App B");
            result.put("endpoint", "/api/app-b/status");
            result.put("response", response);
            result.put("timestamp", LocalDateTime.now().toString());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Error calling App B status", e);
            
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to call App B");
            error.put("message", e.getMessage());
            
            return ResponseEntity.internalServerError().body(error);
        }
    }
    
    /**
     * Call App B's product endpoint
     * 
     * Endpoint: GET /api/app-a/call-app-b/product/{id}
     */
    @GetMapping("/call-app-b/product/{id}")
    public ResponseEntity<Map<String, String>> callAppBProduct(@PathVariable String id) {
        log.info("App A calling App B to get product: {}", id);
        
        try {
            String product = appBClient.getProduct(id);
            log.info("Got product from App B: {}", product);
            
            Map<String, String> result = new HashMap<>();
            result.put("caller", "App A");
            result.put("callee", "App B");
            result.put("endpoint", "/api/app-b/product/" + id);
            result.put("product", product);
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Error getting product from App B", e);
            
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to get product from App B");
            error.put("message", e.getMessage());
            
            return ResponseEntity.internalServerError().body(error);
        }
    }
    
    /**
     * Call App B's greeting endpoint
     * 
     * Endpoint: GET /api/app-a/call-app-b/greet/{name}
     */
    @GetMapping("/call-app-b/greet/{name}")
    public ResponseEntity<Map<String, String>> callAppBGreeting(@PathVariable String name) {
        log.info("App A asking App B to greet: {}", name);
        
        try {
            String greeting = appBClient.getGreeting(name);
            log.info("Got greeting from App B: {}", greeting);
            
            Map<String, String> result = new HashMap<>();
            result.put("caller", "App A");
            result.put("callee", "App B");
            result.put("endpoint", "/api/app-b/greeting/" + name);
            result.put("greeting", greeting);
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Error getting greeting from App B", e);
            
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to get greeting from App B");
            error.put("message", e.getMessage());
            
            return ResponseEntity.internalServerError().body(error);
        }
    }
}
