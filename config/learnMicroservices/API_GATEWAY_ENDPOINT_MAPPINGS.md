# 🌐 API Gateway - Complete Endpoint Mappings

**Gateway URL:** `http://localhost:9002`

All requests should go through the API Gateway on port **9002** instead of directly to services.

---

## 📋 Table of Contents
1. [App A Endpoints](#app-a-endpoints)
2. [App B Endpoints](#app-b-endpoints)
3. [Comparison: Direct vs Gateway](#comparison-direct-vs-gateway)
4. [Testing Guide](#testing-guide)

---

## 🔵 App A Endpoints

### 1. **Resilience Endpoints** (Phase 4 - NEW with Circuit Breaker) ✅

These endpoints have **Circuit Breaker, Retry, Timeout, Bulkhead** protection.

**IMPORTANT:** The ResilienceController uses `@RequestMapping("/api/resilience")`, so gateway URLs need `/api/app-a/api/resilience/**`

#### Via API Gateway (Port 9002):
```bash
# Get App B status with resilience
GET http://localhost:9002/api/app-a/api/resilience/app-b/status

# Get product with resilience
GET http://localhost:9002/api/app-a/api/resilience/app-b/product/101

# Get greeting with resilience
GET http://localhost:9002/api/app-a/api/resilience/app-b/greeting/John

# Async call with resilience
GET http://localhost:9002/api/app-a/api/resilience/app-b/status/async

# View circuit breaker status
GET http://localhost:9002/api/app-a/api/resilience/circuit-breaker/status

# Reset circuit breaker
POST http://localhost:9002/api/app-a/api/resilience/circuit-breaker/reset

# Force circuit breaker state
POST http://localhost:9002/api/app-a/api/resilience/circuit-breaker/state/OPEN
```

#### Direct to Service (Port 8080) - Alternative:
```bash
GET http://localhost:8080/api/resilience/app-b/status
GET http://localhost:8080/api/resilience/circuit-breaker/status
```

**Why the double `/api`?**
- Gateway strips: `/api/app-a` prefix
- Service expects: `/api/resilience` (from `@RequestMapping("/api/resilience")`)
- Therefore: Gateway URL = `/api/app-a` + `/api/resilience` = `/api/app-a/api/resilience/**`

---

### 2. **OLD Controller Endpoints** (No Resilience) ❌

These endpoints have **NO protection** - for comparison only.

#### Via API Gateway (Port 9002):
```bash
# Get greeting (no resilience)
GET http://localhost:9002/api/app-a/greeting/Alice

# Get status (no resilience)
GET http://localhost:9002/api/app-a/status

# Call App B status (no resilience)
GET http://localhost:9002/api/app-a/call-app-b/status

# Call App B product (no resilience)
GET http://localhost:9002/api/app-a/call-app-b/product/101

# Call App B greeting (no resilience)
GET http://localhost:9002/api/app-a/call-app-b/greet/Bob
```

#### Direct to Service (Port 8080) - Alternative:
```bash
GET http://localhost:8080/greeting/Alice
GET http://localhost:8080/status
GET http://localhost:8080/call-app-b/status
```

---

## 🟢 App B Endpoints

All App B endpoints are now accessible via API Gateway.

#### Via API Gateway (Port 9002):
```bash
# Get product by ID
GET http://localhost:9002/api/app-b/product/101

# Health check
GET http://localhost:9002/api/app-b/health

# Status check
GET http://localhost:9002/api/app-b/status

# Greeting endpoint
GET http://localhost:9002/api/app-b/greeting/John

# Call App A status
GET http://localhost:9002/api/app-b/call-app-a/status

# Call App A data
GET http://localhost:9002/api/app-b/call-app-a/data/myKey

# Call App A hello
GET http://localhost:9002/api/app-b/call-app-a/hello/Alice
```

#### Direct to Service (Port 8083) - Alternative:
```bash
GET http://localhost:8083/product/101
GET http://localhost:8083/health
GET http://localhost:8083/status
```

---

## 🔄 Comparison: Direct vs Gateway

### Example: Call App B Status with Resilience

| Access Method | URL | Port | Path Mapping |
|---------------|-----|------|--------------|
| **Via Gateway** (Recommended) | `http://localhost:9002/api/app-a/api/resilience/app-b/status` | 9002 | Gateway strips `/api/app-a` → `/api/resilience/app-b/status` → Matches `@RequestMapping("/api/resilience")` |
| **Direct to Service** | `http://localhost:8080/api/resilience/app-b/status` | 8080 | Direct match with `@RequestMapping("/api/resilience")` |

**Key Concept:**
- OLD Controller: `@RequestMapping("")` → Root path `/`
- NEW Controller: `@RequestMapping("/api/resilience")` → Path `/api/resilience`
- Gateway must preserve the controller's base path after stripping its own prefix

---

## 🧪 Testing Guide

### Test 1: Compare OLD vs NEW Controller (Via Gateway)

**Scenario:** Test with App B DOWN to see the difference

```powershell
# 1. Stop App B

# 2. Test OLD Controller (no resilience) - will hang for 30 seconds
Measure-Command { 
    Invoke-RestMethod -Uri "http://localhost:9002/api/app-a/call-app-b/status" 
}
# Expected: ~30,000ms ❌

# 3. Test NEW Controller (with resilience) - fails fast
Measure-Command { 
    Invoke-RestMethod -Uri "http://localhost:9002/api/app-a/api/resilience/app-b/status" 
}
# Expected: ~3,500ms first time, then < 10ms after circuit opens ✅
```

---

### Test 2: Trigger Circuit Breaker (Via Gateway)

```powershell
# Make 10 requests with App B down
1..10 | ForEach-Object {
    Write-Host "Request $_"
    Measure-Command {
        try {
            Invoke-RestMethod -Uri "http://localhost:9002/api/app-a/api/resilience/app-b/status"
        } catch {}
    } | Select-Object -ExpandProperty TotalMilliseconds
}

# Check circuit breaker status
Invoke-RestMethod -Uri "http://localhost:9002/api/app-a/api/resilience/circuit-breaker/status"
```

**Expected Behavior:**
- First 5 requests: ~3,500ms each (retrying)
- After 5 failures: Circuit OPENS
- Requests 6-10: < 10ms (instant fallback)

---

### Test 3: Gateway Load Balancing

If you have multiple instances of App A or App B:

```bash
# Gateway will automatically load balance
GET http://localhost:9002/api/app-b/status
GET http://localhost:9002/api/app-b/status
GET http://localhost:9002/api/app-b/status
```

Check logs to see requests distributed across instances!

---

### Test 4: Gateway Headers

```powershell
# Check response headers
Invoke-WebRequest -Uri "http://localhost:9002/api/app-a/api/resilience/app-b/status" | 
    Select-Object -ExpandProperty Headers

# Look for:
# X-Gateway-Response: true
# X-Gateway-Route: app-a
```

---

## 📊 Route Summary

| Route ID | Gateway Path | Maps To Service | Controller | Purpose |
|----------|--------------|-----------------|------------|---------|
| `app-a-route` | `/api/app-a/**` | App A `/**` | AppAController (`@RequestMapping("")`) or ResilienceController (`@RequestMapping("/api/resilience")`) | All App A endpoints |
| `app-b-route` | `/api/app-b/**` | App B `/**` | AppBController (`@RequestMapping("")`) | All App B endpoints |

**Total Routes:** 2 (Best Practice - Catch-All Approach)

**Key Examples:**
- `/api/app-a/status` → Strip `/api/app-a` → `/status` → AppAController
- `/api/app-a/api/resilience/app-b/status` → Strip `/api/app-a` → `/api/resilience/app-b/status` → ResilienceController

---

## 🎯 Quick Reference

### For Phase 4 Testing (Resilience Patterns):

**Use these URLs via Gateway:**
```bash
# Circuit Breaker Test (Note the double /api)
http://localhost:9002/api/app-a/api/resilience/app-b/status

# Circuit Breaker Management
http://localhost:9002/api/app-a/api/resilience/circuit-breaker/status
http://localhost:9002/api/app-a/api/resilience/circuit-breaker/reset
```

### For OLD Controller Comparison:

**Use these URLs via Gateway:**
```bash
# No Resilience (will hang if App B is down)
http://localhost:9002/api/app-a/call-app-b/status
```

---

## 🔍 Path Mapping Explanation

### Why `/api/app-a/api/resilience/**`?

**Controller Definitions:**
```java
// OLD Controller - Root path
@RestController
@RequestMapping("")
public class AppAController {
    @GetMapping("/status")  // → Accessible at: /status
}

// NEW Controller - /api/resilience path
@RestController
@RequestMapping("/api/resilience")
public class ResilienceController {
    @GetMapping("/app-b/status")  // → Accessible at: /api/resilience/app-b/status
}
```

**Gateway Routing:**
```yaml
# Gateway strips /api/app-a, forwards the rest
- Path=/api/app-a/**
- RewritePath=/api/app-a(?<segment>/?.*), ${segment}
```

**Mapping Examples:**
```
Gateway URL: /api/app-a/status
  → Strip /api/app-a → /status
  → Service: AppAController ✅

Gateway URL: /api/app-a/api/resilience/app-b/status
  → Strip /api/app-a → /api/resilience/app-b/status
  → Service: ResilienceController ✅
```

---

## 🚀 Benefits of Using API Gateway

1. **Single Entry Point** - One URL to remember (localhost:9002)
2. **Service Discovery** - Gateway automatically finds service instances via Eureka
3. **Load Balancing** - Distributes traffic across multiple instances
4. **Request Tracking** - Gateway adds tracking headers
5. **Centralized Routing** - Easy to modify routes without changing client code
6. **Security Ready** - Can add authentication/authorization in one place (Phase 5)

---

## 📝 Notes

- **Gateway Port:** 9002
- **App A Ports:** 8080, 8081, 8082
- **App B Ports:** 8083, 8084, 8085
- **Eureka Port:** 8761

**Recommendation:** Always use the Gateway URL (port 9002) for all API calls in production-like testing!

---

## 🔧 Troubleshooting

### Gateway shows 503 Service Unavailable
- Check if services are registered in Eureka: `http://localhost:8761`
- Verify service names match: `app-a`, `app-b`
- Check Gateway logs for routing errors

### Route not working
- Check Gateway configuration: `http://localhost:9002/actuator/gateway/routes`
- Verify path pattern matches exactly
- Check logs: `logging.level.org.springframework.cloud.gateway: DEBUG`

---

**Updated:** Phase 4 - Resilience & Fault Tolerance Complete ✅
