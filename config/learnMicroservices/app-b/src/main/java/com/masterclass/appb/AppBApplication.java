package com.masterclass.appb;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * App B - Second Microservice
 * 
 * Features:
 * - Uses centralized configuration from Config Server
 * - Service Discovery via Eureka
 * - Feign Client for inter-service communication
 */
@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients
public class AppBApplication {

    public static void main(String[] args) {
        SpringApplication.run(AppBApplication.class, args);
        
        System.out.println("\n" +
                "╔════════════════════════════════════════════╗\n" +
                "║          APP B - FEIGN ENABLED             ║\n" +
                "║                                            ║\n" +
                "║   Ready to receive calls from other apps   ║\n" +
                "║                                            ║\n" +
                "║    📡 Eureka: http://localhost:8761       ║\n" +
                "║    🔗 App B:  http://localhost:8081       ║\n" +
                "╚════════════════════════════════════════════╝\n");
    }
}
