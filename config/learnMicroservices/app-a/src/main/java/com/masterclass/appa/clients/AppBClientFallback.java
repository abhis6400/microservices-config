package com.masterclass.appa.clients;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;

/**
 * ============================================================
 * PHASE 4: FALLBACK HANDLER FOR APP B CLIENT
 * ============================================================
 * 
 * WHAT IS A FALLBACK?
 * -------------------
 * When App B is unavailable, instead of showing errors to users,
 * we provide a graceful degraded response.
 * 
 * FALLBACK STRATEGIES:
 * 1. Return cached data (best - user sees valid but possibly stale data)
 * 2. Return default response (acceptable - user sees placeholder)
 * 3. Return error message (last resort - but better than stack trace!)
 * 
 * WHY FALLBACKS MATTER:
 * ---------------------
 * Without fallback:
 *   User: "Get my profile"
 *   Response: "500 Internal Server Error" ❌
 *   User: "This app is broken!" 😠
 * 
 * With fallback:
 *   User: "Get my profile"
 *   Response: "Profile loading... (some features temporarily unavailable)"
 *   User: "Okay, I'll wait" 😐
 * 
 * The difference is HUGE for user experience and trust!
 * 
 * WHEN FALLBACK IS TRIGGERED:
 * ---------------------------
 * 1. Circuit breaker is OPEN (service known to be down)
 * 2. All retries exhausted (tried 3 times, still failing)
 * 3. Timeout exceeded (service too slow)
 * 4. Bulkhead full (too many concurrent requests)
 * 5. Rate limit exceeded (too many requests per second)
 */
@Component
public class AppBClientFallback implements AppBClient {
    
    private static final Logger logger = LoggerFactory.getLogger(AppBClientFallback.class);
    
    /**
     * Fallback for getAppBStatus()
     * 
     * Called when:
     * - App B is down
     * - Circuit breaker is OPEN
     * - All retries failed
     * - Timeout exceeded
     * 
     * Response strategy: Return degraded status message
     */
    @Override
    public String getAppBStatus() {
        String traceId = MDC.get("traceId");
        
        logger.warn(
            "[FALLBACK] [TRACE: {}] App B status check failed. " +
            "Using fallback response. Circuit breaker protecting system.",
            traceId != null ? traceId : "NO_TRACE"
        );
        
        // Return a graceful degraded response
        // In production, you might:
        // 1. Check a cache for last known status
        // 2. Return health status from a secondary source
        // 3. Return a generic "service unavailable" message
        
        return """
            {
                "status": "DEGRADED",
                "service": "app-b",
                "message": "App B is temporarily unavailable. Using fallback response.",
                "fallbackReason": "Circuit breaker activated or service unreachable",
                "timestamp": "%s",
                "traceId": "%s",
                "recommendation": "Please try again in a few moments"
            }
            """.formatted(
                java.time.Instant.now().toString(),
                traceId != null ? traceId : "NO_TRACE"
            );
    }
    
    /**
     * Fallback for getProduct(id)
     * 
     * Response strategy: Return "product unavailable" message
     * 
     * In a real system, you might:
     * 1. Return cached product data
     * 2. Return product from a backup service
     * 3. Return minimal product info from local database
     */
    @Override
    public String getProduct(String id) {
        String traceId = MDC.get("traceId");
        
        logger.warn(
            "[FALLBACK] [TRACE: {}] Product {} fetch failed. " +
            "App B unavailable. Using fallback.",
            traceId != null ? traceId : "NO_TRACE",
            id
        );
        
        // Cache lookup would go here in production
        // For now, return a helpful message
        
        return """
            {
                "productId": "%s",
                "status": "UNAVAILABLE",
                "message": "Product details temporarily unavailable",
                "fallbackReason": "Product service (App B) is not responding",
                "timestamp": "%s",
                "traceId": "%s",
                "cached": false,
                "recommendation": "Product information will be available when service recovers"
            }
            """.formatted(
                id,
                java.time.Instant.now().toString(),
                traceId != null ? traceId : "NO_TRACE"
            );
    }
    
    /**
     * Fallback for getGreeting(name)
     * 
     * Response strategy: Return a local greeting (doesn't need App B)
     * 
     * This is an example of GRACEFUL DEGRADATION:
     * - The primary service is down
     * - But we can still provide SOME value to the user
     * - Better than showing an error!
     */
    @Override
    public String getGreeting(String name) {
        String traceId = MDC.get("traceId");
        
        logger.warn(
            "[FALLBACK] [TRACE: {}] Greeting for '{}' from App B failed. " +
            "Using local fallback greeting.",
            traceId != null ? traceId : "NO_TRACE",
            name
        );
        
        // Provide a local greeting instead of failing completely
        // This is GRACEFUL DEGRADATION - the system still works!
        
        return """
            {
                "greeting": "Hello %s! (Greeting generated locally - App B temporarily unavailable)",
                "source": "FALLBACK",
                "originalService": "app-b",
                "timestamp": "%s",
                "traceId": "%s",
                "note": "Full greeting service will resume when App B recovers"
            }
            """.formatted(
                name,
                java.time.Instant.now().toString(),
                traceId != null ? traceId : "NO_TRACE"
            );
    }
}
