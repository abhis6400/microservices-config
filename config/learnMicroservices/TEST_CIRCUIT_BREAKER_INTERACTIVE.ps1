# =========================================
# CIRCUIT BREAKER TESTING - COMPREHENSIVE
# =========================================
# This script demonstrates WHY your circuit breaker stays CLOSED
# and provides solutions to test circuit breaker opening

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔬 CIRCUIT BREAKER BEHAVIOR EXPLAINED" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "📚 WHY YOUR CIRCUIT BREAKER STAYS CLOSED:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  When you call: /api/resilience/app-b/status" -ForegroundColor White
Write-Host "  And App B is DOWN..." -ForegroundColor White
Write-Host ""
Write-Host "  Expected behavior:" -ForegroundColor Gray
Write-Host "    1. Feign call fails (503 Service Unavailable)" -ForegroundColor Gray
Write-Host "    2. Fallback method is triggered" -ForegroundColor Gray
Write-Host "    3. Fallback SUCCEEDS (returns degraded response)" -ForegroundColor Gray
Write-Host "    4. Circuit breaker records: SUCCESS ✅" -ForegroundColor Green
Write-Host ""
Write-Host "  Result:" -ForegroundColor Yellow
Write-Host "    • Failure rate: 0%" -ForegroundColor Green
Write-Host "    • Circuit breaker: CLOSED" -ForegroundColor Green
Write-Host "    • Why? Fallback success = overall success" -ForegroundColor White
Write-Host ""
Write-Host "  This is BY DESIGN! ✅" -ForegroundColor Green
Write-Host "    Good fallbacks prevent circuit breaker from opening" -ForegroundColor White
Write-Host "    Because the system IS recovering gracefully" -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 2

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🎯 THREE WAYS TO OPEN CIRCUIT BREAKER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Configuration
$baseUrl = "http://localhost:9002/api/app-a"
$resilienceUrl = "$baseUrl/api/resilience"
$testUrl = "$baseUrl/api/test-circuit"

Write-Host "Choose a method:`n" -ForegroundColor Yellow

Write-Host "  1. FORCE OPEN (Instant) ⚡" -ForegroundColor White
Write-Host "     • Manually transition to OPEN state" -ForegroundColor Gray
Write-Host "     • Best for: Quick testing/demo" -ForegroundColor Gray
Write-Host "     • Command: POST $testUrl/force-open" -ForegroundColor Cyan
Write-Host ""

Write-Host "  2. SIMULATE FAILURES (Realistic) 🎭" -ForegroundColor White
Write-Host "     • Record 10 artificial failures" -ForegroundColor Gray
Write-Host "     • Circuit breaker opens naturally" -ForegroundColor Gray
Write-Host "     • Command: POST $testUrl/simulate-failures" -ForegroundColor Cyan
Write-Host ""

Write-Host "  3. REAL FAILURES (Production-like) 🏭" -ForegroundColor White
Write-Host "     • Stop App B completely" -ForegroundColor Gray
Write-Host "     • Remove fallback temporarily" -ForegroundColor Gray
Write-Host "     • Make actual calls that fail" -ForegroundColor Gray
Write-Host "     • Command: (requires code change)" -ForegroundColor Cyan
Write-Host ""

$choice = Read-Host "`nSelect method (1, 2, or 3)"

switch ($choice) {
    "1" {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "⚡ METHOD 1: FORCE OPEN" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        Write-Host "Before forcing open:" -ForegroundColor Yellow
        try {
            $beforeStatus = Invoke-RestMethod -Uri "$testUrl/status" -Method Get
            Write-Host "  State: $($beforeStatus.state) 🟢" -ForegroundColor Green
            Write-Host "  Failure Rate: $($beforeStatus.metrics.failureRate)" -ForegroundColor White
        } catch {
            Write-Host "  ❌ Error getting status: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "`nForcing circuit breaker to OPEN state..." -ForegroundColor Yellow
        try {
            $forceResponse = Invoke-RestMethod -Uri "$testUrl/force-open" -Method Post
            Write-Host "  ✅ $($forceResponse.message)" -ForegroundColor Green
            Write-Host "  State: $($forceResponse.currentState) 🔴" -ForegroundColor Red
            Write-Host "  Duration: $($forceResponse.duration)" -ForegroundColor Yellow
        } catch {
            Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Start-Sleep -Seconds 1
        
        Write-Host "`nTesting behavior with circuit breaker OPEN:" -ForegroundColor Yellow
        Write-Host "Making 5 requests..." -ForegroundColor White
        
        for ($i = 1; $i -le 5; $i++) {
            Write-Host "`n  Request $i`: " -NoNewline -ForegroundColor White
            $startTime = Get-Date
            
            try {
                $response = Invoke-RestMethod -Uri "$resilienceUrl/app-b/status" -Method Get
                $endTime = Get-Date
                $duration = ($endTime - $startTime).TotalMilliseconds
                
                Write-Host "⚡ ${duration}ms (INSTANT - Circuit OPEN)" -ForegroundColor Yellow
                Write-Host "    Response: $($response.response.status)" -ForegroundColor Gray
                Write-Host "    CB State: $($response.circuitBreakerState)" -ForegroundColor Gray
            } catch {
                $endTime = Get-Date
                $duration = ($endTime - $startTime).TotalMilliseconds
                Write-Host "❌ ${duration}ms - Error: $($_.Exception.Message)" -ForegroundColor Red
            }
            
            Start-Sleep -Milliseconds 200
        }
        
        Write-Host "`n✅ OBSERVATION:" -ForegroundColor Green
        Write-Host "  When circuit breaker is OPEN:" -ForegroundColor White
        Write-Host "  • Responses are INSTANT (<1ms)" -ForegroundColor Yellow
        Write-Host "  • No actual calls to App B" -ForegroundColor Yellow
        Write-Host "  • Fallback used immediately" -ForegroundColor Yellow
        Write-Host "  • System protected from overload" -ForegroundColor Yellow
    }
    
    "2" {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "🎭 METHOD 2: SIMULATE FAILURES" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        Write-Host "Before simulation:" -ForegroundColor Yellow
        try {
            $beforeStatus = Invoke-RestMethod -Uri "$testUrl/status" -Method Get
            Write-Host "  State: $($beforeStatus.state)" -ForegroundColor White
            Write-Host "  Failure Rate: $($beforeStatus.metrics.failureRate)" -ForegroundColor White
            Write-Host "  Failed Calls: $($beforeStatus.metrics.numberOfFailedCalls)" -ForegroundColor White
        } catch {
            Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "`nSimulating 10 failures..." -ForegroundColor Yellow
        try {
            $simResponse = Invoke-RestMethod -Uri "$testUrl/simulate-failures?count=10" -Method Post
            Write-Host "  ✅ Failures recorded: $($simResponse.failuresRecorded)" -ForegroundColor Green
            Write-Host "  State: $($simResponse.currentState)" -ForegroundColor White
            Write-Host "  Failure Rate: $($simResponse.failureRate)" -ForegroundColor White
            Write-Host "  Message: $($simResponse.message)" -ForegroundColor Yellow
            
            if ($simResponse.currentState -eq "OPEN") {
                Write-Host "`n🎉 SUCCESS! Circuit breaker is now OPEN!" -ForegroundColor Green
            } else {
                Write-Host "`n⚠️  Circuit still CLOSED. Hint: $($simResponse.hint)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "`nDetailed status:" -ForegroundColor Yellow
        try {
            $afterStatus = Invoke-RestMethod -Uri "$testUrl/status" -Method Get
            Write-Host "  State: $($afterStatus.state)" -ForegroundColor White
            Write-Host "  Failure Rate: $($afterStatus.metrics.failureRate)" -ForegroundColor White
            Write-Host "  Failed Calls: $($afterStatus.metrics.numberOfFailedCalls)" -ForegroundColor Red
            Write-Host "  Successful Calls: $($afterStatus.metrics.numberOfSuccessfulCalls)" -ForegroundColor Green
            Write-Host "  Not Permitted: $($afterStatus.metrics.numberOfNotPermittedCalls)" -ForegroundColor Yellow
        } catch {
            Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "3" {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "🏭 METHOD 3: REAL FAILURES" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        Write-Host "This method requires code changes:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "OPTION A: Temporary remove fallback" -ForegroundColor White
        Write-Host "  1. Comment out fallbackMethod in @CircuitBreaker annotation" -ForegroundColor Gray
        Write-Host "  2. Rebuild app-a: mvn clean package -DskipTests" -ForegroundColor Gray
        Write-Host "  3. Restart app-a" -ForegroundColor Gray
        Write-Host "  4. Make 10 calls to /api/resilience/app-b/status" -ForegroundColor Gray
        Write-Host "  5. Circuit breaker will open after 5 failures" -ForegroundColor Gray
        Write-Host ""
        Write-Host "OPTION B: Configure recordFailurePredicate" -ForegroundColor White
        Write-Host "  1. Add custom failure predicate to count fallback as failure" -ForegroundColor Gray
        Write-Host "  2. This requires Java configuration changes" -ForegroundColor Gray
        Write-Host ""
        Write-Host "💡 Recommendation: Use Method 1 or 2 for testing" -ForegroundColor Yellow
    }
    
    default {
        Write-Host "`n❌ Invalid choice. Please run script again and select 1, 2, or 3." -ForegroundColor Red
        exit
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔄 RESET CIRCUIT BREAKER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$reset = Read-Host "Reset circuit breaker to CLOSED state? (y/n)"

if ($reset -eq "y") {
    try {
        $resetResponse = Invoke-RestMethod -Uri "$testUrl/force-closed" -Method Post
        Write-Host "  ✅ $($resetResponse.message)" -ForegroundColor Green
        Write-Host "  State: $($resetResponse.currentState)" -ForegroundColor White
        Write-Host "  Metrics Reset: $($resetResponse.metricsReset)" -ForegroundColor White
    } catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📊 FINAL STATUS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    $finalStatus = Invoke-RestMethod -Uri "$testUrl/status" -Method Get
    
    $stateColor = switch ($finalStatus.state) {
        "CLOSED" { "Green" }
        "OPEN" { "Red" }
        "HALF_OPEN" { "Yellow" }
        default { "White" }
    }
    
    Write-Host "Circuit Breaker: appBCircuitBreaker" -ForegroundColor White
    Write-Host "State: $($finalStatus.state)" -ForegroundColor $stateColor
    Write-Host ""
    Write-Host "Metrics:" -ForegroundColor Yellow
    Write-Host "  • Failure Rate: $($finalStatus.metrics.failureRate)" -ForegroundColor White
    Write-Host "  • Slow Call Rate: $($finalStatus.metrics.slowCallRate)" -ForegroundColor White
    Write-Host "  • Successful Calls: $($finalStatus.metrics.numberOfSuccessfulCalls)" -ForegroundColor Green
    Write-Host "  • Failed Calls: $($finalStatus.metrics.numberOfFailedCalls)" -ForegroundColor Red
    Write-Host "  • Not Permitted: $($finalStatus.metrics.numberOfNotPermittedCalls)" -ForegroundColor Yellow
    Write-Host "  • Buffered Calls: $($finalStatus.metrics.numberOfBufferedCalls)" -ForegroundColor White
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
Write-Host "1. Fallback Success = Circuit Breaker Success" -ForegroundColor White
Write-Host "   When fallback works, circuit breaker sees overall success" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Circuit Breaker Won't Open with Good Fallbacks" -ForegroundColor White
Write-Host "   This is CORRECT behavior - system is recovering gracefully" -ForegroundColor Gray
Write-Host ""
Write-Host "3. To Test Circuit Opening, You Need:" -ForegroundColor White
Write-Host "   • Force it manually (Method 1)" -ForegroundColor Gray
Write-Host "   • Simulate failures (Method 2)" -ForegroundColor Gray
Write-Host "   • Remove fallback temporarily (Method 3)" -ForegroundColor Gray
Write-Host ""
Write-Host "4. In Production:" -ForegroundColor White
Write-Host "   Circuit breaker opens when:" -ForegroundColor Gray
Write-Host "   • Service returns errors (500) even after retries" -ForegroundColor Gray
Write-Host "   • Fallback itself fails" -ForegroundColor Gray
Write-Host "   • Timeouts occur beyond retry capability" -ForegroundColor Gray
Write-Host ""

Write-Host "📚 Next Steps:" -ForegroundColor Yellow
Write-Host "  • Explore the new test endpoints at $testUrl" -ForegroundColor White
Write-Host "  • Try forcing OPEN and observe instant responses" -ForegroundColor White
Write-Host "  • Monitor metrics at /actuator/circuitbreakers" -ForegroundColor White
Write-Host ""
