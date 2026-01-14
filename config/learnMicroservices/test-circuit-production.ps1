# =========================================
# PRODUCTION-LIKE CIRCUIT BREAKER TEST
# =========================================
# This script tests the NEW endpoint that behaves like production
# where circuit breaker OPENS automatically after failures

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🏭 PRODUCTION-LIKE CIRCUIT BREAKER TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:9002/api/app-a/api/resilience"
$testEndpoint = "$baseUrl/app-b/status/cb/test"
$statusEndpoint = "$baseUrl/circuit-breaker/status"

Write-Host "📚 DIFFERENCE FROM REGULAR ENDPOINT:`n" -ForegroundColor Yellow

Write-Host "Regular /app-b/status:" -ForegroundColor White
Write-Host "  ✅ Has fallback" -ForegroundColor Gray
Write-Host "  ✅ Returns 200 OK (degraded service)" -ForegroundColor Gray
Write-Host "  ❌ Circuit breaker NEVER opens (fallback = success)" -ForegroundColor Gray
Write-Host "  📊 Failure rate: 0%`n" -ForegroundColor Gray

Write-Host "THIS endpoint /app-b/status/cb/test:" -ForegroundColor Green
Write-Host "  ❌ NO fallback" -ForegroundColor Gray
Write-Host "  ❌ Returns 500 error when App B down" -ForegroundColor Gray
Write-Host "  ✅ Circuit breaker OPENS after threshold" -ForegroundColor Gray
Write-Host "  📊 Failure rate increases with each failure`n" -ForegroundColor Gray

Write-Host "🎯 EXPECTED BEHAVIOR:`n" -ForegroundColor Yellow
Write-Host "  Requests 1-4:  500 errors (~500-1500ms with retries)" -ForegroundColor White
Write-Host "  Request 5:     Circuit breaker OPENS!" -ForegroundColor Red
Write-Host "  Requests 6-10: INSTANT failures (<1ms, circuit OPEN)" -ForegroundColor Yellow
Write-Host ""

Start-Sleep -Seconds 2

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 INITIAL STATE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    $initial = Invoke-RestMethod -Uri $statusEndpoint -Method Get
    Write-Host "Circuit Breaker: $($initial.state)" -ForegroundColor Green
    Write-Host "Failure Rate: $($initial.metrics.failureRate)" -ForegroundColor White
    Write-Host "Failed Calls: $($initial.metrics.failedCalls)" -ForegroundColor White
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  • Minimum Calls: $($initial.configuration.minimumNumberOfCalls)" -ForegroundColor Gray
    Write-Host "  • Failure Threshold: $($initial.configuration.failureRateThreshold)`n" -ForegroundColor Gray
} catch {
    Write-Host "⚠️  Could not get initial status`n" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🧪 MAKING 10 TEST REQUESTS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "⚠️  Make sure App B is DOWN for this test!`n" -ForegroundColor Yellow

$results = @()

for ($i = 1; $i -le 10; $i++) {
    Write-Host "Request $i`: " -NoNewline -ForegroundColor White
    
    $startTime = Get-Date
    
    try {
        $response = Invoke-RestMethod -Uri $testEndpoint -Method Get -ErrorAction Stop
        $endTime = Get-Date
        $duration = [math]::Round(($endTime - $startTime).TotalMilliseconds, 0)
        
        Write-Host "✅ SUCCESS - ${duration}ms - State: $($response.stateAfter)" -ForegroundColor Green
        
        $results += [PSCustomObject]@{
            Request = $i
            Status = "SUCCESS"
            Duration = $duration
            State = $response.stateAfter
            FailureRate = $response.failureRateAfter
        }
        
    } catch {
        $endTime = Get-Date
        $duration = [math]::Round(($endTime - $startTime).TotalMilliseconds, 0)
        
        $errorResponse = $null
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errorBody = $reader.ReadToEnd()
            $errorResponse = $errorBody | ConvertFrom-Json
        }
        
        if ($errorResponse) {
            $stateAfter = $errorResponse.stateAfter
            $failureRate = $errorResponse.failureRateAfter
            $errorType = $errorResponse.errorType
            
            if ($errorType -eq "CallNotPermittedException") {
                Write-Host "⚡ CIRCUIT OPEN - ${duration}ms (instant!) - State: $stateAfter - Rate: $failureRate" -ForegroundColor Yellow
                
                if ($duration -lt 10) {
                    Write-Host "     └─ ✅ PERFECT! Circuit breaker rejecting instantly" -ForegroundColor Green
                }
            } else {
                $emoji = if ($stateAfter -eq "OPEN") { "🔴" } else { "❌" }
                Write-Host "$emoji FAILED - ${duration}ms - State: $stateAfter - Rate: $failureRate" -ForegroundColor Red
                
                if ($stateAfter -eq "OPEN" -and $i -eq 5) {
                    Write-Host "     └─ 🎯 Circuit breaker just OPENED! (as expected)" -ForegroundColor Green
                }
            }
            
            $results += [PSCustomObject]@{
                Request = $i
                Status = if ($errorType -eq "CallNotPermittedException") { "REJECTED" } else { "FAILED" }
                Duration = $duration
                State = $stateAfter
                FailureRate = $failureRate
            }
        } else {
            Write-Host "❌ ERROR - ${duration}ms" -ForegroundColor Red
            
            $results += [PSCustomObject]@{
                Request = $i
                Status = "ERROR"
                Duration = $duration
                State = "UNKNOWN"
                FailureRate = "N/A"
            }
        }
    }
    
    Start-Sleep -Milliseconds 500
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📊 RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$results | Format-Table -AutoSize

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🔍 FINAL STATE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    $final = Invoke-RestMethod -Uri $statusEndpoint -Method Get
    
    $stateEmoji = switch ($final.state) {
        "CLOSED" { "🟢" }
        "OPEN" { "🔴" }
        "HALF_OPEN" { "🟡" }
        default { "⚪" }
    }
    
    Write-Host "Circuit Breaker State: $stateEmoji $($final.state)" -ForegroundColor White
    Write-Host ""
    Write-Host "Metrics:" -ForegroundColor Yellow
    Write-Host "  • Failure Rate: $($final.metrics.failureRate)" -ForegroundColor White
    Write-Host "  • Failed Calls: $($final.metrics.failedCalls)" -ForegroundColor Red
    Write-Host "  • Successful Calls: $($final.metrics.successfulCalls)" -ForegroundColor Green
    Write-Host "  • Not Permitted Calls: $($final.metrics.notPermittedCalls)" -ForegroundColor Yellow
    Write-Host "  • Buffered Calls: $($final.metrics.bufferedCalls)" -ForegroundColor White
    Write-Host ""
    
    if ($final.state -eq "OPEN") {
        Write-Host "🎉 SUCCESS! Circuit breaker is OPEN!" -ForegroundColor Green
        Write-Host ""
        Write-Host "What happened:" -ForegroundColor Yellow
        Write-Host "  1. First few requests failed (App B down)" -ForegroundColor White
        Write-Host "  2. Failure rate exceeded 50% threshold" -ForegroundColor White
        Write-Host "  3. Circuit breaker opened to protect system" -ForegroundColor White
        Write-Host "  4. Subsequent requests rejected instantly (<1ms)" -ForegroundColor White
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  • Wait 30 seconds → Circuit goes to HALF_OPEN" -ForegroundColor White
        Write-Host "  • Start App B → Next request succeeds" -ForegroundColor White
        Write-Host "  • Circuit automatically closes → Normal operation" -ForegroundColor White
    } elseif ($final.state -eq "CLOSED") {
        Write-Host "⚠️  Circuit breaker is still CLOSED" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "  • Not enough failed calls yet (need $($final.configuration.minimumNumberOfCalls))" -ForegroundColor White
        Write-Host "  • Failure rate not high enough (need $($final.configuration.failureRateThreshold))" -ForegroundColor White
        Write-Host "  • App B might have come back online" -ForegroundColor White
        Write-Host ""
        Write-Host "Try again with App B confirmed DOWN" -ForegroundColor White
    }
    
} catch {
    Write-Host "❌ Error getting final status: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "📈 PERFORMANCE ANALYSIS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$failedRequests = $results | Where-Object { $_.Status -eq "FAILED" }
$rejectedRequests = $results | Where-Object { $_.Status -eq "REJECTED" }

if ($failedRequests.Count -gt 0) {
    $avgFailedDuration = ($failedRequests | Measure-Object -Property Duration -Average).Average
    Write-Host "Failed Requests (Circuit CLOSED):" -ForegroundColor Yellow
    Write-Host "  • Count: $($failedRequests.Count)" -ForegroundColor White
    Write-Host "  • Average Duration: $([math]::Round($avgFailedDuration, 0))ms" -ForegroundColor White
    Write-Host "  • Behavior: Retries with exponential backoff" -ForegroundColor Gray
    Write-Host ""
}

if ($rejectedRequests.Count -gt 0) {
    $avgRejectedDuration = ($rejectedRequests | Measure-Object -Property Duration -Average).Average
    Write-Host "Rejected Requests (Circuit OPEN):" -ForegroundColor Yellow
    Write-Host "  • Count: $($rejectedRequests.Count)" -ForegroundColor White
    Write-Host "  • Average Duration: $([math]::Round($avgRejectedDuration, 2))ms ⚡" -ForegroundColor Green
    Write-Host "  • Behavior: Instant rejection (no remote call)" -ForegroundColor Gray
    Write-Host ""
    
    if ($failedRequests.Count -gt 0) {
        $improvement = [math]::Round((($avgFailedDuration - $avgRejectedDuration) / $avgFailedDuration) * 100, 1)
        Write-Host "Performance Improvement: $improvement% faster when circuit OPEN!" -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "✅ TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "🎓 KEY LEARNINGS:`n" -ForegroundColor Yellow

Write-Host "1. Without Fallback → Circuit Opens" -ForegroundColor White
Write-Host "   Failures count as actual failures, not successes`n" -ForegroundColor Gray

Write-Host "2. Circuit Breaker Protection Works!" -ForegroundColor White
Write-Host "   After threshold: instant rejection (<1ms vs ~1000ms)`n" -ForegroundColor Gray

Write-Host "3. Production-Ready Pattern" -ForegroundColor White
Write-Host "   Some endpoints may not have fallbacks by design`n" -ForegroundColor Gray

Write-Host "4. Automatic Recovery" -ForegroundColor White
Write-Host "   Start App B → Circuit closes automatically`n" -ForegroundColor Gray

Write-Host "📊 COMPARE ENDPOINTS:`n" -ForegroundColor Yellow

Write-Host "  /api/resilience/app-b/status:" -ForegroundColor Cyan
Write-Host "    • User-friendly (always 200 OK)" -ForegroundColor Gray
Write-Host "    • Circuit stays CLOSED (fallback succeeds)" -ForegroundColor Gray
Write-Host "    • Use for: Non-critical operations`n" -ForegroundColor Gray

Write-Host "  /api/resilience/app-b/status/cb/test:" -ForegroundColor Cyan
Write-Host "    • Fail-fast behavior (500 errors)" -ForegroundColor Gray
Write-Host "    • Circuit OPENS after failures" -ForegroundColor Gray
Write-Host "    • Use for: Critical operations`n" -ForegroundColor Gray

Write-Host "🚀 TEST RECOVERY:`n" -ForegroundColor Yellow
Write-Host "  1. Start App B" -ForegroundColor White
Write-Host "  2. Wait 30 seconds (circuit goes HALF_OPEN)" -ForegroundColor White
Write-Host "  3. Call endpoint again" -ForegroundColor White
Write-Host "  4. Circuit closes automatically on success`n" -ForegroundColor White
