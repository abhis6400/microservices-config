# 🚀 PHASE 3 IMPLEMENTATION - Sleuth Distributed Tracing

**Date:** January 12, 2026  
**Status:** Ready to Execute  
**Time to Complete:** 30 minutes  
**Approach:** Add Spring Cloud Sleuth for automatic trace ID generation

---

## ✅ What We'll Do

```
Step 1: Add Sleuth dependency to 3 services (5 min)
Step 2: Update logging configuration (5 min)
Step 3: Rebuild services (15 min)
Step 4: Start services (3 min)
Step 5: Test with trace IDs (2 min)
─────────────────────────────────
TOTAL: ~30 minutes to working Phase 3! 🎉
```

---

## 📋 STEP 1: Add Sleuth to API Gateway

### File: api-gateway/pom.xml

**Find this section:**
```xml
        <!-- Spring Boot Actuator (for health checks and monitoring) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
```

**Add AFTER it (before closing `</dependencies>` tag):**
```xml
        <!-- Spring Cloud Sleuth (Distributed Tracing) -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-sleuth</artifactId>
        </dependency>
```

---

## 📋 STEP 2: Add Sleuth to App A

### File: app-a/pom.xml

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
```

---

## 📋 STEP 3: Add Sleuth to App B

### File: app-b/pom.xml

**Same as App A - add the dependency**

---

## 🔧 STEP 4: Update Logging Configuration - API Gateway

### File: api-gateway/src/main/resources/application.yml

**Add at the END of the file:**
```yaml
# ===== DISTRIBUTED TRACING CONFIGURATION (Phase 3) =====
spring:
  sleuth:
    enabled: true
    sampler:
      probability: 1.0  # Sample 100% of requests (for learning)

logging:
  level:
    root: INFO
    org.springframework.web: DEBUG
    org.springframework.cloud: DEBUG
  pattern:
    console: "%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - [TRACE: %X{traceId}] %msg%n"
```

**Explanation:**
- `spring.sleuth.enabled: true` - Enable tracing
- `probability: 1.0` - Trace 100% of requests
- `%X{traceId}` - Add trace ID to every log line

---

## 🔧 STEP 5: Update Logging Configuration - App A

### File: app-a/src/main/resources/application.yml

**Add at the END of the file:**
```yaml
# ===== DISTRIBUTED TRACING CONFIGURATION (Phase 3) =====
spring:
  sleuth:
    enabled: true
    sampler:
      probability: 1.0

logging:
  level:
    root: INFO
    org.springframework.web: DEBUG
    org.springframework.cloud: DEBUG
  pattern:
    console: "%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - [TRACE: %X{traceId}] %msg%n"
```

---

## 🔧 STEP 6: Update Logging Configuration - App B

### File: app-b/src/main/resources/application.yml

**Same as App A - add the configuration**

---

## 🔄 STEP 7: Rebuild All Services

**This is important - rebuild to pick up the new dependencies!**

### Rebuild API Gateway

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\api-gateway
mvn clean package -DskipTests
```

**Expected output:**
```
[INFO] BUILD SUCCESS
[INFO] Total time: 25.123 s
[INFO] Finished at: 2026-01-12T15:30:00+05:30
```

### Rebuild App A

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn clean package -DskipTests
```

### Rebuild App B

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-b
mvn clean package -DskipTests
```

---

## 🎯 STEP 8: Start Services

**Open 5 different PowerShell windows:**

### Window 1: Eureka Server

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\eureka-server
mvn spring-boot:run
```

**Wait 10 seconds for Eureka to start**

### Window 2: App A (Single Instance First)

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn spring-boot:run -Dserver.port=8080
```

### Window 3: App B (Single Instance First)

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-b
mvn spring-boot:run -Dserver.port=8083
```

### Window 4: API Gateway

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\api-gateway
mvn spring-boot:run
```

**Wait 30-60 seconds for all services to start**

---

## 🧪 STEP 9: Make Test Requests

**In a NEW PowerShell window:**

### Test 1: Simple Request to App A

```powershell
Write-Host "Making request to App A..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "http://localhost:9002/api/app-a/status" -UseBasicParsing
```

**Expected:**
```
StatusCode : 200
Content    : {"status":"OK","port":8080}
```

---

### Test 2: Inter-Service Call (App A calls App B)

```powershell
Write-Host "Making inter-service call..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "http://localhost:9002/api/app-a/call-app-b/status" -UseBasicParsing
```

**Expected:**
```
StatusCode : 200
Content    : {"status":"OK from App B","port":8083}
```

---

### Test 3: Generate Multiple Traces

```powershell
# Make 5 requests to generate multiple traces
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Request $i..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "http://localhost:9002/api/app-a/status" -UseBasicParsing | Out-Null
    Start-Sleep -Seconds 1
}

Write-Host "Done!" -ForegroundColor Green
```

---

## 📊 STEP 10: View Traces in Console Logs

**Look at the PowerShell windows where services are running.**

### In App A Console, you should see:

```
15:35:12.345 [http-nio-8080-exec-1] INFO  org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping - [TRACE: 5f4e3d2c1b0a9876] Mapped to public java.lang.String com.masterclass.appa.controller.AppAController.status()
15:35:12.346 [http-nio-8080-exec-1] DEBUG org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter - [TRACE: 5f4e3d2c1b0a9876] Handler execution
15:35:12.347 [http-nio-8080-exec-1] INFO  com.masterclass.appa.controller.AppAController - [TRACE: 5f4e3d2c1b0a9876] Status endpoint called
```

**Notice:** `[TRACE: 5f4e3d2c1b0a9876]` - This is the automatic trace ID!

---

## ✨ Understanding What You're Seeing

### Single Trace ID Across Services

**Request Flow with Trace IDs:**

```
Request to Gateway:
  [TRACE: abc123def456] Gateway received request
  [TRACE: abc123def456] Routing to App A

App A processes:
  [TRACE: abc123def456] Received from Gateway
  [TRACE: abc123def456] Processing request
  [TRACE: abc123def456] Calling App B

App B processes:
  [TRACE: abc123def456] Received from App A
  [TRACE: abc123def456] Processing request
  [TRACE: abc123def456] Sending response

Response back:
  [TRACE: abc123def456] Response to App A
  [TRACE: abc123def456] Response to Gateway
  [TRACE: abc123def456] Sent to client

All logs have SAME trace ID! 🎯
```

---

## 🔍 How to Use Trace IDs for Debugging

### Example 1: Find All Logs for One Request

**Step 1: See an error with trace ID in logs**
```
ERROR: [TRACE: 5f4e3d2c1b0a9876] Request processing failed
```

**Step 2: Search all console logs for this trace ID**
```powershell
# Search in PowerShell (copy logs to file first)
Get-Content app-a.log | Select-String "5f4e3d2c1b0a9876"
```

**Result:** See complete request flow with timestamps!

---

### Example 2: Performance Analysis

**Without Trace IDs:**
```
Gateway logs: Something happened at 15:35:12.345
App A logs: Something happened at 15:35:12.347
App B logs: Something happened at 15:35:12.350

Manual work: Match timestamps, calculate latency 😫
```

**With Trace IDs:**
```
[TRACE: 5f4e3d2c1b0a9876] 15:35:12.345 Gateway
[TRACE: 5f4e3d2c1b0a9876] 15:35:12.347 App A (2ms after gateway)
[TRACE: 5f4e3d2c1b0a9876] 15:35:12.350 App B (3ms after App A)
[TRACE: 5f4e3d2c1b0a9876] 15:35:12.360 Response (10ms after App B)

Automatic! Trace shows entire flow! 🎉
```

---

## 🧪 Test Scenario: Multi-Instance with Tracing

### Now Test with 3 App A Instances

**Window 2a: App A Port 8080**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn spring-boot:run -Dserver.port=8080
```

**Window 2b: App A Port 8081**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn spring-boot:run -Dserver.port=8081
```

**Window 2c: App A Port 8082**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn spring-boot:run -Dserver.port=8082
```

### Make Requests to See Load Balancing + Tracing

```powershell
# Make 10 requests
for ($i = 1; $i -le 10; $i++) {
    Write-Host "Request $i..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "http://localhost:9002/api/app-a/status" -UseBasicParsing | Out-Null
    Start-Sleep -Seconds 1
}
```

**What You'll See:**
- Request 1: Trace goes to App A port 8080
- Request 2: Trace goes to App A port 8081 (different instance!)
- Request 3: Trace goes to App A port 8082 (different instance!)
- Request 4: Back to 8080 (round-robin)
- ...and so on

**Each trace ID shows which instance handled it!**

---

## 📝 What Trace IDs Tell You

```
Trace ID = Unique request identifier

Each trace includes:
├─ Timestamp (when it started)
├─ Service path (which services processed it)
├─ Instance information (which port)
├─ Processing time (milliseconds)
├─ Success/failure status
└─ Error information (if failed)

All correlated by the trace ID across logs!
```

---

## ✅ Success Checklist

```
✅ Sleuth dependency added to 3 services
✅ Logging configuration updated (with trace ID pattern)
✅ Services rebuilt successfully
✅ Eureka running and services registered
✅ Gateway routing requests
✅ Requests generating trace IDs
✅ Trace IDs visible in console logs
✅ Can see complete request path in logs
✅ Load balancing working with different trace IDs
✅ Inter-service calls have same trace ID
```

---

## 🎯 Phase 3 Complete!

```
✅ Distributed tracing enabled
✅ Automatic trace ID generation
✅ Request correlation across services
✅ Performance visibility (timestamps)
✅ Complete request path tracking
✅ Multi-instance support
✅ Ready for production-like testing
```

---

## 📊 What You've Learned

### Before Phase 3
```
Multiple requests scattered across services
Logs in multiple places
Manual debugging: 30-60 minutes
Hard to understand request flow
```

### After Phase 3 (With Sleuth)
```
Every request has unique trace ID
Trace ID in every log line
Related logs easily found
Request flow immediately visible
Debugging: 2-5 minutes
```

---

## 🚀 Next Steps (When You Have Zipkin)

**Later, when you have Docker on another machine:**

1. Download Zipkin
2. Add Zipkin dependency to services
3. Configure `spring.zipkin.base-url`
4. Services automatically send traces to Zipkin
5. Beautiful visual dashboard appears

**But your Phase 3 foundation is READY now!**

---

## 📝 Important Note

**What's happening right now:**
- ✅ Sleuth generates trace IDs
- ✅ Trace IDs propagate across services (automatic)
- ✅ Logs show trace IDs
- ✅ You can correlate logs manually

**What will happen with Zipkin later:**
- ✅ Same trace IDs
- ✅ But Zipkin collects them
- ✅ Visual dashboard instead of manual log search
- ✅ Automatic service dependency graph

**The tracing infrastructure is identical!**

---

## 🎓 Educational Value

You're learning:
- ✅ How distributed tracing works
- ✅ How trace IDs propagate
- ✅ How services correlate requests
- ✅ Why observability is critical
- ✅ Foundation for professional microservices

---

## ✨ Ready?

**Execute in this order:**

1. ✅ Add Sleuth to 3 services (pom.xml) - **5 min**
2. ✅ Update logging config (application.yml) - **5 min**
3. ✅ Rebuild services (mvn clean package) - **15 min**
4. ✅ Start services - **2 min**
5. ✅ Make requests - **1 min**
6. ✅ See trace IDs in logs - **Immediate!**

---

**Ready to start implementing?** 🚀

Reply when you've:
1. Added Sleuth to pom.xml files
2. Updated application.yml files
3. Ready to rebuild

Or let me know if you need help with any step! 💪

