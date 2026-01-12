# 🚀 PHASE 3 QUICK START - Zipkin Standalone (No Docker Needed)

**Date:** January 12, 2026  
**Platform:** Windows (No Docker Required)  
**Time to Complete:** 10 minutes total  
**Status:** Ready to execute RIGHT NOW

---

## ✅ What You'll Do Today

```
Step 1: Download Zipkin JAR (2 minutes)
Step 2: Start Zipkin server (1 minute)
Step 3: Verify it's working (2 minutes)
Step 4: Update your services (5 minutes)
Step 5: Test everything (3 minutes)
─────────────────────────────────────
TOTAL: ~13 minutes to full Phase 3 working! 🎉
```

---

## 🎯 Step-by-Step: No Docker, Just Java

### STEP 1: Create Zipkin Directory

```powershell
# Create folder for Zipkin
New-Item -ItemType Directory -Path "C:\zipkin" -Force
cd C:\zipkin

# Verify you're in the right directory
Get-Location
# Output should show: C:\zipkin
```

---

### STEP 2: Download Zipkin JAR

**Method A: Automatic Download (Recommended)**

```powershell
# Run this command in PowerShell
$zipkinUrl = "https://search.maven.org/remote_content?g=io.zipkin.java&a=zipkin-server&v=LATEST&c=exec"

Invoke-WebRequest -Uri $zipkinUrl -OutFile "C:\zipkin\zipkin.jar" -UseBasicParsing

# Verify download
Get-Item C:\zipkin\zipkin.jar | Format-List
```

**Expected output:**
```
Mode                 : -a----
Length               : 60+ MB
Name                 : zipkin.jar
```

**If download fails, use Method B:**

```powershell
# Method B: Manual Download
# 1. Open browser
Start-Process "https://zipkin.io/pages/quickstart.html"

# 2. Click "Download the latest release"
# 3. Download zipkin-server-X.X.X-exec.jar
# 4. Save to C:\zipkin\
# 5. Rename to zipkin.jar
```

---

### STEP 3: Verify Java is Installed

```powershell
# Check Java version
java -version

# Expected output:
# openjdk version "17.0.13" 2024-10-15
# OpenJDK Runtime Environment (build 17.0.13+11)
```

**If Java not found:**
```powershell
# You already have Java installed (used for Maven/Spring Boot)
# If error appears, install from: https://www.oracle.com/java/technologies/downloads/

# After installation, restart PowerShell
```

---

### STEP 4: Start Zipkin Server

**Simple Command:**

```powershell
# Navigate to Zipkin directory
cd C:\zipkin

# Start Zipkin
java -jar zipkin.jar
```

**Expected output (wait 10-15 seconds):**
```
2026-01-12 10:30:00 Listening on 0.0.0.0:9411
Zipkin started successfully!
```

**Keep this terminal open!** (Don't close it - Zipkin needs to stay running)

**Troubleshooting:**
```powershell
# If you get: "The term 'java' is not recognized"
# Solution: Add Java to PATH or use full path
"C:\Program Files\Java\jdk-17\bin\java" -jar zipkin.jar

# If port 9411 already in use:
# Kill existing process
netstat -ano | findstr :9411
taskkill /PID <PID> /F

# Then retry
java -jar zipkin.jar
```

---

### STEP 5: Verify Zipkin is Running

**In a NEW PowerShell window (don't close the Zipkin one!):**

```powershell
# Test Zipkin API
Invoke-WebRequest -Uri "http://localhost:9411/api/v2/services" -UseBasicParsing | Select-Object StatusCode, Content

# Expected output:
# StatusCode : 200
# Content    : []  (empty because no services connected yet)
```

**Or manually check:**

```powershell
# Open browser
Start-Process "http://localhost:9411"
```

**You should see:**
```
Zipkin Dashboard
├─ Search box
├─ Service list (empty)
├─ Trace visualization area
└─ Dependencies graph
```

---

## ✅ PART 1 COMPLETE!

```
✅ Zipkin downloaded
✅ Zipkin running
✅ Dashboard accessible
✅ Ready for next phase

Now: Update your services
```

---

## 🔧 PART 2: Update Your Services

### What You Need to Do

Add Sleuth + Zipkin to all **4 services**:
1. ✅ API Gateway
2. ✅ App A
3. ✅ App B
4. ✅ Eureka Server (optional but recommended)
5. ✅ Config Server (optional)

---

## 📝 STEP 1: Update pom.xml Files

### For API Gateway (api-gateway/pom.xml)

**Find this section:**
```xml
        <!-- Spring Boot Actuator (for health checks and monitoring) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
```

**Add AFTER it (before closing dependencies tag):**
```xml
        <!-- Spring Cloud Sleuth (Distributed Tracing) -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-sleuth</artifactId>
        </dependency>

        <!-- Zipkin Client (Trace Collection) -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-sleuth-zipkin</artifactId>
        </dependency>
```

### For App A (app-a/pom.xml)

**Find this section:**
```xml
        <!-- Spring Boot Actuator -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
```

**Add AFTER it:**
```xml
        <!-- Spring Cloud Sleuth (Distributed Tracing) -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-sleuth</artifactId>
        </dependency>

        <!-- Zipkin Client (Trace Collection) -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-sleuth-zipkin</artifactId>
        </dependency>
```

### For App B (app-b/pom.xml)

**Same as App A - add the two dependencies**

---

## 🔧 STEP 2: Update application.yml Files

### For API Gateway (api-gateway/src/main/resources/application.yml)

**Add at the END of the file:**
```yaml
# Distributed Tracing Configuration
spring:
  sleuth:
    enabled: true
    sampler:
      probability: 1.0  # Sample 100% of requests (for learning)
  
  zipkin:
    base-url: http://localhost:9411
    sender:
      type: web  # Use HTTP to send traces

logging:
  level:
    root: INFO
    org.springframework.web: DEBUG
```

### For App A (app-a/src/main/resources/application.yml)

**Add at the END:**
```yaml
# Distributed Tracing Configuration
spring:
  sleuth:
    enabled: true
    sampler:
      probability: 1.0
  
  zipkin:
    base-url: http://localhost:9411
    sender:
      type: web

logging:
  level:
    root: INFO
    org.springframework.web: DEBUG
```

### For App B (app-b/src/main/resources/application.yml)

**Same as App A**

---

## 🔄 STEP 3: Rebuild Services

```powershell
# Navigate to each service and rebuild

# API Gateway
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\api-gateway
mvn clean package -DskipTests

# App A
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn clean package -DskipTests

# App B
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-b
mvn clean package -DskipTests
```

**Expected output:**
```
[INFO] BUILD SUCCESS
[INFO] Total time: 25.123 s
[INFO] Finished at: 2026-01-12T10:30:00+05:30
```

---

## ✅ PART 2 COMPLETE!

```
✅ Dependencies added
✅ Services configured
✅ Services rebuilt
✅ Ready to test
```

---

## 🧪 PART 3: Start Services and Test

### STEP 1: Make Sure Zipkin is Still Running

**Check in first PowerShell window:**
```
If you see:
2026-01-12 10:30:00 Listening on 0.0.0.0:9411

Then: ✅ Zipkin is running
```

---

### STEP 2: Start Services (New PowerShell Windows)

**Open NEW PowerShell windows for each:**

**Window 1: Eureka Server**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\eureka-server
mvn spring-boot:run
```

**Window 2: Config Server (Optional)**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\config-server
mvn spring-boot:run
```

**Window 3: App A**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn spring-boot:run -Dserver.port=8080
```

**Window 4: App B**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-b
mvn spring-boot:run -Dserver.port=8083
```

**Window 5: API Gateway**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\api-gateway
mvn spring-boot:run
```

**Wait 30-60 seconds for all services to start**

---

### STEP 3: Make Test Requests

**In a new PowerShell window:**

```powershell
# Test 1: Check Eureka
Start-Process "http://localhost:8761"

# Test 2: Make requests to generate traces
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Request $i..."
    Invoke-WebRequest -Uri "http://localhost:9002/api/app-a/status" -UseBasicParsing
    Start-Sleep -Seconds 1
}

# Test 3: Make inter-service calls
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Inter-service call $i..."
    Invoke-WebRequest -Uri "http://localhost:9002/api/app-a/call-app-b/status" -UseBasicParsing
    Start-Sleep -Seconds 1
}
```

**Expected responses:**
```
StatusCode : 200

These requests generate traces that go to Zipkin!
```

---

### STEP 4: Check Zipkin Dashboard

```powershell
# Open Zipkin
Start-Process "http://localhost:9411"
```

**You should see:**

```
Zipkin Dashboard:
├─ Services: api-gateway, app-a, app-b ✅
├─ Traces: Multiple entries ✅
├─ Click on a trace to see:
│  ├─ Request timeline
│  ├─ Service latencies
│  ├─ Trace ID
│  └─ Complete request path
└─ Dependencies graph showing: Gateway → App A → App B
```

---

## 🎯 YOU'VE COMPLETED PHASE 3! 🎉

```
✅ Zipkin running (no Docker needed!)
✅ Services configured for distributed tracing
✅ Requests generating traces
✅ Dashboard showing complete request flows
✅ Can see latency breakdown per service
✅ Can trace inter-service calls
```

---

## 📊 What You Can Now Do in Zipkin

### View Traces
```
1. Open http://localhost:9411
2. Click "Find Traces"
3. See all requests with trace IDs
4. Click on one to see full flow
```

### Search Traces
```
1. Filter by service (api-gateway, app-a, app-b)
2. Filter by time range
3. Filter by latency (slow requests)
4. Filter by status (errors)
```

### Analyze Performance
```
1. View service dependencies
2. See latency breakdown:
   ├─ Gateway: 10ms
   ├─ App A: 50ms
   └─ App B: 100ms
   
3. Identify bottlenecks
4. Optimize slow services
```

### Debug Issues
```
Example: Request failed with 500 error

Without Tracing:
└─ Check 3 different log files manually
   └─ Time: 30 minutes 😫

With Tracing (Now!):
├─ Open Zipkin
├─ Search for the trace
├─ See: "Failed at App B, database timeout"
└─ Time: 2 minutes ✨
```

---

## 🧪 Test Scenario: Multi-Instance Load Balancing

### Make Requests with Multiple Instances

```powershell
# Start 3 App A instances (in different PowerShell windows)

# Window 1: Port 8080
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn spring-boot:run -Dserver.port=8080

# Window 2: Port 8081
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn spring-boot:run -Dserver.port=8081

# Window 3: Port 8082
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn spring-boot:run -Dserver.port=8082

# Then make 10 requests
for ($i = 1; $i -le 10; $i++) {
    Invoke-WebRequest -Uri "http://localhost:9002/api/app-a/status" -UseBasicParsing
    Start-Sleep -Seconds 1
}

# Open Zipkin and see different instances in traces!
```

---

## 💾 Production Settings vs. Learning Settings

### Your Current Settings (Good for Learning)
```yaml
spring:
  sleuth:
    sampler:
      probability: 1.0  # ← Sample EVERY request
  zipkin:
    base-url: http://localhost:9411
```

### For Production (When Scaling)
```yaml
spring:
  sleuth:
    sampler:
      probability: 0.1  # ← Sample 10% of requests
      # Why? 100% sampling = too much data/overhead
      # 10% is enough to see patterns
  zipkin:
    base-url: http://your-zipkin-server:9411
```

---

## 🚀 What's Next?

### Phase 3 Complete! Now What?

**Option A: Continue Learning**
```
├─ Run load balancing tests with traces
├─ Simulate failures and trace them
├─ Understand service dependencies
└─ Learn performance analysis
```

**Option B: Upgrade Infrastructure**
```
├─ Add ELK Stack for centralized logging
├─ Add Kafka for high-volume scenarios
├─ Setup production Zipkin deployment
└─ Configure log aggregation
```

**Option C: Move to Phase 4**
```
├─ Phase 4: Circuit Breaker (Resilience4j)
├─ Handle service failures gracefully
├─ Retry mechanisms
└─ Bulkhead pattern
```

---

## 🆘 Troubleshooting

### Issue 1: Port 9411 Already in Use
```powershell
netstat -ano | findstr :9411
taskkill /PID <PID> /F
java -jar zipkin.jar
```

### Issue 2: Services Not Appearing in Zipkin
```
Check:
1. Zipkin base-url is correct: http://localhost:9411
2. Sleuth probability is 1.0 (not 0)
3. Services are running
4. Maven rebuild completed
5. Services restarted after changes
```

### Issue 3: No Traces Showing
```
1. Make requests first: curl http://localhost:9002/api/app-a/status
2. Wait 5 seconds
3. Refresh Zipkin dashboard
4. Click "Find Traces"
```

### Issue 4: Zipkin Dashboard Blank
```
1. Check http://localhost:9411/health
2. Should show: {"status":"UP"}
3. If error: Zipkin failed to start
4. Check: port 9411 free? Java installed? Enough RAM?
```

---

## ✨ Success Checklist

```
✅ Zipkin JAR downloaded to C:\zipkin
✅ Zipkin running: java -jar zipkin.jar
✅ Dashboard accessible: http://localhost:9411
✅ Dependencies added to all 4 services
✅ application.yml configured for all services
✅ Services rebuilt with mvn clean package
✅ Services started and registering with Eureka
✅ Test requests generating traces
✅ Traces visible in Zipkin dashboard
✅ Service dependencies showing in Zipkin
✅ Can trace requests end-to-end
✅ Can identify bottlenecks
```

---

## 🎯 You're Ready!

**Phase 3 is now LIVE with:**
- ✅ Distributed tracing
- ✅ Request flow visibility
- ✅ Performance analysis
- ✅ Multi-service debugging
- ✅ Zero Docker required!

### Ready to Start? Execute This Right Now:

```powershell
# 1. Download Zipkin
$zipkinUrl = "https://search.maven.org/remote_content?g=io.zipkin.java&a=zipkin-server&v=LATEST&c=exec"
Invoke-WebRequest -Uri $zipkinUrl -OutFile "C:\zipkin\zipkin.jar" -UseBasicParsing

# 2. Start Zipkin
cd C:\zipkin
java -jar zipkin.jar

# 3. In new window, verify
Start-Process "http://localhost:9411"
```

**Then send me a screenshot when you see the Zipkin dashboard!** 🎉

