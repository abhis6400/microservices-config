package com.masterclass.appa.controller;

import com.masterclass.appa.service.AppBResilientService;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * ============================================================
 * PHASE 4: RESILIENCE TESTING CONTROLLER
 * ============================================================
 * 
 * PURPOSE:
 * --------
 * This controller provides endpoints to:
 * 1. TEST resilience patterns in action
 * 2. VIEW circuit breaker state
 * 3. SIMULATE failures for testing
 * 
 * ENDPOINTS:
 * ----------
 * GET  /api/resilience/app-b/status     - Call App B with resilience
 * GET  /api/resilience/app-b/product/{id} - Get product with resilience
 * GET  /api/resilience/app-b/greeting/{name} - Get greeting with resilience
 * GET  /api/resilience/circuit-breaker/status - View circuit breaker state
 * POST /api/resilience/circuit-breaker/reset  - Reset circuit breaker
 * 
 * TESTING GUIDE:
 * --------------
 * 1. Start App A and App B normally
 * 2. Call /api/resilience/app-b/status → Should succeed
 * 3. Stop App B (kill the process)
 * 4. Call /api/resilience/app-b/status multiple times
 *    → First few: Retries, then fallback
 *    → After ~5 failures: Circuit opens
 * 5. Call /api/resilience/circuit-breaker/status
 *    → Should show state: OPEN
 * 6. Wait 30 seconds (waitDurationInOpenState)
 * 7. Call /api/resilience/app-b/status
 *    → Circuit is HALF_OPEN, tests recovery
 * 8. Start App B again
 * 9. Call /api/resilience/app-b/status
 *    → Should succeed, circuit closes
 */
@RestController
@RequestMapping("/api/resilience")
public class ResilienceController {
    
    private static final Logger logger = LoggerFactory.getLogger(ResilienceController.class);
    
    private final AppBResilientService appBResilientService;
    private final CircuitBreakerRegistry circuitBreakerRegistry;
    
    public ResilienceController(
            AppBResilientService appBResilientService,
            CircuitBreakerRegistry circuitBreakerRegistry) {
        this.appBResilientService = appBResilientService;
        this.circuitBreakerRegistry = circuitBreakerRegistry;
    }
    
    /**
     * ============================================================
     * ENDPOINT: Get App B Status (with resilience)
     * ============================================================
     * 
     * This endpoint calls App B through the resilient service layer.
     * If App B is down:
     *   1. Retry up to 3 times with exponential backoff
     *   2. If all retries fail, use fallback
     *   3. If too many failures, circuit breaker opens
     *   4. When circuit is OPEN, fail fast with fallback
     */
    @GetMapping("/app-b/status")
    public ResponseEntity<Map<String, Object>> getAppBStatus() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Resilient call to App B status", 
            traceId != null ? traceId : "NO_TRACE");
        
        long startTime = System.currentTimeMillis();
        
        // Call through resilient service
        String response = appBResilientService.getAppBStatus();
        
        long duration = System.currentTimeMillis() - startTime;
        
        // Get current circuit breaker state
        CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        Map<String, Object> result = new HashMap<>();
        result.put("response", response);
        result.put("durationMs", duration);
        result.put("traceId", traceId);
        result.put("circuitBreakerState", circuitBreaker.getState().name());
        result.put("failureRate", circuitBreaker.getMetrics().getFailureRate() + "%");
        result.put("timestamp", java.time.Instant.now().toString());
        
        return ResponseEntity.ok(result);
    }
    
    /**
     * ============================================================
     * ENDPOINT: Get Product (with resilience)
     * ============================================================
     */
    @GetMapping("/app-b/product/{id}")
    public ResponseEntity<Map<String, Object>> getProduct(@PathVariable String id) {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Resilient call to App B product: {}", 
            traceId != null ? traceId : "NO_TRACE", id);
        
        long startTime = System.currentTimeMillis();
        String response = appBResilientService.getProduct(id);
        long duration = System.currentTimeMillis() - startTime;
        
        CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        Map<String, Object> result = new HashMap<>();
        result.put("productId", id);
        result.put("response", response);
        result.put("durationMs", duration);
        result.put("circuitBreakerState", circuitBreaker.getState().name());
        
        return ResponseEntity.ok(result);
    }
    
    /**
     * ============================================================
     * ENDPOINT: Get Greeting (with resilience)
     * ============================================================
     */
    @GetMapping("/app-b/greeting/{name}")
    public ResponseEntity<Map<String, Object>> getGreeting(@PathVariable String name) {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Resilient call to App B greeting: {}", 
            traceId != null ? traceId : "NO_TRACE", name);
        
        long startTime = System.currentTimeMillis();
        String response = appBResilientService.getGreeting(name);
        long duration = System.currentTimeMillis() - startTime;
        
        CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        Map<String, Object> result = new HashMap<>();
        result.put("name", name);
        result.put("response", response);
        result.put("durationMs", duration);
        result.put("circuitBreakerState", circuitBreaker.getState().name());
        
        return ResponseEntity.ok(result);
    }
    
    /**
     * ============================================================
     * ENDPOINT: Get App B Status (async with timeout)
     * ============================================================
     * 
     * This version uses CompletableFuture with TimeLimiter.
     * If App B takes too long (> 3 seconds), request is cancelled.
     */
    @GetMapping("/app-b/status/async")
    public CompletableFuture<ResponseEntity<Map<String, Object>>> getAppBStatusAsync() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Async resilient call to App B status", 
            traceId != null ? traceId : "NO_TRACE");
        
        long startTime = System.currentTimeMillis();
        
        return appBResilientService.getAppBStatusAsync()
            .thenApply(response -> {
                long duration = System.currentTimeMillis() - startTime;
                
                CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
                
                Map<String, Object> result = new HashMap<>();
                result.put("response", response);
                result.put("durationMs", duration);
                result.put("async", true);
                result.put("circuitBreakerState", circuitBreaker.getState().name());
                
                return ResponseEntity.ok(result);
            });
    }
    
    /**
     * ============================================================
     * ENDPOINT: Circuit Breaker Test (Production-like)
     * ============================================================
     * 
     * PURPOSE: Test circuit breaker opening AUTOMATICALLY like in production
     * 
     * KEY DIFFERENCE FROM /app-b/status:
     * ----------------------------------
     * Regular endpoint:  Has fallback → Failures counted as SUCCESS → Circuit stays CLOSED
     * This endpoint:     NO fallback  → Failures counted as FAILURE → Circuit OPENS after threshold
     * 
     * HOW TO USE:
     * -----------
     * 1. Stop App B (simulate downstream service failure)
     * 2. Call this endpoint 10 times:
     *    curl http://localhost:9002/api/app-a/api/resilience/app-b/status/cb/test
     * 
     * EXPECTED BEHAVIOR:
     * ------------------
     * Request 1-4:  Returns 500 error (App B down)
     *               Duration: ~500-1500ms (retries with backoff)
     *               Circuit State: CLOSED
     *               
     * Request 5:    Circuit breaker OPENS! (50% failure rate reached)
     *               Returns 500 error
     *               Circuit State: OPEN
     *               
     * Request 6-10: INSTANT failure (<1ms)
     *               Returns CallNotPermittedException
     *               Circuit State: OPEN
     *               No actual call to App B!
     *               
     * After 30 sec: Circuit transitions to HALF_OPEN
     *               Next request will test if App B recovered
     *               
     * Start App B:  Next request succeeds
     *               Circuit closes automatically
     *               Circuit State: CLOSED
     * 
     * PRODUCTION SCENARIO:
     * --------------------
     * This simulates critical endpoints that MUST succeed or fail
     * (no degraded service acceptable). Circuit breaker protects
     * system by failing fast once threshold is reached.
     * 
     * COMPARE WITH REGULAR ENDPOINT:
     * ------------------------------
     * Regular /app-b/status:           This /app-b/status/cb/test:
     * - Has fallback                   - NO fallback
     * - Returns 200 OK (degraded)      - Returns 500 error
     * - Circuit stays CLOSED           - Circuit OPENS after failures
     * - Always ~5-10ms                 - <1ms when circuit OPEN
     */
    @GetMapping("/app-b/status/cb/test")
    public ResponseEntity<Map<String, Object>> circuitBreakerTest() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] [CB_TEST] Circuit breaker test call (NO FALLBACK)", 
            traceId != null ? traceId : "NO_TRACE");
        
        long startTime = System.currentTimeMillis();
        CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        // Capture state BEFORE call
        String stateBefore = circuitBreaker.getState().name();
        float failureRateBefore = circuitBreaker.getMetrics().getFailureRate();
        int failedCallsBefore = circuitBreaker.getMetrics().getNumberOfFailedCalls();
        
        Map<String, Object> result = new HashMap<>();
        result.put("traceId", traceId);
        result.put("stateBefore", stateBefore);
        result.put("failureRateBefore", String.format("%.1f%%", failureRateBefore));
        
        try {
            // Call WITHOUT fallback - failures will count!
            String response = appBResilientService.getAppBStatusForCircuitBreakerTest();
            
            long duration = System.currentTimeMillis() - startTime;
            
            // Success case
            result.put("success", true);
            result.put("response", response);
            result.put("durationMs", duration);
            result.put("stateAfter", circuitBreaker.getState().name());
            result.put("failureRateAfter", String.format("%.1f%%", circuitBreaker.getMetrics().getFailureRate()));
            result.put("message", "✅ Call succeeded! App B is healthy.");
            
            return ResponseEntity.ok(result);
            
        } catch (io.github.resilience4j.circuitbreaker.CallNotPermittedException e) {
            // Circuit breaker is OPEN - rejecting calls immediately
            long duration = System.currentTimeMillis() - startTime;
            
            result.put("success", false);
            result.put("error", "Circuit Breaker OPEN");
            result.put("errorType", "CallNotPermittedException");
            result.put("durationMs", duration);
            result.put("stateAfter", "OPEN");
            result.put("failureRateAfter", String.format("%.1f%%", circuitBreaker.getMetrics().getFailureRate()));
            result.put("notPermittedCalls", circuitBreaker.getMetrics().getNumberOfNotPermittedCalls());
            result.put("message", "⚡ Circuit breaker OPEN! Call rejected instantly. System protected from cascading failure.");
            result.put("explanation", "Circuit opened because failure rate exceeded 50%. No actual call to App B made. Wait 30 seconds for HALF_OPEN state.");
            
            // Note: Duration should be <1ms since call is rejected immediately
            if (duration < 10) {
                result.put("performance", "⚡ INSTANT rejection - Circuit breaker working perfectly!");
            }
            
            return ResponseEntity.status(503).body(result);
            
        } catch (Exception e) {
            // Actual failure (App B down, timeout, etc.)
            long duration = System.currentTimeMillis() - startTime;
            
            result.put("success", false);
            result.put("error", e.getClass().getSimpleName());
            result.put("errorMessage", e.getMessage());
            result.put("durationMs", duration);
            result.put("stateAfter", circuitBreaker.getState().name());
            result.put("failureRateAfter", String.format("%.1f%%", circuitBreaker.getMetrics().getFailureRate()));
            result.put("failedCallsAfter", circuitBreaker.getMetrics().getNumberOfFailedCalls());
            result.put("failureIncrement", circuitBreaker.getMetrics().getNumberOfFailedCalls() - failedCallsBefore);
            
            // Check if circuit just opened
            String stateAfter = circuitBreaker.getState().name();
            if (!stateBefore.equals("OPEN") && stateAfter.equals("OPEN")) {
                result.put("message", "🔴 Circuit breaker just OPENED! Failure threshold reached.");
                result.put("explanation", "After " + circuitBreaker.getMetrics().getNumberOfFailedCalls() + 
                    " failures, circuit breaker opened to protect system. Next calls will be instant (<1ms).");
            } else if (stateAfter.equals("CLOSED")) {
                result.put("message", "⚠️ Call failed but circuit still CLOSED. Need " + 
                    circuitBreaker.getCircuitBreakerConfig().getMinimumNumberOfCalls() + 
                    " calls with " + circuitBreaker.getCircuitBreakerConfig().getFailureRateThreshold() + 
                    "% failure rate to open.");
            }
            
            return ResponseEntity.status(500).body(result);
        }
    }
    
    /**
     * ============================================================
     * ENDPOINT: View Circuit Breaker Status
     * ============================================================
     * 
     * Returns detailed information about the circuit breaker state.
     * 
     * METRICS EXPLAINED:
     * - state: Current state (CLOSED, OPEN, HALF_OPEN)
     * - failureRate: Percentage of failed calls
     * - slowCallRate: Percentage of slow calls
     * - bufferedCalls: Number of calls in sliding window
     * - failedCalls: Number of failed calls
     * - slowCalls: Number of slow calls
     * - notPermittedCalls: Calls rejected because circuit is OPEN
     */
    @GetMapping("/circuit-breaker/status")
    public ResponseEntity<Map<String, Object>> getCircuitBreakerStatus() {
        CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        CircuitBreaker.Metrics metrics = circuitBreaker.getMetrics();
        
        Map<String, Object> status = new HashMap<>();
        
        // Basic info
        status.put("name", circuitBreaker.getName());
        status.put("state", circuitBreaker.getState().name());
        status.put("timestamp", java.time.Instant.now().toString());
        
        // Metrics
        Map<String, Object> metricsMap = new HashMap<>();
        metricsMap.put("failureRate", metrics.getFailureRate() + "%");
        metricsMap.put("slowCallRate", metrics.getSlowCallRate() + "%");
        metricsMap.put("bufferedCalls", metrics.getNumberOfBufferedCalls());
        metricsMap.put("failedCalls", metrics.getNumberOfFailedCalls());
        metricsMap.put("slowCalls", metrics.getNumberOfSlowCalls());
        metricsMap.put("successfulCalls", metrics.getNumberOfSuccessfulCalls());
        metricsMap.put("notPermittedCalls", metrics.getNumberOfNotPermittedCalls());
        status.put("metrics", metricsMap);
        
        // Configuration (what triggers state changes)
        Map<String, Object> config = new HashMap<>();
        config.put("failureRateThreshold", circuitBreaker.getCircuitBreakerConfig().getFailureRateThreshold() + "%");
        config.put("slowCallRateThreshold", circuitBreaker.getCircuitBreakerConfig().getSlowCallRateThreshold() + "%");
        config.put("slowCallDurationThreshold", circuitBreaker.getCircuitBreakerConfig().getSlowCallDurationThreshold().toMillis() + "ms");
        config.put("slidingWindowSize", circuitBreaker.getCircuitBreakerConfig().getSlidingWindowSize());
        config.put("minimumNumberOfCalls", circuitBreaker.getCircuitBreakerConfig().getMinimumNumberOfCalls());
        config.put("waitDurationInOpenState", circuitBreaker.getCircuitBreakerConfig().getMaxWaitDurationInHalfOpenState().toSeconds() + "s");
        status.put("configuration", config);
        
        // State explanation
        String stateExplanation = switch (circuitBreaker.getState()) {
            case CLOSED -> "Normal operation. All requests are sent to App B.";
            case OPEN -> "App B is considered DOWN. Requests fail fast with fallback.";
            case HALF_OPEN -> "Testing recovery. Limited requests sent to check if App B recovered.";
            case DISABLED -> "Circuit breaker is disabled. All requests pass through.";
            case FORCED_OPEN -> "Manually forced OPEN. All requests use fallback.";
            case METRICS_ONLY -> "Only collecting metrics, not protecting.";
        };
        status.put("stateExplanation", stateExplanation);
        
        return ResponseEntity.ok(status);
    }
    
    /**
     * ============================================================
     * ENDPOINT: Reset Circuit Breaker
     * ============================================================
     * 
     * Manually reset the circuit breaker to CLOSED state.
     * 
     * USE CASES:
     * - Testing: Reset after testing failure scenarios
     * - Emergency: Force circuit closed if you know service is healthy
     * - Debugging: Clear metrics and start fresh
     * 
     * WARNING: Use with caution in production!
     * If service is actually down, circuit will just open again.
     */
    @PostMapping("/circuit-breaker/reset")
    public ResponseEntity<Map<String, Object>> resetCircuitBreaker() {
        CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        String previousState = circuitBreaker.getState().name();
        
        // Reset to CLOSED state
        circuitBreaker.reset();
        
        logger.info("Circuit Breaker [{}] manually reset: {} → CLOSED", 
            circuitBreaker.getName(), previousState);
        
        Map<String, Object> result = new HashMap<>();
        result.put("action", "RESET");
        result.put("previousState", previousState);
        result.put("currentState", circuitBreaker.getState().name());
        result.put("message", "Circuit breaker has been reset to CLOSED state");
        result.put("timestamp", java.time.Instant.now().toString());
        
        return ResponseEntity.ok(result);
    }
    
    /**
     * ============================================================
     * ENDPOINT: Force Circuit Breaker State
     * ============================================================
     * 
     * Manually set circuit breaker state for testing.
     * 
     * VALID STATES:
     * - CLOSED: Normal operation
     * - OPEN: Fail fast
     * - HALF_OPEN: Test recovery
     * - DISABLED: Turn off circuit breaker
     */
    @PostMapping("/circuit-breaker/state/{state}")
    public ResponseEntity<Map<String, Object>> setCircuitBreakerState(@PathVariable String state) {
        CircuitBreaker circuitBreaker = circuitBreakerRegistry.circuitBreaker("appBCircuitBreaker");
        
        String previousState = circuitBreaker.getState().name();
        
        try {
            switch (state.toUpperCase()) {
                case "OPEN" -> circuitBreaker.transitionToOpenState();
                case "CLOSED" -> circuitBreaker.transitionToClosedState();
                case "HALF_OPEN" -> circuitBreaker.transitionToHalfOpenState();
                case "DISABLED" -> circuitBreaker.transitionToDisabledState();
                case "METRICS_ONLY" -> circuitBreaker.transitionToMetricsOnlyState();
                default -> {
                    return ResponseEntity.badRequest().body(Map.of(
                        "error", "Invalid state: " + state,
                        "validStates", "OPEN, CLOSED, HALF_OPEN, DISABLED, METRICS_ONLY"
                    ));
                }
            }
            
            logger.info("Circuit Breaker [{}] manually transitioned: {} → {}", 
                circuitBreaker.getName(), previousState, state.toUpperCase());
            
            Map<String, Object> result = new HashMap<>();
            result.put("action", "STATE_CHANGE");
            result.put("previousState", previousState);
            result.put("currentState", circuitBreaker.getState().name());
            result.put("message", "Circuit breaker state changed successfully");
            
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                "error", "Failed to change state: " + e.getMessage()
            ));
        }
    }
}
