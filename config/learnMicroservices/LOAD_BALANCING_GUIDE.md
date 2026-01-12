# 🔄 LOAD BALANCING IN API GATEWAY - PHASE 2+

## Overview

Load Balancing is the distribution of incoming requests across multiple backend server instances. Our API Gateway uses **Spring Cloud Load Balancer** with **Eureka Service Discovery** to automatically distribute traffic.

---

## 📊 Current Architecture vs. Load Balanced

### BEFORE (Single Instance per Service)
```
┌─────────────────────────────────────────────┐
│           API Gateway (9002)                │
│  - Routes /api/app-a/** to app-a            │
│  - Routes /api/app-b/** to app-b            │
└──────────────┬──────────────┬───────────────┘
               │              │
         ┌─────▼──┐      ┌────▼─────┐
         │ App A  │      │ App B    │
         │ (8080) │      │ (8081)   │
         │        │      │          │
         └────────┘      └──────────┘
         
Problem: All traffic → single instance
If instance fails → service down!
No horizontal scaling!
```

### AFTER (Multiple Instances with Load Balancing)
```
┌──────────────────────────────────────────────────────┐
│         API Gateway (9002)                           │
│  - Load Balancer enabled                             │
│  - Routes /api/app-a/** to app-a (any instance)      │
│  - Routes /api/app-b/** to app-b (any instance)      │
└──────────────┬──────────────────────┬────────────────┘
               │                      │
    ┌──────────┴──────────┐  ┌────────┴───────────┐
    │                     │  │                    │
┌───▼────┐  ┌───────┐ ┌──▼──┐  ┌────────┐  ┌─────▼──┐
│App A-1 │  │App A-2│ │App A-3  │App B-1 │  │App B-2 │
│(8080)  │  │(8081) │ │(8082)   │(8083)  │  │(8084)  │
└────────┘  └───────┘ └────────┘└────────┘  └────────┘
     ↑          ↑           ↑         ↑         ↑
     └──────────┴───────────┘         └─────────┘
        Eureka Service Discovery
        (All instances registered)
        
Benefits:
✅ Traffic distributed across instances
✅ Fault tolerance (if one fails, others handle traffic)
✅ Higher throughput (6 instances process 6x requests)
✅ Horizontal scaling
✅ Zero downtime updates
```

---

## 🔧 How Load Balancing Works in Our Gateway

### Step 1: Service Registration with Eureka
```
Each App Instance registers with Eureka:

Instance 1: app-a:8080
Instance 2: app-a:8081  → All registered under "app-a" service
Instance 3: app-a:8082

Eureka maintains a registry:
SERVICE: app-a
├─ Instance 1 (8080) - Status: UP
├─ Instance 2 (8081) - Status: UP
└─ Instance 3 (8082) - Status: UP
```

### Step 2: Request Arrives at Gateway
```
Client → Gateway: GET /api/app-a/status

Gateway Route Configuration:
routes:
  - id: app-a-route
    uri: lb://app-a  ← Load Balanced URI!
    predicates:
      - Path=/api/app-a/**
```

### Step 3: Load Balancer Selects Instance
```
Gateway Load Balancer Algorithm:

Round-Robin (Default):
Request 1 → app-a:8080
Request 2 → app-a:8081
Request 3 → app-a:8082
Request 4 → app-a:8080  (cycles back)
Request 5 → app-a:8081
Request 6 → app-a:8082
...

This ensures even distribution of load!
```

### Step 4: Route & Response
```
Gateway:
1. Looks up "app-a" in Eureka
2. Gets list: [8080, 8081, 8082]
3. Selects one using Round-Robin
4. Rewrites path: /api/app-a/status → /status
5. Forwards to selected instance
6. Returns response to client
```

---

## 🚀 Setting Up Load Balanced Instances

### Step 1: Build Both Apps
```powershell
cd app-a
mvn clean package -DskipTests

cd ..\app-b
mvn clean package -DskipTests
```

### Step 2: Start Multiple Instances

**Option A: Using the Script (Automatic)**
```powershell
# Run the prepared script
& "C:\...\START_LB_DEMO.ps1"
```

**Option B: Manual (One at a time)**

Terminal 1 - App A Instance 1:
```powershell
cd app-a
java -jar target/app-a-1.0.0.jar --server.port=8080
```

Terminal 2 - App A Instance 2:
```powershell
cd app-a
java -jar target/app-a-1.0.0.jar --server.port=8081
```

Terminal 3 - App A Instance 3:
```powershell
cd app-a
java -jar target/app-a-1.0.0.jar --server.port=8082
```

Terminal 4 - App B Instance 1:
```powershell
cd app-b
java -jar target/app-b-1.0.0.jar --server.port=8083
```

Terminal 5 - App B Instance 2:
```powershell
cd app-b
java -jar target/app-b-1.0.0.jar --server.port=8084
```

Terminal 6 - App B Instance 3:
```powershell
cd app-b
java -jar target/app-b-1.0.0.jar --server.port=8085
```

### Step 3: Verify in Eureka
Open: `http://localhost:8761`

You should see:
```
APP-A
├─ app-a:8080 (UP)
├─ app-a:8081 (UP)
└─ app-a:8082 (UP)

APP-B
├─ app-b:8083 (UP)
├─ app-b:8084 (UP)
└─ app-b:8085 (UP)

API-GATEWAY
└─ api-gateway:9002 (UP)
```

---

## 🧪 Testing Load Balancing

### Test 1: Verify Round-Robin Distribution

**PowerShell Script:**
```powershell
Write-Host "Testing Load Balancing - Round Robin Distribution`n"

$results = @()
for ($i = 1; $i -le 12; $i++) {
    $response = curl -s -i http://localhost:9002/api/app-a/status
    $lines = $response -split "`n"
    
    # Parse response to find port info
    foreach ($line in $lines) {
        if ($line -match "appName|port") {
            $results += "$i`: $line"
        }
    }
    
    Write-Host "Request $i completed"
    Start-Sleep -Milliseconds 200
}

Write-Host "`nResults:"
$results | ForEach-Object { Write-Host $_ }
```

**Expected Output:**
```
Request 1 completed - Port: 8080
Request 2 completed - Port: 8081
Request 3 completed - Port: 8082
Request 4 completed - Port: 8080  ← Cycles back!
Request 5 completed - Port: 8081
Request 6 completed - Port: 8082
Request 7 completed - Port: 8080
Request 8 completed - Port: 8081
Request 9 completed - Port: 8082
...
```

This proves Round-Robin is working!

### Test 2: Direct vs. Load Balanced

**Direct Access (No Load Balancing):**
```powershell
curl -s http://localhost:8080/status  # Always 8080
curl -s http://localhost:8080/status  # Always 8080
curl -s http://localhost:8080/status  # Always 8080
```

**Via Gateway (Load Balanced):**
```powershell
curl -s http://localhost:9002/api/app-a/status  # Could be 8080
curl -s http://localhost:9002/api/app-a/status  # Could be 8081
curl -s http://localhost:9002/api/app-a/status  # Could be 8082
```

### Test 3: Failure Tolerance

**Kill one instance:**
```powershell
# Kill instance on 8080
Get-Process java | Where-Object {(netstat -ano | Select-String "8080").Length -gt 0} | Stop-Process -Force
```

**Test again:**
```powershell
for ($i = 1; $i -le 6; $i++) {
    curl -s http://localhost:9002/api/app-a/status
}
```

**Expected:** Requests still succeed using ports 8081 and 8082!
The gateway automatically skips the dead instance.

### Test 4: Performance Under Load

**Sequential Requests:**
```powershell
Measure-Command {
    for ($i = 1; $i -le 100; $i++) {
        curl -s http://localhost:9002/api/app-a/status | Out-Null
    }
}
```

**Concurrent Requests (Simulated):**
```powershell
$jobs = @()
for ($i = 1; $i -le 20; $i++) {
    $job = Start-Job -ScriptBlock {
        curl -s http://localhost:9002/api/app-a/status
    }
    $jobs += $job
}

$results = $jobs | Wait-Job | Receive-Job
Write-Host "Processed: $($results.Count) requests"
```

---

## 📈 Load Balancing Algorithms

### Round-Robin (Default)
```
Instance 1 → Instance 2 → Instance 3 → Instance 1 → ...
Simple, fair, works well for equal capacity instances
```

### Least Connections
```
Routes to the instance with fewest active connections
Better for long-lived connections
Configured in application.yml
```

### Random
```
Random selection from available instances
Good for very high throughput scenarios
```

### Weighted Round-Robin
```
Some instances get more traffic based on capacity
e.g., Instance 1 (50%), Instance 2 (30%), Instance 3 (20%)
```

---

## ⚙️ Configuration in Gateway

The gateway is already configured for load balancing:

**application.yml:**
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: app-a-route
          uri: lb://app-a  # ← "lb://" means Load Balanced!
          predicates:
            - Path=/api/app-a/**

eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka/
    fetch-registry: true  # ← Fetch updated service list
```

**How it works:**
- `lb://app-a` tells gateway to use Load Balancer
- `fetch-registry: true` refreshes instance list from Eureka
- Gateway automatically distributes requests

---

## 🔄 Eureka Health Checks

Eureka continuously monitors instance health:

```
Every 30 seconds:
├─ Instance 1 → /actuator/health → 200 OK ✅ (keeps in rotation)
├─ Instance 2 → /actuator/health → 200 OK ✅
├─ Instance 3 → /actuator/health → 500 ERROR ❌ (removed from rotation)
└─ Gateway updates → Only use 1 & 2
```

---

## 📊 Benefits Summary

| Aspect | Single Instance | Load Balanced (3 instances) |
|--------|-----------------|---------------------------|
| **Throughput** | ~100 req/s | ~300 req/s |
| **Latency** | 50ms | 15ms (less contention) |
| **Availability** | Down if instance fails | 67% available with 1 down |
| **Scaling** | Add more instances (manual) | Automatic via Eureka |
| **Cost** | 1 server | 3 servers (distribute load) |

---

## 🎯 Next Steps

1. ✅ Run load balancing demo with multiple instances
2. ✅ Monitor traffic distribution in logs
3. ✅ Test failure scenarios
4. ✅ Measure performance improvements
5. 📋 Phase 3: Add Circuit Breaker for resilience
6. 📋 Phase 4: Add distributed tracing to see request flow

---

## 🐛 Troubleshooting

**Issue: All requests going to same instance**
- Check if Eureka has all instances registered
- Verify `lb://` in gateway route configuration
- Check load balancer logs

**Issue: Some instances not getting traffic**
- Verify health check endpoint is responding
- Check instance registration in Eureka
- Ensure instance is marked as UP

**Issue: Requests failing intermittently**
- A failing instance might still be in rotation
- Health check might be failing
- Instance might be registering/deregistering

---

## 📚 Key Concepts

**Load Balancer** - Distributes incoming requests across multiple servers
**Eureka** - Service registry that maintains list of available instances
**Health Check** - Eureka pings `/actuator/health` to verify instance is UP
**Round-Robin** - Default algorithm cycling through instances equally
**Service Discovery** - Automatic registration and discovery of services
**Horizontal Scaling** - Add more instances instead of bigger servers

