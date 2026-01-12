# GitHub Configuration Repository Setup Guide

## Overview

This guide walks you through setting up a GitHub repository to store centralized configuration for the Microservices Masterclass Demo.

## Prerequisites

- GitHub account (https://github.com)
- Git installed locally
- Access to the command line/terminal

---

## Step 1: Create GitHub Repository

### Method 1: Via GitHub Web Interface (Easiest)

1. Open https://github.com/new
2. Fill in the details:
   - **Repository name**: `microservices-config`
   - **Description**: "Centralized configuration for Spring Boot microservices"
   - **Public/Private**: Select "Public" (for this demo) or "Private" (for production)
   - **Initialize this repository with**: No (we'll push existing files)
3. Click "Create repository"

### Method 2: Via GitHub CLI

```bash
gh repo create microservices-config --public --description "Centralized configuration for Spring Boot microservices"
```

---

## Step 2: Clone Repository Locally

```bash
# Clone the repository
git clone https://github.com/yourusername/microservices-config.git
cd microservices-config

# Create the config directory
mkdir config
```

---

## Step 3: Create Configuration Files

### Directory Structure

```
microservices-config/
├── config/
│   ├── app-a.yml                    # Default configuration for App A
│   ├── app-a-development.yml        # Development profile for App A
│   ├── app-a-production.yml         # Production profile for App A
│   ├── app-b.yml                    # Default configuration for App B
│   ├── app-b-development.yml        # Development profile for App B
│   └── app-b-production.yml         # Production profile for App B
├── .gitignore                       # Git ignore file
└── README.md                        # Repository documentation
```

### Create .gitignore

Create `microservices-config/.gitignore`:

```
# IDE
.idea/
.vscode/
*.swp
*.swo
*~
.DS_Store

# Sensitive files
*.key
*.pem
secrets.yml
local-config.yml
```

### Create Configuration Files

#### 1. `config/app-a.yml` (Default Configuration)

```yaml
app:
  name: "App A Microservice"
  description: "First microservice with centralized config"
  version: "1.0.0"
  environment: "default"
  timeout: 30000
```

#### 2. `config/app-a-development.yml` (Development Configuration)

```yaml
app:
  name: "App A Microservice"
  description: "First microservice - Development Environment"
  version: "1.0.0"
  environment: "development"
  timeout: 30000
  # Development specific settings
  debug: true
  logLevel: "DEBUG"
```

#### 3. `config/app-a-production.yml` (Production Configuration)

```yaml
app:
  name: "App A Microservice"
  description: "First microservice - Production Environment"
  version: "1.0.0"
  environment: "production"
  timeout: 60000
  # Production specific settings
  debug: false
  logLevel: "INFO"
  maxThreads: 100
```

#### 4. `config/app-b.yml` (Default Configuration)

```yaml
app:
  name: "App B Microservice"
  description: "Second microservice with centralized config"
  version: "1.0.0"
  environment: "default"
  timeout: 45000
  maxConnections: 50
```

#### 5. `config/app-b-development.yml` (Development Configuration)

```yaml
app:
  name: "App B Microservice"
  description: "Second microservice - Development Environment"
  version: "1.0.0"
  environment: "development"
  timeout: 45000
  maxConnections: 25
  # Development specific settings
  debug: true
  logLevel: "DEBUG"
  cacheEnabled: false
```

#### 6. `config/app-b-production.yml` (Production Configuration)

```yaml
app:
  name: "App B Microservice"
  description: "Second microservice - Production Environment"
  version: "1.0.0"
  environment: "production"
  timeout: 120000
  maxConnections: 100
  # Production specific settings
  debug: false
  logLevel: "WARN"
  cacheEnabled: true
  cacheTTL: 3600
```

#### 7. `README.md` (Repository Documentation)

```markdown
# Microservices Configuration Repository

Centralized configuration storage for Spring Boot microservices using Spring Cloud Config Server.

## Repository Structure

```
config/
├── app-a.yml                    # Default App A configuration
├── app-a-development.yml        # Development profile
├── app-a-production.yml         # Production profile
├── app-b.yml                    # Default App B configuration
├── app-b-development.yml        # Development profile
└── app-b-production.yml         # Production profile
```

## How It Works

1. **Config Server** reads configurations from this GitHub repository
2. **Microservices** (App A, App B) request their configuration from Config Server
3. **Configuration profiles** allow different settings per environment

## Configuration Naming Convention

Spring Cloud Config Server uses this naming pattern:

```
/{application}/{profile}/{label}
```

Examples:
- `/app-a/development` → loads `config/app-a-development.yml`
- `/app-a/production` → loads `config/app-a-production.yml`
- `/app-b/default` → loads `config/app-b.yml`

## Updating Configuration

1. Make changes to YAML files
2. Commit and push to GitHub
3. Microservices can refresh configuration using:
   ```bash
   curl -X POST http://localhost:8080/actuator/refresh
   curl -X POST http://localhost:8081/actuator/refresh
   ```

## Configuration Profiles

- **development**: For local development (loose security, verbose logging)
- **production**: For production environment (strict security, minimal logging)
- **default**: Baseline configuration (no profile specified)

## Best Practices

- Use environment-specific files for sensitive data
- Keep default configuration minimal and generic
- Document all configuration properties
- Use meaningful variable names
- Follow YAML indentation (2 spaces)

---

Last Updated: January 5, 2026
```

---

## Step 4: Push to GitHub

```bash
# Navigate to repository directory (if not already)
cd microservices-config

# Add all files
git add .

# Create initial commit
git commit -m "Initial configuration files for microservices"

# Push to GitHub (main branch)
git push -u origin main

# Verify push was successful
git log --oneline
```

---

## Step 5: Update Config Server Application

Edit: `config-server/src/main/resources/application.yml`

Replace `yourusername` with your actual GitHub username:

```yaml
server:
  port: 8888

spring:
  application:
    name: config-server
  cloud:
    config:
      server:
        git:
          uri: https://github.com/yourusername/microservices-config.git
          default-label: main
          search-paths: config
          clone-on-start: true
          force-pull: true
          timeout: 5
          basedir: ./config-repo

logging:
  level:
    org.springframework.cloud: DEBUG
    com.netflix: WARN
```

---

## Step 6: Verify Configuration Loading

### Start Config Server

```bash
cd config-server
mvn spring-boot:run
```

### Test Configuration Endpoints

```bash
# Get App A default configuration
curl http://localhost:8888/app-a/default

# Get App A development configuration
curl http://localhost:8888/app-a/development

# Get App A production configuration
curl http://localhost:8888/app-a/production

# Get App B default configuration
curl http://localhost:8888/app-b/default

# Get App B development configuration
curl http://localhost:8888/app-b/development

# Get App B production configuration
curl http://localhost:8888/app-b/production
```

### Expected Response Format

```json
{
  "name": "app-a",
  "profiles": ["development"],
  "label": "main",
  "version": "abc123def456",
  "state": null,
  "propertySources": [
    {
      "name": "https://github.com/yourusername/microservices-config.git/config/app-a-development.yml",
      "source": {
        "app.name": "App A Microservice",
        "app.description": "First microservice - Development Environment",
        "app.version": "1.0.0",
        "app.environment": "development",
        "app.timeout": 30000
      }
    }
  ]
}
```

---

## Step 7: Start Microservices

### Start App A

```bash
cd app-a
mvn spring-boot:run
```

### Start App B

In a new terminal:
```bash
cd app-b
mvn spring-boot:run
```

### Verify Configuration Loaded

```bash
# Check App A configuration properties
curl http://localhost:8080/actuator/configprops | grep -A 20 "app-"

# Check App B configuration properties
curl http://localhost:8081/actuator/configprops | grep -A 20 "app-"
```

---

## Common GitHub Operations

### Adding New Configuration File

```bash
# Create new configuration
echo "app:" >> config/app-c.yml
echo "  name: 'App C'" >> config/app-c.yml

# Commit and push
git add config/app-c.yml
git commit -m "Add configuration for App C"
git push origin main
```

### Updating Existing Configuration

```bash
# Edit configuration file
nano config/app-a-production.yml

# Commit and push
git add config/app-a-production.yml
git commit -m "Update production configuration for App A"
git push origin main
```

### Viewing Configuration History

```bash
# View commit history
git log --oneline

# View specific file changes
git log -p config/app-a.yml

# Show latest version
git show HEAD:config/app-a.yml
```

---

## Troubleshooting

### Issue: Config Server Can't Access GitHub

**Error Message:**
```
IOException: Repo not found or authentication failed
```

**Solutions:**
1. Verify GitHub URL is correct
2. Check internet connection
3. For private repositories:
   - Use SSH keys: `git@github.com:yourusername/microservices-config.git`
   - Or use Personal Access Token in HTTPS URL

### Issue: Configuration Not Updating

**Solution:**
1. Verify file was pushed to GitHub: `git log`
2. Check Config Server logs for errors
3. Restart Config Server
4. Call refresh endpoint on microservices:
   ```bash
   curl -X POST http://localhost:8080/actuator/refresh
   curl -X POST http://localhost:8081/actuator/refresh
   ```

### Issue: YAML Format Errors

**Common Mistakes:**
```yaml
# ❌ Wrong: Space after dash
app:
  name: - "App A"

# ✅ Correct: Proper YAML format
app:
  name: "App A"

# ❌ Wrong: Inconsistent indentation
app:
  name: "App A"
    description: "Test"

# ✅ Correct: Consistent indentation (2 spaces)
app:
  name: "App A"
  description: "Test"
```

**Validate YAML:**
```bash
# Online validator: https://www.yamllint.com/
# Or use a text editor with YAML validation
```

---

## Advanced: Using SSH Keys with GitHub

For more secure authentication:

```bash
# Generate SSH key (if not already done)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Add SSH key to GitHub:
# 1. Go to https://github.com/settings/keys
# 2. Click "New SSH key"
# 3. Paste your public key (from ~/.ssh/id_ed25519.pub)

# Update Config Server to use SSH
# Edit: config-server/src/main/resources/application.yml
spring:
  cloud:
    config:
      server:
        git:
          uri: git@github.com:yourusername/microservices-config.git
```

---

## Advanced: Using Personal Access Token

For private repositories without SSH:

```bash
# Create Personal Access Token:
# 1. Go to https://github.com/settings/tokens
# 2. Click "Generate new token"
# 3. Select "repo" scope
# 4. Copy the token

# Update Config Server:
# spring:
#   cloud:
#     config:
#       server:
#         git:
#           uri: https://yourusername:your-token@github.com/yourusername/microservices-config.git

# Or use environment variable:
# export GIT_USERNAME=yourusername
# export GIT_PASSWORD=your-token
```

---

## Next Steps

1. ✅ Create GitHub repository
2. ✅ Push configuration files
3. ✅ Update Config Server URI
4. ✅ Start services and test
5. ✅ Explore configuration refresh capability
6. ✅ Add more microservices

---

## Resources

- [Spring Cloud Config Documentation](https://cloud.spring.io/spring-cloud-config/)
- [GitHub Repository Documentation](https://docs.github.com/repositories)
- [YAML Specification](https://yaml.org/spec/)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)

---

**Version**: 1.0.0  
**Last Updated**: January 5, 2026
