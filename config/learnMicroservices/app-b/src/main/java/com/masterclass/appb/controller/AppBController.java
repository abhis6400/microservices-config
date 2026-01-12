package com.masterclass.appb.controller;

import com.masterclass.appb.clients.AppAClient;
import com.masterclass.appb.config.AppProperties;
import com.masterclass.appb.dto.ProductResponse;
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
 * REST Controller for App B
 * 
 * Features:
 * - Configuration management via Spring Cloud Config
 * - Inter-service communication via Feign Client
 */
@RestController
@RequestMapping("")
@Slf4j
public class AppBController {

    @Autowired
    private AppProperties appProperties;
    
    @Autowired
    private AppAClient appAClient;  // ← Feign Client injection

    /**
     * Endpoint 1: Get product details
     * Uses configuration properties from Config Server
     */
    @GetMapping("/product/{id}")
    public ResponseEntity<ProductResponse> getProduct(@PathVariable String id) {
        log.info("Product request for ID: {}", id);

        ProductResponse response = ProductResponse.builder()
            .productId(id)
            .productName("Sample Product - " + id)
            .appName(appProperties.getName())
            .description(appProperties.getDescription())
            .environment(appProperties.getEnvironment())
            .timestamp(LocalDateTime.now())
            .build();

        return ResponseEntity.ok(response);
    }

    /**
     * Endpoint 2: Get app health
     * Returns configuration and connection information
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> getHealth() {
        log.info("Health check requested");

        Map<String, Object> healthMap = new HashMap<>();
        healthMap.put("appName", appProperties.getName());
        healthMap.put("version", appProperties.getVersion());
        healthMap.put("description", appProperties.getDescription());
        healthMap.put("environment", appProperties.getEnvironment());
        healthMap.put("timeout", appProperties.getTimeout());
        healthMap.put("maxConnections", appProperties.getMaxConnections());
        healthMap.put("status", "HEALTHY");
        healthMap.put("timestamp", LocalDateTime.now());
        healthMap.put("configSource", "Spring Cloud Config Server");

        return ResponseEntity.ok(healthMap);
    }
    
    // ========== Additional endpoints needed for inter-service communication ==========
    
    /**
     * Status endpoint for compatibility with Feign Client calls from App A
     * 
     * Endpoint: GET /api/app-b/status
     */
    @GetMapping("/status")
    public ResponseEntity<String> getStatus() {
        log.info("App B status check");
        return ResponseEntity.ok("App B is running on port 8081 ✅");
    }
    
    /**
     * Greeting endpoint for compatibility with Feign Client calls from App A
     * 
     * Endpoint: GET /api/app-b/greeting/{name}
     */
    @GetMapping("/greeting/{name}")
    public ResponseEntity<String> getGreeting(@PathVariable String name) {
        log.info("App B greeting: {}", name);
        return ResponseEntity.ok("Welcome " + name + " to App B! 🎉");
    }
    
    // ========== Feign Client: Inter-Service Communication ==========
    
    /**
     * Call App A's status endpoint using Feign Client
     * 
     * Endpoint: GET /api/app-b/call-app-a/status
     */
    @GetMapping("/call-app-a/status")
    public ResponseEntity<Map<String, String>> callAppAStatus() {
        log.info("App B calling App A status via Feign Client");
        
        try {
            String response = appAClient.getAppAStatus();
            log.info("Received response from App A: {}", response);
            
            Map<String, String> result = new HashMap<>();
            result.put("caller", "App B");
            result.put("callee", "App A");
            result.put("endpoint", "/api/app-a/status");
            result.put("response", response);
            result.put("timestamp", LocalDateTime.now().toString());
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Error calling App A status", e);
            
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to call App A");
            error.put("message", e.getMessage());
            
            return ResponseEntity.internalServerError().body(error);
        }
    }
    
    /**
     * Call App A's data endpoint
     * 
     * Endpoint: GET /api/app-b/call-app-a/data/{key}
     */
    @GetMapping("/call-app-a/data/{key}")
    public ResponseEntity<Map<String, String>> callAppAData(@PathVariable String key) {
        log.info("App B calling App A to get data: {}", key);
        
        try {
            String data = appAClient.getData(key);
            log.info("Got data from App A: {}", data);
            
            Map<String, String> result = new HashMap<>();
            result.put("caller", "App B");
            result.put("callee", "App A");
            result.put("endpoint", "/api/app-a/data/" + key);
            result.put("data", data);
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Error getting data from App A", e);
            
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to get data from App A");
            error.put("message", e.getMessage());
            
            return ResponseEntity.internalServerError().body(error);
        }
    }
    
    /**
     * Call App A's hello endpoint
     * 
     * Endpoint: GET /api/app-b/call-app-a/hello/{name}
     */
    @GetMapping("/call-app-a/hello/{name}")
    public ResponseEntity<Map<String, String>> callAppAHello(@PathVariable String name) {
        log.info("App B asking App A to say hello to: {}", name);
        
        try {
            String greeting = appAClient.sayHello(name);
            log.info("Got greeting from App A: {}", greeting);
            
            Map<String, String> result = new HashMap<>();
            result.put("caller", "App B");
            result.put("callee", "App A");
            result.put("endpoint", "/api/app-a/hello/" + name);
            result.put("greeting", greeting);
            
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            log.error("Error getting greeting from App A", e);
            
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to get greeting from App A");
            error.put("message", e.getMessage());
            
            return ResponseEntity.internalServerError().body(error);
        }
    }
}
