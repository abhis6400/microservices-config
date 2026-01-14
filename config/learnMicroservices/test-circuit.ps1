# Circuit Breaker Test Script
# Run this after rebuilding app-a with CircuitBreakerTestController

$baseUrl = "http://localhost:9002/api/app-a"
$testUrl = "$baseUrl/api/test-circuit"

Write-Host "`n========== CIRCUIT BREAKER TEST ==========`n" -ForegroundColor Cyan

Write-Host "Why your circuit breaker stays CLOSED:" -ForegroundColor Yellow
Write-Host "- Fallback succeeds = Circuit breaker sees SUCCESS" -ForegroundColor White
Write-Host "- This is CORRECT behavior!`n" -ForegroundColor Green

Write-Host "Step 1: Checking current status..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod -Uri "$testUrl/status" -Method Get
    Write-Host "State: $($status.state)" -ForegroundColor Green
    Write-Host "Failure Rate: $($status.metrics.failureRate)`n" -ForegroundColor White
} catch {
    Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
    Write-Host "Make sure app-a is rebuilt and running!" -ForegroundColor Yellow
    exit
}

Write-Host "Step 2: Forcing circuit breaker to OPEN..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$testUrl/force-open" -Method Post
    Write-Host "Success! State: $($response.currentState)`n" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "Step 3: Testing with circuit OPEN (should be instant)..." -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Request $i`: " -NoNewline
    $startTime = Get-Date
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/api/resilience/app-b/status" -Method Get
        $endTime = Get-Date
        $duration = [math]::Round(($endTime - $startTime).TotalMilliseconds, 2)
        Write-Host "${duration}ms" -ForegroundColor Yellow
    } catch {
        Write-Host "Error" -ForegroundColor Red
    }
    
    Start-Sleep -Milliseconds 200
}

Write-Host "`nStep 4: Resetting circuit breaker..." -ForegroundColor Yellow
try {
    $reset = Invoke-RestMethod -Uri "$testUrl/force-closed" -Method Post
    Write-Host "Success! $($reset.message)`n" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "Step 5: Simulating failures..." -ForegroundColor Yellow
try {
    $sim = Invoke-RestMethod -Uri "$testUrl/simulate-failures?count=10" -Method Post
    Write-Host "Failures recorded: $($sim.failuresRecorded)" -ForegroundColor White
    Write-Host "State: $($sim.currentState)" -ForegroundColor White
    Write-Host "Failure Rate: $($sim.failureRate)`n" -ForegroundColor White
} catch {
    Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "Final Status:" -ForegroundColor Yellow
try {
    $final = Invoke-RestMethod -Uri "$testUrl/status" -Method Get
    Write-Host "State: $($final.state)" -ForegroundColor White
    Write-Host "Failure Rate: $($final.metrics.failureRate)" -ForegroundColor White
    Write-Host "Failed Calls: $($final.metrics.numberOfFailedCalls)" -ForegroundColor White
    Write-Host "Successful Calls: $($final.metrics.numberOfSuccessfulCalls)`n" -ForegroundColor White
} catch {
    Write-Host "Error: $($_.Exception.Message)`n" -ForegroundColor Red
}

Write-Host "========== TEST COMPLETE ==========`n" -ForegroundColor Cyan
Write-Host "Read WHY_CIRCUIT_BREAKER_STAYS_CLOSED.md for full explanation!" -ForegroundColor Yellow
