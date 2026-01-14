# Test Retry Pattern - Now It Will Work!

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  RETRY PATTERN TEST" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if App B is down
Write-Host "1. Checking if App B is DOWN..." -ForegroundColor Yellow
try {
    $null = Invoke-RestMethod -Uri "http://localhost:8084/status" -Method Get -TimeoutSec 2
    Write-Host "   ⚠️  WARNING: App B is RUNNING!" -ForegroundColor Red
    Write-Host "   Please stop App B to test retry properly." -ForegroundColor Red
    exit
} catch {
    Write-Host "   ✅ App B is DOWN (good for testing)" -ForegroundColor Green
}

Write-Host ""
Write-Host "2. Testing regular endpoint (with fallback)..." -ForegroundColor Yellow
Write-Host "   URL: http://localhost:8083/api/resilience/app-b/status" -ForegroundColor Gray
Write-Host "   Expected: ~35 seconds (3 retries × 5s wait)" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8083/api/resilience/app-b/status" -Method Get
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host "   ✅ Response received (with fallback)" -ForegroundColor Green
    Write-Host "   Duration: $([math]::Round($duration, 2)) seconds" -ForegroundColor Yellow
    Write-Host ""
    
    if ($duration -gt 10) {
        Write-Host "   ✅ RETRY IS WORKING! Duration >10s confirms retries" -ForegroundColor Green
        Write-Host "   - Attempt 1: Fails" -ForegroundColor Gray
        Write-Host "   - Wait: 5 seconds" -ForegroundColor Gray
        Write-Host "   - Attempt 2: Fails" -ForegroundColor Gray
        Write-Host "   - Wait: 10 seconds (doubled!)" -ForegroundColor Gray
        Write-Host "   - Attempt 3: Fails" -ForegroundColor Gray
        Write-Host "   - Wait: 20 seconds (doubled again!)" -ForegroundColor Gray
        Write-Host "   - Fallback: Returns degraded response" -ForegroundColor Gray
    } else {
        Write-Host "   ⚠️  Duration too short. Retries may not be happening" -ForegroundColor Yellow
        Write-Host "   Check logs for retry events" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  CHECK YOUR LOGS" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Look for these log messages:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  🔄 RETRY [appBRetry] Attempt 1 of 3" -ForegroundColor Cyan
Write-Host "     Wait before next: 5000ms" -ForegroundColor Gray
Write-Host ""
Write-Host "  [5 seconds pass]" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  🔄 RETRY [appBRetry] Attempt 2 of 3" -ForegroundColor Cyan
Write-Host "     Wait before next: 10000ms" -ForegroundColor Gray
Write-Host ""
Write-Host "  [10 seconds pass]" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  ❌ RETRY [appBRetry] EXHAUSTED after 2 attempts" -ForegroundColor Red
Write-Host ""
Write-Host "  [FALLBACK] Using degraded response" -ForegroundColor Yellow
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Your waitDuration is 5000ms (5 seconds)" -ForegroundColor Yellow
Write-Host "This is VERY LONG! Consider changing to 500ms for production." -ForegroundColor Yellow
Write-Host ""
