# Advanced Guide: Troubleshooting, Testing & Deployment

## Part 1: Troubleshooting Guide

### Common Issues & Solutions

#### Issue 1: Config Server Port 8888 Already in Use

**Error Message**:
```
Address already in use: bind
```

**Diagnosis**:
```bash
# Windows PowerShell: Check what's using port 8888
netstat -ano | findstr :8888

# Linux/Mac: Check process on port
lsof -i :8888
```

**Solutions**:

**Option A**: Kill existing process
```powershell
# Windows PowerShell
$ProcessID = (Get-NetTCPConnection -LocalPort 8888).OwningProcess
Stop-Process -Id $ProcessID -Force
```

**Option B**: Use different port
```yaml
# config-server/src/main/resources/application.yml
server:
  port: 9999  # Use different port

# Update bootstrap.yml in both microservices:
spring:
  cloud:
    config:
      uri: http://localhost:9999  # Point to new port
```

**Option C**: Wait and restart
```bash
# Wait 2 minutes and try again (OS may still hold port)
# Then restart Config Server
mvn spring-boot:run
```

---

#### Issue 2: Microservices Can't Connect to Config Server

**Error Message**:
```
Could not locate PropertySource: I/O error on GET request for "http://localhost:8888"
```

**Checklist**:
- [ ] Is Config Server running on port 8888?
- [ ] Is port 8888 accessible (not blocked by firewall)?
- [ ] Is the URI correct in bootstrap.yml?
- [ ] Are you on the same machine or networked?

**Solutions**:

**Verify Config Server is running**:
```bash
# Check process
ps aux | grep "config-server"

# Or try to connect
curl http://localhost:8888/actuator/health

# Expected response: {"status":"UP"}
```

**Update bootstrap.yml if on different machine**:
```yaml
# ❌ Wrong: localhost only works on same machine
spring:
  cloud:
    config:
      uri: http://localhost:8888

# ✅ Correct: Use actual IP address
spring:
  cloud:
    config:
      uri: http://192.168.1.100:8888
```

**Increase retry attempts**:
```yaml
spring:
  cloud:
    config:
      fail-fast: true  # Fail immediately if can't connect
      # Or:
      fail-fast: false  # Allow startup even if config unavailable
      retry:
        max-attempts: 10
        initial-interval: 1000
        max-interval: 2000
```

---

#### Issue 3: GitHub Repository Not Accessible

**Error Message**:
```
IOException: Repo not found or authentication failed
org.eclipse.jgit.api.errors.TransportException
```

**Checklist**:
- [ ] GitHub URL is correct?
- [ ] Repository exists and is accessible?
- [ ] Internet connection is working?
- [ ] For private repos: authentication configured?

**Solutions**:

**Verify GitHub URL**:
```bash
# Test connectivity to GitHub
ping github.com

# Test exact repository access
git clone https://github.com/yourusername/microservices-config.git test-repo
rm -rf test-repo
```

**Check Config Server logs**:
```bash
# Run with DEBUG logging
mvn spring-boot:run -Dspring-boot.run.arguments="--debug"

# Look for git-related errors
# Expected: "Cloning git repository"
# If error: Check logs for detailed error message
```

**Update Config Server URL**:
```yaml
# config-server/src/main/resources/application.yml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/yourusername/microservices-config.git
          # Add for debugging:
          clone-on-start: true
          force-pull: true
```

**For private repositories - Option A (HTTPS + Token)**:
```yaml
# 1. Create Personal Access Token on GitHub
#    https://github.com/settings/tokens
#    Select scope: "repo"

# 2. Update application.yml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://yourusername:your-token@github.com/yourusername/microservices-config.git
```

**For private repositories - Option B (SSH)**:
```yaml
# 1. Generate SSH key (if not done)
#    ssh-keygen -t ed25519 -C "your-email@example.com"

# 2. Add public key to GitHub
#    https://github.com/settings/keys

# 3. Update application.yml
spring:
  cloud:
    config:
      server:
        git:
          uri: git@github.com:yourusername/microservices-config.git
          # SSH might need explicit timeout
          timeout: 5
```

---

#### Issue 4: Configuration Not Updating After Git Push

**Symptoms**:
- Changed file in GitHub but microservice still uses old config
- Config Server shows old values

**Causes**:
- Config Server caching
- force-pull disabled
- Microservice didn't refresh

**Solutions**:

**Force Config Server to re-fetch**:
```yaml
# config-server/src/main/resources/application.yml
spring:
  cloud:
    config:
      server:
        git:
          force-pull: true  # Always pull latest from GitHub
          clone-on-start: true
```

**Refresh microservice configuration**:
```bash
# Call refresh endpoint (POST required)
curl -X POST http://localhost:8080/actuator/refresh

# Response should show updated properties:
# ["app.timeout", "app.description"]

# Verify new values loaded
curl http://localhost:8080/actuator/configprops
```

**Check Config Server cached directory**:
```bash
# Config Server caches locally in:
# ./config-repo/

# To force re-clone:
rm -rf config-repo/
# Restart Config Server
mvn spring-boot:run
```

---

#### Issue 5: YAML Configuration Syntax Errors

**Error Message**:
```
org.yaml.snakeyaml.scanner.ScannerException
Mapping values are not allowed here
```

**Common YAML Mistakes**:

```yaml
# ❌ Wrong: Missing space after dash
app:
  items:-
    - item1
    - item2

# ✅ Correct:
app:
  items:
    - item1
    - item2

# ❌ Wrong: Tabs used for indentation
app:
→ name: "Test"  # Tab character used

# ✅ Correct: Spaces (2 or 4)
app:
  name: "Test"  # 2 spaces

# ❌ Wrong: Quotes not closed
app:
  name: "Test
  description: "A test"

# ✅ Correct:
app:
  name: "Test"
  description: "A test"

# ❌ Wrong: Special characters without quotes
app:
  name: value with : colon

# ✅ Correct:
app:
  name: "value with : colon"
```

**Validate YAML**:

```bash
# Online validator
# https://www.yamllint.com/

# Or use command-line tool
# Ubuntu/Debian
sudo apt-get install yamllint
yamllint config/app-a.yml

# macOS
brew install yamllint
yamllint config/app-a.yml
```

---

#### Issue 6: Port Conflicts (App A/B on Same Machine)

**Error Message**:
```
Address already in use: bind:8080
```

**Solution**: Use different ports

```yaml
# app-a/src/main/resources/bootstrap.yml
server:
  port: 8080

# app-b/src/main/resources/bootstrap.yml
server:
  port: 8081

# Or if both running on same machine:
# app-a: 8080
# app-b: 8081
# config-server: 8888
```

**Verify ports are free**:
```bash
# Windows PowerShell
Get-NetTCPConnection | findstr -E ":8080|:8081|:8888"

# Linux
netstat -tuln | grep -E "8080|8081|8888"

# macOS
lsof -i -P -n | grep -E "8080|8081|8888"
```

---

### Debugging Techniques

#### Enable Debug Logging

**In bootstrap.yml**:
```yaml
logging:
  level:
    org.springframework: DEBUG
    org.springframework.cloud: DEBUG
    org.springframework.cloud.config: DEBUG
    org.eclipse.jgit: DEBUG
    com.netflix: WARN
```

**Or via environment variable**:
```bash
export LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_CLOUD=DEBUG
mvn spring-boot:run
```

#### Check Configuration Properties

**Inspect what Config Server sees**:
```bash
curl http://localhost:8888/app-a/development
# Returns complete configuration
```

**Inspect what Microservice loaded**:
```bash
curl http://localhost:8080/actuator/configprops
# Returns all bound configuration properties
```

#### View Application Logs

**Run in foreground to see logs**:
```bash
mvn spring-boot:run
# Press Ctrl+C to stop
```

**Save logs to file**:
```bash
mvn spring-boot:run > app.log 2>&1 &

# View logs
tail -f app.log
```

---

## Part 2: Testing Strategies

### Unit Testing Configuration Properties

**Test file**: `app-a/src/test/java/.../config/AppPropertiesTest.java`

```java
package com.masterclass.appa.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
public class AppPropertiesTest {
    
    @Autowired
    private AppProperties appProperties;
    
    @Test
    public void testAppPropertiesLoaded() {
        assertNotNull(appProperties);
        assertNotNull(appProperties.getName());
        assertNotNull(appProperties.getEnvironment());
    }
    
    @Test
    public void testTimeoutProperty() {
        assertTrue(appProperties.getTimeout() > 0);
        assertEquals(30000, appProperties.getTimeout());
    }
    
    @Test
    public void testEnvironmentVariable() {
        assertEquals("development", appProperties.getEnvironment());
    }
}
```

### Integration Testing REST Endpoints

**Test file**: `app-a/src/test/java/.../controller/AppAControllerTest.java`

```java
package com.masterclass.appa.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
public class AppAControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    public void testGreetingEndpoint() throws Exception {
        mockMvc.perform(get("/api/app-a/greeting/John"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.message").value("Hello, John!"))
            .andExpect(jsonPath("$.appName").exists())
            .andExpect(jsonPath("$.timestamp").exists());
    }
    
    @Test
    public void testStatusEndpoint() throws Exception {
        mockMvc.perform(get("/api/app-a/status"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("UP"))
            .andExpect(jsonPath("$.appName").exists())
            .andExpect(jsonPath("$.configSource").value("Spring Cloud Config Server"));
    }
}
```

### Manual Testing with Curl

**Test Configuration Server**:
```bash
#!/bin/bash
# Test all configuration endpoints

echo "Testing Config Server..."
curl -v http://localhost:8888/actuator/health

echo -e "\n\nGetting App A Default Config..."
curl http://localhost:8888/app-a/default | jq .

echo -e "\n\nGetting App A Development Config..."
curl http://localhost:8888/app-a/development | jq .

echo -e "\n\nGetting App B Production Config..."
curl http://localhost:8888/app-b/production | jq .
```

**Test Microservices**:
```bash
#!/bin/bash
# Test all microservice endpoints

echo "Testing App A..."
curl http://localhost:8080/api/app-a/greeting/World | jq .
curl http://localhost:8080/api/app-a/status | jq .
curl http://localhost:8080/actuator/health | jq .

echo -e "\n\nTesting App B..."
curl http://localhost:8081/api/app-b/product/123 | jq .
curl http://localhost:8081/api/app-b/health | jq .
curl http://localhost:8081/actuator/health | jq .

echo -e "\n\nTesting Configuration Refresh..."
curl -X POST http://localhost:8080/actuator/refresh | jq .
curl -X POST http://localhost:8081/actuator/refresh | jq .
```

**Run all tests**:
```bash
# Make script executable
chmod +x test-all.sh

# Run tests
./test-all.sh
```

---

## Part 3: Running Tests via Maven

### Run All Tests

```bash
# For entire project
mvn test

# For specific module
mvn -pl app-a test
mvn -pl app-b test

# With coverage report
mvn test jacoco:report

# Skip tests (when building)
mvn clean install -DskipTests
```

### Run Specific Test Class

```bash
# Single test class
mvn test -Dtest=AppAControllerTest

# Multiple test classes
mvn test -Dtest=AppAControllerTest,AppPropertiesTest

# Tests matching pattern
mvn test -Dtest=*ControllerTest
```

### View Test Reports

```bash
# After running tests, view HTML report
# Location: target/site/jacoco/index.html

# Or open in browser
open target/site/jacoco/index.html  # macOS
start target/site/jacoco/index.html  # Windows
```

---

## Part 4: Deployment Guide

### Development Deployment (Local Machine)

#### Step 1: Ensure GitHub Repository is Setup

```bash
# Create and push configuration
git clone https://github.com/yourusername/microservices-config.git
cd microservices-config
mkdir -p config

# Create configuration files (see GITHUB_CONFIGURATION_SETUP.md)
# ... create app-a.yml, app-b.yml, etc ...

git add .
git commit -m "Initial configuration"
git push -u origin main
```

#### Step 2: Build All Projects

```bash
# Navigate to root directory
cd Microservices-masterclass-demo

# Build all modules
mvn clean install

# Or build specific modules
mvn clean install -pl config-server,app-a,app-b
```

#### Step 3: Start Services in Order

**Terminal 1 - Config Server**:
```bash
cd config-server
mvn spring-boot:run
# Wait for: "Started ConfigServerApplication in X seconds"
```

**Terminal 2 - App A**:
```bash
cd app-a
mvn spring-boot:run
# Wait for: "Started AppAApplication in X seconds"
```

**Terminal 3 - App B**:
```bash
cd app-b
mvn spring-boot:run
# Wait for: "Started AppBApplication in X seconds"
```

#### Step 4: Verify All Services Running

```bash
# Check all services
curl http://localhost:8888/actuator/health
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health

# All should return: {"status":"UP"}
```

---

### Production Deployment (Docker)

#### Create Dockerfile for Config Server

**File**: `config-server/Dockerfile`

```dockerfile
FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

# Copy built JAR
COPY target/config-server-1.0.0.jar app.jar

# Expose port
EXPOSE 8888

# Set environment variables
ENV SPRING_PROFILES_ACTIVE=production

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### Create Dockerfile for App A

**File**: `app-a/Dockerfile`

```dockerfile
FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

COPY target/app-a-1.0.0.jar app.jar

EXPOSE 8080

ENV SPRING_PROFILES_ACTIVE=production
ENV SPRING_CLOUD_CONFIG_URI=http://config-server:8888

ENTRYPOINT ["java", "-jar", "app.jar"]
```

#### Create Docker Compose

**File**: `docker-compose.yml`

```yaml
version: '3.8'

services:
  config-server:
    build:
      context: ./config-server
      dockerfile: Dockerfile
    ports:
      - "8888:8888"
    environment:
      SPRING_PROFILES_ACTIVE: production
      SPRING_CLOUD_CONFIG_SERVER_GIT_URI: https://github.com/yourusername/microservices-config.git
    networks:
      - microservices

  app-a:
    build:
      context: ./app-a
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    depends_on:
      - config-server
    environment:
      SPRING_PROFILES_ACTIVE: production
      SPRING_CLOUD_CONFIG_URI: http://config-server:8888
    networks:
      - microservices

  app-b:
    build:
      context: ./app-b
      dockerfile: Dockerfile
    ports:
      - "8081:8081"
    depends_on:
      - config-server
    environment:
      SPRING_PROFILES_ACTIVE: production
      SPRING_CLOUD_CONFIG_URI: http://config-server:8888
    networks:
      - microservices

networks:
  microservices:
    driver: bridge
```

#### Deploy with Docker Compose

```bash
# Build images
docker-compose build

# Start services
docker-compose up

# Start in background
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f app-a

# View specific service logs
docker-compose logs config-server
```

---

### Cloud Deployment (AWS Example)

#### Step 1: Push Docker Images to ECR

```bash
# Login to AWS ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

# Build and tag images
docker build -t config-server:1.0.0 ./config-server
docker tag config-server:1.0.0 \
  123456789.dkr.ecr.us-east-1.amazonaws.com/config-server:1.0.0

# Push to ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/config-server:1.0.0
```

#### Step 2: Create ECS Task Definition

```json
{
  "family": "microservices-demo",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "config-server",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/config-server:1.0.0",
      "portMappings": [
        {
          "containerPort": 8888,
          "hostPort": 8888,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "SPRING_PROFILES_ACTIVE",
          "value": "production"
        }
      ]
    }
  ]
}
```

#### Step 3: Deploy to ECS

```bash
# Register task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json

# Create service
aws ecs create-service \
  --cluster my-cluster \
  --service-name config-server \
  --task-definition microservices-demo:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-123],securityGroups=[sg-123]}"
```

---

## Part 5: Monitoring in Production

### Enable Production Logging

```yaml
# config-server/src/main/resources/application-production.yml
logging:
  level:
    root: WARN
    com.masterclass: INFO
    org.springframework: WARN
    org.springframework.cloud: INFO
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
  file:
    name: logs/application.log
    max-size: 10MB
    max-history: 10

# Actuator endpoints in production
management:
  endpoints:
    web:
      exposure:
        include: health,configprops,info
  endpoint:
    health:
      show-details: when-authorized
```

### Metrics & Health Checks

```bash
# Health check
curl http://localhost:8080/actuator/health

# Detailed health (with authentication)
curl -u admin:password http://localhost:8080/actuator/health

# Configuration properties
curl http://localhost:8080/actuator/configprops

# Application info
curl http://localhost:8080/actuator/info
```

### Alerting Configuration

```yaml
# Example: Prometheus alerting
groups:
  - name: microservices
    rules:
      - alert: ConfigServerDown
        expr: up{job="config-server"} == 0
        for: 5m
        annotations:
          summary: "Config Server is down"
          
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        annotations:
          summary: "High error rate detected"
```

---

## Checklist for Production Readiness

- [ ] GitHub repository created and private
- [ ] SSH keys configured for GitHub access
- [ ] Configuration files in GitHub (all profiles)
- [ ] Docker images built and tested
- [ ] Docker Compose file validated
- [ ] Environment variables set correctly
- [ ] Security groups/firewall configured
- [ ] Logging enabled and configured
- [ ] Monitoring and alerting enabled
- [ ] Backups configured for GitHub
- [ ] Documentation updated
- [ ] Runbooks created for operations team

---

**Version**: 1.0.0  
**Last Updated**: January 5, 2026
