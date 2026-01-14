# 🆔 MDC.get("traceId") - Quick Reference

## 🎯 **One-Sentence Answer**

**`MDC.get("traceId")`** gets a unique identifier for the current request from thread-local storage, allowing you to track a single request across multiple services.

---

## 📖 **What Each Part Means**

```java
String traceId = MDC.get("traceId");
```

| Part | What It Is | Explanation |
|------|-----------|-------------|
| `MDC` | **Mapped Diagnostic Context** | A logging utility from SLF4J |
| `.get()` | **Retrieve method** | Gets a value by key |
| `"traceId"` | **Key name** | The name we use to store the ID |
| Return value | **UUID String** | Like `7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a` |

---

## 🔄 **Complete Flow**

```
1. Request arrives → Filter creates trace ID → MDC.put("traceId", uuid)
                                                      ↓
2. Service method executes → String traceId = MDC.get("traceId")
                                                      ↓
3. Log statement uses it → logger.info("[TRACE: {}]", traceId)
                                                      ↓
4. Request completes → Filter cleans up → MDC.clear()
```

---

## 💡 **Why We Need It**

### Problem:
```
User: "My order failed!"
You: *Looks at logs*
You: *Sees 1,000,000 log entries*
You: *Can't find which ones belong to this user's request*
You: *Gives up* 😞
```

### Solution:
```
User: "My order failed! Trace ID: 7f5a3b2c"
You: grep "7f5a3b2c" logs/*.log
You: *Sees exactly 47 log entries for this request*
You: *Finds the error in 30 seconds*
You: *Fixed!* 🎉
```

---

## 📝 **Common Code Patterns**

### Pattern 1: Getting Trace ID
```java
String traceId = MDC.get("traceId");
```

### Pattern 2: Using in Logs
```java
logger.info("[TRACE: {}] Processing request", traceId);
// Output: [TRACE: 7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a] Processing request
```

### Pattern 3: Checking if Exists
```java
String traceId = MDC.get("traceId");
if (traceId == null) {
    traceId = "NO_TRACE_ID";
}
```

### Pattern 4: Using in Error Messages
```java
return String.format(
    "{\"error\":\"Service unavailable\",\"traceId\":\"%s\"}", 
    MDC.get("traceId")
);
```

---

## 🎓 **For Interns: 5 Key Facts**

1. **MDC = Thread-Local Storage**
   - Each request thread has its own copy
   - Values don't leak between requests
   - Automatically cleaned up after request

2. **Trace ID = Request Identifier**
   - Unique per request
   - Same ID across all services
   - Used to correlate logs

3. **Filter Sets It**
   - `TraceIdFilter` automatically adds it
   - You don't create it manually
   - It's there when you need it

4. **Use in Every Log**
   - Makes debugging 100x easier
   - Can track request across services
   - Essential in microservices

5. **Return in Errors**
   - User reports error with trace ID
   - You search logs instantly
   - Find root cause quickly

---

## 🚀 **Quick Start**

### Step 1: Create Filter
```java
@Component
public class TraceIdFilter implements Filter {
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        try {
            MDC.put("traceId", UUID.randomUUID().toString());
            chain.doFilter(request, response);
        } finally {
            MDC.clear();
        }
    }
}
```

### Step 2: Use in Service
```java
@Service
public class MyService {
    private static final Logger logger = LoggerFactory.getLogger(MyService.class);
    
    public void doSomething() {
        String traceId = MDC.get("traceId");
        logger.info("[TRACE: {}] Doing something", traceId);
    }
}
```

### Step 3: Configure Logging
```xml
<!-- logback-spring.xml -->
<pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [TraceId:%X{traceId}] - %msg%n</pattern>
```

### Step 4: Search Logs
```bash
# Find all logs for one request
grep "7f5a3b2c" logs/*.log
```

---

## ❓ **FAQ**

**Q: What if MDC.get("traceId") returns null?**
```java
String traceId = MDC.get("traceId");
if (traceId == null) {
    traceId = "UNKNOWN";
}
```

**Q: Can I put other values in MDC?**
```java
MDC.put("userId", "user123");
MDC.put("requestId", "req456");
String userId = MDC.get("userId");
```

**Q: Do I need to clear MDC?**
```java
// YES! Always clear in finally block
try {
    // Your code
} finally {
    MDC.clear();  // Prevents memory leaks
}
```

**Q: How does it work across threads?**
```java
// MDC doesn't automatically copy to child threads
// Use MDCTaskDecorator if using @Async
```

---

## 📊 **Example Output**

### Application Logs:
```
2026-01-14 10:30:45.123 [TraceId:7f5a3b2c] Gateway: Received request
2026-01-14 10:30:45.456 [TraceId:7f5a3b2c] Order: Creating order
2026-01-14 10:30:45.789 [TraceId:7f5a3b2c] Order: Calling payment service
2026-01-14 10:30:46.012 [TraceId:7f5a3b2c] Payment: Processing $99.99
2026-01-14 10:30:46.345 [TraceId:7f5a3b2c] Payment: ❌ Card declined
2026-01-14 10:30:46.678 [TraceId:7f5a3b2c] Order: ❌ Order failed
```

### Search Command:
```bash
grep "7f5a3b2c" logs/*.log
```

### Result:
✅ Found all 6 log entries for this failed order
✅ Can see exact flow: Gateway → Order → Payment → Failed
✅ Root cause: Card declined in payment service

---

## 🎯 **Remember**

```
MDC.get("traceId") = Get unique ID for current request

Why? → Track requests across services
When? → In every log statement
Where? → Set by filter, used everywhere
How? → MDC.get("traceId") returns the ID
```

---

## 📚 **Learn More**

- **Full Guide:** [`TRACE_ID_EXPLAINED.md`](TRACE_ID_EXPLAINED.md)
- **Implementation:** [`RESILIENCE_IMPLEMENTATION_GUIDE_FOR_INTERNS.md`](RESILIENCE_IMPLEMENTATION_GUIDE_FOR_INTERNS.md)

---

**You're ready to use trace IDs! 🎉**
