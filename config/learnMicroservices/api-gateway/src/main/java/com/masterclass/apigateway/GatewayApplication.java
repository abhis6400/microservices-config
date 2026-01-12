package com.masterclass.apigateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * API Gateway Application
 * 
 * This is the main entry point for the API Gateway service.
 * It acts as a single entry point for all client requests and routes them
 * to the appropriate microservices (App A and App B).
 * 
 * Key Features:
 * - Service Discovery: Automatically discovers App A and App B via Eureka
 * - Request Routing: Routes requests to appropriate services based on path
 * - Load Balancing: Automatic load balancing across multiple instances
 * - Filtering: Global and route-specific request/response filters
 * 
 * Port: 9000
 * 
 * Architecture:
 * Client Request → API Gateway (Port 9000)
 *                  ├─ /api/app-a/** → App A (Port 8080)
 *                  └─ /api/app-b/** → App B (Port 8081)
 * 
 * @author Microservices Masterclass
 * @version 1.0.0
 */
@SpringBootApplication
@EnableDiscoveryClient
public class GatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
        
        System.out.println("\n" +
                "╔════════════════════════════════════════════════════════════════╗\n" +
                "║                                                                ║\n" +
                "║           🚀 API GATEWAY SERVICE STARTED 🚀                     ║\n" +
                "║                                                                ║\n" +
                "║           Port: 9000                                           ║\n" +
                "║                                                                ║\n" +
                "║           Endpoints:                                           ║\n" +
                "║           ├─ http://localhost:9000/api/app-a/**              ║\n" +
                "║           ├─ http://localhost:9000/api/app-b/**              ║\n" +
                "║           └─ http://localhost:9000/actuator/health           ║\n" +
                "║                                                                ║\n" +
                "║           Status: Ready for traffic! ✅                        ║\n" +
                "║                                                                ║\n" +
                "╚════════════════════════════════════════════════════════════════╝\n");
    }
}
