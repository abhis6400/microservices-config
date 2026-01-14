package com.masterclass.appa.controller;

import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * ============================================================
 * CIRCUIT BREAKER TESTING CONTROLLER
 * ============================================================
 * 
 * PURPOSE: Endpoints to manually control circuit breaker for testing
 * 
 * WHY NEEDED?
 * -----------
 * In production, circuit breakers open automatically based on failure rate.
 * But when you have good fallbacks, the circuit may never open because
 * fallback success = circuit breaker success.
 * 
 * For testing/demo purposes, we need to:
 * 1. Force circuit breaker to OPEN state
 * 2. Reset circuit breaker to CLOSED state
 * 3. View detailed circuit breaker metrics
 * 
 * ENDPOINTS:
 * ----------
 * GET  /api/test-circuit/status        - Get detailed CB status
 * POST /api/test-circuit/force-open    - Force CB to OPEN (for testing)
 * POST /api/test-circuit/force-closed  - Force CB to CLOSED (reset)
 * POST /api/test-circuit/record-failure - Record artificial failure
 */
@RestController
@RequestMapping("/api/test-circuit")
public class CircuitBreakerTestController {
    
    private final CircuitBreakerRegistry circuitBreakerRegistry;
    
    public CircuitBreakerTestController(CircuitBreakerRegistry circuitBreakerRegistry) {
        this.circuitBreakerRegistry = circuitBreakerRegistry;
    }
    
    /**
     * Get detailed circuit breaker status
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getCircuitBreakerStatus() {
        CircuitBreaker cb = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        Map<String, Object> status = new HashMap<>();
        status.put("name", cb.getName());
        status.put("state", cb.getState().toString());
        
        // Metrics
        CircuitBreaker.Metrics metrics = cb.getMetrics();
        Map<String, Object> metricsMap = new HashMap<>();
        metricsMap.put("failureRate", String.format("%.2f%%", metrics.getFailureRate()));
        metricsMap.put("slowCallRate", String.format("%.2f%%", metrics.getSlowCallRate()));
        metricsMap.put("numberOfSuccessfulCalls", metrics.getNumberOfSuccessfulCalls());
        metricsMap.put("numberOfFailedCalls", metrics.getNumberOfFailedCalls());
        metricsMap.put("numberOfSlowCalls", metrics.getNumberOfSlowCalls());
        metricsMap.put("numberOfNotPermittedCalls", metrics.getNumberOfNotPermittedCalls());
        metricsMap.put("numberOfBufferedCalls", metrics.getNumberOfBufferedCalls());
        
        status.put("metrics", metricsMap);
        
        // Config
        Map<String, Object> config = new HashMap<>();
        config.put("failureRateThreshold", cb.getCircuitBreakerConfig().getFailureRateThreshold());
        config.put("slowCallRateThreshold", cb.getCircuitBreakerConfig().getSlowCallRateThreshold());
        config.put("minimumNumberOfCalls", cb.getCircuitBreakerConfig().getMinimumNumberOfCalls());
        config.put("slidingWindowSize", cb.getCircuitBreakerConfig().getSlidingWindowSize());
        
        status.put("config", config);
        
        return ResponseEntity.ok(status);
    }
    
    /**
     * FORCE circuit breaker to OPEN state (for testing)
     * 
     * WARNING: This bypasses normal circuit breaker logic!
     * Use only for testing/demonstration purposes.
     */
    @PostMapping("/force-open")
    public ResponseEntity<Map<String, String>> forceOpen() {
        CircuitBreaker cb = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        // Transition to OPEN state
        cb.transitionToOpenState();
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "Circuit breaker FORCED to OPEN state");
        response.put("currentState", cb.getState().toString());
        response.put("warning", "This is for TESTING only. In production, circuit breakers open automatically.");
        response.put("duration", "Will stay OPEN for 30 seconds, then transition to HALF_OPEN");
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * FORCE circuit breaker to CLOSED state (reset)
     * 
     * Use this to reset the circuit breaker after testing
     */
    @PostMapping("/force-closed")
    public ResponseEntity<Map<String, String>> forceClosed() {
        CircuitBreaker cb = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        // Transition to CLOSED state (reset)
        cb.transitionToClosedState();
        
        // Reset metrics
        cb.reset();
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "Circuit breaker RESET to CLOSED state");
        response.put("currentState", cb.getState().toString());
        response.put("metricsReset", "true");
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * Record artificial failures to trigger circuit breaker opening
     * 
     * This simulates 10 failed calls to reach the failure threshold
     */
    @PostMapping("/simulate-failures")
    public ResponseEntity<Map<String, Object>> simulateFailures(
            @RequestParam(defaultValue = "10") int count) {
        
        CircuitBreaker cb = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        int failuresRecorded = 0;
        
        // Record failures
        for (int i = 0; i < count; i++) {
            try {
                // Simulate a call that fails
                cb.executeRunnable(() -> {
                    throw new RuntimeException("Simulated failure for testing");
                });
            } catch (Exception e) {
                // Expected - we're simulating failures
                failuresRecorded++;
            }
        }
        
        Map<String, Object> response = new HashMap<>();
        response.put("failuresRecorded", failuresRecorded);
        response.put("currentState", cb.getState().toString());
        response.put("failureRate", String.format("%.2f%%", cb.getMetrics().getFailureRate()));
        
        if (cb.getState() == CircuitBreaker.State.OPEN) {
            response.put("message", "✅ Circuit breaker OPENED after recording failures!");
        } else {
            response.put("message", "Circuit breaker still CLOSED. May need more failures.");
            response.put("hint", "Need at least " + cb.getCircuitBreakerConfig().getMinimumNumberOfCalls() 
                    + " calls with " + cb.getCircuitBreakerConfig().getFailureRateThreshold() + "% failure rate");
        }
        
        return ResponseEntity.ok(response);
    }
}
