package com.masterclass.appa.service;

import com.masterclass.appa.clients.AppBClient;
import com.masterclass.appa.clients.AppBClientFallback;
import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.ratelimiter.annotation.RateLimiter;
import io.github.resilience4j.retry.annotation.Retry;
import io.github.resilience4j.timelimiter.annotation.TimeLimiter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;

/**
 * ============================================================
 * PHASE 4: RESILIENT SERVICE LAYER
 * ============================================================
 * 
 * PURPOSE OF THIS SERVICE:
 * ------------------------
 * This service wraps calls to App B with resilience patterns.
 * Instead of calling AppBClient directly from controllers,
 * we call this service which adds:
 * 
 * 1. @CircuitBreaker - Stops calling if service is down
 * 2. @Retry - Retries transient failures
 * 3. @TimeLimiter - Sets timeout deadline
 * 4. @Bulkhead - Isolates thread pool
 * 5. @RateLimiter - Controls request rate
 * 
 * WHY A SEPARATE SERVICE LAYER?
 * -----------------------------
 * 1. Single Responsibility: Controller handles HTTP, Service handles business logic
 * 2. Testability: Can test resilience patterns in isolation
 * 3. Reusability: Multiple controllers can use same resilient calls
 * 4. Clarity: Easy to see which patterns are applied
 * 
 * ANNOTATION ORDER MATTERS!
 * -------------------------
 * The annotations are applied as decorators (outermost to innermost):
 * 
 * Request → @Bulkhead → @TimeLimiter → @RateLimiter → @CircuitBreaker → @Retry → Actual Call
 *                                                                                    ↓
 * Response ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ← ←
 * 
 * So if Bulkhead is full → request rejected immediately (doesn't even try others)
 * If Circuit is OPEN → fails fast without retry
 * If all retries fail → fallback triggered
 */
@Service
public class AppBResilientService {
    
    private static final Logger logger = LoggerFactory.getLogger(AppBResilientService.class);
    
    private final AppBClient appBClient;
    private final AppBClientFallback fallback;
    
    // Circuit breaker and other pattern names (match application.yml)
    private static final String CIRCUIT_BREAKER_NAME = "appBCircuitBreaker";
    private static final String RETRY_NAME = "appBRetry";
    private static final String BULKHEAD_NAME = "appBBulkhead";
    private static final String RATE_LIMITER_NAME = "appBRateLimiter";
    private static final String TIME_LIMITER_NAME = "appBTimeLimiter";
    
    public AppBResilientService(AppBClient appBClient, AppBClientFallback fallback) {
        this.appBClient = appBClient;
        this.fallback = fallback;
    }
    
    /**
     * Get App B status with ALL resilience patterns applied.
     * 
     * PATTERN FLOW:
     * -------------
     * 1. Bulkhead checks: Are there available threads? (max 10)
     *    → NO: Reject immediately, use fallback
     *    → YES: Continue
     * 
     * 2. RateLimiter checks: Within rate limit? (100/sec)
     *    → NO: Wait up to 500ms, then reject
     *    → YES: Continue
     * 
     * 3. CircuitBreaker checks: Is circuit OPEN?
     *    → OPEN: Fail fast, use fallback
     *    → CLOSED/HALF_OPEN: Continue
     * 
     * 4. TimeLimiter: Starts 3 second countdown
     *    → If exceeded: Cancel and use fallback
     * 
     * 5. Retry: If call fails, retry up to 3 times
     *    → All retries fail: Use fallback
     * 
     * 6. Actual call to App B
     *    → Success: Return response
     *    → Failure: Go to step 5 (retry)
     * 
     * ANNOTATION ORDER (CRITICAL!):
     * - Outer annotations execute FIRST (in AOP advice)
     * - Inner annotations execute LAST (closest to actual call)
     * 
     * Resilience4j Aspect Order (from official docs):
     * Retry ( CircuitBreaker ( RateLimiter ( TimeLimiter ( Bulkhead ( Function ) ) ) ) )
     * 
     * THIS METHOD: WITH FALLBACK (Graceful Degradation Pattern)
     * -----------------------------------------------------------
     * Purpose: Demonstrate graceful degradation
     * Behavior: 
     *   - Returns 200 OK with degraded response
     *   - Fast response (~5ms)
     *   - NO RETRY (fallback prevents it)
     *   - Circuit breaker stays CLOSED (fallback succeeds)
     * 
     * Use Case: User-facing endpoints where speed and availability matter more than accuracy
     * 
     * Compare with: getAppBStatusForCircuitBreakerTest() - NO fallback, DOES retry
     */
    @Retry(name = RETRY_NAME)  // Won't retry (fallback prevents it)
    @CircuitBreaker(name = CIRCUIT_BREAKER_NAME)  // Won't open (fallback succeeds)
    @RateLimiter(name = RATE_LIMITER_NAME)
    @Bulkhead(name = BULKHEAD_NAME, fallbackMethod = "getStatusFallback")  // FALLBACK - Prevents retry!
    public String getAppBStatus() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Calling App B status endpoint with resilience patterns", 
            traceId != null ? traceId : "NO_TRACE");
        
        // This call is now protected by:
        // - Circuit Breaker (fails fast if App B is down)
        // - Retry (retries transient failures)
        // - Bulkhead (limited concurrent calls)
        // - Rate Limiter (controlled request rate)
        return appBClient.getAppBStatus();
    }
    
    /**
     * Fallback method for getAppBStatus()
     * 
     * IMPORTANT: Fallback method signature must match:
     * - Same return type
     * - Same parameters + Exception parameter
     * 
     * The Exception parameter tells us WHY the fallback was triggered:
     * - CircuitBreakerException: Circuit is OPEN
     * - TimeoutException: Request took too long
     * - BulkheadFullException: Too many concurrent requests
     * - RequestNotPermitted: Rate limit exceeded
     */
    public String getStatusFallback(Exception ex) {
        String traceId = MDC.get("traceId");
        logger.warn("[FALLBACK] [TRACE: {}] getAppBStatus failed: {}. Using fallback.", 
            traceId != null ? traceId : "NO_TRACE",
            ex.getClass().getSimpleName() + ": " + ex.getMessage());
        
        return fallback.getAppBStatus();
    }
    
    /**
     * Get product from App B with resilience.
     * WITH FALLBACK - Demonstrates graceful degradation for product catalog
     */
    @Retry(name = RETRY_NAME)  // Won't retry (fallback prevents it)
    @CircuitBreaker(name = CIRCUIT_BREAKER_NAME)  // Won't open (fallback succeeds)
    @RateLimiter(name = RATE_LIMITER_NAME)
    @Bulkhead(name = BULKHEAD_NAME, fallbackMethod = "getProductFallback")  // FALLBACK
    public String getProduct(String productId) {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Calling App B product endpoint for product: {}", 
            traceId != null ? traceId : "NO_TRACE", productId);
        
        return appBClient.getProduct(productId);
    }
    
    public String getProductFallback(String productId, Exception ex) {
        String traceId = MDC.get("traceId");
        logger.warn("[FALLBACK] [TRACE: {}] getProduct({}) failed: {}. Using fallback.", 
            traceId != null ? traceId : "NO_TRACE",
            productId,
            ex.getClass().getSimpleName());
        
        return fallback.getProduct(productId);
    }
    
    /**
     * Get greeting from App B with resilience.
     * WITH FALLBACK - Demonstrates graceful degradation for greeting service
     */
    @Retry(name = RETRY_NAME)  // Won't retry (fallback prevents it)
    @CircuitBreaker(name = CIRCUIT_BREAKER_NAME)  // Won't open (fallback succeeds)
    @RateLimiter(name = RATE_LIMITER_NAME)
    @Bulkhead(name = BULKHEAD_NAME, fallbackMethod = "getGreetingFallback")  // FALLBACK
    public String getGreeting(String name) {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Calling App B greeting endpoint for: {}", 
            traceId != null ? traceId : "NO_TRACE", name);
        
        return appBClient.getGreeting(name);
    }
    
    public String getGreetingFallback(String name, Exception ex) {
        String traceId = MDC.get("traceId");
        logger.warn("[FALLBACK] [TRACE: {}] getGreeting({}) failed: {}. Using fallback.", 
            traceId != null ? traceId : "NO_TRACE",
            name,
            ex.getClass().getSimpleName());
        
        return fallback.getGreeting(name);
    }
    
    /**
     * Async version with TimeLimiter
     * 
     * WHY ASYNC FOR TIMELIMITER?
     * --------------------------
     * TimeLimiter works with CompletableFuture/Reactor types.
     * For synchronous calls, we wrap in CompletableFuture.
     * 
     * This allows the timeout to actually INTERRUPT the call
     * rather than just timing out after the fact.
     */
    @TimeLimiter(name = TIME_LIMITER_NAME, fallbackMethod = "getStatusAsyncFallback")
    @CircuitBreaker(name = CIRCUIT_BREAKER_NAME, fallbackMethod = "getStatusAsyncFallback")
    public CompletableFuture<String> getAppBStatusAsync() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Calling App B status (async with timeout)", 
            traceId != null ? traceId : "NO_TRACE");
        
        return CompletableFuture.supplyAsync(() -> appBClient.getAppBStatus());
    }
    
    public CompletableFuture<String> getStatusAsyncFallback(Exception ex) {
        String traceId = MDC.get("traceId");
        logger.warn("[FALLBACK] [TRACE: {}] Async getAppBStatus failed: {}. Using fallback.", 
            traceId != null ? traceId : "NO_TRACE",
            ex.getClass().getSimpleName());
        
        return CompletableFuture.completedFuture(fallback.getAppBStatus());
    }
    
    /**
     * ============================================================
     * PRODUCTION-LIKE TEST METHOD - WITH RETRY (No Fallback)
     * ============================================================
     * 
     * PURPOSE: Demonstrate retry behavior with circuit breaker
     * 
     * KEY DIFFERENCE FROM getAppBStatus():
     * ------------------------------------
     * THIS METHOD HAS NO FALLBACK!
     * 
     * COMPARISON OF BOTH PATTERNS:
     * -----------------------------
     * 
     * getAppBStatus() - WITH FALLBACK (Old Pattern):
     *   ✅ Fast response (~5ms)
     *   ✅ User-friendly (200 OK with degraded data)
     *   ❌ NO RETRY (fallback prevents it)
     *   ❌ Circuit breaker stays CLOSED (fallback succeeds)
     *   ❌ Masks failures (you don't know App B is down)
     * 
     * getAppBStatusForCircuitBreakerTest() - NO FALLBACK (New Pattern):
     *   ✅ RETRY WORKS (3 attempts with exponential backoff)
     *   ✅ Circuit breaker opens correctly (records failures)
     *   ✅ Visibility of failures (circuit opens = alerts triggered)
     *   ❌ Slow response (~15s with retries)
     *   ❌ User gets error (500) after all retries
     * 
     * WHY NO FALLBACK HERE?
     * ---------------------
     * To allow retry to work:
     *   1. Call fails ❌
     *   2. NO fallback → Exception propagates
     *   3. Retry catches exception → Waits 5s
     *   4. Retry attempts again (up to 3 times)
     *   5. All retries fail → Exception continues
     *   6. Circuit breaker records: FAILURE ❌
     *   7. After 5 failures at 50%+ rate → Circuit OPENS! 🔴
     * 
     * HOW TO TEST BOTH PATTERNS:
     * --------------------------
     * 1. Stop App B
     * 
     * 2. Test OLD pattern (with fallback):
     *    curl http://localhost:8084/api/resilience/app-b/status
     *    Result: 200 OK, ~5ms, NO retry, Circuit stays CLOSED
     * 
     * 3. Test NEW pattern (no fallback):
     *    curl http://localhost:8084/api/resilience/app-b/status/cb/test
     *    Result: 500 Error, ~15s, DOES retry, Circuit OPENS after 5 calls
     * 
     * ANNOTATION ORDER (Official Resilience4j):
     * -----------------------------------------
     * @Retry - OUTERMOST (catches exceptions after all inner patterns)
     * @CircuitBreaker - Records result after retries
     * @RateLimiter - Controls rate
     * @Bulkhead - INNERMOST (closest to actual call)
     * 
     * NO FALLBACK = Retry works, Circuit opens, Failures visible
     */
    @Retry(name = RETRY_NAME)  // No fallback - RETRY WORKS!
    @CircuitBreaker(name = CIRCUIT_BREAKER_NAME)  // NO FALLBACK - Circuit opens!
    @RateLimiter(name = RATE_LIMITER_NAME)  // No fallback
    @Bulkhead(name = BULKHEAD_NAME)  // No fallback - Critical!
    public String getAppBStatusForCircuitBreakerTest() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] [CB_TEST] Calling App B status WITHOUT FALLBACK for circuit breaker testing", 
            traceId != null ? traceId : "NO_TRACE");
        
        // This call has NO fallback, so:
        // - If App B is down → Exception propagates → Circuit breaker counts FAILURE
        // - After 5 failures at 50%+ rate → Circuit OPENS
        // - When circuit is OPEN → CallNotPermittedException thrown immediately
        return appBClient.getAppBStatus();
    }
}
