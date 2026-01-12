# Architecture & Design Patterns

## System Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                         Deployment Environment                      │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      GitHub Repository                       │  │
│  │           (microservices-config/config/ directory)          │  │
│  │                                                              │  │
│  │  - app-a.yml                                                │  │
│  │  - app-a-development.yml                                   │  │
│  │  - app-a-production.yml                                    │  │
│  │  - app-b.yml                                                │  │
│  │  - app-b-development.yml                                   │  │
│  │  - app-b-production.yml                                    │  │
│  └────────────────────────┬─────────────────────────────────────┘  │
│                           │                                         │
│                           ▼                                         │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │     Spring Cloud Config Server (Port 8888)                  │  │
│  │                                                              │  │
│  │  - Reads configuration from GitHub                          │  │
│  │  - Exposes REST endpoints: /app-a/{profile}                │  │
│  │  - Caches configuration in local directory                  │  │
│  │  - Provides /actuator/health endpoint                       │  │
│  └────────────────┬──────────────────────┬───────────────────┘  │
│                   │                      │                        │
│         ┌─────────▼────────┐   ┌────────▼─────────┐               │
│         │                  │   │                  │               │
│         ▼                  ▼   ▼                  ▼               │
│  ┌──────────────┐   ┌─────────────────┐   Other Microservices   │
│  │   App A      │   │     App B       │   (Future)               │
│  │ (Port 8080)  │   │  (Port 8081)    │                         │
│  │              │   │                 │                         │
│  │ Endpoints:   │   │ Endpoints:      │                         │
│  │ • /greeting  │   │ • /product      │                         │
│  │ • /status    │   │ • /health       │                         │
│  │              │   │                 │                         │
│  │ Properties:  │   │ Properties:     │                         │
│  │ • name       │   │ • name          │                         │
│  │ • version    │   │ • version       │                         │
│  │ • environment│   │ • environment   │                         │
│  │ • timeout    │   │ • timeout       │                         │
│  │              │   │ • maxConnections│                         │
│  └──────────────┘   └─────────────────┘                         │
│         │                   │                                     │
│         └───────────────────┴─► /actuator/refresh               │
│                                 /actuator/health                 │
│                                 /actuator/configprops            │
│                                                                   │
└────────────────────────────────────────────────────────────────────┘
```

## Design Patterns Implemented

### 1. Microservices Pattern

**What**: Each microservice is an independent, deployable application.

**Benefits**:
- Independent scaling
- Technology flexibility
- Fault isolation
- Rapid deployment

**Implementation**:
- App A: Greeting service (self-contained)
- App B: Product service (self-contained)
- Each has its own port, configuration, and lifecycle

### 2. Centralized Configuration Pattern

**What**: Configuration stored in single location (GitHub) rather than embedded in applications.

**Benefits**:
- Single source of truth
- Environment-specific configuration
- Configuration without redeployment
- Audit trail (Git history)

**Implementation**:
```
GitHub Repository
      ↓
Config Server
      ↓
Microservices (via HTTP)
```

### 3. Configuration Server Pattern (Spring Cloud Config)

**What**: Dedicated service that provides configuration to other services.

**Benefits**:
- Dynamic configuration
- Profile-based configuration
- Encryption support
- Actuator endpoints for health/status

**How it works**:
1. Config Server reads from GitHub
2. Microservices request: `GET /app-a/development`
3. Config Server returns YAML/properties
4. Microservice maps to @ConfigurationProperties

### 4. Property Binding Pattern (@ConfigurationProperties)

**What**: Automatic mapping of configuration files to Java objects.

**Benefits**:
- Type-safe configuration
- IDE auto-completion
- Validation support
- Immutability options

**Implementation**:
```java
@Component
@ConfigurationProperties(prefix = "app")
@Data
public class AppProperties {
    private String name;          // app.name
    private String description;   // app.description
    private String version;       // app.version
    private String environment;   // app.environment
    private int timeout;           // app.timeout
}
```

### 5. Spring Profiles Pattern

**What**: Environment-specific configuration files with naming convention.

**Convention**:
```
app.yml                    (default/baseline)
app-development.yml        (development profile)
app-production.yml         (production profile)
app-staging.yml            (staging profile)
```

**How to use**:
```bash
# Set profile
export SPRING_PROFILES_ACTIVE=production

# Or via Maven
mvn spring-boot:run -Dspring.profiles.active=production

# Or via application.yml
spring:
  profiles:
    active: production
```

### 6. Actuator Endpoints Pattern

**What**: Auto-exposed REST endpoints for monitoring and management.

**Endpoints Used**:
- `/actuator/health` - Application health status
- `/actuator/configprops` - All configuration properties
- `/actuator/refresh` - Reload configuration (POST)

**Example**:
```bash
# Check health
curl http://localhost:8080/actuator/health
# Returns: {"status":"UP"}

# Refresh configuration
curl -X POST http://localhost:8080/actuator/refresh
# Returns: array of refreshed properties

# View all properties
curl http://localhost:8080/actuator/configprops
```

### 7. REST API Pattern

**What**: Standard HTTP-based API design.

**Principles**:
- Resource-based URLs: `/api/{service}/{resource}`
- HTTP methods: GET, POST, PUT, DELETE
- Status codes: 200 OK, 400 Bad Request, 500 Server Error
- JSON response format

**Examples**:
```
GET  /api/app-a/greeting/{name}     → Get greeting for user
POST /api/app-a/process             → Process something
GET  /api/app-b/product/{id}        → Get product details
PUT  /api/app-b/product/{id}        → Update product
```

### 8. Data Transfer Object (DTO) Pattern

**What**: Objects used only for transferring data between layers.

**Benefits**:
- Separation of concerns
- API contract definition
- Easy JSON serialization
- Validation

**Implementation**:
```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GreetingResponse {
    private String message;
    private String appName;
    private String description;
    private String environment;
    private LocalDateTime timestamp;
}
```

---

## Spring Cloud Config Server Deep Dive

### Configuration Resolution Order

When a microservice requests configuration, Spring Cloud resolves it in this order:

```
1. app-a-{profile}.yml      (Profile-specific: highest priority)
2. app-a.yml                (Application-specific)
3. application-{profile}.yml (Global profile-specific)
4. application.yml          (Global default: lowest priority)
```

### Example Configuration Flow

**Request**: `GET http://localhost:8888/app-a/development`

**Resolution**:
1. Look for: `config/app-a-development.yml` ✓ (found)
2. Merge with: `config/app-a.yml` (if exists)
3. Return merged configuration

**Response**:
```json
{
  "name": "app-a",
  "profiles": ["development"],
  "propertySources": [
    {
      "name": "https://github.com/.../config/app-a-development.yml",
      "source": {
        "app.name": "App A Microservice",
        "app.environment": "development",
        "app.timeout": 30000
      }
    },
    {
      "name": "https://github.com/.../config/app-a.yml",
      "source": {
        "app.version": "1.0.0"
      }
    }
  ]
}
```

### Microservice Bootstrap Sequence

**Step 1**: Client startup
```java
// Application loads bootstrap.yml BEFORE application.yml
spring:
  cloud:
    config:
      uri: http://localhost:8888
      name: app-a
      profile: development
```

**Step 2**: Request configuration from Config Server
```
GET http://localhost:8888/app-a/development
```

**Step 3**: Config Server retrieves from GitHub
```
GitHub: microservices-config/config/app-a-development.yml
```

**Step 4**: Return to client
```json
{
  "app.name": "App A Microservice",
  "app.environment": "development"
}
```

**Step 5**: Bind to @ConfigurationProperties
```java
@ConfigurationProperties(prefix = "app")
public class AppProperties {
    private String name;        // Bound to: app.name
    private String environment; // Bound to: app.environment
}
```

**Step 6**: Available in application
```java
@RestController
public class AppAController {
    @Autowired
    private AppProperties appProperties;
    
    @GetMapping("/status")
    public ResponseEntity<?> getStatus() {
        // Use: appProperties.getName()
        // Use: appProperties.getEnvironment()
    }
}
```

---

## Configuration Refresh at Runtime

### Scenario: Update Configuration Without Downtime

**Step 1**: Update GitHub
```bash
# Edit: config/app-a-production.yml
timeout: 60000  # Changed from 30000

# Commit and push
git commit -am "Update timeout for production"
git push origin main
```

**Step 2**: Config Server detects change
- Automatically pulls from GitHub (force-pull enabled)
- Updates local cache
- Ready to serve new configuration

**Step 3**: Microservice refreshes configuration
```bash
# Call refresh endpoint
curl -X POST http://localhost:8080/actuator/refresh

# Response:
["app.timeout"]  # Updated properties
```

**Step 4**: Application uses new values
```java
@Component
@RefreshScope  // Enables refresh capability
@ConfigurationProperties(prefix = "app")
public class AppProperties {
    private int timeout;  // Now: 60000
}
```

---

## Security Best Practices

### 1. GitHub Repository Access

**Public Repository** (for demo/open source):
- Anyone can read configuration
- Good for: Learning, open-source projects

**Private Repository** (for production):
- Restrict access via GitHub teams
- Use SSH keys or Personal Access Token
- Enable two-factor authentication

### 2. Sensitive Configuration

**Avoid storing secrets in configuration files:**
```yaml
# ❌ Wrong: Password in Git repository
database:
  password: "mySecretPassword123"

# ✅ Correct: Use environment variables or secrets manager
database:
  password: ${DB_PASSWORD}  # From environment
```

### 3. Configuration Encryption

**For sensitive properties**, use Spring Cloud Config Encryption:
```bash
# Encrypt a value
curl localhost:8888/encrypt -d "mysecret"
# Response: e8e080ff9e1c8f...

# Store encrypted value in YAML
database:
  password: '{cipher}e8e080ff9e1c8f...'
```

### 4. Access Control

**Config Server authentication**:
```yaml
spring:
  security:
    user:
      name: admin
      password: mypassword
```

**Microservice calls with authentication**:
```yaml
spring:
  cloud:
    config:
      username: admin
      password: mypassword
```

---

## Monitoring & Troubleshooting

### Check Config Server Status
```bash
curl http://localhost:8888/actuator/health
# Response: {"status":"UP"}
```

### View Config Server Logs
```bash
# Real-time logs
mvn spring-boot:run

# Or check recent logs
tail -f logs/application.log
```

### Debug Configuration Loading
```bash
# Enable debug logging in bootstrap.yml
logging:
  level:
    org.springframework.cloud: DEBUG

# Or via environment variable
export LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_CLOUD=DEBUG
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Config not loading | Config Server not running | Start Config Server first |
| GitHub 404 | Wrong repository URL | Verify GitHub URL in application.yml |
| Configuration cached | Auto-pull disabled | Set `force-pull: true` |
| Port in use | Another service on port | Kill process or use different port |

---

## Future Enhancements

### 1. Service Discovery
Replace hardcoded Config Server URL with Eureka:
```yaml
spring:
  cloud:
    config:
      discovery:
        enabled: true
        service-id: config-server  # Eureka service name
```

### 2. API Gateway
Route all requests through single gateway:
```
Client → API Gateway (Spring Cloud Gateway) → App A/B
```

### 3. Circuit Breaker
Handle Config Server failures gracefully:
```java
@CircuitBreaker(name = "configServer")
public ConfigResponse getConfiguration() {
    return configClient.fetch();
}
```

### 4. Distributed Tracing
Track requests across microservices:
```
Spring Cloud Sleuth + Zipkin
```

### 5. Message Queue Integration
Asynchronous configuration updates:
```
RabbitMQ/Kafka → ConfigUpdateEvent → Services
```

---

## References

- [Spring Cloud Config Documentation](https://cloud.spring.io/spring-cloud-config/reference/html/)
- [Spring Boot Actuator Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Microservices Patterns - Sam Newman](https://samnewman.io/books/building_microservices_2nd_edition/)
- [Spring Cloud Best Practices](https://spring.io/blog/2015/07/14/microservices-with-spring)

---

**Version**: 1.0.0  
**Last Updated**: January 5, 2026
