package com.eureka;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

/**
 * Eureka Server - Service Registry
 * 
 * This is the central service registry where all microservices register themselves.
 * Services can discover other services by querying this registry.
 * 
 * Port: 8761 (default Eureka port)
 * Dashboard: http://localhost:8761
 */
@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
        
        System.out.println("\n" +
                "╔═══════════════════════════════════════════════════════════╗\n" +
                "║                 EUREKA SERVER STARTED                     ║\n" +
                "║                                                           ║\n" +
                "║          Service Registry & Discovery is Active           ║\n" +
                "║                                                           ║\n" +
                "║     🌐 Dashboard: http://localhost:8761                  ║\n" +
                "║                                                           ║\n" +
                "║  Services will automatically register on startup          ║\n" +
                "╚═══════════════════════════════════════════════════════════╝\n");
    }

}
