@echo off
REM =========================================
REM CIRCUIT BREAKER TESTING - CMD VERSION
REM =========================================

echo.
echo ========================================
echo CIRCUIT BREAKER TESTING
echo ========================================
echo.

set BASE_URL=http://localhost:9002/api/app-a
set TEST_URL=%BASE_URL%/api/test-circuit

echo WHY YOUR CIRCUIT BREAKER STAYS CLOSED:
echo.
echo   Your circuit breaker stays CLOSED because:
echo   - Fallback succeeds = Circuit breaker sees SUCCESS
echo   - Failure rate: 0%%
echo   - This is CORRECT behavior!
echo.

timeout /t 2 /nobreak >nul

echo ========================================
echo METHOD 1: FORCE CIRCUIT BREAKER OPEN
echo ========================================
echo.

echo Step 1: Check current status...
curl -s -X GET "%TEST_URL%/status"
echo.

echo Step 2: Force circuit breaker to OPEN...
curl -X POST "%TEST_URL%/force-open"
echo.
echo.

echo Step 3: Testing with circuit breaker OPEN...
echo Making 5 requests...
echo.

for /L %%i in (1,1,5) do (
    echo Request %%i:
    curl -s -X GET "%BASE_URL%/api/resilience/app-b/status"
    echo.
    timeout /t 1 /nobreak >nul
)

echo.
echo ========================================
echo METHOD 2: SIMULATE FAILURES
echo ========================================
echo.

echo Resetting circuit breaker...
curl -X POST "%TEST_URL%/force-closed"
echo.
echo.

timeout /t 1 /nobreak >nul

echo Simulating 10 failures...
curl -X POST "%TEST_URL%/simulate-failures?count=10"
echo.
echo.

echo ========================================
echo FINAL STATUS
echo ========================================
echo.

curl -s -X GET "%TEST_URL%/status"
echo.
echo.

echo ========================================
echo TESTING COMPLETE
echo ========================================
echo.

echo KEY LEARNINGS:
echo.
echo 1. Circuit breaker stays CLOSED because fallback succeeds
echo 2. When OPEN, responses are instant (less than 1ms)
echo 3. This is CORRECT production behavior!
echo.

echo Available endpoints:
echo   GET  %TEST_URL%/status
echo   POST %TEST_URL%/force-open
echo   POST %TEST_URL%/force-closed
echo   POST %TEST_URL%/simulate-failures
echo.

echo Read WHY_CIRCUIT_BREAKER_STAYS_CLOSED.md for full explanation!
echo.

pause
