# GitHub Configuration Repository Template

This is a template for your centralized Spring Cloud Config repository on GitHub.

## Structure

```
microservices-config/
├── config/
│   ├── app-a.yml
│   ├── app-a-development.yml
│   ├── app-a-production.yml
│   ├── app-b.yml
│   ├── app-b-development.yml
│   └── app-b-production.yml
├── README.md
└── .gitignore
```

## Steps to Setup

### 1. Create GitHub Repository
- Go to https://github.com/new
- Create repo named: `microservices-config`
- Make it **Public** (for this demo) or **Private** (for production)

### 2. Create Configuration Files Locally

Create file: `app-a.yml`
```yaml
# App A Configuration
app:
  name: App A Microservice
  description: First microservice with centralized config
  version: 1.0.0
  timeout: 30000
  max-connections: 100
```

Create file: `app-a-development.yml`
```yaml
# App A - Development Configuration
app:
  environment: development
  timeout: 60000

# Database
database:
  url: jdbc:mysql://localhost:3306/app_a_dev
  username: root
  password: root

# Logging
logging:
  level: DEBUG
```

Create file: `app-a-production.yml`
```yaml
# App A - Production Configuration
app:
  environment: production
  timeout: 30000

# Database
database:
  url: jdbc:mysql://prod-db.example.com:3306/app_a
  username: ${DB_USER}
  password: ${DB_PASSWORD}

# Logging
logging:
  level: INFO
```

Create file: `app-b.yml`
```yaml
# App B Configuration
app:
  name: App B Microservice
  description: Second microservice with centralized config
  version: 1.0.0
  timeout: 45000
  max-connections: 50
```

Create file: `app-b-development.yml`
```yaml
# App B - Development Configuration
app:
  environment: development
  timeout: 60000

# API Configuration
api:
  base-url: http://localhost:8080
  timeout: 30

# Logging
logging:
  level: DEBUG
```

Create file: `app-b-production.yml`
```yaml
# App B - Production Configuration
app:
  environment: production
  timeout: 45000

# API Configuration
api:
  base-url: https://api.example.com
  timeout: 15

# Logging
logging:
  level: INFO
```

### 3. Push to GitHub

```bash
# Initialize git repo
git init

# Add files
git add .

# Commit
git commit -m "Initial configuration files"

# Add remote (replace with your repo)
git remote add origin https://github.com/yourusername/microservices-config.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### 4. Update Config Server

Update: `config-server/src/main/resources/application.yml`

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

### 5. For Private Repositories

Add credentials to: `~/.ssh/config` or update pom.xml:

```xml
<plugin>
  <groupId>org.springframework.cloud</groupId>
  <artifactId>spring-cloud-config-server</artifactId>
  <configuration>
    <git>
      <uri>git@github.com:yourusername/microservices-config.git</uri>
      <username>${github.username}</username>
      <password>${github.token}</password>
    </git>
  </configuration>
</plugin>
```

## Testing Configuration

Access configurations via HTTP:

```bash
# Get app-a development config
curl http://localhost:8888/app-a/development

# Get app-b production config
curl http://localhost:8888/app-b/production

# Get app-a default config
curl http://localhost:8888/app-a/main
```

## Configuration File Naming Conventions

- `{app-name}.yml` - Default configuration
- `{app-name}-{profile}.yml` - Profile-specific configuration

Profiles can be:
- `development`
- `staging`
- `production`
- Custom profiles

## Updating Configurations

1. Update files in GitHub repository
2. Microservices can refresh configuration with:

```bash
POST http://localhost:8080/actuator/refresh
POST http://localhost:8081/actuator/refresh
```

Or enable auto-refresh with `@RefreshScope` annotation:

```java
@Component
@RefreshScope
@ConfigurationProperties(prefix = "app")
public class AppProperties {
    // Configuration will auto-refresh when files change
}
```
