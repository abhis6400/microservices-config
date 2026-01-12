package com.masterclass.appb.clients;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

/**
 * Feign Client for communicating with App A
 * 
 * Allows App B to call endpoints on App A using service discovery.
 * Just like AppBClient in App A, this interface enables clean inter-service calls.
 */
@FeignClient(
    name = "app-a",
    url = "http://localhost:8080"  // Fallback URL (Eureka preferred)
)
public interface AppAClient {
    
    /**
     * Call the health check endpoint on App A
     * Maps to: GET /status (after gateway rewrite)
     */
    @GetMapping("/status")
    String getAppAStatus();
    
    /**
     * Get data from App A
     * Maps to: GET /data/{key}
     */
    @GetMapping("/data/{key}")
    String getData(@PathVariable("key") String key);
    
    /**
     * Get a greeting from App A
     * Maps to: GET /greeting/{name}
     */
    @GetMapping("/greeting/{name}")
    String sayHello(@PathVariable("name") String name);
}
