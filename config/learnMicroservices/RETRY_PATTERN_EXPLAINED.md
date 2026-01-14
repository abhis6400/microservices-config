# 🔄 Retry Pattern - Complete Documentation

## ✅ YES! Retry is Fully Active

**Configuration:** 3 attempts with exponential backoff  
**Wait Times:** 500ms → 1000ms → (fallback)  
**Total Duration:** ~1.8 seconds when App B is down

---

## 📊 Your Retry Configuration

**File:** `app-a/src/main/resources/application.yml`

```yaml
retry:
  instances:
    appBRetry:
      maxAttempts: 3                      # 1 original + 2 retries
      waitDuration: 500ms                 # Initial wait
      enableExponentialBackoff: true      # Double each time
      exponentialBackoffMultiplier: 2     # 2x multiplier
      exponentialMaxWaitDuration: 5s      # Cap at 5 seconds
      
      # Retry these exceptions (transient failures)
      retryExceptions:
        - java.io.IOException
        - java.net.SocketTimeoutException
        - java.net.ConnectException
        - feign.RetryableException
      
      # Don't retry these (permanent failures)
      ignoreExceptions:
        - feign.FeignException.BadRequest   # 400
        - feign.FeignException.NotFound     # 404
```

---

## ⏱️ Timeline of Request with App B Down

```
User Request
    ↓
    
ATTEMPT 1 (Original Call)
    Time: 0ms
    Action: Try to call App B
    Result: Failed (No servers available)
    Duration: ~100ms
    ↓
    [Wait 500ms] ⏳
    ↓
    
ATTEMPT 2 (First Retry)
    Time: 600ms
    Action: Retry calling App B
    Result: Failed (still down)
    Duration: ~100ms
    Emoji: 🔄 RETRY Attempt 1 of 3
    ↓
    [Wait 1000ms] ⏳⏳ (doubled!)
    ↓
    
ATTEMPT 3 (Second Retry)
    Time: 1700ms
    Action: Final retry
    Result: Failed (still down)
    Duration: ~100ms
    Emoji: 🔄 RETRY Attempt 2 of 3
    ↓
    
RETRIES EXHAUSTED
    Time: 1800ms
    Action: Trigger fallback
    Emoji: ❌ RETRY EXHAUSTED
    ↓
    
FALLBACK
    Action: Return degraded response
    Duration: ~5ms
    Result: 200 OK (degraded)
    ↓
    
Response to User
    Total Duration: ~1805ms
```

---

## 🔍 How to Observe Retry in Logs

### When You Make a Request to:
```
GET http://localhost:9002/api/app-a/api/resilience/app-b/status
```

### Expected Logs:

```log
13:45:00.100 [http-nio-8084-exec-1] INFO  AppBResilientService
  [TRACE: abc123] Calling App B status endpoint with resilience patterns

# ATTEMPT 1 (Original)
13:45:00.150 [http-nio-8084-exec-1] WARN  RoundRobinLoadBalancer
  [TRACE: abc123] No servers available for service: app-b

# RETRY EVENT 1
13:45:00.200 [http-nio-8084-exec-1] WARN  ResilienceEventConfig
  🔄 RETRY [appBRetry] Attempt 1 of 3
     Exception: FeignException$ServiceUnavailable
     Wait before next: Will use exponential backoff

# [500ms wait]

# ATTEMPT 2 (First Retry)
13:45:00.700 [http-nio-8084-exec-1] WARN  RoundRobinLoadBalancer
  [TRACE: abc123] No servers available for service: app-b

# RETRY EVENT 2
13:45:00.750 [http-nio-8084-exec-1] WARN  ResilienceEventConfig
  🔄 RETRY [appBRetry] Attempt 2 of 3
     Exception: FeignException$ServiceUnavailable
     Wait before next: Will use exponential backoff

# [1000ms wait - doubled!]

# ATTEMPT 3 (Second Retry)
13:45:01.750 [http-nio-8084-exec-1] WARN  RoundRobinLoadBalancer
  [TRACE: abc123] No servers available for service: app-b

# RETRY EXHAUSTED
13:45:01.800 [http-nio-8084-exec-1] ERROR ResilienceEventConfig
  ❌ RETRY [appBRetry] EXHAUSTED after 2 attempts
     Final Exception: FeignException$ServiceUnavailable
     Action: Fallback will be used

# FALLBACK TRIGGERED
13:45:01.805 [http-nio-8084-exec-1] WARN  AppBResilientService
  [FALLBACK] [TRACE: abc123] getAppBStatus failed. Using fallback.

# CIRCUIT BREAKER RECORDS SUCCESS (because fallback worked)
13:45:01.810 [http-nio-8084-exec-1] DEBUG ResilienceEventConfig
  ✅ CIRCUIT BREAKER [appBCircuitBreaker] SUCCESS: Duration: 1705ms

# RESPONSE
13:45:01.815 [http-nio-8084-exec-1] DEBUG DispatcherServlet
  Completed 200 OK
```

**Total Duration:** ~1815ms (1.8 seconds)

---

## 📈 Duration Breakdown

| Phase | Duration | Cumulative | Notes |
|-------|----------|------------|-------|
| Attempt 1 | 100ms | 100ms | Initial call fails |
| Wait 1 | 500ms | 600ms | First backoff |
| Attempt 2 | 100ms | 700ms | Retry #1 fails |
| Wait 2 | 1000ms | 1700ms | Doubled backoff |
| Attempt 3 | 100ms | 1800ms | Retry #2 fails |
| Fallback | 5ms | 1805ms | Return degraded |
| **Total** | **~1805ms** | | **~1.8 seconds** |

---

## 🧪 Test to See Retry in Action

### Test Script: Measure Duration

```powershell
# Test regular endpoint
Write-Host "Testing with App B DOWN (should retry 3 times)..."
Write-Host ""

$startTime = Get-Date

try {
    $response = Invoke-RestMethod -Uri "http://localhost:9002/api/app-a/api/resilience/app-b/status" -Method Get
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "✅ Response received (with fallback)" -ForegroundColor Green
    Write-Host "Duration: ${duration}ms" -ForegroundColor Yellow
    Write-Host "Response duration: $($response.durationMs)ms" -ForegroundColor White
    Write-Host ""
    
    if ($duration -gt 1500) {
        Write-Host "✅ RETRY CONFIRMED! Duration >1.5s indicates retries happened" -ForegroundColor Green
        Write-Host "   - 3 attempts: ~300ms" -ForegroundColor Gray
        Write-Host "   - 2 waits: ~1500ms" -ForegroundColor Gray
        Write-Host "   - Total: ~1800ms ✅" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Duration too short. Retries may not have happened" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Check logs for retry events:" -ForegroundColor Yellow
Write-Host '  Look for: 🔄 RETRY [appBRetry] Attempt X of 3' -ForegroundColor Cyan
```

**Save as:** `test-retry.ps1`

**Run:**
```powershell
.\test-retry.ps1
```

---

### Expected Output:

```
Testing with App B DOWN (should retry 3 times)...

✅ Response received (with fallback)
Duration: 1823ms
Response duration: 1805ms

✅ RETRY CONFIRMED! Duration >1.5s indicates retries happened
   - 3 attempts: ~300ms
   - 2 waits: ~1500ms
   - Total: ~1800ms ✅

Check logs for retry events:
  Look for: 🔄 RETRY [appBRetry] Attempt X of 3
```

---

## 🎯 Retry Behavior in Different Scenarios

### Scenario 1: Regular Endpoint (With Fallback)

**Endpoint:** `/api/resilience/app-b/status`

**When App B is DOWN:**
```
Attempt 1 → Fails → Wait 500ms
Attempt 2 → Fails → Wait 1000ms
Attempt 3 → Fails → Fallback
Result: 200 OK (degraded)
Duration: ~1800ms
Circuit Breaker: Records SUCCESS (fallback worked)
```

---

### Scenario 2: Test Endpoint (NO Fallback)

**Endpoint:** `/api/resilience/app-b/status/cb/test`

**When App B is DOWN:**
```
Attempt 1 → Fails → Wait 500ms
Attempt 2 → Fails → Wait 1000ms
Attempt 3 → Fails → Exception propagates
Result: 500 Error
Duration: ~1800ms
Circuit Breaker: Records FAILURE
```

---

### Scenario 3: Circuit Breaker OPEN

**Any Endpoint**

**When Circuit is OPEN:**
```
Request → Circuit OPEN → Instant rejection
NO RETRIES! Circuit breaker bypasses retry
Result: 503 Error (or fallback if available)
Duration: <5ms ⚡
```

**Key Point:** When circuit is OPEN, retry is BYPASSED!

---

## 🔄 Annotation Order Matters!

**Your Current Order:**
```java
@Bulkhead(name = "appBBulkhead")
@RateLimiter(name = "appBRateLimiter")
@CircuitBreaker(name = "appBCircuitBreaker")
@Retry(name = "appBRetry")  // ← Innermost (executes first)
public String getAppBStatus() {
    return appBClient.getAppBStatus();
}
```

**Execution Flow (Inside-Out):**
```
Request
  ↓
Bulkhead check (outer)
  ↓
Rate Limiter check
  ↓
Circuit Breaker check
  ↓
Retry logic (inner - executes first on actual call)
  ↓
Actual Feign call
```

**When Call Fails:**
```
Actual call fails
  ↓
Retry catches → Attempts 1, 2, 3
  ↓
All retries fail
  ↓
Circuit Breaker records result (SUCCESS if fallback works, FAILURE if not)
  ↓
Response returned
```

---

## 📊 Retry Event Logging

**File:** `app-a/src/main/java/com/masterclass/appa/config/ResilienceEventConfig.java`

```java
retry.getEventPublisher()
    // Each retry attempt
    .onRetry(event -> {
        logger.warn(
            "🔄 RETRY [{}] Attempt {} of {}\n" +
            "   Exception: {}\n" +
            "   Wait before next: Will use exponential backoff",
            name,
            event.getNumberOfRetryAttempts(),
            retry.getRetryConfig().getMaxAttempts(),
            event.getLastThrowable().getClass().getSimpleName()
        );
    })
    
    // Retry succeeded
    .onSuccess(event -> {
        if (event.getNumberOfRetryAttempts() > 0) {
            logger.info(
                "✅ RETRY [{}] SUCCEEDED after {} attempts",
                name,
                event.getNumberOfRetryAttempts()
            );
        }
    })
    
    // All retries exhausted
    .onError(event -> {
        logger.error(
            "❌ RETRY [{}] EXHAUSTED after {} attempts\n" +
            "   Final Exception: {}\n" +
            "   Action: Fallback will be used",
            name,
            event.getNumberOfRetryAttempts(),
            event.getLastThrowable().getClass().getSimpleName()
        );
    });
```

---

## 🧪 Manual Test Commands

### Test 1: Single Request (Observe Duration)
```powershell
Measure-Command {
    curl http://localhost:9002/api/app-a/api/resilience/app-b/status
}
```

**Expected:** TotalMilliseconds: ~1800-2000ms

---

### Test 2: Circuit Breaker Test (First Request)
```powershell
Measure-Command {
    curl http://localhost:9002/api/app-a/api/resilience/app-b/status/cb/test
}
```

**Expected:** TotalMilliseconds: ~1800-2000ms (same retry logic)

---

### Test 3: After Circuit Opens (6th Request)
```powershell
Measure-Command {
    curl http://localhost:9002/api/app-a/api/resilience/app-b/status/cb/test
}
```

**Expected:** TotalMilliseconds: <10ms ⚡ (NO retry, circuit OPEN)

---

## 📈 Comparison: With vs Without Retry

### Without Retry (Hypothetical)
```
Request → Fails immediately → Fallback
Duration: ~100ms
User Experience: Fast but less resilient
```

### With Retry (Your Current Setup)
```
Request → Retry 1 (500ms) → Retry 2 (1000ms) → Fallback
Duration: ~1800ms
User Experience: Slower but more resilient to transient failures
```

**Trade-off:**
- ✅ More resilient (handles temporary glitches)
- ⚠️ Slower response (when service is actually down)
- ✅ Better for production (worth the wait for transient issues)

---

## 🎓 Key Learnings

### 1. Retry is Active and Working
- **3 attempts total** (1 original + 2 retries)
- **Exponential backoff** (500ms, 1000ms)
- **Total duration:** ~1.8 seconds when App B is down

### 2. Retry Logging is Enabled
- Look for `🔄 RETRY` emoji in logs
- Shows attempt number and exception
- Confirms retry is happening

### 3. Circuit Breaker Bypasses Retry
- When circuit is OPEN: NO retries
- Instant rejection: <5ms
- Protects system from unnecessary retries

### 4. Retry Happens Before Circuit Breaker
- Retry tries 3 times
- Circuit breaker sees final result
- If fallback works → Circuit records SUCCESS
- If no fallback → Circuit records FAILURE

---

## ✅ Verification Checklist

To confirm retry is working:

- [  ] Make request with App B down
- [  ] Observe duration: ~1.8 seconds
- [  ] Check logs for `🔄 RETRY` messages
- [  ] Count attempts in logs: Should see "Attempt 1 of 3", "Attempt 2 of 3"
- [  ] See `❌ RETRY EXHAUSTED` after 2 retries
- [  ] Total wait time: 500ms + 1000ms = 1500ms
- [  ] Actual call attempts: ~300ms
- [  ] Total: ~1800ms ✅

---

## 📊 Summary Table

| Metric | Value | Notes |
|--------|-------|-------|
| **Max Attempts** | 3 | 1 original + 2 retries |
| **Initial Wait** | 500ms | Before first retry |
| **Second Wait** | 1000ms | Doubled (exponential) |
| **Max Wait** | 5000ms | Cap (not reached in your case) |
| **Total Duration** | ~1800ms | When App B is down |
| **Retry Exceptions** | IOException, SocketTimeout, ConnectException, RetryableException | |
| **Ignored Exceptions** | BadRequest (400), NotFound (404) | Won't retry permanent failures |
| **Logging** | ✅ Enabled | Look for 🔄 emoji |
| **Circuit OPEN Behavior** | Bypasses retry | <5ms response |

---

## 🚀 Next Steps

1. **Test with provided script:**
   ```powershell
   .\test-retry.ps1
   ```

2. **Check logs for retry events:**
   ```
   grep "RETRY" app-a/logs/*.log
   ```

3. **Compare durations:**
   - Circuit CLOSED: ~1800ms (with retries)
   - Circuit OPEN: <5ms (no retries)

4. **Understand the trade-off:**
   - Retry = Better resilience, slower response
   - No retry = Faster fail, less resilient

---

**🎉 YES! Retry is fully implemented and working!**

The ~1.8 second duration you observe when App B is down is PROOF that retry is happening with exponential backoff.
