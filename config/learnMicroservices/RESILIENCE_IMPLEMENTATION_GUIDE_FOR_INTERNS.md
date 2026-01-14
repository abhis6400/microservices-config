# 🎓 Phase 4: Resilience Patterns - Complete Implementation Guide

## 📚 **Educational Guide for Interns**

This document explains **step-by-step** how to implement resilience patterns in a Spring Boot microservices application using Resilience4j.

**What you'll learn:**
1. How to add resilience dependencies
2. How to configure resilience patterns in YAML
3. How to create resilient service methods
4. How to implement fallback methods
5. How to add event logging for monitoring
6. How to test resilience patterns

---

## 📋 **Table of Contents**

1. [Overview](#overview)
2. [Step 1: Add Dependencies](#step-1-add-dependencies)
3. [Step 2: Configure Resilience Patterns](#step-2-configure-resilience-patterns)
4. [Step 3: Create Resilient Service](#step-3-create-resilient-service)
5. [Step 4: Implement Fallback Methods](#step-4-implement-fallback-methods)
6. [Step 5: Add Event Monitoring](#step-5-add-event-monitoring)
7. [Step 6: Create Controllers](#step-6-create-controllers)
8. [Testing Your Implementation](#testing-your-implementation)
9. [Common Patterns](#common-patterns)
10. [Troubleshooting](#troubleshooting)

---

## 📖 **Overview**

### What is Resilience?

**Resilience** = Your application's ability to handle failures gracefully.

**Problem:** When Service A calls Service B, and Service B is down:
- ❌ Without resilience: Service A hangs for 30+ seconds, then crashes
- ✅ With resilience: Service A detects failure quickly, retries if needed, or returns graceful error

### The 5 Resilience Patterns

| Pattern | Purpose | Example |
|---------|---------|---------|
| **Circuit Breaker** | Stop calling failing service | After 5 failures, stop trying for 30s |
| **Retry** | Try again on transient failures | Retry 3 times with exponential backoff |
| **Bulkhead** | Limit concurrent calls | Max 10 calls at once |
| **Rate Limiter** | Control request rate | Max 100 requests per second |
| **Time Limiter** | Set maximum wait time | Cancel if takes more than 3 seconds |

---

## 🔧 **Step 1: Add Dependencies**

### File: `pom.xml`

Add these dependencies to your `<dependencies>` section:

```xml
<!-- Resilience4j Spring Boot 3 Starter -->
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-spring-boot3</artifactId>
    <version>2.2.0</version>
</dependency>

<!-- Circuit Breaker -->
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-circuitbreaker</artifactId>
    <version>2.2.0</version>
</dependency>

<!-- Retry -->
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-retry</artifactId>
    <version>2.2.0</version>
</dependency>

<!-- Bulkhead -->
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-bulkhead</artifactId>
    <version>2.2.0</version>
</dependency>

<!-- Rate Limiter -->
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-ratelimiter</artifactId>
    <version>2.2.0</version>
</dependency>

<!-- Time Limiter -->
<dependency>
    <groupId>io.github.resilience4j</groupId>
    <artifactId>resilience4j-timelimiter</artifactId>
    <version>2.2.0</version>
</dependency>

<!-- Spring Cloud Circuit Breaker -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-circuitbreaker-resilience4j</artifactId>
</dependency>

<!-- Spring Boot AOP (Required for Resilience4j) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>

<!-- Spring Boot Actuator (For monitoring) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

**Why these dependencies?**
- `resilience4j-spring-boot3`: Main integration with Spring Boot
- Individual pattern dependencies: Each resilience pattern
- `spring-boot-starter-aop`: Required for `@CircuitBreaker`, `@Retry` annotations
- `spring-boot-starter-actuator`: Exposes health and metrics endpoints

---

## ⚙️ **Step 2: Configure Resilience Patterns**

### File: `src/main/resources/application.yml`

Add this configuration to your `application.yml`:

```yaml
# ============================================================
# RESILIENCE4J CONFIGURATION
# ============================================================

resilience4j:
  
  # ============================================================
  # CIRCUIT BREAKER PATTERN
  # ============================================================
  # Purpose: Stop calling a failing service to prevent cascading failures
  # 
  # How it works:
  # - CLOSED state: Calls go through normally
  # - After X% failures: Opens circuit (rejects calls immediately)
  # - After wait time: Half-opens (tries a few test calls)
  # - If test calls succeed: Closes circuit (back to normal)
  
  circuitbreaker:
    instances:
      appBCircuitBreaker:
        # Sliding window: Track last 10 calls
        slidingWindowSize: 10
        slidingWindowType: COUNT_BASED
        
        # When to open circuit:
        # - Need at least 5 calls in the window
        # - If 50% or more fail, open the circuit
        minimumNumberOfCalls: 5
        failureRateThreshold: 50
        
        # Wait 30 seconds before trying again (HALF_OPEN)
        waitDurationInOpenState: 30s
        
        # In HALF_OPEN state, allow 3 test calls
        permittedNumberOfCallsInHalfOpenState: 3
        
        # Automatically transition from OPEN to HALF_OPEN
        automaticTransitionFromOpenToHalfOpenEnabled: true
        
        # Record these as failures
        recordExceptions:
          - java.io.IOException
          - java.util.concurrent.TimeoutException
          - feign.FeignException$ServiceUnavailable
          - feign.FeignException$InternalServerError
        
        # Ignore these exceptions (don't count as failures)
        ignoreExceptions:
          - feign.FeignException$BadRequest
          - feign.FeignException$NotFound
  
  # ============================================================
  # RETRY PATTERN
  # ============================================================
  # Purpose: Retry failed calls (useful for transient failures)
  # 
  # How it works:
  # - First call fails
  # - Wait 500ms, retry
  # - Wait 1000ms (doubled!), retry
  # - Wait 2000ms (doubled again!), retry
  # - Give up after 3 attempts
  
  retry:
    instances:
      appBRetry:
        # Total attempts: 1 original + 2 retries = 3
        maxAttempts: 3
        
        # Initial wait time before first retry
        waitDuration: 500ms
        
        # Exponential backoff: Double wait time after each retry
        enableExponentialBackoff: true
        exponentialBackoffMultiplier: 2
        
        # Maximum wait time (cap exponential growth)
        exponentialMaxWaitDuration: 5s
        
        # Retry on these exceptions (transient failures)
        retryExceptions:
          - java.io.IOException
          - java.net.SocketTimeoutException
          - java.net.ConnectException
          - feign.RetryableException
          - feign.FeignException$ServiceUnavailable
          - feign.FeignException$InternalServerError
          - feign.FeignException$GatewayTimeout
        
        # Don't retry on these (permanent failures)
        ignoreExceptions:
          - feign.FeignException$BadRequest
          - feign.FeignException$NotFound
          - feign.FeignException$Forbidden
          - feign.FeignException$Unauthorized
  
  # ============================================================
  # BULKHEAD PATTERN
  # ============================================================
  # Purpose: Limit concurrent calls to prevent resource exhaustion
  # 
  # How it works:
  # - Max 10 calls to App B at the same time
  # - 11th caller waits or gets rejected
  # - Prevents thread pool exhaustion
  
  bulkhead:
    instances:
      appBBulkhead:
        # Maximum concurrent calls
        maxConcurrentCalls: 10
        
        # Maximum time to wait for a slot
        maxWaitDuration: 100ms
  
  # ============================================================
  # RATE LIMITER PATTERN
  # ============================================================
  # Purpose: Control the rate of requests
  # 
  # How it works:
  # - Allow 100 requests per 1 second
  # - Reset counter every second
  # - 101st request in same second is rejected
  
  ratelimiter:
    instances:
      appBRateLimiter:
        # Allow 100 requests per refresh period
        limitForPeriod: 100
        
        # Refresh period: 1 second
        limitRefreshPeriod: 1s
        
        # How long to wait for permission (0 = fail immediately)
        timeoutDuration: 0
  
  # ============================================================
  # TIME LIMITER PATTERN
  # ============================================================
  # Purpose: Cancel long-running operations
  # 
  # How it works:
  # - If call takes more than 3 seconds, cancel it
  # - Prevents hanging threads
  
  timelimiter:
    instances:
      appBTimeLimiter:
        # Maximum wait time
        timeoutDuration: 3s
        
        # Cancel the running future if timeout
        cancelRunningFuture: true

# ============================================================
# ACTUATOR ENDPOINTS (For monitoring)
# ============================================================

management:
  endpoints:
    web:
      exposure:
        include: health,metrics,circuitbreakers,circuitbreakerevents
  endpoint:
    health:
      show-details: always
  health:
    circuitbreakers:
      enabled: true
```

**Key Points:**
- Each pattern has an `instances` section where you define named instances
- Use meaningful names (e.g., `appBCircuitBreaker`, `appBRetry`)
- Adjust thresholds based on your requirements
- Add detailed comments so others understand your configuration

### 📊 **How to Access Actuator Endpoints**

After configuring actuator, you can monitor your resilience patterns through HTTP endpoints:

#### **1. Health Endpoint** - Overall application health
```bash
# Basic health check
curl http://localhost:8084/actuator/health

# Response:
{
  "status": "UP",
  "components": {
    "circuitBreakers": {
      "status": "UP",
      "details": {
        "appBCircuitBreaker": {
          "status": "UP",
          "details": {
            "state": "CLOSED",
            "failureRate": "0.0%",
            "slowCallRate": "0.0%",
            "bufferedCalls": 0,
            "failedCalls": 0,
            "slowCalls": 0,
            "notPermittedCalls": 0
          }
        }
      }
    }
  }
}
```

#### **2. Circuit Breakers List** - All circuit breakers
```bash
# Get all circuit breakers
curl http://localhost:8084/actuator/circuitbreakers

# Response:
{
  "circuitBreakers": [
    "appBCircuitBreaker"
  ]
}
```

#### **3. Circuit Breaker Events** - Recent events

**Note:** Circuit breaker events are typically accessed through **application logs** or external monitoring tools, not through a dedicated actuator endpoint. Spring Boot Actuator provides **metrics** (current state) but not **event history** by default.

**To view circuit breaker events, you have two options:**

**Option A: Check Application Logs** (Recommended)
```bash
# Your ResilienceEventConfig logs all events
# Look for these in your application logs:
✅ CIRCUIT BREAKER [appBCircuitBreaker] SUCCESS: Duration: 5ms
⚠️ CIRCUIT BREAKER [appBCircuitBreaker] ERROR recorded
🔴 CIRCUIT BREAKER [appBCircuitBreaker] STATE TRANSITION: CLOSED → OPEN
⚡ CIRCUIT BREAKER [appBCircuitBreaker] SHORT CIRCUIT
```

**Option B: Use Circuit Breaker Metrics** (Current State)
```bash
# Get circuit breaker state (CLOSED, OPEN, HALF_OPEN)
curl http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.state

# Response:
{
  "name": "resilience4j.circuitbreaker.state",
  "measurements": [
    {
      "statistic": "VALUE",
      "value": 0.0  # 0=CLOSED, 1=OPEN, 2=HALF_OPEN
    }
  ],
  "availableTags": [
    {
      "tag": "name",
      "values": ["appBCircuitBreaker"]
    }
  ]
}

# Filter by circuit breaker name
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.state?tag=name:appBCircuitBreaker"

# Get failure rate
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.failure.rate?tag=name:appBCircuitBreaker"
```

#### **4. Metrics Endpoint** - Detailed metrics
```bash
# Get all metrics
curl http://localhost:8084/actuator/metrics

# Response shows ALL available metrics (you'll see these):
{
  "names": [
    # Resilience4j Circuit Breaker Metrics
    "resilience4j.circuitbreaker.buffered.calls",        # Number of calls in sliding window
    "resilience4j.circuitbreaker.calls",                 # Total calls (successful, failed, not_permitted)
    "resilience4j.circuitbreaker.failure.rate",          # Current failure rate percentage
    "resilience4j.circuitbreaker.not.permitted.calls",   # Calls rejected (circuit OPEN)
    "resilience4j.circuitbreaker.slow.call.rate",        # Percentage of slow calls
    "resilience4j.circuitbreaker.slow.calls",            # Number of slow calls
    "resilience4j.circuitbreaker.state",                 # Current state (0=CLOSED, 1=OPEN, 2=HALF_OPEN)
    
    # Resilience4j Retry Metrics
    "resilience4j.retry.calls",                          # Retry call results
    
    # Resilience4j Bulkhead Metrics
    "resilience4j.bulkhead.available.concurrent.calls",  # Available permits
    "resilience4j.bulkhead.max.allowed.concurrent.calls", # Max concurrent calls
    
    # Resilience4j Rate Limiter Metrics
    "resilience4j.ratelimiter.available.permissions",    # Available permissions
    "resilience4j.ratelimiter.waiting_threads",          # Threads waiting for permission
    
    # Resilience4j Time Limiter Metrics
    "resilience4j.timelimiter.calls",                    # Time limiter call results
    
    # Application Metrics
    "http.server.requests",                              # HTTP request metrics
    "jvm.memory.used",                                   # JVM memory usage
    # ... and many more
  ]
}
```

### 📊 **Detailed Metrics Examples**

#### **A. Circuit Breaker State** (Most Important!)
```bash
# Check if circuit is OPEN or CLOSED
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.state?tag=name:appBCircuitBreaker"

# Response:
{
  "name": "resilience4j.circuitbreaker.state",
  "measurements": [
    {
      "statistic": "VALUE",
      "value": 0.0
    }
  ],
  "availableTags": [
    {
      "tag": "name",
      "values": ["appBCircuitBreaker"]
    }
  ]
}

# State values:
# 0.0 = CLOSED (normal operation)
# 1.0 = OPEN (circuit is open, calls rejected)
# 2.0 = HALF_OPEN (testing if service recovered)
```

#### **B. Circuit Breaker Calls** (Success vs Failure)
```bash
# Get all call types
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:appBCircuitBreaker"

# Response:
{
  "name": "resilience4j.circuitbreaker.calls",
  "measurements": [
    {
      "statistic": "COUNT",
      "value": 25.0  # Total calls
    }
  ],
  "availableTags": [
    {
      "tag": "name",
      "values": ["appBCircuitBreaker"]
    },
    {
      "tag": "kind",
      "values": ["successful", "failed", "not_permitted"]
    }
  ]
}

# Get only successful calls
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:appBCircuitBreaker&tag=kind:successful"

# Get only failed calls
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:appBCircuitBreaker&tag=kind:failed"

# Get rejected calls (circuit OPEN)
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:appBCircuitBreaker&tag=kind:not_permitted"
```

#### **C. Circuit Breaker Failure Rate**
```bash
# Get current failure rate
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.failure.rate?tag=name:appBCircuitBreaker"

# Response:
{
  "name": "resilience4j.circuitbreaker.failure.rate",
  "measurements": [
    {
      "statistic": "VALUE",
      "value": 0.0  # 0% failure rate (all calls successful)
      # OR
      "value": 75.0  # 75% failure rate (circuit will open at 50%)
    }
  ]
}

# If value >= 50% (your threshold), circuit will OPEN!
```

#### **D. Retry Metrics**
```bash
# Get retry call results
curl "http://localhost:8084/actuator/metrics/resilience4j.retry.calls?tag=name:appBRetry"

# Response shows available tags:
{
  "availableTags": [
    {
      "tag": "kind",
      "values": [
        "successful_without_retry",  # Succeeded on first attempt
        "successful_with_retry",     # Succeeded after retry
        "failed_without_retry",      # Failed (non-retryable exception)
        "failed_with_retry"          # Failed after all retries
      ]
    }
  ]
}

# Get calls that succeeded after retry
curl "http://localhost:8084/actuator/metrics/resilience4j.retry.calls?tag=name:appBRetry&tag=kind:successful_with_retry"

# Get calls that failed after all retries
curl "http://localhost:8084/actuator/metrics/resilience4j.retry.calls?tag=name:appBRetry&tag=kind:failed_with_retry"
```

#### **E. Bulkhead Metrics**
```bash
# Get available concurrent calls
curl "http://localhost:8084/actuator/metrics/resilience4j.bulkhead.available.concurrent.calls?tag=name:appBBulkhead"

# Response:
{
  "name": "resilience4j.bulkhead.available.concurrent.calls",
  "measurements": [
    {
      "statistic": "VALUE",
      "value": 10.0  # All 10 permits available
      # OR
      "value": 3.0   # Only 3 permits available (7 calls in progress)
    }
  ]
}

# If value = 0, bulkhead is full (next call will be rejected)
```

#### **F. Rate Limiter Metrics**
```bash
# Get available permissions
curl "http://localhost:8084/actuator/metrics/resilience4j.ratelimiter.available.permissions?tag=name:appBRateLimiter"

# Response:
{
  "name": "resilience4j.ratelimiter.available.permissions",
  "measurements": [
    {
      "statistic": "VALUE",
      "value": 100.0  # All 100 permissions available
      # OR
      "value": 0.0    # No permissions (limit reached)
    }
  ]
}

# Resets every second (based on limitRefreshPeriod: 1s)
```

---

### 🎯 **Complete Monitoring Example**

Here's a PowerShell script that monitors ALL resilience metrics:

```powershell
# Save as: monitor-all-metrics.ps1
function Get-MetricValue {
    param([string]$MetricName, [string]$Name, [string]$Kind = $null)
    
    $url = "http://localhost:8084/actuator/metrics/$MetricName`?tag=name:$Name"
    if ($Kind) {
        $url += "&tag=kind:$Kind"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -ErrorAction SilentlyContinue
        return $response.measurements[0].value
    } catch {
        return "N/A"
    }
}

while ($true) {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       RESILIENCE4J METRICS DASHBOARD                        ║" -ForegroundColor Cyan
    Write-Host "║       Time: $(Get-Date -Format 'HH:mm:ss')                              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Circuit Breaker Metrics
    Write-Host "🔴 CIRCUIT BREAKER [appBCircuitBreaker]" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────" -ForegroundColor DarkGray
    
    $state = Get-MetricValue "resilience4j.circuitbreaker.state" "appBCircuitBreaker"
    $stateText = switch ($state) {
        0 { "CLOSED" }
        1 { "OPEN" }
        2 { "HALF_OPEN" }
        default { "UNKNOWN" }
    }
    
    $stateColor = switch ($state) {
        0 { "Green" }
        1 { "Red" }
        2 { "Yellow" }
        default { "Gray" }
    }
    
    Write-Host "  State: " -NoNewline
    Write-Host $stateText -ForegroundColor $stateColor
    
    $failureRate = Get-MetricValue "resilience4j.circuitbreaker.failure.rate" "appBCircuitBreaker"
    $failureRateColor = if ($failureRate -ge 50) { "Red" } elseif ($failureRate -ge 30) { "Yellow" } else { "Green" }
    Write-Host "  Failure Rate: " -NoNewline
    Write-Host "$failureRate%" -ForegroundColor $failureRateColor
    
    $successCalls = Get-MetricValue "resilience4j.circuitbreaker.calls" "appBCircuitBreaker" "successful"
    $failedCalls = Get-MetricValue "resilience4j.circuitbreaker.calls" "appBCircuitBreaker" "failed"
    $notPermitted = Get-MetricValue "resilience4j.circuitbreaker.calls" "appBCircuitBreaker" "not_permitted"
    
    Write-Host "  Successful Calls: " -NoNewline; Write-Host $successCalls -ForegroundColor Green
    Write-Host "  Failed Calls: " -NoNewline; Write-Host $failedCalls -ForegroundColor Red
    Write-Host "  Not Permitted (Short Circuit): " -NoNewline; Write-Host $notPermitted -ForegroundColor Magenta
    Write-Host ""
    
    # Retry Metrics
    Write-Host "🔄 RETRY [appBRetry]" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────" -ForegroundColor DarkGray
    
    $retrySuccess = Get-MetricValue "resilience4j.retry.calls" "appBRetry" "successful_with_retry"
    $retryFailed = Get-MetricValue "resilience4j.retry.calls" "appBRetry" "failed_with_retry"
    
    Write-Host "  Successful After Retry: " -NoNewline; Write-Host $retrySuccess -ForegroundColor Green
    Write-Host "  Failed After Retry: " -NoNewline; Write-Host $retryFailed -ForegroundColor Red
    Write-Host ""
    
    # Bulkhead Metrics
    Write-Host "🏗️ BULKHEAD [appBBulkhead]" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────" -ForegroundColor DarkGray
    
    $availableCalls = Get-MetricValue "resilience4j.bulkhead.available.concurrent.calls" "appBBulkhead"
    $maxCalls = Get-MetricValue "resilience4j.bulkhead.max.allowed.concurrent.calls" "appBBulkhead"
    $inProgress = $maxCalls - $availableCalls
    
    Write-Host "  Available: $availableCalls / $maxCalls"
    Write-Host "  In Progress: " -NoNewline
    Write-Host $inProgress -ForegroundColor $(if ($inProgress -gt 7) { "Yellow" } else { "Green" })
    Write-Host ""
    
    # Rate Limiter Metrics
    Write-Host "⏱️ RATE LIMITER [appBRateLimiter]" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────" -ForegroundColor DarkGray
    
    $availablePermissions = Get-MetricValue "resilience4j.ratelimiter.available.permissions" "appBRateLimiter"
    $permissionColor = if ($availablePermissions -lt 10) { "Red" } elseif ($availablePermissions -lt 50) { "Yellow" } else { "Green" }
    
    Write-Host "  Available Permissions: " -NoNewline
    Write-Host "$availablePermissions / 100" -ForegroundColor $permissionColor
    Write-Host ""
    
    Write-Host "Press Ctrl+C to exit" -ForegroundColor DarkGray
    Start-Sleep -Seconds 2
}
```

**To run:**
```powershell
.\monitor-all-metrics.ps1
```

#### **5. Retry Metrics**
```bash
# Get retry metrics
curl http://localhost:8084/actuator/metrics/resilience4j.retry.calls

# Filter by retry name
curl "http://localhost:8084/actuator/metrics/resilience4j.retry.calls?tag=name:appBRetry&tag=kind:successful_with_retry"
```

#### **6. Bulkhead Metrics**
```bash
# Get bulkhead metrics
curl http://localhost:8084/actuator/metrics/resilience4j.bulkhead.available.concurrent.calls

# Filter by bulkhead name
curl "http://localhost:8084/actuator/metrics/resilience4j.bulkhead.available.concurrent.calls?tag=name:appBBulkhead"
```

#### **7. Rate Limiter Metrics**
```bash
# Get rate limiter metrics
curl http://localhost:8084/actuator/metrics/resilience4j.ratelimiter.available.permissions

# Filter by rate limiter name
curl "http://localhost:8084/actuator/metrics/resilience4j.ratelimiter.available.permissions?tag=name:appBRateLimiter"
```

### 🎯 **Monitoring in Real-Time**

#### **PowerShell Script to Monitor Circuit Breaker State**
```powershell
# Save as monitor-circuit-breaker.ps1
while ($true) {
    Clear-Host
    Write-Host "=== Circuit Breaker Status ===" -ForegroundColor Cyan
    Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""
    
    $health = Invoke-RestMethod -Uri "http://localhost:8084/actuator/health" -Method Get
    $cbStatus = $health.components.circuitBreakers.details.appBCircuitBreaker.details
    
    Write-Host "State: " -NoNewline
    switch ($cbStatus.state) {
        "CLOSED" { Write-Host $cbStatus.state -ForegroundColor Green }
        "OPEN" { Write-Host $cbStatus.state -ForegroundColor Red }
        "HALF_OPEN" { Write-Host $cbStatus.state -ForegroundColor Yellow }
    }
    
    Write-Host "Failure Rate: $($cbStatus.failureRate)"
    Write-Host "Buffered Calls: $($cbStatus.bufferedCalls)"
    Write-Host "Failed Calls: $($cbStatus.failedCalls)"
    Write-Host "Not Permitted Calls: $($cbStatus.notPermittedCalls)"
    
    Start-Sleep -Seconds 2
}
```

#### **Watch Application Logs in Real-Time**
```powershell
# Save as: watch-logs.ps1
# This watches your application log file for resilience events

$logFile = ".\logs\app-a.log"  # Adjust path to your log file

Write-Host "Watching logs for resilience events..." -ForegroundColor Cyan
Write-Host "Log file: $logFile" -ForegroundColor Gray
Write-Host "Press Ctrl+C to exit" -ForegroundColor Gray
Write-Host ""

Get-Content $logFile -Wait -Tail 20 | Where-Object {
    $_ -match "CIRCUIT BREAKER|RETRY|BULKHEAD|RATE LIMITER|FALLBACK"
} | ForEach-Object {
    # Color code based on event type
    if ($_ -match "SUCCESS") {
        Write-Host $_ -ForegroundColor Green
    } elseif ($_ -match "ERROR|FAILED|EXHAUSTED") {
        Write-Host $_ -ForegroundColor Red
    } elseif ($_ -match "STATE TRANSITION|RETRY") {
        Write-Host $_ -ForegroundColor Yellow
    } elseif ($_ -match "SHORT CIRCUIT|NOT PERMITTED") {
        Write-Host $_ -ForegroundColor Magenta
    } elseif ($_ -match "FALLBACK") {
        Write-Host $_ -ForegroundColor Cyan
    } else {
        Write-Host $_
    }
}
```

### 📈 **Understanding Metrics Tags**

#### **Circuit Breaker Call Types:**
- `successful`: Call completed successfully
- `failed`: Call failed (exception thrown)
- `not_permitted`: Call rejected by circuit breaker (circuit is OPEN)

#### **Retry Call Types:**
- `successful_without_retry`: First attempt succeeded
- `successful_with_retry`: Succeeded after retry
- `failed_without_retry`: Failed without retry (non-retryable exception)
- `failed_with_retry`: Failed after all retries

#### **Example: Get All Failed Calls**
```bash
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:appBCircuitBreaker&tag=kind:failed"
```

### 🔍 **Troubleshooting Actuator Endpoints**

#### **Issue 1: Circuit Breaker Events Endpoint Returns 404**

**Symptom:**
```bash
curl http://localhost:8084/actuator/circuitbreakerevents/appBCircuitBreaker
# Returns: 404 Not Found
```

**Explanation:**
Circuit breaker **events** (historical event list) are not exposed by Spring Boot Actuator by default. Actuator provides **metrics** (current state) but not event history.

**Solutions:**

**Option A: Use Metrics Instead** (Recommended)
```bash
# Get current circuit breaker state
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.state?tag=name:appBCircuitBreaker"

# Get failure rate
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.failure.rate?tag=name:appBCircuitBreaker"

# Get call counts
curl "http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:appBCircuitBreaker&tag=kind:failed"
```

**Option B: Check Application Logs**
Your `ResilienceEventConfig` logs all events:
```bash
# Linux/Mac
tail -f logs/app-a.log | grep "CIRCUIT BREAKER"

# Windows PowerShell
Get-Content logs\app-a.log -Wait | Select-String "CIRCUIT BREAKER"
```

**Option C: Enable Event Endpoint** (Advanced - Requires Custom Configuration)
To expose circuit breaker events, you need to add custom actuator endpoints. This is beyond basic setup.

---

#### **Issue 2: 404 Not Found on /actuator**
```bash
# Check if actuator is enabled
curl http://localhost:8084/actuator

# Should return list of available endpoints
```

**Solution:** Verify `management.endpoints.web.exposure.include` in `application.yml`

#### **Issue: No circuitbreakers endpoint**
**Solution:** Add to `application.yml`:
```yaml
management:
  health:
    circuitbreakers:
      enabled: true
```

#### **Issue: Health shows DOWN**
```bash
curl http://localhost:8084/actuator/health
```

Check the circuit breaker state - if OPEN, it might show as DOWN depending on configuration.

---

## 🔨 **Step 3: Create Resilient Service**

### 🆔 **Understanding Trace IDs (MDC)**

Before creating the service, let's understand **Trace IDs** and **MDC**:

#### **What is MDC?**

**MDC = Mapped Diagnostic Context** (from SLF4J logging framework)

- Thread-local storage for logging context
- Stores key-value pairs (like a Map)
- Automatically available in all log statements
- Useful for tracking requests across multiple services

#### **What is a Trace ID?**

A **Trace ID** is a unique identifier for a single request/transaction:

```
Example: 7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a
```

**Purpose:**
- Track a single request across multiple services
- Correlate logs from different microservices
- Debug distributed systems
- Monitor performance across services

#### **How it Works:**

```
User Request → API Gateway (generates traceId) → Service A → Service B → Service C
              [traceId: abc123]      [traceId: abc123] [traceId: abc123]
```

All logs for this request will have `[traceId: abc123]` making it easy to trace the entire flow!

#### **Code Example:**

```java
// Setting trace ID (usually done in a filter)
MDC.put("traceId", UUID.randomUUID().toString());

// Getting trace ID (in any method)
String traceId = MDC.get("traceId");

// Using in logs
logger.info("[TRACE: {}] Processing request", traceId);
// Output: [TRACE: 7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a] Processing request

// Removing trace ID (important!)
MDC.remove("traceId");
// Or clear all
MDC.clear();
```

#### **Setting Up Trace ID Filter:**

Create this filter to automatically add trace ID to all requests:

```java
package com.yourpackage.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.UUID;

/**
 * Filter that adds a unique trace ID to each request
 * 
 * This trace ID:
 * - Is automatically added to all log statements
 * - Can be used to track requests across services
 * - Helps with debugging and monitoring
 */
@Component
public class TraceIdFilter implements Filter {

    private static final String TRACE_ID_HEADER = "X-Trace-Id";
    private static final String MDC_TRACE_ID_KEY = "traceId";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        
        try {
            // Check if trace ID already exists in header (from gateway)
            String traceId = httpRequest.getHeader(TRACE_ID_HEADER);
            
            // If not, generate new one
            if (traceId == null || traceId.isEmpty()) {
                traceId = UUID.randomUUID().toString();
            }
            
            // Store in MDC (thread-local storage)
            MDC.put(MDC_TRACE_ID_KEY, traceId);
            
            // Continue with the request
            chain.doFilter(request, response);
            
        } finally {
            // IMPORTANT: Clear MDC after request completes
            // (prevents memory leaks in thread pools)
            MDC.clear();
        }
    }
}
```

#### **Configuring Logback to Show Trace ID:**

Update `src/main/resources/logback-spring.xml`:

```xml
<configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>
                %d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} [TraceId:%X{traceId}] - %msg%n
            </pattern>
        </encoder>
    </appender>
    
    <root level="INFO">
        <appender-ref ref="CONSOLE" />
    </root>
</configuration>
```

**Log Output:**
```
2026-01-14 10:30:45.123 [http-nio-8084-exec-1] INFO  c.m.a.service.AppBResilientService [TraceId:7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a] - Calling App B status endpoint
2026-01-14 10:30:45.456 [http-nio-8084-exec-1] WARN  c.m.a.service.AppBResilientService [TraceId:7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a] - [FALLBACK] Using fallback
```

Now you can search logs for `7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a` and see the entire request flow!

📚 **Want more details?** Read [`TRACE_ID_EXPLAINED.md`](TRACE_ID_EXPLAINED.md) for:
- Visual diagrams of trace ID flow
- Complete code examples
- Feign client integration
- Real-world use cases
- Best practices and pitfalls

#### **Benefits of Using Trace IDs:**

| Benefit | Example |
|---------|---------|
| **Debugging** | Find all logs for one failed request |
| **Performance** | Track request duration across services |
| **Monitoring** | Count errors per trace ID |
| **Correlation** | See which services were called |
| **User Support** | User reports error, you search by trace ID |

#### **Real-World Example:**

**Scenario:** User reports "My order failed"

**Without Trace ID:**
```
❌ Have to search through millions of logs
❌ Hard to find specific user's request
❌ Can't see full flow across services
```

**With Trace ID:**
```
✅ User provides trace ID (from error page)
✅ Search logs: grep "7f5a3b2c" logs/*.log
✅ See entire flow: Gateway → Order Service → Payment Service → Inventory Service
✅ Find exact failure point: Payment Service timeout
```

---

### File: `src/main/java/com/yourpackage/service/AppBResilientService.java`

Create a service class that applies resilience patterns:

```java
package com.masterclass.appa.service;

import com.masterclass.appa.clients.AppBClient;
import com.masterclass.appa.clients.AppBClientFallback;
import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.ratelimiter.annotation.RateLimiter;
import io.github.resilience4j.retry.annotation.Retry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Service;

@Service
public class AppBResilientService {

    private static final Logger logger = LoggerFactory.getLogger(AppBResilientService.class);
    
    // Instance names must match those in application.yml
    private static final String CIRCUIT_BREAKER_NAME = "appBCircuitBreaker";
    private static final String RETRY_NAME = "appBRetry";
    private static final String BULKHEAD_NAME = "appBBulkhead";
    private static final String RATE_LIMITER_NAME = "appBRateLimiter";
    
    private final AppBClient appBClient;
    private final AppBClientFallback fallback;
    
    public AppBResilientService(AppBClient appBClient, AppBClientFallback fallback) {
        this.appBClient = appBClient;
        this.fallback = fallback;
    }
    
    /**
     * PATTERN 1: WITH FALLBACK (Graceful Degradation)
     * ================================================
     * 
     * This method demonstrates graceful degradation:
     * - Fast response even when service is down
     * - Returns degraded/cached data instead of error
     * - User-friendly (200 OK always)
     * 
     * Trade-off: Retry won't work (fallback prevents it)
     * 
     * Annotation Order (CRITICAL!):
     * @Retry - Outermost (but won't retry because fallback succeeds)
     * @CircuitBreaker - Won't open (fallback succeeds)
     * @RateLimiter - Controls rate
     * @Bulkhead - Innermost, has fallback
     */
    @Retry(name = RETRY_NAME)
    @CircuitBreaker(name = CIRCUIT_BREAKER_NAME)
    @RateLimiter(name = RATE_LIMITER_NAME)
    @Bulkhead(name = BULKHEAD_NAME, fallbackMethod = "getStatusFallback")
    public String getAppBStatus() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Calling App B status endpoint with resilience patterns", traceId);
        
        return appBClient.getAppBStatus();
    }
    
    /**
     * Fallback method for getAppBStatus()
     * 
     * IMPORTANT: 
     * - Method signature must match original method (except add Exception parameter)
     * - Must be in same class
     * - Can have multiple fallback methods for different exception types
     */
    public String getStatusFallback(Exception ex) {
        String traceId = MDC.get("traceId");
        logger.warn("[FALLBACK] [TRACE: {}] getAppBStatus failed: {}. Using fallback.", 
            traceId, ex.getClass().getSimpleName());
        
        // Return degraded response
        return fallback.getAppBStatus();
    }
    
    /**
     * PATTERN 2: WITHOUT FALLBACK (Retry + Circuit Breaker)
     * ======================================================
     * 
     * This method demonstrates retry and circuit breaker:
     * - Retries 3 times with exponential backoff
     * - Circuit breaker opens after threshold failures
     * - Returns error to caller after all retries
     * 
     * Trade-off: Slower (waits for retries), error response
     * 
     * Annotation Order (CRITICAL!):
     * @Retry - Outermost (WILL retry because no fallback)
     * @CircuitBreaker - WILL open (sees failures)
     * @RateLimiter - Controls rate
     * @Bulkhead - Innermost, NO fallback
     */
    @Retry(name = RETRY_NAME)
    @CircuitBreaker(name = CIRCUIT_BREAKER_NAME)
    @RateLimiter(name = RATE_LIMITER_NAME)
    @Bulkhead(name = BULKHEAD_NAME)
    public String getAppBStatusWithRetry() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Calling App B status (NO FALLBACK - retry enabled)", traceId);
        
        return appBClient.getAppBStatus();
    }
}
```

**Key Concepts:**

### 1. **Annotation Order Matters!**

Resilience4j executes annotations in this order (from official docs):
```
Retry ( CircuitBreaker ( RateLimiter ( TimeLimiter ( Bulkhead ( Function ) ) ) ) )
```

Think of it like nested parentheses:
- **Retry is outermost** - Catches exceptions from all inner patterns
- **Bulkhead is innermost** - Closest to the actual call

### 2. **Fallback Method Rules:**

✅ **Correct:**
```java
// Original method
public String doSomething() { ... }

// Fallback method - adds Exception parameter
public String doSomethingFallback(Exception ex) { ... }
```

❌ **Wrong:**
```java
// Different return type
public Integer doSomethingFallback(Exception ex) { ... }

// Different name
public String somethingElseFallback(Exception ex) { ... }

// In different class
// (must be in same class)
```

### 3. **With Fallback vs Without Fallback:**

| Aspect | With Fallback | Without Fallback |
|--------|---------------|------------------|
| **Response Time** | Fast (~5ms) | Slow (~15s with retries) |
| **Response Status** | 200 OK | 500 Error |
| **Retry** | NO (fallback prevents it) | YES (3 attempts) |
| **Circuit Opens** | NO (fallback succeeds) | YES (after failures) |
| **Use Case** | User-facing | Critical/Testing |

---

## 🎯 **Step 4: Implement Fallback Methods**

### File: `src/main/java/com/yourpackage/clients/AppBClientFallback.java`

Create a fallback class that provides degraded responses:

```java
package com.masterclass.appa.clients;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Fallback implementation for AppBClient
 * 
 * Purpose: Provide degraded/cached responses when App B is unavailable
 * 
 * This is called when:
 * - App B is down
 * - App B is too slow (timeout)
 * - Network issues
 * - Circuit breaker is OPEN
 */
@Component
public class AppBClientFallback {

    private static final Logger logger = LoggerFactory.getLogger(AppBClientFallback.class);
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    /**
     * Fallback for status check
     * 
     * Returns degraded status indicating service issues
     */
    public String getAppBStatus() {
        String traceId = MDC.get("traceId");
        logger.warn("[FALLBACK] [TRACE: {}] App B status check failed. Using fallback response.", traceId);
        
        try {
            // Create degraded response
            var response = objectMapper.createObjectNode();
            response.put("status", "DEGRADED");
            response.put("message", "Service temporarily unavailable. Using cached data.");
            response.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_DATE_TIME));
            response.put("source", "fallback");
            response.put("traceId", traceId);
            
            return objectMapper.writeValueAsString(response);
        } catch (Exception e) {
            logger.error("Error creating fallback response", e);
            return "{\"status\":\"DEGRADED\",\"message\":\"Service unavailable\"}";
        }
    }
    
    /**
     * Fallback for product lookup
     * 
     * Returns cached/default product information
     */
    public String getProduct(String productId) {
        String traceId = MDC.get("traceId");
        logger.warn("[FALLBACK] [TRACE: {}] Product lookup failed for: {}. Using cached data.", traceId, productId);
        
        try {
            var response = objectMapper.createObjectNode();
            response.put("productId", productId);
            response.put("name", "Product information temporarily unavailable");
            response.put("message", "Using cached data. Product details may be outdated.");
            response.put("cached", true);
            response.put("source", "fallback");
            
            return objectMapper.writeValueAsString(response);
        } catch (Exception e) {
            logger.error("Error creating product fallback", e);
            return "{\"error\":\"Product unavailable\"}";
        }
    }
    
    /**
     * Fallback for greeting
     * 
     * Returns default greeting
     */
    public String getGreeting(String name) {
        String traceId = MDC.get("traceId");
        logger.warn("[FALLBACK] [TRACE: {}] Greeting service failed for: {}. Using default greeting.", traceId, name);
        
        try {
            var response = objectMapper.createObjectNode();
            response.put("greeting", "Hello " + name + "!");
            response.put("message", "Using default greeting. Personalized greeting service unavailable.");
            response.put("source", "fallback");
            
            return objectMapper.writeValueAsString(response);
        } catch (Exception e) {
            logger.error("Error creating greeting fallback", e);
            return "{\"greeting\":\"Hello!\"}";
        }
    }
}
```

**Key Points:**
- Fallback class is a regular Spring `@Component`
- Methods should return the same type as the original methods
- Log warnings so you know fallback was used
- Include trace ID for debugging
- Mark response as "degraded" or "cached" so clients know

---

## 📊 **Step 5: Add Event Monitoring**

### File: `src/main/java/com/yourpackage/config/ResilienceEventConfig.java`

Create a configuration class to log resilience events:

```java
package com.masterclass.appa.config;

import io.github.resilience4j.bulkhead.Bulkhead;
import io.github.resilience4j.bulkhead.BulkheadRegistry;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.ratelimiter.RateLimiter;
import io.github.resilience4j.ratelimiter.RateLimiterRegistry;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration for Resilience4j Event Monitoring
 * 
 * Purpose: Log all resilience events for debugging and monitoring
 * 
 * This class registers event listeners for:
 * - Circuit Breaker state changes
 * - Retry attempts
 * - Bulkhead events
 * - Rate limiter events
 */
@Configuration
public class ResilienceEventConfig {

    private static final Logger logger = LoggerFactory.getLogger(ResilienceEventConfig.class);
    
    /**
     * Register Circuit Breaker event listeners
     * 
     * Logs:
     * - State transitions (CLOSED → OPEN → HALF_OPEN)
     * - Success/Failure events
     * - Error details
     */
    @Bean
    public void registerCircuitBreakerEventListeners(CircuitBreakerRegistry registry) {
        logger.info("🔧 PHASE 4: Registering Resilience Event Listeners");
        
        registry.getAllCircuitBreakers().forEach(circuitBreaker -> {
            String name = circuitBreaker.getName();
            logger.info("Registering event listeners for Circuit Breaker: {} ✅", name);
            
            circuitBreaker.getEventPublisher()
                // State transition: CLOSED → OPEN
                .onStateTransition(event -> {
                    logger.warn("🔴 CIRCUIT BREAKER [{}] STATE TRANSITION\n" +
                        "   From: {} → To: {}\n" +
                        "   Reason: {}",
                        name,
                        event.getStateTransition().getFromState(),
                        event.getStateTransition().getToState(),
                        getTransitionReason(event.getStateTransition().getFromState(), 
                                          event.getStateTransition().getToState()));
                })
                
                // Successful call
                .onSuccess(event -> {
                    logger.debug("✅ CIRCUIT BREAKER [{}] SUCCESS: Duration: {}ms",
                        name, event.getElapsedDuration().toMillis());
                })
                
                // Failed call (error recorded)
                .onError(event -> {
                    logger.warn("⚠️ CIRCUIT BREAKER [{}] ERROR recorded\n" +
                        "   Exception: {}\n" +
                        "   Duration: {}ms\n" +
                        "   Current Failure Rate: {}%",
                        name,
                        event.getThrowable().getClass().getSimpleName(),
                        event.getElapsedDuration().toMillis(),
                        circuitBreaker.getMetrics().getFailureRate());
                })
                
                // Call rejected (circuit is OPEN)
                .onCallNotPermitted(event -> {
                    logger.warn("⚡ CIRCUIT BREAKER [{}] SHORT CIRCUIT\n" +
                        "   State: {}\n" +
                        "   Action: Call not permitted",
                        name,
                        circuitBreaker.getState());
                });
        });
    }
    
    /**
     * Register Retry event listeners
     * 
     * Logs:
     * - Each retry attempt
     * - Retry exhaustion
     * - Success after retry
     */
    @Bean
    public void registerRetryEventListeners(RetryRegistry registry) {
        registry.getAllRetries().forEach(retry -> {
            String name = retry.getName();
            logger.info("Registering event listeners for Retry: {} ✅", name);
            
            retry.getEventPublisher()
                // Each retry attempt
                .onRetry(event -> {
                    logger.warn("🔄 RETRY [{}] Attempt {} of {}\n" +
                        "   Exception: {}\n" +
                        "   Wait before next: Will use exponential backoff",
                        name,
                        event.getNumberOfRetryAttempts(),
                        retry.getRetryConfig().getMaxAttempts(),
                        event.getLastThrowable().getClass().getSimpleName());
                })
                
                // Retry succeeded
                .onSuccess(event -> {
                    if (event.getNumberOfRetryAttempts() > 0) {
                        logger.info("✅ RETRY [{}] SUCCEEDED after {} attempts",
                            name, event.getNumberOfRetryAttempts());
                    }
                })
                
                // All retries exhausted
                .onError(event -> {
                    logger.error("❌ RETRY [{}] EXHAUSTED after {} attempts\n" +
                        "   Final Exception: {}\n" +
                        "   Action: Fallback will be used",
                        name,
                        event.getNumberOfRetryAttempts(),
                        event.getLastThrowable().getClass().getSimpleName());
                })
                
                // Exception ignored (not retryable)
                .onIgnoredError(event -> {
                    logger.debug("🚫 RETRY [{}] IGNORED: {} (not retryable)",
                        name, event.getLastThrowable().getClass().getSimpleName());
                });
        });
    }
    
    /**
     * Register Bulkhead event listeners
     * 
     * Logs:
     * - Call permitted
     * - Call rejected (bulkhead full)
     * - Call finished
     */
    @Bean
    public void registerBulkheadEventListeners(BulkheadRegistry registry) {
        registry.getAllBulkheads().forEach(bulkhead -> {
            String name = bulkhead.getName();
            logger.info("Registering event listeners for Bulkhead: {} ✅", name);
            
            bulkhead.getEventPublisher()
                // Call permitted
                .onCallPermitted(event -> {
                    logger.debug("🟢 BULKHEAD [{}] PERMITTED: Available permits: {}",
                        name, bulkhead.getMetrics().getAvailableConcurrentCalls());
                })
                
                // Call rejected (bulkhead full)
                .onCallRejected(event -> {
                    logger.warn("🔴 BULKHEAD [{}] REJECTED: No available permits\n" +
                        "   Max concurrent: {}\n" +
                        "   Current: {}",
                        name,
                        bulkhead.getBulkheadConfig().getMaxConcurrentCalls(),
                        bulkhead.getMetrics().getAvailableConcurrentCalls());
                })
                
                // Call finished
                .onCallFinished(event -> {
                    logger.debug("🟢 BULKHEAD [{}] FINISHED: Available permits now: {}",
                        name, bulkhead.getMetrics().getAvailableConcurrentCalls());
                });
        });
    }
    
    /**
     * Register Rate Limiter event listeners
     * 
     * Logs:
     * - Call permitted
     * - Call rejected (rate limit exceeded)
     */
    @Bean
    public void registerRateLimiterEventListeners(RateLimiterRegistry registry) {
        registry.getAllRateLimiters().forEach(rateLimiter -> {
            String name = rateLimiter.getName();
            logger.info("Registering event listeners for RateLimiter: {} ✅", name);
            
            rateLimiter.getEventPublisher()
                // Call permitted
                .onSuccess(event -> {
                    logger.debug("🟢 RATE LIMITER [{}] PERMITTED: Available: {}",
                        name, rateLimiter.getMetrics().getAvailablePermissions());
                })
                
                // Call rejected (rate limit exceeded)
                .onFailure(event -> {
                    logger.warn("🔴 RATE LIMITER [{}] REJECTED: Rate limit exceeded\n" +
                        "   Limit: {} per {}\n" +
                        "   Available: {}",
                        name,
                        rateLimiter.getRateLimiterConfig().getLimitForPeriod(),
                        rateLimiter.getRateLimiterConfig().getLimitRefreshPeriod(),
                        rateLimiter.getMetrics().getAvailablePermissions());
                });
        });
    }
    
    /**
     * Helper method to explain state transitions
     */
    private String getTransitionReason(CircuitBreaker.State from, CircuitBreaker.State to) {
        if (from == CircuitBreaker.State.CLOSED && to == CircuitBreaker.State.OPEN) {
            return "Failure rate threshold exceeded";
        } else if (from == CircuitBreaker.State.OPEN && to == CircuitBreaker.State.HALF_OPEN) {
            return "Wait duration elapsed, testing service";
        } else if (from == CircuitBreaker.State.HALF_OPEN && to == CircuitBreaker.State.CLOSED) {
            return "Test calls succeeded, service recovered";
        } else if (from == CircuitBreaker.State.HALF_OPEN && to == CircuitBreaker.State.OPEN) {
            return "Test calls failed, service still down";
        }
        return "State changed";
    }
}
```

**What This Does:**
- Registers listeners for ALL resilience patterns
- Logs events with emoji for easy identification (🔴🟢🔄⚡)
- Provides detailed information about each event
- Helps with debugging and monitoring

**Emoji Legend:**
- 🔴 Error/Rejection/Open
- 🟢 Success/Permitted/Closed
- 🔄 Retry
- ⚡ Short circuit
- ✅ Success
- ❌ Failure

---

## 🎮 **Step 6: Create Controllers**

### File: `src/main/java/com/yourpackage/controller/ResilienceController.java`

Create a controller to expose your resilient endpoints:

```java
package com.masterclass.appa.controller;

import com.masterclass.appa.service.AppBResilientService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for resilient API endpoints
 * 
 * This controller demonstrates two patterns:
 * 1. WITH fallback: Graceful degradation (fast, user-friendly)
 * 2. WITHOUT fallback: Retry + circuit breaker (accurate, visible failures)
 */
@RestController
@RequestMapping("/api/resilience")
public class ResilienceController {

    private static final Logger logger = LoggerFactory.getLogger(ResilienceController.class);
    
    private final AppBResilientService resilientService;
    
    public ResilienceController(AppBResilientService resilientService) {
        this.resilientService = resilientService;
    }
    
    /**
     * PATTERN 1: WITH FALLBACK (Graceful Degradation)
     * ================================================
     * 
     * Endpoint: GET /api/resilience/app-b/status
     * 
     * Behavior:
     * - Always returns 200 OK (even when App B is down)
     * - Fast response (~5ms)
     * - Returns degraded/cached data when service is down
     * - NO retry (fallback prevents it)
     * - Circuit breaker stays CLOSED (fallback succeeds)
     * 
     * Use Case: User-facing endpoints, dashboards, monitoring
     */
    @GetMapping("/app-b/status")
    public ResponseEntity<String> getAppBStatus() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Resilient call to App B status", traceId);
        
        String result = resilientService.getAppBStatus();
        return ResponseEntity.ok(result);
    }
    
    /**
     * PATTERN 2: WITHOUT FALLBACK (Retry + Circuit Breaker)
     * ======================================================
     * 
     * Endpoint: GET /api/resilience/app-b/status/cb/test
     * 
     * Behavior:
     * - Returns error when App B is down (500 after retries)
     * - Slow response (~15s with retries)
     * - Retries 3 times with exponential backoff
     * - Circuit breaker OPENS after failures
     * - Subsequent calls are instant (<5ms) when circuit is OPEN
     * 
     * Use Case: Testing, critical operations, internal APIs
     */
    @GetMapping("/app-b/status/cb/test")
    public ResponseEntity<String> circuitBreakerTest() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] [CB_TEST] Circuit breaker test call (NO FALLBACK)", traceId);
        
        try {
            String result = resilientService.getAppBStatusWithRetry();
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            // No fallback - return error to caller
            logger.error("[TRACE: {}] [CB_TEST] Call failed after all retries: {}", 
                traceId, e.getMessage());
            return ResponseEntity
                .status(500)
                .body("{\"error\":\"Service unavailable after retries\"}");
        }
    }
    
    /**
     * Get product with resilience
     */
    @GetMapping("/app-b/product/{productId}")
    public ResponseEntity<String> getProduct(@PathVariable String productId) {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Resilient call to get product: {}", traceId, productId);
        
        String result = resilientService.getProduct(productId);
        return ResponseEntity.ok(result);
    }
    
    /**
     * Get greeting with resilience
     */
    @GetMapping("/app-b/greeting/{name}")
    public ResponseEntity<String> getGreeting(@PathVariable String name) {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Resilient call to get greeting for: {}", traceId, name);
        
        String result = resilientService.getGreeting(name);
        return ResponseEntity.ok(result);
    }
}
```

**Controller Best Practices:**
- Keep controllers thin - business logic in services
- Log all requests with trace ID
- Document each endpoint clearly
- Handle exceptions appropriately
- Return meaningful HTTP status codes

---

## 🧪 **Testing Your Implementation**

### Test 1: Verify Application Starts

```bash
mvn clean package -DskipTests
java -jar target/your-app.jar
```

**Look for in logs:**
```
🔧 PHASE 4: Registering Resilience Event Listeners
Registering event listeners for Circuit Breaker: appBCircuitBreaker ✅
Registering event listeners for Retry: appBRetry ✅
Registering event listeners for Bulkhead: appBBulkhead ✅
Registering event listeners for RateLimiter: appBRateLimiter ✅
```

### Test 1.5: Verify Actuator Endpoints Work

**Run the actuator test script:**
```powershell
.\test-actuator-endpoints.ps1
```

**This will test all 10 actuator endpoints and show:**
- ✅ Which endpoints are working
- Current circuit breaker state
- Failure rates
- Call counts (successful, failed, not permitted)
- Retry metrics
- Bulkhead availability
- Rate limiter permissions

**Expected output:**
```
✅ All working endpoints tested!

📌 Key Endpoints to Monitor:
   • Health:           http://localhost:8084/actuator/health
   • CB State:         http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.state
   • CB Failure Rate:  http://localhost:8084/actuator/metrics/resilience4j.circuitbreaker.failure.rate
```

### Test 2: Test WITH Fallback (Fast, Graceful)

**Stop App B** (simulate failure)

```bash
curl http://localhost:8084/api/resilience/app-b/status
```

**Expected:**
- Response time: ~5ms
- HTTP Status: 200 OK
- Response body: Degraded status message
- Logs show: "✅ CIRCUIT BREAKER SUCCESS"
- Logs show: "[FALLBACK] Using fallback"
- NO retry logs

### Test 3: Test WITHOUT Fallback (Slow, Retry)

**Stop App B** (simulate failure)

```bash
curl http://localhost:8084/api/resilience/app-b/status/cb/test
```

**Expected:**
- Response time: ~15 seconds
- HTTP Status: 500 Error
- Logs show:
  ```
  🔄 RETRY Attempt 1 of 3
  [5 seconds wait]
  🔄 RETRY Attempt 2 of 3
  [10 seconds wait]
  ❌ RETRY EXHAUSTED after 3 attempts
  ```

### Test 4: Verify Circuit Breaker Opens

**Call the test endpoint 5 times** (with App B down):

```bash
for i in {1..5}; do
  echo "Call $i"
  curl http://localhost:8084/api/resilience/app-b/status/cb/test
done
```

**Expected:**
- First 5 calls: ~15 seconds each (with retries)
- Logs show: "🔴 CIRCUIT BREAKER STATE TRANSITION: CLOSED → OPEN"
- 6th call onwards: <5ms (circuit breaker rejects immediately)
- Logs show: "⚡ CIRCUIT BREAKER SHORT CIRCUIT"

### Test 5: Verify Circuit Breaker Closes

**Wait 30 seconds**, then **start App B**, then call:

```bash
curl http://localhost:8084/api/resilience/app-b/status/cb/test
```

**Expected:**
- Logs show: "🔴 STATE TRANSITION: OPEN → HALF_OPEN"
- Call succeeds
- Logs show: "🔴 STATE TRANSITION: HALF_OPEN → CLOSED"
- Circuit is back to normal

---

## 🎯 **Common Patterns**

### Pattern 1: User-Facing Endpoint (Graceful Degradation)

```java
@Retry(name = "myRetry")
@CircuitBreaker(name = "myCircuitBreaker")
@Bulkhead(name = "myBulkhead", fallbackMethod = "myFallback")
public String getUserData() {
    return externalService.getData();
}

public String myFallback(Exception ex) {
    return cachedDataService.getCachedData();
}
```

**Use when:**
- User is waiting for response
- Have cached/degraded data available
- Fast response more important than accuracy

### Pattern 2: Critical Operation (No Fallback, Retry)

```java
@Retry(name = "myRetry")
@CircuitBreaker(name = "myCircuitBreaker")
@Bulkhead(name = "myBulkhead")
public PaymentResult processPayment(PaymentRequest request) {
    return paymentService.process(request);
}
```

**Use when:**
- Operation must succeed or fail (no degraded alternative)
- Retry is needed for transient failures
- Failure visibility is important

### Pattern 3: Background Job (Circuit Breaker Only)

```java
@CircuitBreaker(name = "myCircuitBreaker")
@Scheduled(fixedRate = 60000)
public void syncData() {
    externalService.syncData();
}
```

**Use when:**
- Background task
- Don't need retry (will run again later)
- Want to stop calling failing service

---

## 🐛 **Troubleshooting**

### Issue 1: Retry Not Working

**Symptom:** Logs don't show retry attempts

**Causes:**
1. ✅ **Fallback prevents retry** - Remove fallback or move to controller
2. ✅ **Wrong exception type** - Exception not in `retryExceptions` list
3. ✅ **Circuit is OPEN** - Circuit breaker bypasses retry

**Solution:**
```yaml
# Add exception to retryExceptions
retryExceptions:
  - feign.FeignException$ServiceUnavailable  # Add this!
```

### Issue 2: Circuit Breaker Stays CLOSED

**Symptom:** Circuit never opens even with failures

**Causes:**
1. ✅ **Fallback succeeds** - Circuit sees SUCCESS, not FAILURE
2. ✅ **Not enough calls** - Need `minimumNumberOfCalls` failures
3. ✅ **Failure rate too low** - Need 50%+ failure rate

**Solution:**
```java
// Remove fallback to let circuit breaker see failures
@CircuitBreaker(name = "myCircuitBreaker")  // NO fallbackMethod
```

### Issue 3: Application Won't Start

**Symptom:** Error on startup related to Resilience4j

**Causes:**
1. ✅ **Missing AOP dependency** - Add `spring-boot-starter-aop`
2. ✅ **Wrong Spring Boot version** - Use resilience4j-spring-boot3 for Boot 3.x
3. ✅ **Configuration error** - Check YAML syntax

**Solution:**
```xml
<!-- Add AOP -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

### Issue 4: Logs Not Showing Events

**Symptom:** No emoji logs, no event messages

**Causes:**
1. ✅ **Event config not loaded** - Ensure `@Configuration` class is in component scan
2. ✅ **Log level too high** - Set to DEBUG or INFO
3. ✅ **Wrong logger name** - Check logger configuration

**Solution:**
```yaml
# Set log level in application.yml
logging:
  level:
    com.yourpackage.config.ResilienceEventConfig: INFO
```

---

## 📚 **Summary Checklist**

Use this checklist when implementing resilience:

### Dependencies
- [ ] Added `resilience4j-spring-boot3`
- [ ] Added individual pattern dependencies (circuitbreaker, retry, etc.)
- [ ] Added `spring-boot-starter-aop`
- [ ] Added `spring-boot-starter-actuator`

### Configuration (application.yml)
- [ ] Configured Circuit Breaker with thresholds
- [ ] Configured Retry with max attempts and backoff
- [ ] Configured Bulkhead with max concurrent calls
- [ ] Configured Rate Limiter with limits
- [ ] Configured Time Limiter with timeout
- [ ] Enabled actuator endpoints

### Service Layer
- [ ] Created service class with `@Service`
- [ ] Added resilience annotations in correct order
- [ ] Defined fallback methods (if needed)
- [ ] Added trace ID logging

### Fallback Implementation
- [ ] Created fallback class with `@Component`
- [ ] Implemented fallback methods with correct signatures
- [ ] Return degraded/cached data
- [ ] Log fallback usage

### Event Monitoring
- [ ] Created event config class with `@Configuration`
- [ ] Registered event listeners for all patterns
- [ ] Added emoji logging for easy identification
- [ ] Log all state transitions and errors

### Controller Layer
- [ ] Created controller with `@RestController`
- [ ] Exposed endpoints for testing
- [ ] Handle exceptions appropriately
- [ ] Return meaningful HTTP status codes

### Testing
- [ ] Application starts without errors
- [ ] Fallback endpoints return 200 OK when service is down
- [ ] Non-fallback endpoints retry and return errors
- [ ] Circuit breaker opens after threshold failures
- [ ] Circuit breaker closes when service recovers
- [ ] Logs show all resilience events

---

## 🎉 **Congratulations!**

You've successfully implemented resilience patterns in your microservices!

**Key Takeaways:**
1. ✅ Resilience prevents cascading failures
2. ✅ Use fallback for user-facing endpoints
3. ✅ Use retry for critical operations
4. ✅ Circuit breaker protects from cascading failures
5. ✅ Monitor events for debugging and alerts

**Next Steps:**
- Add metrics collection (Prometheus)
- Create dashboards (Grafana)
- Set up alerts for circuit breaker opens
- Load test your resilience thresholds
- Document your patterns for team

---

## 📖 **Additional Resources**

**Official Documentation:**
- [Resilience4j Official Docs](https://resilience4j.readme.io/)
- [Spring Cloud Circuit Breaker](https://spring.io/projects/spring-cloud-circuitbreaker)

**Further Reading:**
- Michael Nygard's "Release It!" (Book)
- Martin Fowler's Circuit Breaker pattern
- Netflix Hystrix design patterns

---

**Happy coding! 🚀**

*This guide was created for educational purposes to help interns understand and implement resilience patterns in microservices.*
