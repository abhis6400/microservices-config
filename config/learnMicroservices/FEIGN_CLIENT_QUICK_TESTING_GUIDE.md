# Feign Client - Quick Testing Guide

## 🚀 Quick Start

Before testing, ensure:
1. **Eureka Server** is running on port 8761
2. **App A** is running on port 8080
3. **App B** is running on port 8081
4. **Config Server** is running on port 8888

---

## 📝 Test Cases

### **Test 1: App A Direct Endpoints**

```bash
# Get App A greeting
curl http://localhost:8080/api/app-a/greeting/John

# Get App A status
curl http://localhost:8080/api/app-a/status
```

### **Test 2: App B Direct Endpoints**

```bash
# Get App B product
curl http://localhost:8081/api/app-b/product/123

# Get App B status
curl http://localhost:8081/api/app-b/status

# Get App B health
curl http://localhost:8081/api/app-b/health

# Get App B greeting
curl http://localhost:8081/api/app-b/greeting/Alice
```

### **Test 3: App A Calling App B via Feign**

```bash
# App A calls App B status
curl http://localhost:8080/api/app-a/call-app-b/status

# App A gets product from App B
curl http://localhost:8080/api/app-a/call-app-b/product/456

# App A asks App B to greet
curl http://localhost:8080/api/app-a/call-app-b/greet/Bob
```

### **Test 4: App B Calling App A via Feign**

```bash
# App B calls App A status
curl http://localhost:8081/api/app-b/call-app-a/status

# App B gets data from App A
curl http://localhost:8081/api/app-b/call-app-a/data/mykey

# App B asks App A to say hello
curl http://localhost:8081/api/app-b/call-app-a/hello/Charlie
```

### **Test 5: Verify Service Discovery**

Open Eureka Dashboard:
```
http://localhost:8761
```

You should see:
- **APP-A** (registered from App A)
- **APP-B** (registered from App B)
- **EUREKA-SERVER** (the registry itself)

---

## ✅ Expected Results

### **When calling App A → App B:**

Request:
```bash
curl http://localhost:8080/api/app-a/call-app-b/status
```

Response:
```json
{
  "caller": "App A",
  "callee": "App B",
  "endpoint": "/api/app-b/status",
  "response": "App B is running on port 8081 ✅",
  "timestamp": "2026-01-05T10:30:45.123456"
}
```

### **When calling App B → App A:**

Request:
```bash
curl http://localhost:8081/api/app-b/call-app-a/status
```

Response:
```json
{
  "caller": "App B",
  "callee": "App A",
  "endpoint": "/api/app-a/status",
  "response": {...status object...},
  "timestamp": "2026-01-05T10:30:50.654321"
}
```

---

## 🔍 How to Check Logs

### **App A Logs:**
Look for messages like:
```
App A calling App B status via Feign Client
Received response from App B: App B is running on port 8081 ✅
```

### **App B Logs:**
Look for messages like:
```
App B calling App A status via Feign Client
Received response from App A: {...}
```

---

## 🐛 Troubleshooting

### **Issue: Service not found**
```
Error: "Client registration failed on app-b"
```

**Solution:**
- Check Eureka dashboard: http://localhost:8761
- Ensure both apps show as registered
- Check that spring.application.name is correct in bootstrap.yml

### **Issue: Connection refused**
```
Error: "Failed to connect to http://localhost:8081"
```

**Solution:**
- Ensure all services are running
- Check port numbers (8761, 8080, 8081, 8888)
- Check firewall settings

### **Issue: Feign not creating proxy**
```
Error: "NoSuchBeanDefinitionException: No qualifying bean of type"
```

**Solution:**
- Add @EnableFeignClients to main application class
- Ensure client interface is in correct package
- Check that @FeignClient annotation is present

---

## 📊 Request/Response Flow with Feign

```
User Request to App A:
GET /api/app-a/call-app-b/status

↓

App A Controller:
1. Receives request
2. Injects AppBClient (Feign proxy)
3. Calls appBClient.getAppBStatus()

↓

Feign Client:
1. Intercepts method call
2. Looks at @FeignClient(name = "app-b")
3. Queries Eureka: "Where is app-b?"
4. Gets URL: http://localhost:8081
5. Constructs: GET http://localhost:8081/api/app-b/status
6. Sends HTTP request
7. Receives response

↓

App A Controller:
1. Receives response from Feign
2. Wraps in response object
3. Returns to user

↓

User gets:
{
  "caller": "App A",
  "callee": "App B",
  "response": "App B is running on port 8081 ✅"
}
```

---

## 💡 Key Points

1. **Service Discovery Automatic**: Feign queries Eureka, no hardcoding URLs
2. **Interface-Based**: Defines what, not how
3. **Type-Safe**: Compiler catches errors
4. **Bidirectional**: App A can call App B AND App B can call App A
5. **Clean Code**: No verbose try-catch, no RestTemplate builder patterns

---

## 🎯 Next Steps

After verifying this works:
1. ✅ Add retry policies
2. ✅ Add circuit breaker
3. ✅ Add fallback methods
4. ✅ Add request/response logging
5. ✅ Add timeout configuration

---

## 📚 Files Modified

**App A:**
- ✅ pom.xml (added Feign + Eureka)
- ✅ AppAApplication.java (@EnableFeignClients)
- ✅ AppBClient.java (NEW Feign interface)
- ✅ AppAController.java (added Feign calls)
- ✅ bootstrap.yml (Eureka config)

**App B:**
- ✅ pom.xml (added Feign + Eureka)
- ✅ AppBApplication.java (@EnableFeignClients)
- ✅ AppAClient.java (NEW Feign interface)
- ✅ AppBController.java (added Feign calls + new endpoints)
- ✅ bootstrap.yml (Eureka config)

---

## 🎉 You're Now Using Feign Client!

The modern, production-grade way to do microservice communication! 🚀
