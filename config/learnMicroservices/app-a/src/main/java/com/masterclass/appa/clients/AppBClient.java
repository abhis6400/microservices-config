package com.masterclass.appa.clients;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

/**
 * Feign Client for communicating with App B
 * 
 * How it works:
 * - @FeignClient("app-b") tells Feign to look for "app-b" service in Eureka
 * - Feign automatically discovers the URL from Eureka registry
 * - Methods defined here create HTTP calls to App B
 * - All with zero boilerplate code!
 * 
 * Example: appBClient.getAppBStatus() → GET /api/app-b/status on App B service
 */
@FeignClient(
    name = "app-b"
    // URL will be discovered from Eureka service registry
)
public interface AppBClient {
    
    /**
     * Call the health check endpoint on App B
     * Maps to: GET /status (after gateway rewrite)
     */
    @GetMapping("/status")
    String getAppBStatus();
    
    /**
     * Get a product from App B
     * Maps to: GET /product/{id}
     */
    @GetMapping("/product/{id}")
    String getProduct(@PathVariable("id") String id);
    
    /**
     * Get a greeting from App B
     * Maps to: GET /greeting/{name}
     */
    @GetMapping("/greeting/{name}")
    String getGreeting(@PathVariable("name") String name);
}
