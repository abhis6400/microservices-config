package com.masterclass.appa;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

/**
 * App A - First Microservice
 * 
 * Features:
 * - Uses centralized configuration from Config Server
 * - Service Discovery via Eureka
 * - Feign Client for inter-service communication
 */
@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients
public class AppAApplication {

    public static void main(String[] args) {
        SpringApplication.run(AppAApplication.class, args);
        
        System.out.println("\n" +
                "╔════════════════════════════════════════════╗\n" +
                "║          APP A - FEIGN ENABLED             ║\n" +
                "║                                            ║\n" +
                "║   Can now call App B using Feign Client    ║\n" +
                "║         Service Discovery: Active          ║\n" +
                "║                                            ║\n" +
                "║    📡 Eureka: http://localhost:8761       ║\n" +
                "║    🔗 App A:  http://localhost:8080       ║\n" +
                "╚════════════════════════════════════════════╝\n");
    }
}
