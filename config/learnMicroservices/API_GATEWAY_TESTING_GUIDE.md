# 🧪 API GATEWAY TESTING GUIDE - PHASE 2

## Quick Start Testing

### **Prerequisites**
- ✅ Config Server running on 8888
- ✅ Eureka Server running on 8761
- ✅ App A running on 8080
- ✅ App B running on 8081
- ✅ API Gateway running on 9000

---

## 🚀 BUILD & RUN API GATEWAY

### **Step 1: Build the Gateway**

```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\api-gateway
mvn clean install
```

**Expected Output:**
```
[INFO] Building jar: target\api-gateway-1.0.0.jar
[INFO] BUILD SUCCESS
```

### **Step 2: Run the Gateway**

```powershell
mvn spring-boot:run
```

**Or run the JAR:**
```powershell
java -jar target/api-gateway-1.0.0.jar
```

**Expected Startup Output:**
```
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║           🚀 API GATEWAY SERVICE STARTED 🚀                     ║
║                                                                ║
║           Port: 9000                                           ║
║                                                                ║
║           Endpoints:                                           ║
║           ├─ http://localhost:9000/api/app-a/**              ║
║           ├─ http://localhost:9000/api/app-b/**              ║
║           └─ http://localhost:9000/actuator/health           ║
║                                                                ║
║           Status: Ready for traffic! ✅                        ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

### **Step 3: Verify Eureka Registration**

Open browser: `http://localhost:8761`

**Expected:**
```
Registered Services:
✅ APP-A (instance running)
✅ APP-B (instance running)
✅ API-GATEWAY (instance running) ← NEW!
```

---

## 📋 TEST SCENARIOS

### **SCENARIO 1: Health Check**

#### **Test Gateway Health**

```powershell
curl -s http://localhost:9002/actuator/health | ConvertFrom-Json | ConvertTo-Json
```

**Expected Response:**
```json
{
  "status": "UP"
}
```

**Alternative (pretty print):**
```powershell
Invoke-RestMethod http://localhost:9000/actuator/health | ConvertTo-Json
```

---

### **SCENARIO 2: GET All Routes**

#### **View Configured Routes**

```powershell
curl -s http://localhost:9000/actuator/gateway/routes | ConvertFrom-Json | ConvertTo-Json
```

**Expected Response:**
```json
[
  {
    "route_id": "app-a-route",
    "uri": "lb://app-a",
    "predicates": [
      {
        "name": "Path",
        "args": {
          "pattern": "/api/app-a/**"
        }
      }
    ],
    "filters": [...]
  },
  {
    "route_id": "app-b-route",
    "uri": "lb://app-b",
    ...
  }
]
```

---

### **SCENARIO 3: Route to App A**

#### **Test 3.1: Call App A Status via Gateway**

```powershell
curl -v http://localhost:9002/api/app-a/status
```

**Request Flow:**
```
1. You send: GET http://localhost:9000/api/app-a/status
2. Gateway matches: Path=/api/app-a/**
3. Gateway rewrites: /api/app-a/status → /status
4. Gateway looks up: Eureka for "app-a"
5. Gateway forwards: GET http://localhost:8080/status
6. App A responds
7. Gateway adds header: X-Gateway-Response: true
8. Gateway returns to you
```

**Expected Response:**
```
< HTTP/1.1 200 OK
< X-Gateway-Route: app-a
< X-Gateway-Response: true
< Content-Type: application/json

{"status":"OK","timestamp":"2026-01-07T..."}
```

**Key Headers to Verify:**
```
✓ X-Gateway-Route: app-a          (Our custom header)
✓ X-Gateway-Response: true        (Gateway marked this)
```

#### **Test 3.2: Call App A Data Endpoint**

```powershell
# Via Gateway
curl -s http://localhost:9000/api/app-a/data?key=test | ConvertFrom-Json | ConvertTo-Json

# Compare with Direct Access
curl -s http://localhost:8080/data?key=test | ConvertFrom-Json | ConvertTo-Json
```

**Expected: Same response, but through gateway route**

#### **Test 3.3: Call App A Greeting**

```powershell
curl -s "http://localhost:9000/api/app-a/greeting?name=Alice"
```

**Expected Response:**
```json
{"message": "Hello Alice from App A"}
```

---

### **SCENARIO 4: Route to App B**

#### **Test 4.1: Call App B Status via Gateway**

```powershell
curl -v http://localhost:9000/api/app-b/status
```

**Expected Response:**
```
< HTTP/1.1 200 OK
< X-Gateway-Route: app-b          ← Note: changed to app-b!
< X-Gateway-Response: true
< Content-Type: application/json

{"status":"UP","timestamp":"2026-01-07T..."}
```

#### **Test 4.2: Call App B Greeting**

```powershell
curl -s "http://localhost:9000/api/app-b/greeting?name=Bob"
```

**Expected Response:**
```json
{"message": "Hello Bob from App B"}
```

#### **Test 4.3: Call App B Call to App A (via Feign)**

```powershell
curl -s http://localhost:9000/api/app-b/call-app-a
```

**Request Flow:**
```
1. You → Gateway → App B
2. App B calls App A via Feign
3. Response from App A → App B
4. App B response → Gateway
5. Gateway → You

Total: App B successfully calls App A through our gateway!
```

**Expected Response:**
```json
{
  "service": "App B",
  "called": "App A",
  "response": {...}
}
```

---

### **SCENARIO 5: Verify Load Balancing Setup**

#### **Test 5.1: Check Gateway Info**

```powershell
curl -s http://localhost:9000/actuator/info | ConvertFrom-Json | ConvertTo-Json
```

**Expected Response:**
```json
{
  "app": {
    "name": "API Gateway",
    "description": "Spring Cloud API Gateway for routing and managing traffic",
    "version": "1.0.0",
    "author": "Microservices Masterclass"
  },
  "gateway": {
    "routes": 2,
    "services": "app-a, app-b",
    "port": 9000,
    "discovery": "Eureka"
  }
}
```

#### **Test 5.2: Verify Service Discovery**

```powershell
# Check what services gateway knows about
curl -s http://localhost:8761/eureka/apps | Select-String "app-a|app-b|api-gateway"
```

**Expected: All three services listed**

---

### **SCENARIO 6: Request Path Rewriting**

#### **Test 6.1: Verify Path Prefix is Stripped**

```powershell
# Original request path: /api/app-a/status
# Rewritten path: /status

curl -v http://localhost:9000/api/app-a/status 2>&1 | Select-String "Host:"
```

**The gateway should:**
1. ✓ Receive: `/api/app-a/status`
2. ✓ Rewrite to: `/status`
3. ✓ Forward to App A: `GET http://localhost:8080/status`
4. ✓ App A responds (looking at its `/status` endpoint)

---

### **SCENARIO 7: Error Handling**

#### **Test 7.1: Invalid Route (404)**

```powershell
curl -v http://localhost:9000/api/invalid-service/path
```

**Expected Response:**
```
< HTTP/1.1 404 Not Found
< Content-Type: application/json

{"timestamp":"...","status":404,"error":"Not Found"}
```

#### **Test 7.2: Invalid Endpoint (404)**

```powershell
curl -v http://localhost:9000/api/app-a/nonexistent
```

**Expected Response:**
```
< HTTP/1.1 404 Not Found

(App A returns 404 through gateway)
```

---

### **SCENARIO 8: Custom Headers**

#### **Test 8.1: Send Custom Header to Service**

```powershell
curl -H "X-Custom-Header: MyValue" -v http://localhost:9000/api/app-a/status
```

**The gateway should:**
- ✓ Receive your custom header
- ✓ Add X-Gateway-Route header
- ✓ Forward to App A

#### **Test 8.2: Verify Response Headers**

```powershell
curl -i http://localhost:9000/api/app-a/status
```

**Headers to verify:**
```
X-Gateway-Route: app-a        ← Added by gateway
X-Gateway-Response: true      ← Added by gateway
Content-Type: application/json
```

---

### **SCENARIO 9: CORS Testing**

#### **Test 9.1: OPTIONS Request (CORS Preflight)**

```powershell
curl -i -X OPTIONS -H "Origin: http://example.com" http://localhost:9000/api/app-a/status
```

**Expected Response:**
```
< HTTP/1.1 200 OK
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
< Access-Control-Allow-Headers: *
```

---

## 📊 COMPLETE TEST FLOW

### **Run All Tests in Sequence**

```powershell
# Test 1: Health Check
Write-Host "Test 1: Health Check"
curl -s http://localhost:9000/actuator/health

# Test 2: Routes
Write-Host "`nTest 2: Available Routes"
curl -s http://localhost:9000/actuator/gateway/routes

# Test 3: App A Status
Write-Host "`nTest 3: App A Status"
curl -s http://localhost:9000/api/app-a/status

# Test 4: App B Status
Write-Host "`nTest 4: App B Status"
curl -s http://localhost:9000/api/app-b/status

# Test 5: App A to App B (via Feign)
Write-Host "`nTest 5: App A Call to App B"
curl -s http://localhost:9000/api/app-a/call-app-b

# Test 6: App B to App A (via Feign)
Write-Host "`nTest 6: App B Call to App A"
curl -s http://localhost:9000/api/app-b/call-app-a

# Test 7: Gateway Info
Write-Host "`nTest 7: Gateway Info"
curl -s http://localhost:9000/actuator/info

Write-Host "`n✅ All tests complete!"
```

---

## ✅ VALIDATION CHECKLIST

```
Gateway Tests:
□ Health check returns UP
□ Routes endpoint shows app-a and app-b routes
□ App A status accessible via /api/app-a/status
□ App B status accessible via /api/app-b/status
□ X-Gateway-Route header present in responses
□ X-Gateway-Response header present in responses
□ Path rewriting works (strip /api/app-a prefix)
□ Service discovery works (no hardcoded URLs)
□ Eureka shows all 4 services (config, eureka, app-a, app-b, gateway)
□ CORS headers present for OPTIONS requests

Integration Tests:
□ App A can call App B via Feign through gateway
□ App B can call App A via Feign through gateway
□ Gateway correctly handles errors (404s)
□ Response times acceptable (<100ms typically)

All Endpoints Working:
□ GET /api/app-a/status
□ GET /api/app-a/data?key=test
□ GET /api/app-a/greeting?name=Alice
□ GET /api/app-b/status
□ GET /api/app-b/greeting?name=Bob
□ GET /api/app-b/call-app-a
```

---

## 🐛 TROUBLESHOOTING

### **Issue: Gateway returns 503 Service Unavailable**

**Cause:** Service not registered with Eureka

**Solution:**
```powershell
# Check Eureka
curl http://localhost:8761/eureka/apps

# Verify app-a and app-b are registered
# If not, restart those services
```

### **Issue: Gateway returns 404**

**Cause:** Route path doesn't match

**Solution:**
```
Check:
- Request path matches /api/app-a/** or /api/app-b/**
- Service name in Eureka matches uri (lb://app-a, lb://app-b)
- Path rewriting isn't removing needed segments
```

### **Issue: Connection refused to localhost:9000**

**Cause:** Gateway not running

**Solution:**
```powershell
# Start gateway
cd api-gateway
mvn spring-boot:run
```

### **Issue: CORS errors in browser**

**Cause:** CORS not configured

**Solution:** Already configured in application.yml
```yaml
globalcors:
  corsConfigurations:
    '[/**]':
      allowedOrigins: "*"
```

---

## 📈 PERFORMANCE TESTING

### **Test Response Time**

```powershell
# Direct access (baseline)
Measure-Command { curl -s http://localhost:8080/status | Out-Null } | Select-Object TotalMilliseconds

# Via gateway
Measure-Command { curl -s http://localhost:9000/api/app-a/status | Out-Null } | Select-Object TotalMilliseconds
```

**Expected:** Gateway adds ~5-10ms overhead

### **Test Concurrent Requests**

```powershell
# Send 100 concurrent requests to gateway
1..100 | ForEach-Object { curl -s http://localhost:9000/api/app-a/status } | Measure-Object
```

**Expected:** All succeed, showing load balancing works

---

## 🎯 NEXT STEPS

After verifying all tests pass:

1. **Phase 3:** Add Circuit Breaker & Distributed Tracing
2. **Phase 4:** Add Authentication & Authorization
3. **Advanced:** Multi-instance load balancing
4. **Production:** Deploy with multiple gateway instances

---

## 📝 SUMMARY

Your API Gateway is working when:

✅ Gateway responds on port 9000
✅ Routes to App A (/api/app-a/**)
✅ Routes to App B (/api/app-b/**)
✅ Load balancer (lb://) working via Eureka
✅ Custom headers added to requests
✅ Path rewriting strips prefix correctly
✅ Service discovery automatic (no hardcoding)
✅ All endpoints accessible and returning correct responses

**Gateway Ready for Phase 3!** 🚀
