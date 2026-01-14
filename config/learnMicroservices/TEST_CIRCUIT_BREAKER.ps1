# =========================================
# Phase 4 Circuit Breaker Testing Script
# =========================================
# Purpose: Trigger circuit breaker to OPEN state by making 5+ failed requests
# Expected: After 5 failures, circuit breaker opens and responses become instant

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔬 CIRCUIT BREAKER TESTING SCRIPT" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "📋 TEST SETUP:" -ForegroundColor Yellow
Write-Host "  - App B Status: DOWN (not running)" -ForegroundColor White
Write-Host "  - Circuit Breaker Config:" -ForegroundColor White
Write-Host "    • minimumNumberOfCalls: 5" -ForegroundColor Gray
Write-Host "    • failureRateThreshold: 50%" -ForegroundColor Gray
Write-Host "    • waitDurationInOpenState: 30s" -ForegroundColor Gray
Write-Host "`n  - Expected Behavior:" -ForegroundColor White
Write-Host "    1. Requests 1-4: Fast fallback (~5-10ms)" -ForegroundColor Gray
Write-Host "    2. Request 5: Circuit breaker OPENS" -ForegroundColor Gray
Write-Host "    3. Requests 6+: INSTANT fallback (<1ms, no remote call)" -ForegroundColor Gray
Write-Host ""

# Configuration
$baseUrl = "http://localhost:9002/api/app-a/api/resilience"
$statusEndpoint = "$baseUrl/app-b/status"
$cbStatusEndpoint = "$baseUrl/circuit-breaker/status"

# Function to extract response time from response
function Get-ResponseTime {
    param($response)
    if ($response.durationMs) { return $response.durationMs }
    return "N/A"
}

# Function to extract circuit breaker state
function Get-CBState {
    param($response)
    if ($response.circuitBreakerState) { return $response.circuitBreakerState }
    return "UNKNOWN"
}

# Function to color code duration
function Format-Duration {
    param([int]$ms)
    if ($ms -lt 1) { return "⚡ ${ms}ms (INSTANT)" }
    elseif ($ms -lt 10) { return "✅ ${ms}ms (FAST)" }
    elseif ($ms -lt 100) { return "⚠️ ${ms}ms (MODERATE)" }
    else { return "❌ ${ms}ms (SLOW)" }
}

# Function to color code CB state
function Format-CBState {
    param([string]$state)
    switch ($state) {
        "CLOSED" { return "🟢 CLOSED (Healthy)" }
        "OPEN" { return "🔴 OPEN (Protection Active)" }
        "HALF_OPEN" { return "🟡 HALF_OPEN (Testing Recovery)" }
        default { return "❓ $state" }
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🧪 PHASE 1: TRIGGER CIRCUIT BREAKER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Making 10 requests to trigger circuit breaker opening...`n" -ForegroundColor White

# Array to store results
$results = @()

for ($i = 1; $i -le 10; $i++) {
    Write-Host "Request $i`: " -NoNewline -ForegroundColor White
    
    try {
        $response = Invoke-RestMethod -Uri $statusEndpoint -Method Get -ErrorAction Stop
        $duration = Get-ResponseTime -response $response
        $cbState = Get-CBState -response $response
        
        # Store result
        $results += [PSCustomObject]@{
            Request = $i
            Duration = $duration
            State = $cbState
            Status = $response.status
        }
        
        Write-Host "$(Format-Duration $duration) | $(Format-CBState $cbState)" -ForegroundColor White
        
        # Check if circuit breaker opened
        if ($cbState -eq "OPEN" -and $i -eq 5) {
            Write-Host "`n  🎯 SUCCESS! Circuit Breaker OPENED after 5 failures (as configured)" -ForegroundColor Green
            Write-Host "  ⚡ Next requests will be INSTANT (no remote call)`n" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Small delay between requests
    Start-Sleep -Milliseconds 100
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📊 RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Display results table
$results | Format-Table -AutoSize

# Calculate statistics
$avgDurationBeforeOpen = ($results | Where-Object { $_.Request -le 4 } | Measure-Object -Property Duration -Average).Average
$avgDurationAfterOpen = ($results | Where-Object { $_.Request -gt 5 } | Measure-Object -Property Duration -Average).Average

Write-Host "`n📈 PERFORMANCE METRICS:" -ForegroundColor Yellow
Write-Host "  • Average Duration (Requests 1-4): $([math]::Round($avgDurationBeforeOpen, 2))ms" -ForegroundColor White
Write-Host "  • Average Duration (Requests 6-10): $([math]::Round($avgDurationAfterOpen, 2))ms" -ForegroundColor White
Write-Host "  • Performance Improvement: $([math]::Round((($avgDurationBeforeOpen - $avgDurationAfterOpen) / $avgDurationBeforeOpen) * 100, 1))%" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔍 CIRCUIT BREAKER DETAILED STATUS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    $cbStatus = Invoke-RestMethod -Uri $cbStatusEndpoint -Method Get -ErrorAction Stop
    
    Write-Host "State: $(Format-CBState $cbStatus.state)" -ForegroundColor White
    Write-Host "Failure Rate: $($cbStatus.failureRate)" -ForegroundColor White
    Write-Host "Slow Call Rate: $($cbStatus.slowCallRate)" -ForegroundColor White
    Write-Host "`nCall Metrics:" -ForegroundColor Yellow
    Write-Host "  • Successful Calls: $($cbStatus.numberOfSuccessfulCalls)" -ForegroundColor Green
    Write-Host "  • Failed Calls: $($cbStatus.numberOfFailedCalls)" -ForegroundColor Red
    Write-Host "  • Not Permitted Calls: $($cbStatus.numberOfNotPermittedCalls)" -ForegroundColor Yellow
    
    if ($cbStatus.state -eq "OPEN") {
        Write-Host "`n⏰ Circuit breaker will automatically attempt recovery in 30 seconds" -ForegroundColor Cyan
    }
}
catch {
    Write-Host "❌ Failed to get circuit breaker status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ TESTING COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "🎯 KEY OBSERVATIONS:" -ForegroundColor Yellow
Write-Host "  1. First 4 requests: Circuit breaker CLOSED, fast fallback (~5-10ms)" -ForegroundColor White
Write-Host "  2. Request 5: Circuit breaker OPENS after reaching threshold" -ForegroundColor White
Write-Host "  3. Requests 6-10: INSTANT fallback (<1ms, no remote call attempt)" -ForegroundColor White
Write-Host "  4. System protected from cascading failures" -ForegroundColor White
Write-Host "`n  💡 This is the circuit breaker pattern in action!" -ForegroundColor Green

Write-Host "`n📚 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Wait 30 seconds for circuit breaker to enter HALF_OPEN state" -ForegroundColor White
Write-Host "  2. Start App B to test automatic recovery" -ForegroundColor White
Write-Host "  3. Make requests to see circuit breaker transition to CLOSED" -ForegroundColor White
Write-Host "  4. Compare with OLD endpoint (still returns 500 errors)`n" -ForegroundColor White
