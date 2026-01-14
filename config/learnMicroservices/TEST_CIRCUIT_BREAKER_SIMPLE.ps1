# =========================================
# CIRCUIT BREAKER TESTING - SIMPLE VERSION
# =========================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔬 CIRCUIT BREAKER TESTING" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Configuration
$baseUrl = "http://localhost:9002/api/app-a"
$testUrl = "$baseUrl/api/test-circuit"

Write-Host "📚 WHY CIRCUIT BREAKER STAYS CLOSED:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Your circuit breaker stays CLOSED because:" -ForegroundColor White
Write-Host "  • Fallback succeeds = Circuit breaker sees SUCCESS" -ForegroundColor Gray
Write-Host "  • Failure rate: 0%" -ForegroundColor Gray
Write-Host "  • This is CORRECT behavior!" -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 2

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🎯 METHOD 1: FORCE CIRCUIT BREAKER OPEN" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Step 1: Check current status..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod -Uri "$testUrl/status" -Method Get
    Write-Host "  State: $($status.state) 🟢" -ForegroundColor Green
    Write-Host "  Failure Rate: $($status.metrics.failureRate)" -ForegroundColor White
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n  Make sure app-a is rebuilt with CircuitBreakerTestController!" -ForegroundColor Yellow
    Write-Host "  Run: mvn clean package -DskipTests (after stopping app-a)" -ForegroundColor Cyan
    exit
}

Write-Host "`nStep 2: Forcing circuit breaker to OPEN..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$testUrl/force-open" -Method Post
    Write-Host "  ✅ $($response.message)" -ForegroundColor Green
    Write-Host "  State: $($response.currentState) 🔴" -ForegroundColor Red
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nStep 3: Testing with circuit breaker OPEN..." -ForegroundColor Yellow
Write-Host "Making 5 requests to see instant responses...`n" -ForegroundColor White

for ($i = 1; $i -le 5; $i++) {
    Write-Host "  Request $i`: " -NoNewline -ForegroundColor White
    $startTime = Get-Date
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/resilience/app-b/status" -Method Get
        $endTime = Get-Date
        $duration = [math]::Round(($endTime - $startTime).TotalMilliseconds, 2)
        
        if ($duration -lt 1) {
            Write-Host "⚡ ${duration}ms (INSTANT!) - Circuit OPEN" -ForegroundColor Yellow
        } else {
            Write-Host "✅ ${duration}ms - Circuit State: $($response.circuitBreakerState)" -ForegroundColor White
        }
    } catch {
        Write-Host "❌ Error" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 200
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🎯 METHOD 2: SIMULATE FAILURES" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "First, let's reset the circuit breaker..." -ForegroundColor Yellow
try {
    $reset = Invoke-RestMethod -Uri "$testUrl/force-closed" -Method Post
    Write-Host "  ✅ $($reset.message)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 1

Write-Host "`nSimulating 10 failures..." -ForegroundColor Yellow
try {
    $simResponse = Invoke-RestMethod -Uri "$testUrl/simulate-failures?count=10" -Method Post
    Write-Host "  ✅ Failures recorded: $($simResponse.failuresRecorded)" -ForegroundColor Green
    Write-Host "  State: $($simResponse.currentState)" -ForegroundColor White
    Write-Host "  Failure Rate: $($simResponse.failureRate)" -ForegroundColor White
    
    if ($simResponse.currentState -eq "OPEN") {
        Write-Host "`n  🎉 SUCCESS! Circuit breaker is now OPEN!" -ForegroundColor Green
    } else {
        Write-Host "`n  ℹ️  $($simResponse.message)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📊 FINAL STATUS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    $finalStatus = Invoke-RestMethod -Uri "$testUrl/status" -Method Get
    
    $stateEmoji = switch ($finalStatus.state) {
        "CLOSED" { "🟢" }
        "OPEN" { "🔴" }
        "HALF_OPEN" { "🟡" }
        default { "⚪" }
    }
    
    Write-Host "Circuit Breaker: appBCircuitBreaker" -ForegroundColor White
    Write-Host "State: $stateEmoji $($finalStatus.state)" -ForegroundColor White
    Write-Host ""
    Write-Host "Metrics:" -ForegroundColor Yellow
    Write-Host "  • Failure Rate: $($finalStatus.metrics.failureRate)" -ForegroundColor White
    Write-Host "  • Successful Calls: $($finalStatus.metrics.numberOfSuccessfulCalls)" -ForegroundColor Green
    Write-Host "  • Failed Calls: $($finalStatus.metrics.numberOfFailedCalls)" -ForegroundColor Red
    Write-Host "  • Not Permitted: $($finalStatus.metrics.numberOfNotPermittedCalls)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  • Failure Threshold: $($finalStatus.config.failureRateThreshold)%" -ForegroundColor White
    Write-Host "  • Minimum Calls: $($finalStatus.config.minimumNumberOfCalls)" -ForegroundColor White
    Write-Host "  • Sliding Window: $($finalStatus.config.slidingWindowSize)" -ForegroundColor White
} catch {
    Write-Host "❌ Error getting status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ TESTING COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "🎓 KEY LEARNINGS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Your circuit breaker stays CLOSED because:" -ForegroundColor White
Write-Host "   • Fallback succeeds = Overall success ✅" -ForegroundColor Gray
Write-Host "   • This is CORRECT production behavior!" -ForegroundColor Gray
Write-Host ""
Write-Host "2. When circuit breaker is OPEN:" -ForegroundColor White
Write-Host "   • Responses are instant (<1ms) ⚡" -ForegroundColor Gray
Write-Host "   • No calls to downstream service" -ForegroundColor Gray
Write-Host "   • System protected from overload" -ForegroundColor Gray
Write-Host ""
Write-Host "3. New test endpoints available:" -ForegroundColor White
Write-Host "   • GET  $testUrl/status" -ForegroundColor Cyan
Write-Host "   • POST $testUrl/force-open" -ForegroundColor Cyan
Write-Host "   • POST $testUrl/force-closed" -ForegroundColor Cyan
Write-Host "   • POST $testUrl/simulate-failures" -ForegroundColor Cyan
Write-Host ""

Write-Host "📚 Read WHY_CIRCUIT_BREAKER_STAYS_CLOSED.md for full explanation!" -ForegroundColor Yellow
Write-Host ""
