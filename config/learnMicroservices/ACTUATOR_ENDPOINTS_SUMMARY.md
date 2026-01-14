# 📊 Actuator Endpoints - What Actually Works

## ❌ What DOESN'T Work

### Circuit Breaker Events Endpoint
```bash
# This returns 404 Not Found
curl http://localhost:8084/actuator/circuitbreakerevents/appBCircuitBreaker
```

**Why?** Spring Boot Actuator doesn't expose circuit breaker **event history** by default. This would require custom implementation.

---

## ✅ What DOES Work

### 1. Health Endpoint
```bash
curl http://localhost:8084/actuator/health
```
**Shows:** Circuit breaker state in health check

### 2. All Metrics List
```bash
curl http://localhost:8084/actuator/metrics
```
**Shows:** All available Resilience4j metrics:
- `resilience4j.circuitbreaker.state`
- `resilience4j.circuitbreaker.calls`
- `resilience4j.circuitbreaker.failure.rate`
- `resilience4j.retry.calls`
- `resilience4j.bulkhead.available.concurrent.calls`
- `resilience4j.ratelimiter.available.permissions`
- And more...

### 3. Circuit Breaker State
```bash
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.state?tag=name:appBCircuitBreaker"
```
**Shows:** Current state (0=CLOSED, 1=OPEN, 2=HALF_OPEN)

### 4. Circuit Breaker Failure Rate
```bash
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.failure.rate?tag=name:appBCircuitBreaker"
```
**Shows:** Current failure percentage

### 5. Circuit Breaker Calls (by type)
```bash
# Successful calls
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:appBCircuitBreaker&tag=kind:successful"

# Failed calls
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:appBCircuitBreaker&tag=kind:failed"

# Not permitted (short circuit)
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:appBCircuitBreaker&tag=kind:not_permitted"
```
**Shows:** Call counts by result type

### 6. Retry Metrics
```bash
curl "http://localhost:8084/actuator/metrics/resilience4j.retry.calls?tag=name:appBRetry&tag=kind:successful_with_retry"
```
**Shows:** Retry statistics

### 7. Bulkhead Metrics
```bash
curl "http://localhost:8084/actuator/metrics/resilience4j.bulkhead.available.concurrent.calls?tag=name:appBBulkhead"
```
**Shows:** Available concurrent call slots

### 8. Rate Limiter Metrics
```bash
curl "http://localhost:8084/actuator/metrics/resilience4j.ratelimiter.available.permissions?tag=name:appBRateLimiter"
```
**Shows:** Available rate limit permissions

---

## 📖 How to See Events

Since actuator doesn't provide event history, use **application logs**:

### Option 1: Watch Logs (PowerShell)
```powershell
Get-Content logs\app-a.log -Wait | Select-String "CIRCUIT BREAKER|RETRY|FALLBACK"
```

### Option 2: Use the Monitoring Script
```powershell
.\monitor-all-metrics.ps1
```
Live dashboard showing all metrics in real-time

### Option 3: Test All Endpoints
```powershell
.\test-actuator-endpoints.ps1
```
Validates all actuator endpoints are working

---

## 🎯 Key Differences

| Feature | Actuator | Application Logs |
|---------|----------|------------------|
| **Current State** | ✅ Yes (metrics) | ❌ No |
| **Event History** | ❌ No | ✅ Yes |
| **Real-time Stats** | ✅ Yes | ❌ No |
| **State Transitions** | ❌ No | ✅ Yes |
| **Call Details** | ✅ Counts only | ✅ Full details |
| **Format** | JSON (API) | Text (logs) |

---

## 💡 Best Practice

**Use BOTH:**
1. **Actuator Metrics** → Monitor current state and statistics
2. **Application Logs** → Debug issues and see event details

**Example Workflow:**
```powershell
# Terminal 1: Watch metrics
.\monitor-all-metrics.ps1

# Terminal 2: Watch events
Get-Content logs\app-a.log -Wait | Select-String "CIRCUIT BREAKER"

# Terminal 3: Run tests
curl http://localhost:8084/api/resilience/app-b/status/cb/test
```

---

## 📚 Updated Guide

The `RESILIENCE_IMPLEMENTATION_GUIDE_FOR_INTERNS.md` has been updated with:
- ✅ Correct actuator endpoints
- ✅ Explanation of what works and what doesn't
- ✅ PowerShell scripts for monitoring
- ✅ Troubleshooting for 404 errors
- ✅ Complete examples with actual responses

---

**Quick Test:**
```powershell
# 1. Test all endpoints
.\test-actuator-endpoints.ps1

# 2. Monitor in real-time
.\monitor-all-metrics.ps1

# 3. Make some calls to generate data
curl http://localhost:8084/api/resilience/app-b/status/cb/test
```

**Perfect for demos! 🚀**
