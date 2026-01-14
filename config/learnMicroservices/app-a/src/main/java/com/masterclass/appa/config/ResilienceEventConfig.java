package com.masterclass.appa.config;

import io.github.resilience4j.bulkhead.BulkheadRegistry;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.ratelimiter.RateLimiterRegistry;
import io.github.resilience4j.retry.RetryRegistry;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;

/**
 * ============================================================
 * PHASE 4: RESILIENCE EVENT MONITORING CONFIGURATION
 * ============================================================
 * <p>
 * PURPOSE:
 * --------
 * This configuration registers event listeners for all resilience patterns.
 * Events are logged so you can:
 * <p>
 * 1. SEE when circuit breaker changes state (CLOSED → OPEN → HALF_OPEN)
 * 2. TRACK retry attempts and outcomes
 * 3. MONITOR bulkhead thread pool usage
 * 4. OBSERVE rate limiting in action
 * <p>
 * WHY EVENT MONITORING?
 * ---------------------
 * Without monitoring, resilience patterns are a "black box":
 * - Is the circuit breaker working? 🤷
 * - How often are retries happening? 🤷
 * - Is the bulkhead protecting us? 🤷
 * <p>
 * With monitoring, you have VISIBILITY:
 * - Circuit opened at 10:05 due to 60% failure rate ✅
 * - 15 retry attempts in the last minute ✅
 * - Bulkhead rejected 5 requests (pool full) ✅
 * <p>
 * This is OBSERVABILITY - the ability to understand system behavior!
 * <p>
 * LOG LEVELS:
 * -----------
 * - INFO: Normal events (circuit created, state transitions)
 * - WARN: Concerning events (failures, rejections, retries)
 * - ERROR: Critical events (circuit opened, all retries failed)
 */
@Configuration
public class ResilienceEventConfig {

    private static final Logger logger = LoggerFactory.getLogger(ResilienceEventConfig.class);

    private final CircuitBreakerRegistry circuitBreakerRegistry;
    private final RetryRegistry retryRegistry;
    private final BulkheadRegistry bulkheadRegistry;
    private final RateLimiterRegistry rateLimiterRegistry;

    public ResilienceEventConfig(
            CircuitBreakerRegistry circuitBreakerRegistry,
            RetryRegistry retryRegistry,
            BulkheadRegistry bulkheadRegistry,
            RateLimiterRegistry rateLimiterRegistry) {
        this.circuitBreakerRegistry = circuitBreakerRegistry;
        this.retryRegistry = retryRegistry;
        this.bulkheadRegistry = bulkheadRegistry;
        this.rateLimiterRegistry = rateLimiterRegistry;
    }

    /**
     * Register event listeners after all beans are initialized.
     *
     * @PostConstruct ensures this runs after dependency injection is complete.
     */
    @PostConstruct
    public void registerEventListeners() {
        logger.info("============================================================");
        logger.info("PHASE 4: Registering Resilience Event Listeners");
        logger.info("============================================================");

        registerCircuitBreakerEvents();
        registerRetryEvents();
        registerBulkheadEvents();
        registerRateLimiterEvents();

        logger.info("============================================================");
        logger.info("PHASE 4: All Resilience Event Listeners Registered ✅");
        logger.info("============================================================");
    }

    /**
     * ============================================================
     * CIRCUIT BREAKER EVENTS
     * ============================================================
     * <p>
     * Events to monitor:
     * - STATE TRANSITIONS: CLOSED → OPEN → HALF_OPEN → CLOSED
     * - SUCCESS/ERROR: Each call recorded
     * - SLOW CALLS: Calls exceeding threshold
     * - IGNORED ERRORS: Errors that don't count toward failure rate
     */
    private void registerCircuitBreakerEvents() {
        circuitBreakerRegistry.getAllCircuitBreakers().forEach(circuitBreaker -> {
            String name = circuitBreaker.getName();

            logger.info("Registering event listeners for Circuit Breaker: {}", name);

            circuitBreaker.getEventPublisher()
                    // STATE TRANSITIONS - Most important events!
                    .onStateTransition(event -> {
                        CircuitBreaker.StateTransition transition = event.getStateTransition();

                        if (transition.getToState() == CircuitBreaker.State.OPEN) {
                            // CRITICAL: Circuit opened - service is considered DOWN
                            logger.error(
                                    "🔴 CIRCUIT BREAKER [{}] OPENED! Transition: {} → {}\n" +
                                            "   Reason: Too many failures detected\n" +
                                            "   Action: Requests will fail fast until recovery\n" +
                                            "   Metrics: Failure Rate: {}%, Slow Call Rate: {}%",
                                    name,
                                    transition.getFromState(),
                                    transition.getToState(),
                                    circuitBreaker.getMetrics().getFailureRate(),
                                    circuitBreaker.getMetrics().getSlowCallRate()
                            );
                        } else if (transition.getToState() == CircuitBreaker.State.HALF_OPEN) {
                            // Testing recovery
                            logger.warn(
                                    "🟡 CIRCUIT BREAKER [{}] HALF_OPEN: {} → {}\n" +
                                            "   Status: Testing if service has recovered\n" +
                                            "   Action: Allowing limited test requests",
                                    name,
                                    transition.getFromState(),
                                    transition.getToState()
                            );
                        } else if (transition.getToState() == CircuitBreaker.State.CLOSED) {
                            // Recovered!
                            logger.info(
                                    "🟢 CIRCUIT BREAKER [{}] CLOSED: {} → {}\n" +
                                            "   Status: Service recovered, normal operation resumed\n" +
                                            "   Action: All requests will be sent normally",
                                    name,
                                    transition.getFromState(),
                                    transition.getToState()
                            );
                        }
                    })
                    // ERRORS - Track each failure
                    .onError(event -> {
                        logger.warn(
                                "⚠️ CIRCUIT BREAKER [{}] ERROR recorded\n" +
                                        "   Exception: {}\n" +
                                        "   Duration: {}ms\n" +
                                        "   Current Failure Rate: {}%",
                                name,
                                event.getThrowable().getClass().getSimpleName(),
                                event.getElapsedDuration().toMillis(),
                                circuitBreaker.getMetrics().getFailureRate()
                        );
                    })
                    // SUCCESS - Track each success
                    .onSuccess(event -> {
                        logger.debug(
                                "✅ CIRCUIT BREAKER [{}] SUCCESS: Duration: {}ms",
                                name,
                                event.getElapsedDuration().toMillis()
                        );
                    })
                    // SLOW CALLS - Track performance issues
                    .onSlowCallRateExceeded(event -> {
                        logger.warn(
                                "🐢 CIRCUIT BREAKER [{}] SLOW CALL RATE EXCEEDED: {}%",
                                name,
                                event.getSlowCallRate()
                        );
                    })
                    // FAILURE RATE EXCEEDED - About to open!
                    .onFailureRateExceeded(event -> {
                        logger.error(
                                "🚨 CIRCUIT BREAKER [{}] FAILURE RATE EXCEEDED: {}%\n" +
                                        "   Circuit will open if this continues!",
                                name,
                                event.getFailureRate()
                        );
                    });
        });
    }

    /**
     * ============================================================
     * RETRY EVENTS
     * ============================================================
     * <p>
     * Events to monitor:
     * - RETRY: Each retry attempt
     * - SUCCESS: Retry succeeded
     * - ERROR: All retries exhausted
     * - IGNORED ERROR: Error that shouldn't be retried
     */
    private void registerRetryEvents() {
        retryRegistry.getAllRetries().forEach(retry -> {
            String name = retry.getName();

            logger.info("Registering event listeners for Retry: {}", name);

            retry.getEventPublisher()
                    // RETRY ATTEMPT
                    .onRetry(event -> {
                        logger.warn(
                                "🔄 RETRY [{}] Attempt {} of {}\n" +
                                        "   Exception: {}\n" +
                                        "   Wait before next: Will use exponential backoff",
                                name,
                                event.getNumberOfRetryAttempts(),
                                retry.getRetryConfig().getMaxAttempts(),
                                event.getLastThrowable().getClass().getSimpleName()
                        );
                    })
                    // RETRY SUCCESS
                    .onSuccess(event -> {
                        if (event.getNumberOfRetryAttempts() > 0) {
                            logger.info(
                                    "✅ RETRY [{}] SUCCEEDED after {} attempts",
                                    name,
                                    event.getNumberOfRetryAttempts()
                            );
                        }
                    })
                    // ALL RETRIES FAILED
                    .onError(event -> {
                        logger.error(
                                "❌ RETRY [{}] EXHAUSTED after {} attempts\n" +
                                        "   Final Exception: {}\n" +
                                        "   Action: Fallback will be used",
                                name,
                                event.getNumberOfRetryAttempts(),
                                event.getLastThrowable().getClass().getSimpleName()
                        );
                    })
                    // IGNORED ERROR
                    .onIgnoredError(event -> {
                        logger.debug(
                                "⏭️ RETRY [{}] IGNORED: {} (not retryable)",
                                name,
                                event.getLastThrowable().getClass().getSimpleName()
                        );
                    });
        });
    }

    /**
     * ============================================================
     * BULKHEAD EVENTS
     * ============================================================
     * <p>
     * Events to monitor:
     * - CALL PERMITTED: Request allowed through
     * - CALL REJECTED: Pool full, request rejected
     * - CALL FINISHED: Request completed
     */
    private void registerBulkheadEvents() {
        bulkheadRegistry.getAllBulkheads().forEach(bulkhead -> {
            String name = bulkhead.getName();

            logger.info("Registering event listeners for Bulkhead: {}", name);

            bulkhead.getEventPublisher()
                    // REJECTED - Pool full!
                    .onCallRejected(event -> {
                        logger.warn(
                                "🚫 BULKHEAD [{}] REJECTED request\n" +
                                        "   Reason: Maximum concurrent calls reached\n" +
                                        "   Available permits: {}\n" +
                                        "   Action: Fallback will be used",
                                name,
                                bulkhead.getMetrics().getAvailableConcurrentCalls()
                        );
                    })
                    // PERMITTED - Request allowed
                    .onCallPermitted(event -> {
                        logger.debug(
                                "✅ BULKHEAD [{}] PERMITTED: Available permits: {}",
                                name,
                                bulkhead.getMetrics().getAvailableConcurrentCalls()
                        );
                    })
                    // FINISHED - Request completed
                    .onCallFinished(event -> {
                        logger.debug(
                                "✅ BULKHEAD [{}] FINISHED: Available permits now: {}",
                                name,
                                bulkhead.getMetrics().getAvailableConcurrentCalls()
                        );
                    });
        });
    }

    /**
     * ============================================================
     * RATE LIMITER EVENTS
     * ============================================================
     * <p>
     * Events to monitor:
     * - SUCCESS: Request within rate limit
     * - FAILURE: Rate limit exceeded
     */
    private void registerRateLimiterEvents() {
        rateLimiterRegistry.getAllRateLimiters().forEach(rateLimiter -> {
            String name = rateLimiter.getName();

            logger.info("Registering event listeners for RateLimiter: {}", name);

            rateLimiter.getEventPublisher()
                    // RATE LIMIT EXCEEDED
                    .onFailure(event -> {
                        logger.warn(
                                "🚦 RATE LIMITER [{}] EXCEEDED\n" +
                                        "   Available permissions: {}\n" +
                                        "   Action: Request rejected or delayed",
                                name,
                                rateLimiter.getMetrics().getAvailablePermissions()
                        );
                    })
                    // SUCCESS
                    .onSuccess(event -> {
                        logger.debug(
                                "✅ RATE LIMITER [{}] PERMITTED: Available: {}",
                                name,
                                rateLimiter.getMetrics().getAvailablePermissions()
                        );
                    });
        });
    }
}
