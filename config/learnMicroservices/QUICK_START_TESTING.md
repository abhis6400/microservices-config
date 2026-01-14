# 🚀 QUICK START GUIDE - Running Circuit Breaker Tests

## ⚠️ IMPORTANT: First Steps

### Before Running Tests

**1. Stop App A** (if running)
- The JAR file needs to be unlocked for rebuild
- Close any running `app-a` processes

**2. Rebuild App A with Test Controller**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo\app-a
mvn clean package -DskipTests
```

**3. Restart App A**
```powershell
java -jar target/app-a-1.0.0.jar
```

**4. Ensure App B is DOWN** (for testing circuit breaker)
- App B should NOT be running
- This simulates downstream service failure

---

## 🎯 Three Ways to Run Tests

### **Option 1: Simple PowerShell Script (Recommended)**

**From PowerShell Terminal:**
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo
.\TEST_CIRCUIT_BREAKER_SIMPLE.ps1
```

**From VS Code Terminal:** (Your current setup)
```powershell
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo
.\TEST_CIRCUIT_BREAKER_SIMPLE.ps1
```

**What it does:**
- ✅ Checks current circuit breaker status
- ✅ Forces circuit breaker to OPEN
- ✅ Makes 5 test requests (should be <1ms)
- ✅ Simulates 10 failures
- ✅ Shows final status

---

### **Option 2: CMD Batch File**

**From CMD (Command Prompt):**
```cmd
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo
TEST_CIRCUIT_BREAKER.bat
```

**Double-click in File Explorer:**
1. Navigate to folder
2. Double-click `TEST_CIRCUIT_BREAKER.bat`

---

### **Option 3: Manual cURL Commands**

**From PowerShell or CMD:**

```powershell
# Check status
curl http://localhost:9002/api/app-a/api/test-circuit/status

# Force circuit breaker to OPEN
curl -X POST http://localhost:9002/api/app-a/api/test-circuit/force-open

# Test with circuit OPEN (should be instant)
curl http://localhost:9002/api/app-a/api/resilience/app-b/status

# Check status again
curl http://localhost:9002/api/app-a/api/test-circuit/status

# Reset to CLOSED
curl -X POST http://localhost:9002/api/app-a/api/test-circuit/force-closed
```

---

## 📋 Test Endpoints Available

All endpoints are accessible via API Gateway:

### **Status Endpoint**
```http
GET http://localhost:9002/api/app-a/api/test-circuit/status
```
**Returns:**
- Current state (CLOSED/OPEN/HALF_OPEN)
- Failure rate
- Success/failure counts
- Configuration details

### **Force OPEN** (Instant transition)
```http
POST http://localhost:9002/api/app-a/api/test-circuit/force-open
```
**Effect:** Instantly opens circuit breaker for testing

### **Force CLOSED** (Reset)
```http
POST http://localhost:9002/api/app-a/api/test-circuit/force-closed
```
**Effect:** Resets circuit breaker to CLOSED state

### **Simulate Failures**
```http
POST http://localhost:9002/api/app-a/api/test-circuit/simulate-failures?count=10
```
**Effect:** Records 10 artificial failures to trigger opening

---

## 🔍 What to Observe

### When Circuit Breaker is CLOSED (Normal)
```
Request → Tries App B → Fails → Fallback → Response
Duration: ~5-10ms
Status: DEGRADED
CB State: CLOSED 🟢
```

### When Circuit Breaker is OPEN (Protected)
```
Request → Circuit OPEN → Instant Fallback → Response
Duration: <1ms ⚡
Status: DEGRADED
CB State: OPEN 🔴
No actual call to App B!
```

---

## 🐛 Troubleshooting

### Error: "Cannot connect to localhost:9002"
**Solution:** Start API Gateway
```powershell
cd api-gateway
java -jar target/api-gateway-1.0.0.jar
```

### Error: "404 Not Found" on test endpoints
**Solution:** App A needs to be rebuilt with new controller
```powershell
# Stop App A first!
cd app-a
mvn clean package -DskipTests
java -jar target/app-a-1.0.0.jar
```

### Error: "Failed to delete app-a-1.0.0.jar"
**Solution:** App A is still running, stop it first
- Find process: `tasklist | findstr java`
- Kill process: `taskkill /F /PID <process_id>`

### Circuit breaker stays CLOSED even after many calls
**Solution:** This is CORRECT! Read `WHY_CIRCUIT_BREAKER_STAYS_CLOSED.md`
- Fallback succeeds = Circuit breaker sees success
- Use test endpoints to force OPEN state

---

## 📊 Expected Test Results

### Test 1: Force OPEN
```
Before: State = CLOSED 🟢
After:  State = OPEN 🔴
Request Duration: <1ms (instant)
```

### Test 2: Simulate Failures
```
Failures Recorded: 10
State: OPEN 🔴 (after threshold reached)
Failure Rate: 100%
```

### Test 3: Reset
```
State: CLOSED 🟢
Metrics Reset: true
Failure Rate: 0%
```

---

## 🎓 Understanding the Results

### Why Circuit Breaker Stayed CLOSED Before

**Your Original Issue:**
- Made 10-15 calls with App B down
- Circuit breaker stayed CLOSED
- Failure rate: 0%

**Reason:**
- Feign call fails ❌
- Fallback succeeds ✅
- Circuit breaker records: SUCCESS ✅
- Failure rate stays at 0%
- Circuit never opens

### Why New Tests Work

**Force OPEN Method:**
- Bypasses normal logic
- Manually transitions to OPEN state
- Shows circuit breaker behavior

**Simulate Failures Method:**
- Records actual failures
- No fallback involved
- Circuit breaker opens naturally

---

## 📚 Additional Resources

### Documentation Files
1. **`WHY_CIRCUIT_BREAKER_STAYS_CLOSED.md`** - Complete explanation
2. **`PHASE_4_TEST_RESULTS.md`** - Your actual test analysis
3. **`CircuitBreakerTestController.java`** - Test endpoint source code

### Test Scripts
1. **`TEST_CIRCUIT_BREAKER_SIMPLE.ps1`** - Simple PowerShell (recommended)
2. **`TEST_CIRCUIT_BREAKER.bat`** - CMD batch file
3. **`TEST_CIRCUIT_BREAKER_INTERACTIVE.ps1`** - Full interactive (has syntax error, use simple version)

---

## ✅ Complete Test Checklist

- [ ] Stop App A
- [ ] Rebuild App A: `mvn clean package -DskipTests`
- [ ] Start App A: `java -jar target/app-a-1.0.0.jar`
- [ ] Ensure App B is DOWN
- [ ] Ensure API Gateway is running
- [ ] Run test script: `.\TEST_CIRCUIT_BREAKER_SIMPLE.ps1`
- [ ] Observe instant responses when circuit is OPEN
- [ ] Check status endpoint
- [ ] Read `WHY_CIRCUIT_BREAKER_STAYS_CLOSED.md`

---

## 🚀 Quick Start Commands (Copy-Paste Ready)

**All-in-One PowerShell:**
```powershell
# Navigate to project
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo

# Run simple test
.\TEST_CIRCUIT_BREAKER_SIMPLE.ps1
```

**All-in-One CMD:**
```cmd
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo
TEST_CIRCUIT_BREAKER.bat
```

**Manual cURL Test:**
```powershell
# Force open
curl -X POST http://localhost:9002/api/app-a/api/test-circuit/force-open

# Test response time (should be <1ms)
curl http://localhost:9002/api/app-a/api/resilience/app-b/status

# Check status
curl http://localhost:9002/api/app-a/api/test-circuit/status
```

---

## 🎯 Success Criteria

**Test Passed When:**
- ✅ Circuit breaker transitions to OPEN state
- ✅ Response time drops to <1ms (instant)
- ✅ No actual calls to App B when OPEN
- ✅ Failure rate increases to 100% (in simulate test)
- ✅ Circuit breaker can be reset to CLOSED

**You'll See:**
```
State: OPEN 🔴
Duration: <1ms ⚡
Message: "Circuit breaker is open - using instant fallback"
```

---

**🎉 You're ready to test! Start with the simple PowerShell script.**
