# 🚀 Microservices Masterclass Demo - Quick Start Guide

## Project Structure

```
Microservices-masterclass-demo/
├── config-server/                 # Spring Cloud Config Server (Port 8888)
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/masterclass/config/
│       │   └── ConfigServerApplication.java
│       └── resources/
│           └── application.yml
│
├── app-a/                         # First Microservice (Port 8080)
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/masterclass/appa/
│       │   ├── AppAApplication.java
│       │   ├── controller/AppAController.java
│       │   ├── config/AppProperties.java
│       │   └── dto/GreetingResponse.java
│       └── resources/
│           └── bootstrap.yml
│
├── app-b/                         # Second Microservice (Port 8081)
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/masterclass/appb/
│       │   ├── AppBApplication.java
│       │   ├── controller/AppBController.java
│       │   ├── config/AppProperties.java
│       │   └── dto/ProductResponse.java
│       └── resources/
│           └── bootstrap.yml
│
├── config-repo-github-template/   # Configuration template for GitHub
│   ├── GITHUB_SETUP_GUIDE.md
│   └── DIRECTORY_STRUCTURE.txt
│
└── README.md (this file)
```

## Technology Stack

- **Java**: 17
- **Spring Boot**: 3.5.5 (Latest)
- **Spring Cloud**: 2024.0.0
- **Build Tool**: Maven 3.6+
- **Config Storage**: GitHub Repository

## Prerequisites

1. **Java 17** installed
   ```bash
   java -version
   ```

2. **Maven** installed
   ```bash
   mvn -version
   ```

3. **Git** installed
   ```bash
   git --version
   ```

4. **GitHub Account** (for configuration repository)

## Quick Start (5 Minutes)

### Step 1: Start Config Server

```bash
cd config-server
mvn clean install
mvn spring-boot:run
```

**Expected Output:**
```
Started ConfigServerApplication in X seconds
Tomcat started on port(s): 8888
```

### Step 2: Start App A

Open new terminal:
```bash
cd app-a
mvn clean install
mvn spring-boot:run
```

**Expected Output:**
```
Started AppAApplication in X seconds
Tomcat started on port(s): 8080
```

### Step 3: Start App B

Open another new terminal:
```bash
cd app-b
mvn clean install
mvn spring-boot:run
```

**Expected Output:**
```
Started AppBApplication in X seconds
Tomcat started on port(s): 8081
```

## Testing the Services

### Test Config Server

```bash
# Get default app-a configuration
curl http://localhost:8888/app-a/default

# Get app-b configuration
curl http://localhost:8888/app-b/default
```

### Test App A Endpoints

```bash
# Endpoint 1: Get greeting
curl http://localhost:8080/api/app-a/greeting/John

# Expected Response:
# {
#   "message": "Hello, John!",
#   "appName": "App A Microservice",
#   "description": "First microservice with centralized config",
#   "environment": "development",
#   "timestamp": "2026-01-05T12:34:56.789"
# }

# Endpoint 2: Get status
curl http://localhost:8080/api/app-a/status

# Expected Response:
# {
#   "appName": "App A Microservice",
#   "version": "1.0.0",
#   "description": "First microservice with centralized config",
#   "environment": "development",
#   "timeout": 30000,
#   "status": "UP",
#   "timestamp": "2026-01-05T12:34:56.789",
#   "configSource": "Spring Cloud Config Server"
# }
```

### Test App B Endpoints

```bash
# Endpoint 1: Get product
curl http://localhost:8081/api/app-b/product/123

# Expected Response:
# {
#   "productId": "123",
#   "productName": "Sample Product - 123",
#   "appName": "App B Microservice",
#   "description": "Second microservice with centralized config",
#   "environment": "development",
#   "timestamp": "2026-01-05T12:34:56.789"
# }

# Endpoint 2: Get health
curl http://localhost:8081/api/app-b/health

# Expected Response:
# {
#   "appName": "App B Microservice",
#   "version": "1.0.0",
#   "description": "Second microservice with centralized config",
#   "environment": "development",
#   "timeout": 45000,
#   "maxConnections": 50,
#   "status": "HEALTHY",
#   "timestamp": "2026-01-05T12:34:56.789",
#   "configSource": "Spring Cloud Config Server"
# }
```

### Test Actuator Endpoints

```bash
# App A Health Check
curl http://localhost:8080/actuator/health

# App A Configuration Properties
curl http://localhost:8080/actuator/configprops

# App B Health Check
curl http://localhost:8081/actuator/health
```

## Setting up GitHub Configuration Repository

### 1. Create GitHub Repo

1. Go to https://github.com/new
2. Repository name: `microservices-config`
3. Description: "Centralized configuration for microservices"
4. Make it **Public** (for this demo)
5. Click "Create repository"

### 2. Clone and Setup Locally

```bash
# Clone your new repo
git clone https://github.com/yourusername/microservices-config.git
cd microservices-config

# Create config directory
mkdir -p config

# Copy configuration template
# (See config-repo-github-template/GITHUB_SETUP_GUIDE.md)

# Create files:
# - config/app-a.yml
# - config/app-a-development.yml
# - config/app-a-production.yml
# - config/app-b.yml
# - config/app-b-development.yml
# - config/app-b-production.yml
```

### 3. Push to GitHub

```bash
git add .
git commit -m "Initial configuration files"
git push -u origin main
```

### 4. Update Config Server

Edit: `config-server/src/main/resources/application.yml`

```yaml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/yourusername/microservices-config.git
          default-label: main
          search-paths: config
          clone-on-start: true
```

Restart Config Server:
```bash
mvn spring-boot:run
```

## Configuration Profiles

Each microservice supports multiple profiles:

- **development** - Local development settings
- **staging** - Staging environment
- **production** - Production settings

Switch profile by setting environment variable:

```bash
export PROFILE=production
mvn spring-boot:run
```

Or via command line:
```bash
mvn spring-boot:run -Dspring.profiles.active=production
```

## Updating Configuration at Runtime

Without restarting, refresh configuration:

```bash
# Refresh App A configuration
curl -X POST http://localhost:8080/actuator/refresh

# Refresh App B configuration
curl -X POST http://localhost:8081/actuator/refresh
```

For automatic refresh, add `@RefreshScope` annotation:

```java
@Component
@RefreshScope
@ConfigurationProperties(prefix = "app")
public class AppProperties {
    // Properties will auto-refresh when config changes
}
```

## Common Issues & Solutions

### Issue: Config Server not found

**Error:**
```
Could not locate PropertySource: I/O error on GET request for "http://localhost:8888"
```

**Solution:**
1. Ensure Config Server is running on port 8888
2. Check if port 8888 is not blocked by firewall
3. Verify `spring.cloud.config.uri` in bootstrap.yml

### Issue: GitHub repository not accessible

**Error:**
```
IOException: Repo not found or authentication failed
```

**Solution:**
1. Verify GitHub URL is correct
2. For private repos, setup SSH keys or use personal access token
3. Check internet connection

### Issue: Port already in use

**Error:**
```
Address already in use: bind
```

**Solution:**
```bash
# Change port in bootstrap.yml
server:
  port: 8090  # Use different port

# Or kill existing process
# Windows: netstat -ano | findstr :8080
# Linux: lsof -i :8080
```

## Project Architecture

```
┌─────────────┐
│   GitHub    │
│ Repository  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────┐
│ Spring Cloud Config Server  │
│  (Port 8888)                │
│ Provides centralized config │
└──────┬──────────────────────┘
       │
       ├─────────────────┬──────────────────┐
       ▼                 ▼                  ▼
   ┌────────┐        ┌────────┐        ┌────────┐
   │ App A  │        │ App B  │        │ Others │
   │ :8080  │        │ :8081  │        │ Future │
   └────────┘        └────────┘        └────────┘
```

## Next Steps

1. ✅ Setup GitHub repository (see GITHUB_SETUP_GUIDE.md)
2. ✅ Test all services are running
3. ✅ Verify configuration is loaded from Config Server
4. ✅ Try configuration refresh endpoint
5. ✅ Add more microservices using same pattern

## Additional Features to Explore

- **Security**: Add authentication/authorization
- **Service Discovery**: Add Eureka service discovery
- **API Gateway**: Add Spring Cloud Gateway
- **Load Balancing**: Configure load balancing
- **Circuit Breaker**: Add resilience4j
- **Logging**: Add centralized logging (ELK Stack)
- **Monitoring**: Add Prometheus & Grafana

## Useful Commands

```bash
# Build all projects
mvn clean install -DskipTests

# Run specific service
mvn -pl app-a spring-boot:run

# View Config Server logs
mvn spring-boot:run -Dspring-boot.run.arguments="--debug"

# Kill process on port
# Windows PowerShell
Stop-Process -Id (Get-NetTCPConnection -LocalPort 8888).OwningProcess -Force

# Linux
kill -9 $(lsof -t -i :8888)
```

## Resources

- [Spring Cloud Config Documentation](https://cloud.spring.io/spring-cloud-config/)
- [Spring Boot 3.5.5 Documentation](https://docs.spring.io/spring-boot/docs/3.5.5/reference/html/)
- [Spring Cloud Documentation](https://spring.io/projects/spring-cloud)
- [GitHub API Documentation](https://docs.github.com)

## Support

For issues or questions:
1. Check logs in console output
2. Review Common Issues & Solutions section
3. Check Spring Cloud Config documentation
4. Verify GitHub repository is accessible

---

**Created**: January 5, 2026  
**Version**: 1.0.0  
**Status**: Ready for Development
