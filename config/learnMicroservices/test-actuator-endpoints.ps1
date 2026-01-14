# ================================================================
# ACTUATOR ENDPOINTS TEST SCRIPT
# ================================================================
# This script tests all available Resilience4j actuator endpoints
# Run this to verify your monitoring is working correctly
# ================================================================

$baseUrl = "http://localhost:8084"
$cbName = "appBCircuitBreaker"
$retryName = "appBRetry"
$bulkheadName = "appBBulkhead"
$rateLimiterName = "appBRateLimiter"

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       RESILIENCE4J ACTUATOR ENDPOINTS TEST                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ================================================================
# 1. HEALTH ENDPOINT
# ================================================================
Write-Host "1️⃣  Testing Health Endpoint..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/health" -ForegroundColor Gray

try {
    $health = Invoke-RestMethod -Uri "$baseUrl/actuator/health" -Method Get
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    Write-Host "   Status: $($health.status)" -ForegroundColor Green
    
    if ($health.components.circuitBreakers) {
        $cbHealth = $health.components.circuitBreakers.details.$cbName.details
        Write-Host "   Circuit Breaker State: $($cbHealth.state)" -ForegroundColor $(if ($cbHealth.state -eq "CLOSED") { "Green" } else { "Red" })
        Write-Host "   Failure Rate: $($cbHealth.failureRate)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# 2. ALL METRICS
# ================================================================
Write-Host "2️⃣  Testing Metrics List..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/metrics" -ForegroundColor Gray

try {
    $metrics = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics" -Method Get
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    
    $r4jMetrics = $metrics.names | Where-Object { $_ -like "resilience4j.*" }
    Write-Host "   Found $($r4jMetrics.Count) Resilience4j metrics:" -ForegroundColor Green
    
    foreach ($metric in $r4jMetrics) {
        Write-Host "      • $metric" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# 3. CIRCUIT BREAKER STATE
# ================================================================
Write-Host "3️⃣  Testing Circuit Breaker State..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/metrics/resilience4j.circuitbreaker.state" -ForegroundColor Gray

try {
    $state = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.circuitbreaker.state?tag=name:$cbName" -Method Get
    $stateValue = $state.measurements[0].value
    $stateText = switch ($stateValue) {
        0 { "CLOSED (Normal)" }
        1 { "OPEN (Circuit Open)" }
        2 { "HALF_OPEN (Testing)" }
        default { "UNKNOWN" }
    }
    
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    Write-Host "   State Value: $stateValue = $stateText" -ForegroundColor $(if ($stateValue -eq 0) { "Green" } elseif ($stateValue -eq 1) { "Red" } else { "Yellow" })
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# 4. CIRCUIT BREAKER FAILURE RATE
# ================================================================
Write-Host "4️⃣  Testing Circuit Breaker Failure Rate..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/metrics/resilience4j.circuitbreaker.failure.rate" -ForegroundColor Gray

try {
    $failureRate = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.circuitbreaker.failure.rate?tag=name:$cbName" -Method Get
    $rate = $failureRate.measurements[0].value
    
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    Write-Host "   Failure Rate: $rate%" -ForegroundColor $(if ($rate -ge 50) { "Red" } elseif ($rate -ge 30) { "Yellow" } else { "Green" })
    Write-Host "   Threshold: 50% (circuit opens above this)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# 5. CIRCUIT BREAKER CALLS (SUCCESSFUL)
# ================================================================
Write-Host "5️⃣  Testing Circuit Breaker Successful Calls..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/metrics/resilience4j.circuitbreaker.calls" -ForegroundColor Gray

try {
    $calls = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:$cbName&tag=kind:successful" -Method Get
    $count = $calls.measurements[0].value
    
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    Write-Host "   Successful Calls: $count" -ForegroundColor Green
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# 6. CIRCUIT BREAKER CALLS (FAILED)
# ================================================================
Write-Host "6️⃣  Testing Circuit Breaker Failed Calls..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/metrics/resilience4j.circuitbreaker.calls" -ForegroundColor Gray

try {
    $calls = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:$cbName&tag=kind:failed" -Method Get
    $count = $calls.measurements[0].value
    
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    Write-Host "   Failed Calls: $count" -ForegroundColor Red
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# 7. CIRCUIT BREAKER CALLS (NOT PERMITTED)
# ================================================================
Write-Host "7️⃣  Testing Circuit Breaker Not Permitted Calls..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/metrics/resilience4j.circuitbreaker.calls" -ForegroundColor Gray

try {
    $calls = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.circuitbreaker.calls?tag=name:$cbName&tag=kind:not_permitted" -Method Get
    $count = $calls.measurements[0].value
    
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    Write-Host "   Not Permitted (Short Circuit): $count" -ForegroundColor Magenta
    
    if ($count -gt 0) {
        Write-Host "   ⚠️  Circuit breaker is rejecting calls!" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# 8. RETRY METRICS
# ================================================================
Write-Host "8️⃣  Testing Retry Metrics..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/metrics/resilience4j.retry.calls" -ForegroundColor Gray

try {
    $retry = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.retry.calls?tag=name:$retryName" -Method Get
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    
    # Try to get specific retry metrics
    try {
        $retrySuccess = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.retry.calls?tag=name:$retryName&tag=kind:successful_with_retry" -Method Get
        Write-Host "   Successful After Retry: $($retrySuccess.measurements[0].value)" -ForegroundColor Green
    } catch { }
    
    try {
        $retryFailed = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.retry.calls?tag=name:$retryName&tag=kind:failed_with_retry" -Method Get
        Write-Host "   Failed After Retry: $($retryFailed.measurements[0].value)" -ForegroundColor Red
    } catch { }
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# 9. BULKHEAD METRICS
# ================================================================
Write-Host "9️⃣  Testing Bulkhead Metrics..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/metrics/resilience4j.bulkhead.available.concurrent.calls" -ForegroundColor Gray

try {
    $bulkhead = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.bulkhead.available.concurrent.calls?tag=name:$bulkheadName" -Method Get
    $available = $bulkhead.measurements[0].value
    
    $maxBulkhead = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.bulkhead.max.allowed.concurrent.calls?tag=name:$bulkheadName" -Method Get
    $max = $maxBulkhead.measurements[0].value
    
    $inProgress = $max - $available
    
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    Write-Host "   Available: $available / $max" -ForegroundColor $(if ($available -eq $max) { "Green" } else { "Yellow" })
    Write-Host "   In Progress: $inProgress" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# 10. RATE LIMITER METRICS
# ================================================================
Write-Host "🔟 Testing Rate Limiter Metrics..." -ForegroundColor Yellow
Write-Host "   URL: $baseUrl/actuator/metrics/resilience4j.ratelimiter.available.permissions" -ForegroundColor Gray

try {
    $rateLimiter = Invoke-RestMethod -Uri "$baseUrl/actuator/metrics/resilience4j.ratelimiter.available.permissions?tag=name:$rateLimiterName" -Method Get
    $permissions = $rateLimiter.measurements[0].value
    
    Write-Host "   ✅ SUCCESS" -ForegroundColor Green
    Write-Host "   Available Permissions: $permissions / 100" -ForegroundColor $(if ($permissions -gt 50) { "Green" } elseif ($permissions -gt 10) { "Yellow" } else { "Red" })
} catch {
    Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# ================================================================
# SUMMARY
# ================================================================
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       TEST COMPLETE                                          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ All working endpoints tested!" -ForegroundColor Green
Write-Host ""
Write-Host "📌 Key Endpoints to Monitor:" -ForegroundColor Yellow
Write-Host "   • Health:           $baseUrl/actuator/health" -ForegroundColor Gray
Write-Host "   • CB State:         $baseUrl/actuator/metrics/resilience4j.circuitbreaker.state" -ForegroundColor Gray
Write-Host "   • CB Failure Rate:  $baseUrl/actuator/metrics/resilience4j.circuitbreaker.failure.rate" -ForegroundColor Gray
Write-Host "   • CB Calls:         $baseUrl/actuator/metrics/resilience4j.circuitbreaker.calls" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 For event history, check application logs:" -ForegroundColor Yellow
Write-Host "   Get-Content logs\app-a.log -Wait | Select-String 'CIRCUIT BREAKER'" -ForegroundColor Gray
Write-Host ""
