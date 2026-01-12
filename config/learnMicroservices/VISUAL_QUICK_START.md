# 🎯 Getting Started - Visual Quick Guide

## 🚀 5-Minute Quick Start

### Step 1: Build (2 minutes)
```bash
cd Microservices-masterclass-demo
mvn clean install
```

✅ You'll see: `BUILD SUCCESS`

---

### Step 2: Start Services (1 minute each, 3 terminals)

**Terminal 1 - Config Server:**
```bash
cd config-server
mvn spring-boot:run
```
✅ Look for: `Started ConfigServerApplication in X seconds`
✅ Port: 8888

---

**Terminal 2 - App A:**
```bash
cd app-a
mvn spring-boot:run
```
✅ Look for: `Started AppAApplication in X seconds`
✅ Port: 8080

---

**Terminal 3 - App B:**
```bash
cd app-b
mvn spring-boot:run
```
✅ Look for: `Started AppBApplication in X seconds`
✅ Port: 8081

---

### Step 3: Test (1 minute)

**Test Config Server:**
```bash
curl http://localhost:8888/actuator/health
```
Response should show: `{"status":"UP"}`

**Test App A:**
```bash
curl http://localhost:8080/api/app-a/greeting/World
```
Response should show:
```json
{
  "message": "Hello, World!",
  "appName": "App A Microservice",
  "description": "First microservice with centralized config",
  "environment": "development",
  "timestamp": "2026-01-05T12:34:56"
}
```

**Test App B:**
```bash
curl http://localhost:8081/api/app-b/product/123
```
Response should show:
```json
{
  "productId": "123",
  "productName": "Sample Product - 123",
  "appName": "App B Microservice",
  "description": "Second microservice with centralized config",
  "environment": "development",
  "timestamp": "2026-01-05T12:34:56"
}
```

✅ **All working!** Continue to next section.

---

## 📚 What to Read Next

### After 5-Minute Quick Start

#### Option A: Learn the Architecture (30 minutes)
→ Read: `ARCHITECTURE_AND_PATTERNS.md`
- Understand why things work this way
- Learn about design patterns
- See future enhancements

#### Option B: Setup GitHub (15 minutes)
→ Read: `GITHUB_CONFIGURATION_SETUP.md`
- Create GitHub repository
- Add configuration files
- See configuration refresh in action

#### Option C: Full Documentation (1 hour)
→ Read: `DOCUMENTATION_INDEX.md` → `README.md` → others
- Get complete understanding
- Learn deployment options
- Explore troubleshooting

---

## 🎯 Success Checklist

After quick start, verify:

- [ ] Config Server running (8888)
- [ ] App A running (8080)
- [ ] App B running (8081)
- [ ] Greeting endpoint returns response
- [ ] Product endpoint returns response
- [ ] Health endpoints return "UP"

If all checked ✅ → You're ready for next steps!

---

## 🔄 What Happens When You Call an Endpoint

### Example: `curl http://localhost:8080/api/app-a/greeting/World`

```
1. Request reaches App A on port 8080
                    ↓
2. AppAController.getGreeting("World") is called
                    ↓
3. Injects AppProperties (from Config Server)
                    ↓
4. Creates GreetingResponse with:
   - Injected properties (name, description, etc.)
   - Dynamic greeting message
   - Current timestamp
                    ↓
5. Returns JSON response to client
                    ↓
6. You see the response in terminal!
```

---

## 🌍 Architecture Overview

```
┌─────────────────────────────────────────────────┐
│           Your Local Computer                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │    Port 8888: Config Server              │  │
│  │  - Reads config from GitHub              │  │
│  │  - Serves config to other services       │  │
│  │  - Caches locally                        │  │
│  └──────┬───────────────────────────────────┘  │
│         │ provides config                      │
│         ├──────────────┬──────────────┐        │
│         ▼              ▼              ▼        │
│  ┌─────────────┐ ┌──────────────┐ ┌───────┐  │
│  │ Port 8080   │ │  Port 8081   │ │Future │  │
│  │   App A     │ │    App B     │ │ Apps  │  │
│  │             │ │              │ │       │  │
│  │ - greeting  │ │ - product    │ │       │  │
│  │ - status    │ │ - health     │ │       │  │
│  └─────────────┘ └──────────────┘ └───────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
         ↓
    Uses Config
         ↓
    ┌─────────────────────────────────────┐
    │     GitHub Repository               │
    │   (microservices-config)            │
    │                                     │
    │   config/                          │
    │   ├── app-a.yml                    │
    │   ├── app-a-development.yml        │
    │   ├── app-a-production.yml         │
    │   ├── app-b.yml                    │
    │   ├── app-b-development.yml        │
    │   └── app-b-production.yml         │
    │                                     │
    │  (You need to create these!)        │
    └─────────────────────────────────────┘
```

---

## 🔑 Key Concepts (Simple Explanation)

### Config Server (Port 8888)
**What**: A service that reads configuration files from GitHub and gives them to other services.

**Why**: Instead of changing code to change settings, you just update files on GitHub.

**How**: 
1. Reads from: `https://github.com/yourusername/microservices-config.git`
2. Serves to: Anyone who asks via HTTP
3. Cache: Stores locally so it doesn't hit GitHub every time

---

### App A & App B (Ports 8080 & 8081)
**What**: Actual business logic services that use configuration from Config Server.

**Why**: You can run multiple independent services, each with their own code but shared configuration.

**How**:
1. Start up
2. Ask Config Server: "Give me my config"
3. Config Server: "Here's your settings"
4. Use settings in code (AppProperties)
5. Serve REST endpoints to users

---

### Centralized Configuration
**What**: One place (GitHub) where all configuration lives.

**Why**: 
- Change settings without redeploying code
- All services see same settings
- History of changes (Git history)
- Different settings per environment

**How**:
```
GitHub (source of truth)
    ↓
Config Server (distributor)
    ↓
Services (consumers)
```

---

## 📊 Endpoint Reference

### Config Server Endpoints

```bash
# Get default config for app-a
curl http://localhost:8888/app-a/default

# Get development profile for app-a
curl http://localhost:8888/app-a/development

# Get production profile for app-b
curl http://localhost:8888/app-b/production

# Check health
curl http://localhost:8888/actuator/health
```

### App A Endpoints

```bash
# Greeting service
curl http://localhost:8080/api/app-a/greeting/John
curl http://localhost:8080/api/app-a/greeting/Jane

# Status/info
curl http://localhost:8080/api/app-a/status

# Health check
curl http://localhost:8080/actuator/health

# View loaded properties
curl http://localhost:8080/actuator/configprops

# Refresh configuration
curl -X POST http://localhost:8080/actuator/refresh
```

### App B Endpoints

```bash
# Product service
curl http://localhost:8081/api/app-b/product/P001
curl http://localhost:8081/api/app-b/product/P002

# Health/info
curl http://localhost:8081/api/app-b/health

# Health check
curl http://localhost:8081/actuator/health

# View loaded properties
curl http://localhost:8081/actuator/configprops

# Refresh configuration
curl -X POST http://localhost:8081/actuator/refresh
```

---

## 🛠️ Troubleshooting Quick Fixes

### Issue: "Address already in use: bind:8080"

**Fix**: Port 8080 is busy. Either:

```bash
# Option 1: Kill process on that port (Windows PowerShell)
$ProcessID = (Get-NetTCPConnection -LocalPort 8080).OwningProcess
Stop-Process -Id $ProcessID -Force

# Option 2: Use different port (edit bootstrap.yml)
server:
  port: 8090  # Use different port
```

---

### Issue: "Could not connect to Config Server"

**Fix**:

```bash
# 1. Check if Config Server is running
curl http://localhost:8888/actuator/health

# 2. If not, start it in another terminal:
cd config-server
mvn spring-boot:run

# 3. Wait for message: "Started ConfigServerApplication in X seconds"

# 4. Restart App A/B
```

---

### Issue: Build fails with "Cannot find symbol"

**Fix**:

```bash
# Try clean build:
mvn clean install -U

# If still fails, check you're in correct directory:
pwd  # Should show .../Microservices-masterclass-demo/

# Then try again:
mvn clean install
```

---

## 🎓 Next Learning Steps

### After Quick Start Works

**Step 1: Read README.md** (10 min)
- Full list of commands
- Complete testing procedure
- Common issues explained

**Step 2: Read GITHUB_CONFIGURATION_SETUP.md** (20 min)
- Create GitHub repository
- Add configuration files
- Test configuration refresh

**Step 3: Read ARCHITECTURE_AND_PATTERNS.md** (30 min)
- Understand design patterns
- Learn why it's built this way
- Explore future enhancements

**Step 4: Try Adding a Feature** (30 min)
- Add new endpoint to App A
- Add new configuration property
- Refresh and test

---

## 🎯 Common Tasks & How To Do Them

### "I want to change the greeting message"

1. Edit `app-a/src/main/java/.../AppAController.java`
2. Change the greeting string
3. Rebuild: `mvn clean install`
4. Restart App A
5. Test: `curl http://localhost:8080/api/app-a/greeting/World`

---

### "I want to change timeout configuration"

**Option A: Without GitHub (for testing)**
1. Edit `app-a/src/main/resources/bootstrap.yml`
2. Change: `timeout: 30000` to `timeout: 60000`
3. Restart App A

**Option B: With GitHub (proper way)**
1. Create GitHub repository (see GITHUB_CONFIGURATION_SETUP.md)
2. Edit GitHub file: `config/app-a-development.yml`
3. Change timeout value
4. Git push
5. Call refresh: `curl -X POST http://localhost:8080/actuator/refresh`

---

### "I want to add a new microservice"

1. Copy `app-a/` folder to `app-c/`
2. Update `pom.xml`: change artifact-id
3. Update `AppAApplication.java` → `AppCApplication.java`
4. Update `bootstrap.yml`: change port (8082) and name (app-c)
5. Update controller and DTOs
6. Build and run!

---

## 📞 When You Get Stuck

### Checklist:
1. [ ] Are all 3 services running? (Check terminals)
2. [ ] Are they on correct ports? (8888, 8080, 8081)
3. [ ] Did you see "Started" messages?
4. [ ] Are services giving errors? (Check terminal output)
5. [ ] Can you reach them? Try `curl http://localhost:8080/actuator/health`

### Resources:
- README.md → Common Issues & Solutions
- TROUBLESHOOTING_AND_DEPLOYMENT.md → Part 1
- Logs in terminal (read carefully!)

---

## ✅ Quick Verification

After starting services, run these commands in a terminal:

```bash
# Should all return UP or OK
curl http://localhost:8888/actuator/health
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health

# Should return actual data
curl http://localhost:8080/api/app-a/greeting/Test
curl http://localhost:8081/api/app-b/product/1

# All done if all above work!
```

---

## 🎉 Congratulations!

If you've completed the quick start:

✅ You understand how microservices work  
✅ You understand configuration management  
✅ You can run services locally  
✅ You can test endpoints  

**Next**: Pick one of the learning paths above!

---

## 📚 Document Map for This Guide

```
You are here (VISUAL_QUICK_START.md)
    ↓
Read Next: README.md (detailed quick start)
    ↓
Then Choose:
    ├─ Learning Path → ARCHITECTURE_AND_PATTERNS.md
    ├─ GitHub Setup → GITHUB_CONFIGURATION_SETUP.md
    ├─ Need Help → TROUBLESHOOTING_AND_DEPLOYMENT.md
    └─ Navigation → DOCUMENTATION_INDEX.md
```

---

**Ready? Start with Step 1!** 🚀

---

**Version**: 1.0.0  
**Last Updated**: January 5, 2026  
**Status**: ✅ Complete
