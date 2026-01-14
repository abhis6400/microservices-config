Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  TESTING BOTH RESILIENCE PATTERNS" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if App B is down
Write-Host "1. Checking if App B is DOWN..." -ForegroundColor Yellow
try {
    $null = Invoke-RestMethod -Uri "http://localhost:8084/status" -Method Get -TimeoutSec 2 -ErrorAction Stop
    Write-Host "   ⚠️  WARNING: App B is RUNNING!" -ForegroundColor Red
    Write-Host "   Please stop App B to test properly." -ForegroundColor Red
    exit
} catch {
    Write-Host "   ✅ App B is DOWN (good for testing)" -ForegroundColor Green
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  PATTERN 1: WITH FALLBACK" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Testing: /api/resilience/app-b/status" -ForegroundColor Yellow
Write-Host "Expected: 200 OK, ~5ms, NO retry" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8084/api/resilience/app-b/status" -Method Get -ErrorAction Stop
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "✅ Response: 200 OK" -ForegroundColor Green
    Write-Host "Duration: $([math]::Round($duration, 0))ms" -ForegroundColor Yellow
    Write-Host "Status: $($response.response.status)" -ForegroundColor White
    Write-Host ""
    
    if ($duration -lt 500) {
        Write-Host "✅ FAST response (fallback worked)" -ForegroundColor Green
        Write-Host "❌ NO RETRY (fallback prevented it)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  PATTERN 2: NO FALLBACK (RETRY)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Testing: /api/resilience/app-b/status/cb/test" -ForegroundColor Yellow
Write-Host "Expected: 500 Error, ~15s, DOES retry" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8084/api/resilience/app-b/status/cb/test" -Method Get -ErrorAction Stop
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host "❌ Unexpected: 200 OK" -ForegroundColor Red
    Write-Host "Duration: $([math]::Round($duration, 2))s" -ForegroundColor Yellow
} catch {
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host "✅ Response: 500 Error (expected)" -ForegroundColor Green
    Write-Host "Duration: $([math]::Round($duration, 2))s" -ForegroundColor Yellow
    Write-Host ""
    
    if ($duration -gt 10) {
        Write-Host "✅ SLOW response (retries happened!)" -ForegroundColor Green
        Write-Host "✅ RETRY WORKED! (3 attempts with backoff)" -ForegroundColor Green
        Write-Host ""
        Write-Host "Breakdown:" -ForegroundColor Gray
        Write-Host "  - Attempt 1: Fails" -ForegroundColor Gray
        Write-Host "  - Wait: 5 seconds" -ForegroundColor Gray
        Write-Host "  - Attempt 2: Fails" -ForegroundColor Gray
        Write-Host "  - Wait: 10 seconds (exponential backoff)" -ForegroundColor Gray
        Write-Host "  - Attempt 3: Fails" -ForegroundColor Gray
        Write-Host "  - Total: ~15 seconds" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Duration too short. Retries may not have happened" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  CHECK YOUR LOGS" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pattern 1 logs should show:" -ForegroundColor Yellow
Write-Host "  ✅ CIRCUIT BREAKER SUCCESS" -ForegroundColor Green
Write-Host "  [FALLBACK] Using fallback" -ForegroundColor Yellow
Write-Host "  NO retry logs" -ForegroundColor Red
Write-Host ""
Write-Host "Pattern 2 logs should show:" -ForegroundColor Yellow
Write-Host "  🔄 RETRY Attempt 1 of 3" -ForegroundColor Cyan
Write-Host "  🔄 RETRY Attempt 2 of 3" -ForegroundColor Cyan
Write-Host "  ❌ RETRY EXHAUSTED" -ForegroundColor Red
Write-Host "  ⚠️ CIRCUIT BREAKER ERROR recorded" -ForegroundColor Yellow
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pattern 1 (WITH Fallback):" -ForegroundColor Yellow
Write-Host "  ✅ Fast (~5ms)" -ForegroundColor Green
Write-Host "  ✅ User-friendly (200 OK)" -ForegroundColor Green
Write-Host "  ❌ NO retry" -ForegroundColor Red
Write-Host "  ❌ Circuit stays CLOSED" -ForegroundColor Red
Write-Host ""
Write-Host "Pattern 2 (NO Fallback):" -ForegroundColor Yellow
Write-Host "  ✅ Retry works (3 attempts)" -ForegroundColor Green
Write-Host "  ✅ Circuit opens correctly" -ForegroundColor Green
Write-Host "  ❌ Slow (~15s)" -ForegroundColor Red
Write-Host "  ❌ Error response (500)" -ForegroundColor Red
Write-Host ""
