# 🎯 Phase 1: Service Discovery & Inter-Service Communication

## 📊 Phase 1 Overview

**Goal**: Make services discover and communicate with each other dynamically

**Duration**: 1-2 days

**Technologies**:
- Eureka Server (Service Registry)
- Eureka Client (Service Discovery)
- RestTemplate (Service Communication)

**End Result**:
- App A can call App B using service name (not IP:port)
- Services automatically register with Eureka
- Eureka dashboard shows all running services

---

## 🗺️ Phase 1 Architecture

### Before Phase 1:
```
Client → App A (Port 8080, hardcoded URL to App B)
         ↓
         App B (Port 8081)
         
Problem: URLs are hardcoded, no service discovery
```

### After Phase 1:
```
Client → App A
         ↓
    Eureka Server (Port 8761)
         ↑  ↓
    App A  App B
         
Benefits: Services find each other, dynamic scaling
```

---

## 📋 Step-by-Step Implementation

### **STEP 1.1: Create Eureka Server**

#### **1.1.1: Create project directory structure**

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo

# Create eureka-server folder
mkdir eureka-server
cd eureka-server
mkdir -p src/main/java/com/eureka
mkdir -p src/main/resources
```

---

#### **1.1.2: Create pom.xml for Eureka Server**

Create file: `eureka-server/pom.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.9</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>

    <groupId>com.eureka</groupId>
    <artifactId>eureka-server</artifactId>
    <version>1.0.0</version>
    <name>Eureka Server</name>
    <description>Service Registry for Microservices</description>

    <properties>
        <java.version>17</java.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <spring-cloud.version>2023.0.3</spring-cloud.version>
    </properties>

    <dependencies>
        <!-- Spring Cloud Eureka Server -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
        </dependency>

        <!-- Spring Boot Web -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- Spring Boot Actuator -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>
```

---

#### **1.1.3: Create EurekaServerApplication.java**

Create file: `eureka-server/src/main/java/com/eureka/EurekaServerApplication.java`

```java
package com.eureka;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

/**
 * Eureka Server Application
 * 
 * Service Registry for all microservices
 * Dashboard: http://localhost:8761
 */
@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
        System.out.println("\n\n");
        System.out.println("╔════════════════════════════════════════════════════════╗");
        System.out.println("║                                                        ║");
        System.out.println("║          🎉 Eureka Server Started Successfully!         ║");
        System.out.println("║                                                        ║");
        System.out.println("║   📊 Dashboard: http://localhost:8761                  ║");
        System.out.println("║   🔍 REST API: http://localhost:8761/eureka/           ║");
        System.out.println("║                                                        ║");
        System.out.println("╚════════════════════════════════════════════════════════╝");
        System.out.println("\n\n");
    }

}
```

---

#### **1.1.4: Create application.yml for Eureka Server**

Create file: `eureka-server/src/main/resources/application.yml`

```yaml
# ============================================
# Eureka Server Configuration
# ============================================

spring:
  application:
    name: eureka-server
  
  # JPA Configuration (for Eureka dashboard)
  jpa:
    hibernate:
      ddl-auto: update

server:
  port: 8761

# Eureka Server Configuration
eureka:
  instance:
    hostname: localhost
    prefer-ip-address: false
  
  # This is a SERVER - don't register itself as client
  client:
    register-with-eureka: false
    fetch-registry: false
    service-url:
      defaultZone: http://${eureka.instance.hostname}:${server.port}/eureka/
  
  # Server settings
  server:
    enable-self-preservation: false  # For development only
    eviction-interval-timer-in-ms: 3000

# Management endpoints
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: always

# Logging
logging:
  level:
    root: INFO
    com.netflix: DEBUG
    org.springframework.cloud: INFO

# Actuator
info:
  app:
    name: Eureka Server
    description: Service Registry for Microservices
    version: 1.0.0
```

---

### **STEP 1.2: Register App A with Eureka**

#### **1.2.1: Update App A pom.xml**

Add this dependency to `app-a/pom.xml` (in the `<dependencies>` section):

```xml
<!-- Spring Cloud Eureka Client -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>

<!-- Spring Boot Web Client -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>
```

---

#### **1.2.2: Create/Update bootstrap.yml for App A**

Create or update file: `app-a/src/main/resources/bootstrap.yml`

```yaml
spring:
  application:
    name: app-a
  
  config:
    import: optional:configserver:http://localhost:8888
  
  cloud:
    config:
      enabled: true
      uri: http://localhost:8888
      fail-fast: false
      retry:
        initial-interval: 1000
        max-interval: 2000
        max-attempts: 6

# ============================================
# Eureka Client Configuration
# ============================================
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
    register-with-eureka: true
    fetch-registry: true
    registry-fetch-interval-seconds: 10
  
  instance:
    prefer-ip-address: false
    hostname: localhost
    instance-id: app-a-instance-1
    lease-renewal-interval-in-seconds: 10
    lease-expiration-duration-in-seconds: 30
    metadata-map:
      version: "1.0.0"
```

---

#### **1.2.3: Update App A application.yml**

Update file: `app-a/src/main/resources/application.yml`

Add this at the end (keep existing content):

```yaml
# ============================================
# Eureka Configuration (redundancy)
# ============================================
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
    register-with-eureka: true
    fetch-registry: true

# RestTemplate for service-to-service communication
# (We'll define this in config)
```

---

### **STEP 1.3: Register App B with Eureka**

#### **1.3.1: Update App B pom.xml**

Add same dependencies to `app-b/pom.xml`:

```xml
<!-- Spring Cloud Eureka Client -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>

<!-- Spring Boot Web Client -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-webflux</artifactId>
</dependency>
```

---

#### **1.3.2: Create/Update bootstrap.yml for App B**

Create or update file: `app-b/src/main/resources/bootstrap.yml`

```yaml
spring:
  application:
    name: app-b
  
  config:
    import: optional:configserver:http://localhost:8888
  
  cloud:
    config:
      enabled: true
      uri: http://localhost:8888
      fail-fast: false
      retry:
        initial-interval: 1000
        max-interval: 2000
        max-attempts: 6

# ============================================
# Eureka Client Configuration
# ============================================
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
    register-with-eureka: true
    fetch-registry: true
    registry-fetch-interval-seconds: 10
  
  instance:
    prefer-ip-address: false
    hostname: localhost
    instance-id: app-b-instance-1
    lease-renewal-interval-in-seconds: 10
    lease-expiration-duration-in-seconds: 30
    metadata-map:
      version: "1.0.0"
```

---

#### **1.3.3: Update App B application.yml**

Update file: `app-b/src/main/resources/application.yml`

Add this at the end (keep existing content):

```yaml
# ============================================
# Eureka Configuration (redundancy)
# ============================================
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
    register-with-eureka: true
    fetch-registry: true
```

---

### **STEP 1.4: Create RestTemplate Configuration**

#### **1.4.1: Create RestClientConfig for App A**

Create file: `app-a/src/main/java/com/masterclass/config/RestClientConfig.java`

```java
package com.masterclass.config;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * RestTemplate Configuration for Service-to-Service Communication
 * 
 * @LoadBalanced annotation enables automatic load balancing
 * When you call http://app-b/api/... it:
 * 1. Looks up "app-b" in Eureka registry
 * 2. Gets all instances
 * 3. Load balances between them
 */
@Configuration
public class RestClientConfig {

    @Bean
    @LoadBalanced  // ← This enables load balancing!
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder.build();
    }

}
```

---

#### **1.4.2: Create RestClientConfig for App B**

Create file: `app-b/src/main/java/com/masterclass/config/RestClientConfig.java`

```java
package com.masterclass.config;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * RestTemplate Configuration for Service-to-Service Communication
 */
@Configuration
public class RestClientConfig {

    @Bean
    @LoadBalanced
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder.build();
    }

}
```

---

### **STEP 1.5: Add Inter-Service Communication to App A**

#### **1.5.1: Update App A Controller**

Update file: `app-a/src/main/java/com/masterclass/controller/AppAController.java`

Add new endpoint to existing controller:

```java
// Add these imports at the top
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.bind.annotation.GetMapping;

// In the AppAController class, add:

@Autowired
private RestTemplate restTemplate;

/**
 * Call App B from App A
 * Uses Eureka to discover App B
 * No hardcoded URL needed!
 */
@GetMapping("/call-app-b/{productId}")
public String callAppB(@PathVariable String productId) {
    try {
        // This calls App B using service name from Eureka
        // Instead of: http://localhost:8081/...
        String response = restTemplate.getForObject(
            "http://app-b/api/app-b/product/" + productId,
            String.class
        );
        
        return "✅ Called App B successfully!\n\n" +
               "App B Response:\n" + response;
    } catch (Exception e) {
        return "❌ Failed to call App B: " + e.getMessage();
    }
}
```

---

#### **1.5.2: Full Updated AppAController**

Here's the complete controller for reference:

```java
package com.masterclass.controller;

import com.masterclass.model.GreetingResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("/api/app-a")
@CrossOrigin(origins = "*")
public class AppAController {

    @Value("${app.name:App A}")
    private String appName;

    @Value("${app.description:App A Microservice}")
    private String appDescription;

    @Value("${app.version:1.0.0}")
    private String appVersion;

    @Value("${app.environment:default}")
    private String appEnvironment;

    @Value("${app.timeout:30000}")
    private long appTimeout;

    @Value("${server.port:8080}")
    private String serverPort;

    @Autowired
    private RestTemplate restTemplate;

    /**
     * Get greeting with configuration from Config Server
     */
    @GetMapping("/greeting/{name}")
    public GreetingResponse getGreeting(@PathVariable String name) {
        return new GreetingResponse(
            "Hello, " + name + "!",
            appName,
            appVersion,
            appTimeout,
            Integer.parseInt(serverPort)
        );
    }

    /**
     * Get application status
     */
    @GetMapping("/status")
    public String getStatus() {
        return "✅ App A is running!\n" +
               "Name: " + appName + "\n" +
               "Version: " + appVersion + "\n" +
               "Environment: " + appEnvironment + "\n" +
               "Port: " + serverPort + "\n" +
               "Timeout: " + appTimeout + "ms";
    }

    /**
     * Call App B using Eureka Service Discovery
     * This demonstrates inter-service communication!
     */
    @GetMapping("/call-app-b/{productId}")
    public String callAppB(@PathVariable String productId) {
        try {
            // Service discovery through Eureka!
            // "app-b" is resolved from Eureka registry automatically
            String response = restTemplate.getForObject(
                "http://app-b/api/app-b/product/" + productId,
                String.class
            );
            
            return "\n╔════════════════════════════════════════════╗\n" +
                   "║  ✅ Successfully Called App B!             ║\n" +
                   "╚════════════════════════════════════════════╝\n\n" +
                   "Response from App B:\n" +
                   response;
        } catch (Exception e) {
            return "\n╔════════════════════════════════════════════╗\n" +
                   "║  ❌ Failed to Call App B                   ║\n" +
                   "╚════════════════════════════════════════════╝\n\n" +
                   "Error: " + e.getMessage();
        }
    }

}
```

---

## 🧪 Testing Phase 1

### **Complete Testing Checklist**

#### **Step 1: Build All Services**

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo

# Build all services
mvn clean install -U -DskipTests
```

Wait for: `BUILD SUCCESS`

---

#### **Step 2: Start Services (in separate terminals)**

**Terminal 1 - Eureka Server**:
```powershell
cd eureka-server
mvn spring-boot:run
```

Wait for:
```
╔════════════════════════════════════════════════════════╗
║          🎉 Eureka Server Started Successfully!        ║
║          📊 Dashboard: http://localhost:8761           ║
╚════════════════════════════════════════════════════════╝
```

**Terminal 2 - Config Server**:
```powershell
cd config-server
mvn spring-boot:run
```

Wait for:
```
Started ConfigServerApplication
```

**Terminal 3 - App A**:
```powershell
cd app-a
mvn spring-boot:run
```

Wait for:
```
Started AppAApplication
🟢 Registered with Eureka
```

**Terminal 4 - App B**:
```powershell
cd app-b
mvn spring-boot:run
```

Wait for:
```
Started AppBApplication
🟢 Registered with Eureka
```

---

#### **Step 3: Verify Eureka Dashboard**

Open browser: `http://localhost:8761`

**Expected Screen**:
```
Eureka Server

Instances currently registered with Eureka

Application    | Status
─────────────────────────────
APP-A          | UP (1) - http://localhost:8080
APP-B          | UP (1) - http://localhost:8081
CONFIG-SERVER  | UP (1) - http://localhost:8888
```

✅ If you see all 3 services with status UP, Eureka is working!

---

#### **Step 4: Test Service-to-Service Communication**

**Test 1: Call App A's endpoint**
```powershell
curl http://localhost:8080/api/app-a/greeting/World
```

Expected response:
```json
{
  "message": "Hello, World!",
  "appName": "Greeting Service",
  "appVersion": "1.0.0",
  "timeout": 30000,
  "serverPort": 8080
}
```

**Test 2: Call App B's endpoint**
```powershell
curl http://localhost:8081/api/app-b/product/123
```

Expected response:
```json
{
  "id": 123,
  "name": "Sample Product",
  "appName": "App B",
  "appVersion": "1.0.0",
  "timeout": 45000,
  "maxConnections": 50
}
```

**Test 3: Call App A's call-app-b endpoint** ⭐⭐⭐
```powershell
curl http://localhost:8080/api/app-a/call-app-b/123
```

Expected response:
```
╔════════════════════════════════════════════╗
║  ✅ Successfully Called App B!             ║
╚════════════════════════════════════════════╝

Response from App B:
{
  "id": 123,
  "name": "Sample Product",
  "appName": "App B",
  ...
}
```

✅ **If you see this, inter-service communication is working!**

---

## 📊 Phase 1 Success Criteria

You've completed Phase 1 when:

- [ ] Eureka Server starts on port 8761
- [ ] App A registers with Eureka (status: UP)
- [ ] App B registers with Eureka (status: UP)
- [ ] Config Server shows in Eureka dashboard
- [ ] Direct endpoints work (App A greeting, App B product)
- [ ] App A can call App B using service name
- [ ] Eureka dashboard shows all 3+ services

---

## 🐛 Troubleshooting Phase 1

### **Problem: Services not showing in Eureka dashboard**

**Solution**:
1. Check app startup logs for "Registered with Eureka"
2. Verify `eureka.client.register-with-eureka: true` in bootstrap.yml
3. Verify Eureka server is running on port 8761
4. Clear application cache: `mvn clean`

### **Problem: "Unable to connect to app-b"**

**Solution**:
1. Verify App B is running on port 8081
2. Check Eureka dashboard - App B should show UP
3. Check logs for RestTemplate errors
4. Try direct URL first: `http://localhost:8081/api/app-b/product/123`

### **Problem: "401 Unauthorized" or security errors**

**Solution**:
1. Eureka client might need credentials
2. Check if running in same network
3. Verify no firewall blocking ports

---

## 📝 What You Learned

**Key Concepts**:
✅ Service Registry (Eureka Server)  
✅ Service Discovery (Eureka Client)  
✅ Client-side Load Balancing (@LoadBalanced)  
✅ Inter-service Communication  
✅ Dynamic Service URLs  

**Technologies**:
✅ Spring Cloud Netflix Eureka  
✅ RestTemplate with Load Balancing  

---

## 🎉 Congratulations!

You've completed **Phase 1: Service Discovery & Inter-Service Communication**!

Your services can now:
- ✅ Find each other automatically (no hardcoded URLs)
- ✅ Communicate through service names
- ✅ Support multiple instances with load balancing

---

## 🚀 Next: Phase 2

When you're ready, we'll add:
- API Gateway (single entry point)
- Advanced load balancing
- Request routing

**Ready to continue?** Let me know when you want to start Phase 2!

---

**Great job! You're building real enterprise microservices! 🚀**
