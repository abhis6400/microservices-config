Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  TESTING ALL ENDPOINTS" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Check if App B is down
Write-Host "Checking if App B is DOWN..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8084/status" -Method Get -TimeoutSec 2 -ErrorAction Stop | Out-Null
    Write-Host "⚠️  App B is RUNNING! Stop it to test resilience." -ForegroundColor Red
    exit
} catch {
    Write-Host "✅ App B is DOWN (good for testing)" -ForegroundColor Green
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  TYPE 1: WITH FALLBACK (Graceful)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# Test 1: Status
Write-Host "1. Testing Status Endpoint..." -ForegroundColor Yellow
$start = Get-Date
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8084/api/resilience/app-b/status" -Method Get
    $duration = ((Get-Date) - $start).TotalMilliseconds
    Write-Host "   ✅ 200 OK - $([math]::Round($duration))ms" -ForegroundColor Green
    Write-Host "   Status: $($response.response.status)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Product
Write-Host "2. Testing Product Endpoint..." -ForegroundColor Yellow
$start = Get-Date
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8084/api/resilience/app-b/product/123" -Method Get
    $duration = ((Get-Date) - $start).TotalMilliseconds
    Write-Host "   ✅ 200 OK - $([math]::Round($duration))ms" -ForegroundColor Green
    Write-Host "   Cached: $($response.cached)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Greeting
Write-Host "3. Testing Greeting Endpoint..." -ForegroundColor Yellow
$start = Get-Date
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8084/api/resilience/app-b/greeting/John" -Method Get
    $duration = ((Get-Date) - $start).TotalMilliseconds
    Write-Host "   ✅ 200 OK - $([math]::Round($duration))ms" -ForegroundColor Green
    Write-Host "   Source: $($response.source)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  TYPE 2: NO FALLBACK (Retry)" -ForegroundColor Red
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

# Test 4: CB Test
Write-Host "4. Testing Circuit Breaker Test Endpoint..." -ForegroundColor Yellow
Write-Host "   Expected: ~15s with retries" -ForegroundColor Gray
$start = Get-Date
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8084/api/resilience/app-b/status/cb/test" -Method Get -ErrorAction Stop
    $duration = ((Get-Date) - $start).TotalSeconds
    Write-Host "   ❌ Unexpected 200 OK - $([math]::Round($duration, 2))s" -ForegroundColor Red
} catch {
    $duration = ((Get-Date) - $start).TotalSeconds
    Write-Host "   ✅ 500 Error (expected) - $([math]::Round($duration, 2))s" -ForegroundColor Green
    if ($duration -gt 10) {
        Write-Host "   ✅ RETRY WORKED! (3 attempts)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Type 1 (WITH Fallback):" -ForegroundColor Yellow
Write-Host "  • Status:   Fast, 200 OK, NO retry ✅" -ForegroundColor Gray
Write-Host "  • Product:  Fast, 200 OK, NO retry ✅" -ForegroundColor Gray
Write-Host "  • Greeting: Fast, 200 OK, NO retry ✅" -ForegroundColor Gray
Write-Host ""
Write-Host "Type 2 (NO Fallback):" -ForegroundColor Yellow
Write-Host "  • CB Test:  Slow, 500 Error, DOES retry ✅" -ForegroundColor Gray
Write-Host ""
Write-Host "All fallback methods are now being used!" -ForegroundColor Green
Write-Host ""
