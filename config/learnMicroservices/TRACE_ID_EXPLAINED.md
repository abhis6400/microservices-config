# 🆔 Trace ID (MDC) - Complete Explanation

## 📚 **What is MDC?**

**MDC = Mapped Diagnostic Context**

Think of it as a **thread-local storage** that holds information for logging.

```
MDC (Mapped Diagnostic Context)
    ├── traceId: "7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a"
    ├── userId: "user123"
    ├── requestId: "req-456"
    └── sessionId: "session-789"
```

---

## 🔍 **What is a Trace ID?**

A **Trace ID** is a **unique identifier** for a single request/transaction.

**Format:** Usually a UUID (Universally Unique Identifier)
```
Example: 7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a
```

---

## 🎯 **Why Use Trace IDs?**

### Problem: Distributed System Chaos

Without trace IDs:
```
❌ User: "My order failed!"
❌ You: *Searches through millions of logs*
❌ Logs from 5 different services mixed together
❌ Can't tell which logs belong to which request
❌ Takes hours to debug
```

With trace IDs:
```
✅ User: "My order failed! Trace ID: 7f5a3b2c"
✅ You: grep "7f5a3b2c" logs/*.log
✅ See entire flow in 30 seconds
✅ Found: Payment service timeout
✅ Fixed!
```

---

## 🌊 **How Trace IDs Flow**

### Single Request Across Multiple Services

```
┌─────────────────────────────────────────────────────────────────┐
│  User Browser                                                    │
│  Makes request to: http://example.com/api/orders                 │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  API Gateway (Port 9002)                                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 1. Generate Trace ID: 7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a │ │
│  │ 2. Add to MDC: MDC.put("traceId", "7f5a3b2c...")           │ │
│  │ 3. Add to HTTP Header: X-Trace-Id: 7f5a3b2c...             │ │
│  └────────────────────────────────────────────────────────────┘ │
│  Logs: [TraceId:7f5a3b2c] Routing to order-service              │
└───────────────────────────────┬─────────────────────────────────┘
                                │ X-Trace-Id: 7f5a3b2c...
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  Order Service (Port 8081)                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 1. Extract from header: X-Trace-Id: 7f5a3b2c...            │ │
│  │ 2. Put in MDC: MDC.put("traceId", "7f5a3b2c...")           │ │
│  └────────────────────────────────────────────────────────────┘ │
│  Logs: [TraceId:7f5a3b2c] Creating order #12345                 │
│  Logs: [TraceId:7f5a3b2c] Calling payment service               │
└───────────────────────────────┬─────────────────────────────────┘
                                │ X-Trace-Id: 7f5a3b2c...
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  Payment Service (Port 8082)                                     │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ 1. Extract from header: X-Trace-Id: 7f5a3b2c...            │ │
│  │ 2. Put in MDC: MDC.put("traceId", "7f5a3b2c...")           │ │
│  └────────────────────────────────────────────────────────────┘ │
│  Logs: [TraceId:7f5a3b2c] Processing payment $99.99             │
│  Logs: [TraceId:7f5a3b2c] ❌ Payment failed: Card declined      │
└───────────────────────────────┬─────────────────────────────────┘
                                │ X-Trace-Id: 7f5a3b2c...
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│  All Logs Combined (Centralized Logging)                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Search: grep "7f5a3b2c" logs/*.log                          │ │
│  │                                                              │ │
│  │ [TraceId:7f5a3b2c] Gateway: Routing to order-service        │ │
│  │ [TraceId:7f5a3b2c] Order: Creating order #12345             │ │
│  │ [TraceId:7f5a3b2c] Order: Calling payment service           │ │
│  │ [TraceId:7f5a3b2c] Payment: Processing payment $99.99       │ │
│  │ [TraceId:7f5a3b2c] Payment: ❌ Card declined                │ │
│  │                                                              │ │
│  │ ✅ Found the problem: Card declined in Payment Service!     │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 💻 **Code Examples**

### 1. Creating the Filter (Auto-adds Trace ID)

```java
package com.masterclass.appa.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;
import java.io.IOException;
import java.util.UUID;

@Component
public class TraceIdFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        
        try {
            // Get trace ID from header (if exists)
            String traceId = httpRequest.getHeader("X-Trace-Id");
            
            // Generate new one if not present
            if (traceId == null) {
                traceId = UUID.randomUUID().toString();
            }
            
            // Store in MDC (thread-local)
            MDC.put("traceId", traceId);
            
            // Continue request processing
            chain.doFilter(request, response);
            
        } finally {
            // CRITICAL: Clear MDC to prevent memory leaks
            MDC.clear();
        }
    }
}
```

### 2. Using Trace ID in Service Methods

```java
@Service
public class AppBResilientService {
    private static final Logger logger = LoggerFactory.getLogger(AppBResilientService.class);
    
    public String getAppBStatus() {
        // Get trace ID from MDC
        String traceId = MDC.get("traceId");
        
        // Use in logs
        logger.info("[TRACE: {}] Calling App B status endpoint", traceId);
        
        try {
            return appBClient.getAppBStatus();
        } catch (Exception ex) {
            logger.error("[TRACE: {}] Failed to call App B: {}", traceId, ex.getMessage());
            return fallback.getAppBStatus();
        }
    }
}
```

### 3. Passing Trace ID to Other Services (Feign Client)

```java
@Component
public class FeignTraceIdInterceptor implements RequestInterceptor {
    
    @Override
    public void apply(RequestTemplate template) {
        // Get trace ID from current thread
        String traceId = MDC.get("traceId");
        
        if (traceId != null) {
            // Add to outgoing request header
            template.header("X-Trace-Id", traceId);
        }
    }
}
```

### 4. Configuring Logback to Show Trace ID

**File:** `src/main/resources/logback-spring.xml`

```xml
<configuration>
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <!-- %X{traceId} extracts trace ID from MDC -->
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} [TraceId:%X{traceId}] - %msg%n</pattern>
        </encoder>
    </appender>
    
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/app-a.log</file>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} [TraceId:%X{traceId}] - %msg%n</pattern>
        </encoder>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/app-a.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
    </appender>
    
    <root level="INFO">
        <appender-ref ref="CONSOLE" />
        <appender-ref ref="FILE" />
    </root>
</configuration>
```

---

## 📋 **Log Output Example**

### Without Trace ID:
```
2026-01-14 10:30:45.123 INFO  OrderService - Creating order
2026-01-14 10:30:45.456 INFO  PaymentService - Processing payment
2026-01-14 10:30:46.789 ERROR PaymentService - Payment failed
2026-01-14 10:30:47.012 INFO  OrderService - Creating order
2026-01-14 10:30:47.345 INFO  PaymentService - Processing payment

❌ Which "Creating order" caused the payment failure?
❌ Logs are mixed together!
```

### With Trace ID:
```
2026-01-14 10:30:45.123 INFO  OrderService [TraceId:7f5a3b2c] Creating order
2026-01-14 10:30:45.456 INFO  PaymentService [TraceId:7f5a3b2c] Processing payment
2026-01-14 10:30:46.789 ERROR PaymentService [TraceId:7f5a3b2c] Payment failed
2026-01-14 10:30:47.012 INFO  OrderService [TraceId:9a1c4e7f] Creating order
2026-01-14 10:30:47.345 INFO  PaymentService [TraceId:9a1c4e7f] Processing payment

✅ Clear! Trace ID 7f5a3b2c had the payment failure
✅ Trace ID 9a1c4e7f is a different request
```

---

## 🔧 **MDC API Reference**

```java
// Import
import org.slf4j.MDC;

// Put value
MDC.put("traceId", "7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a");
MDC.put("userId", "user123");

// Get value
String traceId = MDC.get("traceId");  // Returns: "7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a"

// Remove specific key
MDC.remove("traceId");

// Clear all
MDC.clear();

// Get all values as Map
Map<String, String> contextMap = MDC.getCopyOfContextMap();
```

---

## 🎯 **Best Practices**

### ✅ DO:
1. **Always clear MDC** after request completes (in `finally` block)
2. **Use UUIDs** for trace IDs (globally unique)
3. **Pass trace ID** between services via HTTP headers
4. **Include in error responses** so users can report issues
5. **Use consistent naming** (e.g., always "X-Trace-Id")

### ❌ DON'T:
1. **Don't forget to clear MDC** (causes memory leaks in thread pools)
2. **Don't use sequential numbers** (not unique across services)
3. **Don't log sensitive data** in MDC (passwords, tokens, etc.)
4. **Don't create new trace ID** when one already exists in header

---

## 🌟 **Real-World Use Cases**

### Use Case 1: User Reports Error
```
User: "I got an error placing my order!"
You: "Can you provide the error code or trace ID?"
User: "It shows Trace ID: 7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a"
You: *Searches logs with trace ID*
You: "Found it! Your payment card was declined. Please try a different card."
```

### Use Case 2: Performance Investigation
```bash
# Find all slow requests (took >1 second)
grep "Duration: [1-9][0-9][0-9][0-9]ms" logs/app.log

# Then get trace IDs of slow requests
grep "7f5a3b2c" logs/app.log

# Analyze entire flow of one slow request
```

### Use Case 3: Distributed Tracing Dashboard
```
┌────────────────────────────────────────────────┐
│  Request Trace: 7f5a3b2c-8d1e-4f9b-a6c0...    │
├────────────────────────────────────────────────┤
│  Gateway          → 5ms                        │
│  ├─ Order Service → 120ms                      │
│     ├─ Payment    → 3000ms ⚠️ SLOW!           │
│     └─ Inventory  → 15ms                       │
└────────────────────────────────────────────────┘
Total: 3140ms

💡 Problem identified: Payment service is slow!
```

---

## 🎓 **Summary for Interns**

### What is `String traceId = MDC.get("traceId");`?

**Short Answer:**
Gets a unique ID for the current request from thread-local storage.

**Full Answer:**
1. **MDC** = Mapped Diagnostic Context (a logging feature)
2. **Thread-local storage** = Each thread has its own copy
3. **"traceId"** = Key name we use to store the unique ID
4. **UUID** = Unique identifier like `7f5a3b2c-8d1e-4f9b-a6c0-1e2f3d4b5c6a`
5. **Purpose** = Track one request across multiple services

**When to use:**
- In every log statement
- When calling other services
- When returning errors to users
- When debugging issues

**Why it's important:**
- Microservices = Many services
- One request = Touches many services
- Without trace ID = Impossible to track
- With trace ID = Easy to find entire flow!

---

## 📖 **Additional Resources**

**Official Documentation:**
- [SLF4J MDC](http://www.slf4j.org/manual.html#mdc)
- [Spring Cloud Sleuth](https://spring.io/projects/spring-cloud-sleuth) (Automatic trace ID generation)
- [OpenTelemetry](https://opentelemetry.io/) (Industry standard for distributed tracing)

**Related Concepts:**
- Distributed Tracing
- Correlation IDs
- Request IDs
- Span IDs (for timing within a trace)

---

**Now you understand `MDC.get("traceId")`! 🎉**

*It's one of the most important patterns in microservices logging!*
