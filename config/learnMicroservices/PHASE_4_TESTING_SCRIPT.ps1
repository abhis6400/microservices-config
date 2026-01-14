# 🧪 PHASE 4: Quick Testing Script - Before vs After

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "PHASE 4: RESILIENCE TESTING - BEFORE vs AFTER COMPARISON" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Test URLs
$oldEndpoint = "http://localhost:8080/api/app-a/call-app-b/status"
$newEndpoint = "http://localhost:8080/api/resilience/app-b/status"
$circuitStatus = "http://localhost:8080/api/resilience/circuit-breaker/status"

Write-Host "Test Endpoints:" -ForegroundColor Yellow
Write-Host "  OLD (No Resilience): $oldEndpoint" -ForegroundColor Gray
Write-Host "  NEW (With Resilience): $newEndpoint" -ForegroundColor Gray
Write-Host ""

# Function to make HTTP request and measure time
function Test-Endpoint {
    param(
        [string]$Url,
        [string]$Name
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    Write-Host "URL: $Url" -ForegroundColor Gray
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 35 -ErrorAction Stop
        $stopwatch.Stop()
        
        Write-Host "✅ SUCCESS" -ForegroundColor Green
        Write-Host "   Response Time: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
        
        if ($response.circuitBreakerState) {
            Write-Host "   Circuit Breaker State: $($response.circuitBreakerState)" -ForegroundColor Cyan
            Write-Host "   Failure Rate: $($response.failureRate)" -ForegroundColor Cyan
        }
        
        return @{
            Success = $true
            Duration = $stopwatch.ElapsedMilliseconds
            Response = $response
        }
    }
    catch {
        $stopwatch.Stop()
        
        Write-Host "❌ FAILED" -ForegroundColor Red
        Write-Host "   Response Time: $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        
        return @{
            Success = $false
            Duration = $stopwatch.ElapsedMilliseconds
            Error = $_.Exception.Message
        }
    }
    finally {
        Write-Host ""
    }
}

# TEST MENU
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "SELECT TEST SCENARIO:" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Test BOTH endpoints (App B should be UP)" -ForegroundColor White
Write-Host "2. Test OLD endpoint only (watch it timeout if App B is down)" -ForegroundColor White
Write-Host "3. Test NEW endpoint only (watch it handle failure gracefully)" -ForegroundColor White
Write-Host "4. Trigger Circuit Breaker (call NEW endpoint 10 times)" -ForegroundColor White
Write-Host "5. View Circuit Breaker Status" -ForegroundColor White
Write-Host "6. Compare response times (5 calls each)" -ForegroundColor White
Write-Host "7. Simulate load (50 concurrent requests to NEW endpoint)" -ForegroundColor White
Write-Host "Q. Quit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice"

switch ($choice) {
    "1" {
        Write-Host "`n==== TEST 1: Both Endpoints (Normal Operation) ====" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "--- OLD Controller (No Resilience) ---" -ForegroundColor Yellow
        $oldResult = Test-Endpoint -Url $oldEndpoint -Name "OLD Controller"
        
        Write-Host "--- NEW Controller (With Resilience) ---" -ForegroundColor Yellow
        $newResult = Test-Endpoint -Url $newEndpoint -Name "NEW Controller"
        
        Write-Host "COMPARISON:" -ForegroundColor Cyan
        Write-Host "  OLD Response Time: $($oldResult.Duration)ms" -ForegroundColor Gray
        Write-Host "  NEW Response Time: $($newResult.Duration)ms" -ForegroundColor Gray
        $overhead = $newResult.Duration - $oldResult.Duration
        Write-Host "  Resilience Overhead: ${overhead}ms (~5-10ms is normal)" -ForegroundColor Gray
    }
    
    "2" {
        Write-Host "`n==== TEST 2: OLD Controller Only ====" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⚠️  WARNING: If App B is down, this will hang for 30 seconds!" -ForegroundColor Yellow
        Write-Host "⚠️  Press Ctrl+C to cancel if you don't want to wait" -ForegroundColor Yellow
        Write-Host ""
        Start-Sleep -Seconds 2
        
        Test-Endpoint -Url $oldEndpoint -Name "OLD Controller (No Protection)"
    }
    
    "3" {
        Write-Host "`n==== TEST 3: NEW Controller Only ====" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "✅ This should handle failures gracefully (max 3.5 seconds)" -ForegroundColor Green
        Write-Host ""
        
        Test-Endpoint -Url $newEndpoint -Name "NEW Controller (With Resilience)"
    }
    
    "4" {
        Write-Host "`n==== TEST 4: Trigger Circuit Breaker ====" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Making 10 requests to trigger circuit breaker..." -ForegroundColor Yellow
        Write-Host "⚠️  Make sure App B is DOWN to see circuit breaker in action!" -ForegroundColor Yellow
        Write-Host ""
        
        $results = @()
        
        for ($i = 1; $i -le 10; $i++) {
            Write-Host "Request $i of 10:" -ForegroundColor Cyan
            $result = Test-Endpoint -Url $newEndpoint -Name "NEW Controller"
            $results += $result
            
            if ($i -eq 5) {
                Write-Host "🔴 Circuit should open around here (after ~5 failures)..." -ForegroundColor Yellow
                Write-Host ""
            }
        }
        
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "RESULTS SUMMARY:" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        
        $avgTime = ($results | Measure-Object -Property Duration -Average).Average
        Write-Host "Average Response Time: ${avgTime}ms" -ForegroundColor White
        
        $first5 = ($results[0..4] | Measure-Object -Property Duration -Average).Average
        $last5 = ($results[5..9] | Measure-Object -Property Duration -Average).Average
        
        Write-Host "First 5 requests: ${first5}ms (before circuit opens)" -ForegroundColor Gray
        Write-Host "Last 5 requests: ${last5}ms (after circuit opens)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "If circuit opened correctly:" -ForegroundColor Yellow
        Write-Host "  - First 5: ~3500ms (retrying)" -ForegroundColor Yellow
        Write-Host "  - Last 5: < 10ms (failing fast)" -ForegroundColor Yellow
        Write-Host ""
        
        Write-Host "Checking circuit breaker status..." -ForegroundColor Cyan
        try {
            $status = Invoke-RestMethod -Uri $circuitStatus -Method Get
            Write-Host "Circuit Breaker State: $($status.state)" -ForegroundColor $(if ($status.state -eq "OPEN") { "Red" } else { "Green" })
            Write-Host "Failure Rate: $($status.metrics.failureRate)" -ForegroundColor Gray
        }
        catch {
            Write-Host "Could not get circuit breaker status" -ForegroundColor Red
        }
    }
    
    "5" {
        Write-Host "`n==== TEST 5: View Circuit Breaker Status ====" -ForegroundColor Cyan
        Write-Host ""
        
        try {
            $status = Invoke-RestMethod -Uri $circuitStatus -Method Get
            
            Write-Host "Circuit Breaker: $($status.name)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "STATE: $($status.state)" -ForegroundColor $(
                switch ($status.state) {
                    "CLOSED" { "Green" }
                    "OPEN" { "Red" }
                    "HALF_OPEN" { "Yellow" }
                    default { "Gray" }
                }
            )
            Write-Host "$($status.stateExplanation)" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "METRICS:" -ForegroundColor Yellow
            Write-Host "  Failure Rate: $($status.metrics.failureRate)" -ForegroundColor White
            Write-Host "  Slow Call Rate: $($status.metrics.slowCallRate)" -ForegroundColor White
            Write-Host "  Buffered Calls: $($status.metrics.bufferedCalls)" -ForegroundColor White
            Write-Host "  Failed Calls: $($status.metrics.failedCalls)" -ForegroundColor White
            Write-Host "  Successful Calls: $($status.metrics.successfulCalls)" -ForegroundColor White
            Write-Host "  Not Permitted Calls: $($status.metrics.notPermittedCalls)" -ForegroundColor White
            Write-Host ""
            
            Write-Host "CONFIGURATION:" -ForegroundColor Yellow
            Write-Host "  Failure Rate Threshold: $($status.configuration.failureRateThreshold)" -ForegroundColor White
            Write-Host "  Sliding Window Size: $($status.configuration.slidingWindowSize)" -ForegroundColor White
            Write-Host "  Minimum Number of Calls: $($status.configuration.minimumNumberOfCalls)" -ForegroundColor White
        }
        catch {
            Write-Host "❌ Could not get circuit breaker status" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    "6" {
        Write-Host "`n==== TEST 6: Compare Response Times (5 calls each) ====" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Testing OLD Controller (5 calls)..." -ForegroundColor Yellow
        $oldTimes = @()
        for ($i = 1; $i -le 5; $i++) {
            Write-Host "  Call $i..." -NoNewline
            $result = Test-Endpoint -Url $oldEndpoint -Name "OLD"
            $oldTimes += $result.Duration
            Write-Host " $($result.Duration)ms"
        }
        
        Write-Host ""
        Write-Host "Testing NEW Controller (5 calls)..." -ForegroundColor Yellow
        $newTimes = @()
        for ($i = 1; $i -le 5; $i++) {
            Write-Host "  Call $i..." -NoNewline
            $result = Test-Endpoint -Url $newEndpoint -Name "NEW"
            $newTimes += $result.Duration
            Write-Host " $($result.Duration)ms"
        }
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "RESULTS:" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        
        $oldAvg = ($oldTimes | Measure-Object -Average).Average
        $newAvg = ($newTimes | Measure-Object -Average).Average
        
        Write-Host "OLD Controller Average: ${oldAvg}ms" -ForegroundColor White
        Write-Host "NEW Controller Average: ${newAvg}ms" -ForegroundColor White
        Write-Host ""
        
        if ($oldAvg -gt 5000) {
            Write-Host "⚠️  OLD controller is very slow (> 5 seconds)" -ForegroundColor Red
            Write-Host "    This suggests App B is down or slow" -ForegroundColor Red
        }
        
        if ($newAvg -lt 100) {
            Write-Host "✅ NEW controller is very fast (< 100ms)" -ForegroundColor Green
            Write-Host "    Circuit breaker is likely OPEN (failing fast)" -ForegroundColor Green
        }
    }
    
    "7" {
        Write-Host "`n==== TEST 7: Load Test (50 concurrent requests) ====" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "⚠️  This will send 50 concurrent requests to NEW endpoint" -ForegroundColor Yellow
        Write-Host "⚠️  Make sure App B is DOWN to see bulkhead protection!" -ForegroundColor Yellow
        Write-Host ""
        $confirm = Read-Host "Continue? (Y/N)"
        
        if ($confirm -eq "Y" -or $confirm -eq "y") {
            Write-Host ""
            Write-Host "Sending 50 concurrent requests..." -ForegroundColor Cyan
            
            $jobs = 1..50 | ForEach-Object {
                Start-Job -ScriptBlock {
                    param($url)
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    try {
                        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 10
                        $stopwatch.Stop()
                        return @{
                            Success = $true
                            Duration = $stopwatch.ElapsedMilliseconds
                        }
                    }
                    catch {
                        $stopwatch.Stop()
                        return @{
                            Success = $false
                            Duration = $stopwatch.ElapsedMilliseconds
                        }
                    }
                } -ArgumentList $newEndpoint
            }
            
            Write-Host "Waiting for all requests to complete..." -ForegroundColor Yellow
            $results = $jobs | Wait-Job | Receive-Job
            $jobs | Remove-Job
            
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host "LOAD TEST RESULTS:" -ForegroundColor Cyan
            Write-Host "============================================================" -ForegroundColor Cyan
            
            $successful = ($results | Where-Object { $_.Success }).Count
            $failed = ($results | Where-Object { -not $_.Success }).Count
            
            Write-Host "Successful: $successful / 50" -ForegroundColor Green
            Write-Host "Failed: $failed / 50" -ForegroundColor $(if ($failed -gt 0) { "Yellow" } else { "Green" })
            
            $avgDuration = ($results | Measure-Object -Property Duration -Average).Average
            $minDuration = ($results | Measure-Object -Property Duration -Minimum).Minimum
            $maxDuration = ($results | Measure-Object -Property Duration -Maximum).Maximum
            
            Write-Host ""
            Write-Host "Response Times:" -ForegroundColor Yellow
            Write-Host "  Average: ${avgDuration}ms" -ForegroundColor White
            Write-Host "  Min: ${minDuration}ms" -ForegroundColor White
            Write-Host "  Max: ${maxDuration}ms" -ForegroundColor White
            
            Write-Host ""
            Write-Host "ANALYSIS:" -ForegroundColor Yellow
            if ($avgDuration -lt 1000) {
                Write-Host "✅ System handled load well (avg < 1s)" -ForegroundColor Green
                Write-Host "   Bulkhead and circuit breaker protected the system" -ForegroundColor Green
            }
            else {
                Write-Host "⚠️  System was under stress (avg > 1s)" -ForegroundColor Yellow
                Write-Host "   But no catastrophic failure - resilience patterns working!" -ForegroundColor Yellow
            }
        }
    }
    
    "Q" {
        Write-Host "Exiting..." -ForegroundColor Gray
        exit
    }
    
    default {
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Test complete! Press any key to exit..." -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
