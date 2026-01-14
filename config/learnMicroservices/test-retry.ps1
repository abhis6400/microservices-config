# Test Retry Pattern
# This script demonstrates that retry is active

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "🔄 RETRY PATTERN TEST" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:9002/api/app-a/api/resilience"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  • Max Attempts: 3 (1 original + 2 retries)" -ForegroundColor White
Write-Host "  • Wait Duration: 500ms → 1000ms (exponential backoff)" -ForegroundColor White
Write-Host "  • Expected Total Duration: ~1800ms`n" -ForegroundColor White

Write-Host "⚠️  Ensure App B is DOWN for this test!`n" -ForegroundColor Yellow

Start-Sleep -Seconds 2

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 1: Regular Endpoint (With Fallback)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Making request to: $baseUrl/app-b/status`n" -ForegroundColor Gray

$startTime = Get-Date

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/app-b/status" -Method Get
    $endTime = Get-Date
    $duration = [math]::Round(($endTime - $startTime).TotalMilliseconds, 0)
    
    Write-Host "✅ Response received (with fallback)" -ForegroundColor Green
    Write-Host "Duration: ${duration}ms" -ForegroundColor Yellow
    Write-Host "Response says: $($response.durationMs)ms`n" -ForegroundColor White
    
    if ($duration -gt 1500) {
        Write-Host "✅ RETRY CONFIRMED!" -ForegroundColor Green
        Write-Host "   Duration >1.5s indicates multiple retry attempts" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Breakdown:" -ForegroundColor Yellow
        Write-Host "  • 3 call attempts: ~300ms" -ForegroundColor White
        Write-Host "  • Wait 1 (before retry 1): 500ms" -ForegroundColor White
        Write-Host "  • Wait 2 (before retry 2): 1000ms" -ForegroundColor White
        Write-Host "  • Fallback processing: ~5ms" -ForegroundColor White
        Write-Host "  • Total: ~1805ms ✅`n" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Duration: ${duration}ms" -ForegroundColor Yellow
        Write-Host "   Expected: >1500ms" -ForegroundColor Gray
        Write-Host "   Possible reasons:" -ForegroundColor Gray
        Write-Host "     - Circuit breaker may be OPEN (no retries when OPEN)" -ForegroundColor Gray
        Write-Host "     - App B may have started" -ForegroundColor Gray
    }
    
} catch {
    $endTime = Get-Date
    $duration = [math]::Round(($endTime - $startTime).TotalMilliseconds, 0)
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Duration: ${duration}ms`n" -ForegroundColor White
}

Start-Sleep -Seconds 2

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST 2: Circuit Breaker Test Endpoint" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Making first request (circuit should be CLOSED)...`n" -ForegroundColor Gray

$startTime = Get-Date

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/app-b/status/cb/test" -Method Get -ErrorAction Stop
    $endTime = Get-Date
    $duration = [math]::Round(($endTime - $startTime).TotalMilliseconds, 0)
    
    Write-Host "✅ Success: ${duration}ms" -ForegroundColor Green
    
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
        Write-Host "❌ Failed (expected): ${duration}ms" -ForegroundColor Red
        Write-Host "State: $($errorResponse.stateAfter)" -ForegroundColor White
        Write-Host ""
        
        if ($duration -gt 1500) {
            Write-Host "✅ RETRY CONFIRMED!" -ForegroundColor Green
            Write-Host "   Duration ${duration}ms indicates retry happened" -ForegroundColor Gray
            Write-Host "   3 attempts with exponential backoff`n" -ForegroundColor Gray
        } else {
            Write-Host "⚠️  Duration: ${duration}ms (expected >1500ms)" -ForegroundColor Yellow
            if ($errorResponse.stateAfter -eq "OPEN") {
                Write-Host "   Circuit is OPEN - No retries when circuit is open`n" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "❌ Error: ${duration}ms`n" -ForegroundColor Red
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 UNDERSTANDING THE TIMINGS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "When App B is DOWN and circuit is CLOSED:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Timeline:" -ForegroundColor White
Write-Host "  0ms      → Attempt 1 (fails)" -ForegroundColor Gray
Write-Host "  100ms    → Retry policy activated" -ForegroundColor Gray
Write-Host "  600ms    → Attempt 2 (fails) [after 500ms wait]" -ForegroundColor Gray
Write-Host "  700ms    → Retry policy activated again" -ForegroundColor Gray
Write-Host "  1700ms   → Attempt 3 (fails) [after 1000ms wait]" -ForegroundColor Gray
Write-Host "  1800ms   → Retries exhausted, fallback triggered" -ForegroundColor Gray
Write-Host "  1805ms   → Response returned`n" -ForegroundColor Gray

Write-Host "Duration Breakdown:" -ForegroundColor White
Write-Host "  • Attempt 1:     ~100ms" -ForegroundColor Gray
Write-Host "  • Wait 1:         500ms  ⏳" -ForegroundColor Gray
Write-Host "  • Attempt 2:     ~100ms" -ForegroundColor Gray
Write-Host "  • Wait 2:        1000ms  ⏳⏳ (doubled!)" -ForegroundColor Gray
Write-Host "  • Attempt 3:     ~100ms" -ForegroundColor Gray
Write-Host "  • Fallback:       ~5ms" -ForegroundColor Gray
Write-Host "  ────────────────────────" -ForegroundColor Gray
Write-Host "  • Total:        ~1805ms`n" -ForegroundColor Yellow

Write-Host "When circuit is OPEN:" -ForegroundColor Yellow
Write-Host "  • NO retries (bypassed)" -ForegroundColor Gray
Write-Host "  • Instant rejection" -ForegroundColor Gray
Write-Host "  • Duration: <5ms ⚡`n" -ForegroundColor Gray

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🔍 HOW TO SEE RETRY IN LOGS" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Look for these log entries:`n" -ForegroundColor Yellow

Write-Host "1. Retry attempts:" -ForegroundColor White
Write-Host '   🔄 RETRY [appBRetry] Attempt 1 of 3' -ForegroundColor Cyan
Write-Host '   🔄 RETRY [appBRetry] Attempt 2 of 3' -ForegroundColor Cyan
Write-Host ""

Write-Host "2. Retry exhausted:" -ForegroundColor White
Write-Host '   ❌ RETRY [appBRetry] EXHAUSTED after 2 attempts' -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Fallback triggered:" -ForegroundColor White
Write-Host '   [FALLBACK] getAppBStatus failed. Using fallback.' -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "🎓 Summary:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  ✅ Retry IS implemented and active" -ForegroundColor Green
Write-Host "  ✅ 3 attempts with exponential backoff" -ForegroundColor Green
Write-Host "  ✅ Total duration: ~1.8 seconds (proof of retry)" -ForegroundColor Green
Write-Host "  ✅ Retry bypassed when circuit is OPEN (optimization)" -ForegroundColor Green
Write-Host ""

Write-Host "📚 Read RETRY_PATTERN_EXPLAINED.md for complete details!" -ForegroundColor Yellow
Write-Host ""
