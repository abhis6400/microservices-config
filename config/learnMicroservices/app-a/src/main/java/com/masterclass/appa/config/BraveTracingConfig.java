package com.masterclass.appa.config;

import feign.RequestInterceptor;
import feign.RequestTemplate;
import io.micrometer.tracing.Tracer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Tracing Configuration for App A
 * 
 * Micrometer Tracing + Brave Bridge handles trace ID generation and logging.
 * This config adds a Feign interceptor to propagate trace IDs in HTTP headers.
 * 
 * Uses tracer.currentSpan() which is reliable across thread boundaries.
 */
@Configuration
public class BraveTracingConfig {

    /**
     * Feign interceptor to add B3 trace headers to outgoing Feign requests.
     * This ensures trace IDs are propagated from App A to App B.
     * 
     * Uses tracer.currentSpan() instead of currentTraceContext() for proper
     * thread context propagation in async/threaded environments.
     */
    @Bean
    public RequestInterceptor feignTracingInterceptor(Tracer tracer) {
        return template -> {
            // Get current span using Micrometer's recommended method
            // currentSpan() is reliable across thread boundaries
            var currentSpan = tracer.currentSpan();
            
            if (currentSpan != null && currentSpan.context() != null) {
                var context = currentSpan.context();
                String traceId = context.traceId();
                String spanId = context.spanId();
                
                // Add B3 single header format: b3=traceId-spanId
                if (traceId != null && spanId != null) {
                    template.header("b3", traceId + "-" + spanId);
                }
            }
        };
    }
}
