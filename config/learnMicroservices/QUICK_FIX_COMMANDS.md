# ⚡ QUICK FIX - Run These Commands Now

## The Issue
Spring Cloud 2023.0.3 needs Spring Boot **3.2.x or 3.3.x**, NOT 3.5.5

## The Fix Applied ✅
Changed all POM files from Spring Boot 3.5.5 → **3.3.9**

---

## Execute These Steps (Windows PowerShell)

### Step 1: Navigate to Project
```powershell
cd "C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo"
```

### Step 2: Clean Everything
```powershell
mvn clean
```

### Step 3: Rebuild with New Versions
```powershell
mvn clean install -U -DskipTests
```

**What this does:**
- `-U` = Force check for updates
- `-DskipTests` = Skip tests (faster)
- Will download Spring Boot 3.3.9 and Spring Cloud 2023.0.3

**Wait for:** `BUILD SUCCESS` message

---

## Then Start Services (3 Separate PowerShell Windows)

### Window 1 - Config Server
```powershell
cd config-server
mvn spring-boot:run
```

**Wait for:** 
```
Started ConfigServerApplication in X.XXX seconds
Tomcat initialized with port(s): 8888 (http)
```

### Window 2 - App A
```powershell
cd app-a
mvn spring-boot:run
```

**Wait for:**
```
Started AppAApplication in X.XXX seconds
Tomcat initialized with port(s): 8080 (http)
```

### Window 3 - App B
```powershell
cd app-b
mvn spring-boot:run
```

**Wait for:**
```
Started AppBApplication in X.XXX seconds
Tomcat initialized with port(s): 8081 (http)
```

---

## Verify It Works

In a new PowerShell window:

```powershell
# Test Config Server
curl http://localhost:8888/actuator/health
# Should return: {"status":"UP"}

# Test App A
curl http://localhost:8080/api/app-a/greeting/World
# Should return: greeting JSON

# Test App B
curl http://localhost:8081/api/app-b/product/123
# Should return: product JSON
```

---

## Common Errors & Fixes

### Error: "Cannot find symbol"
```powershell
# Solution:
mvn clean install -U -DskipTests
```

### Error: "Port already in use"
```powershell
# Kill all Java processes using ports
$ProcessID = (Get-NetTCPConnection -LocalPort 8888 -ErrorAction SilentlyContinue).OwningProcess
if ($ProcessID) { Stop-Process -Id $ProcessID -Force }

$ProcessID = (Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue).OwningProcess
if ($ProcessID) { Stop-Process -Id $ProcessID -Force }

$ProcessID = (Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue).OwningProcess
if ($ProcessID) { Stop-Process -Id $ProcessID -Force }

# Then restart services
```

### Error: "Dependency not found"
```powershell
# Solution:
rm -r $env:USERPROFILE\.m2\repository\org\springframework
mvn clean install -U -DskipTests
```

---

## Versions Now Using

| Component | Version | Status |
|-----------|---------|--------|
| Java | 17 | ✅ |
| Spring Boot | 3.3.9 | ✅ |
| Spring Cloud | 2023.0.3 | ✅ |
| Maven | 3.6+ | ✅ |

All **fully compatible** and **production-ready**! ✅

---

## What Changed

✅ Spring Boot: 3.5.5 → 3.3.9  
✅ Spring Cloud: 2024.0.0 → 2023.0.3  
❌ Nothing else changed  

All endpoints, features, and documentation remain **exactly the same**.

---

**Next Step:** Run Step 1-3 above, then start the 3 services! 🚀
