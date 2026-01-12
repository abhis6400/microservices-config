# ============================================================================
# 🚀 START LOAD BALANCING DEMO - Multiple Instances
# ============================================================================
# This script starts multiple instances of App A and App B to demonstrate
# Load Balancing capabilities of the API Gateway
# ============================================================================

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║        🚀 LOAD BALANCING DEMO - Starting Multiple Instances   ║
║                                                                ║
║        Current Architecture:                                  ║
║        ├─ Eureka Server (8761)                                ║
║        ├─ Config Server (8888)                                ║
║        ├─ API Gateway (9002)                                  ║
║        ├─ App A Instance 1 (8080)                             ║
║        ├─ App A Instance 2 (8081) ← NEW                       ║
║        ├─ App A Instance 3 (8082) ← NEW                       ║
║        ├─ App B Instance 1 (8083) ← NEW                       ║
║        ├─ App B Instance 2 (8084) ← NEW                       ║
║        └─ App B Instance 3 (8085) ← NEW                       ║
║                                                                ║
║        Total: 9 running services!                             ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@

# Define base directories
$appADir = "C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a"
$appBDir = "C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-b"

Write-Host "`n⏳ Starting App A - Instance 1 (Port 8080)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd $appADir; java -jar target/app-a-1.0.0.jar --server.port=8080"

Write-Host "⏳ Starting App A - Instance 2 (Port 8081)..." -ForegroundColor Cyan
Start-Sleep -Seconds 3
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd $appADir; java -jar target/app-a-1.0.0.jar --server.port=8081"

Write-Host "⏳ Starting App A - Instance 3 (Port 8082)..." -ForegroundColor Cyan
Start-Sleep -Seconds 3
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd $appADir; java -jar target/app-a-1.0.0.jar --server.port=8082"

Write-Host "`n⏳ Starting App B - Instance 1 (Port 8083)..." -ForegroundColor Green
Start-Sleep -Seconds 3
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd $appBDir; java -jar target/app-b-1.0.0.jar --server.port=8083"

Write-Host "⏳ Starting App B - Instance 2 (Port 8084)..." -ForegroundColor Green
Start-Sleep -Seconds 3
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd $appBDir; java -jar target/app-b-1.0.0.jar --server.port=8084"

Write-Host "⏳ Starting App B - Instance 3 (Port 8085)..." -ForegroundColor Green
Start-Sleep -Seconds 3
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd $appBDir; java -jar target/app-b-1.0.0.jar --server.port=8085"

Write-Host @"

╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║        ✅ ALL INSTANCES STARTING...                           ║
║                                                                ║
║        Wait 30-40 seconds for all to register with Eureka     ║
║                                                                ║
║        Check Eureka Dashboard:                                ║
║        → http://localhost:8761                                ║
║                                                                ║
║        You should see:                                        ║
║        ├─ APP-A with 3 instances                              ║
║        ├─ APP-B with 3 instances                              ║
║        └─ API-GATEWAY with 1 instance                         ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green

Write-Host "`n⏳ Waiting for services to register..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host @"

╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║        🧪 LOAD BALANCING TEST COMMANDS                        ║
║                                                                ║
║        Test Round-Robin (each request goes to different port) ║
║                                                                ║
║        Via Gateway (Load Balanced):                           ║
║        for (`$i=1; `$i -le 6; `$i++) {                         ║
║          curl -s http://localhost:9002/api/app-a/status      ║
║          Write-Host "Request `$i completed"                    ║
║        }                                                       ║
║                                                                ║
║        Check headers to see which instance responded:         ║
║        curl -i http://localhost:9002/api/app-a/status        ║
║                                                                ║
║        Direct access (no load balancing):                    ║
║        curl -s http://localhost:8080/status                  ║
║        curl -s http://localhost:8081/status                  ║
║        curl -s http://localhost:8082/status                  ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Magenta
