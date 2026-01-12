# 🏗️ PHASE 3 INFRASTRUCTURE SETUP - Windows Machine Guide

**Date:** January 12, 2026  
**Platform:** Windows (PowerShell)  
**Topic:** Setting up Zipkin, ELK Stack, and Kafka for distributed logging

---

## 📋 Overview: Three Infrastructure Options

```
Option 1: SIMPLE (Recommended for Learning)
├─ Zipkin Server Only
├─ No external dependencies
├─ Easy setup on Windows
├─ Time to setup: 5 minutes
└─ Perfect for: Phase 3 learning

Option 2: INTERMEDIATE (Recommended for Development)
├─ Zipkin + ELK Stack
├─ Centralized logging
├─ Better visualization
├─ Time to setup: 20 minutes
└─ Perfect for: Local development

Option 3: PRODUCTION-READY (Advanced)
├─ Zipkin + ELK + Kafka
├─ High performance
├─ Scalable architecture
├─ Time to setup: 45 minutes
└─ Perfect for: Production deployment
```

---

## 🎯 My Recommendation for You

### Best Approach for Windows Development:

```
START WITH: Option 1 (Zipkin Only)
├─ Get Phase 3 working quickly
├─ Understand distributed tracing
├─ Test with your 6 instances
└─ Time investment: 5 minutes

THEN UPGRADE TO: Option 2 (Zipkin + ELK)
├─ Add centralized logging
├─ Learn log aggregation
├─ Better search capabilities
└─ Time investment: 15 additional minutes

SKIP FOR NOW: Option 3 (Kafka)
├─ Use only when scaling to production
├─ Add later when needed
└─ Too complex for Windows dev environment
```

---

## ✅ OPTION 1: ZIPKIN ONLY (RECOMMENDED FOR START)

### What You'll Get
```
✅ Distributed tracing dashboard
✅ Request flow visualization
✅ Latency analysis
✅ Service dependency mapping
✅ Easy to setup on Windows
✅ Perfect for learning Phase 3
```

### Setup Method A: Docker (Easiest)

**Prerequisites:**
```
✅ Docker Desktop installed on Windows
✅ Running in PowerShell as Administrator
```

**Step 1: Install Docker Desktop (if not already)**
```powershell
# Download from: https://www.docker.com/products/docker-desktop
# Follow installation wizard
# Restart Windows after installation
```

**Step 2: Start Zipkin Server**
```powershell
# Run this command in PowerShell
docker run -d -p 9411:9411 --name zipkin openzipkin/zipkin:latest
```

**Step 3: Verify Zipkin is Running**
```powershell
# Check if container is running
docker ps | grep zipkin

# Expected output:
# CONTAINER ID   IMAGE            STATUS           PORTS
# 1a2b3c4d       openzipkin/...   Up 2 minutes     0.0.0.0:9411->9411/tcp   zipkin
```

**Step 4: Access Zipkin Dashboard**
```powershell
# Open browser to Zipkin
Start-Process "http://localhost:9411"
```

**Expected result:**
```
Dashboard loads with:
├─ Search interface
├─ Service list (empty at first)
├─ Trace view
└─ Dependencies graph
```

**To Stop Zipkin:**
```powershell
docker stop zipkin
```

**To Remove Zipkin:**
```powershell
docker rm zipkin
```

---

### Setup Method B: Standalone JAR (No Docker)

**If you don't have Docker or prefer direct installation:**

**Step 1: Download Zipkin JAR**
```powershell
# Create Zipkin directory
New-Item -ItemType Directory -Path "C:\zipkin" -Force

# Download latest Zipkin JAR
$url = "https://zipkin.io/quickstart.sh"
# Or manually download from: https://zipkin.io/pages/quickstart.html

# Download using Invoke-WebRequest
Invoke-WebRequest -Uri "https://search.maven.org/remote_content?g=io.zipkin.java&a=zipkin-server&v=LATEST&c=exec" -OutFile "C:\zipkin\zipkin.jar"

# Alternative: Download directly from browser
# https://search.maven.org/search?q=g:io.zipkin.java%20AND%20a:zipkin-server&core=gav
```

**Step 2: Run Zipkin**
```powershell
# Navigate to Zipkin directory
cd C:\zipkin

# Start Zipkin server
java -jar zipkin.jar
```

**Expected output:**
```
2026-01-12 10:30:00 - Zipkin started on port 9411
Open browser to: http://localhost:9411
```

**Step 3: Access Dashboard**
```powershell
# In another PowerShell window
Start-Process "http://localhost:9411"
```

**To Stop Zipkin:**
```
Press Ctrl+C in the terminal running zipkin.jar
```

---

### Option 1 Verification

**After setup, you should see:**
```
Browser: http://localhost:9411
├─ Zipkin UI loads
├─ Search box visible
├─ No traces yet (normal)
└─ Services: [] (will populate when apps run)
```

---

## 🔧 OPTION 2: ZIPKIN + ELK STACK (INTERMEDIATE)

### What You'll Get
```
✅ Everything from Option 1 +
✅ Centralized log storage (Elasticsearch)
✅ Advanced log search (Kibana)
✅ Full-text log queries
✅ Custom dashboards
✅ Better for larger applications
```

### Architecture
```
Services (with Sleuth)
    ↓ logs + trace ID
┌───────────────────────┐
│ Logstash              │ (log processor)
│ (listens on 5000)     │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│ Elasticsearch         │ (log storage)
│ (port 9200)           │
└───────┬───────────────┘
        ↓
┌───────────────────────┐
│ Kibana                │ (visualization)
│ (port 5601)           │
└───────────────────────┘
```

### Setup Method A: Docker Compose (Easiest)

**Step 1: Create docker-compose.yml**
```powershell
# Navigate to your project directory
cd C:\Users\2267040\Desktop\Ai-Life_assitant-Vibe-coding-final\Microservices-masterclass-demo

# Create docker-compose.yml file
@"
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - xpack.security.enrollment.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
      - "9300:9300"
    healthcheck:
      test: curl -s http://localhost:9200 >/dev/null || exit 1
      interval: 30s
      timeout: 10s
      retries: 5

  kibana:
    image: docker.elastic.co/kibana/kibana:8.0.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch
    healthcheck:
      test: curl -s http://localhost:5601/app/kibana >/dev/null || exit 1
      interval: 30s
      timeout: 10s
      retries: 5

  logstash:
    image: docker.elastic.co/logstash/logstash:8.0.0
    container_name: logstash
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    ports:
      - "5000:5000"
      - "5000:5000/udp"
    environment:
      - "LS_JAVA_OPTS=-Xmx256m -Xms256m"
    depends_on:
      - elasticsearch
    healthcheck:
      test: bin/logstash -t -f /usr/share/logstash/pipeline/logstash.conf
      interval: 30s
      timeout: 10s
      retries: 3

  zipkin:
    image: openzipkin/zipkin:latest
    container_name: zipkin
    ports:
      - "9411:9411"
    depends_on:
      - elasticsearch
    environment:
      - STORAGE_TYPE=elasticsearch
      - ES_HOSTS=elasticsearch:9200
    healthcheck:
      test: curl -s http://localhost:9411 >/dev/null || exit 1
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  elasticsearch_data:

networks:
  default:
    name: elk-zipkin-network
"@ | Out-File docker-compose.yml -Encoding UTF8
```

**Step 2: Create logstash.conf**
```powershell
# Create logstash configuration
@"
input {
  tcp {
    port => 5000
    codec => json
  }
  udp {
    port => 5000
    codec => json
  }
}

filter {
  # Extract trace ID if present
  if [traceId] {
    mutate {
      add_field => { "[@metadata][trace_id]" => "%{traceId}" }
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "logs-%{+YYYY.MM.dd}"
  }
}
"@ | Out-File logstash.conf -Encoding UTF8
```

**Step 3: Start ELK Stack**
```powershell
# Start all containers
docker-compose up -d

# Wait for containers to start (30-60 seconds)
Start-Sleep -Seconds 60

# Verify all services are running
docker-compose ps
```

**Expected output:**
```
NAME                STATE           PORTS
elasticsearch       Up (healthy)    0.0.0.0:9200->9200/tcp
kibana             Up (healthy)    0.0.0.0:5601->5601/tcp
logstash           Up (healthy)    0.0.0.0:5000->5000/tcp
zipkin             Up (healthy)    0.0.0.0:9411->9411/tcp
```

**Step 4: Access Dashboards**
```powershell
# Zipkin (traces)
Start-Process "http://localhost:9411"

# Kibana (logs)
Start-Process "http://localhost:5601"

# Elasticsearch (API)
Start-Process "http://localhost:9200"
```

**Step 5: Configure Kibana Data View (First Time)**
```
In Kibana:
1. Go to: Management → Data Views
2. Click: Create Data View
3. Name: logs-*
4. Time field: @timestamp
5. Create
```

**To Stop ELK Stack:**
```powershell
docker-compose down
```

**To Remove Everything (Clean Start):**
```powershell
docker-compose down -v  # -v removes volumes
```

---

### Setup Method B: Individual Containers

**If you prefer not to use docker-compose:**

**Step 1: Start Elasticsearch**
```powershell
docker run -d `
  --name elasticsearch `
  -p 9200:9200 `
  -e "discovery.type=single-node" `
  -e "xpack.security.enabled=false" `
  -e "ES_JAVA_OPTS=-Xms512m -Xmx512m" `
  docker.elastic.co/elasticsearch/elasticsearch:8.0.0
```

**Step 2: Start Kibana**
```powershell
docker run -d `
  --name kibana `
  -p 5601:5601 `
  -e "ELASTICSEARCH_HOSTS=http://host.docker.internal:9200" `
  docker.elastic.co/kibana/kibana:8.0.0

# Wait 30 seconds for Kibana to start
Start-Sleep -Seconds 30
```

**Step 3: Start Logstash**
```powershell
# First, create logstash config directory
New-Item -ItemType Directory -Path "C:\logstash\config" -Force

# Create logstash.conf (see content above)
# Then run:

docker run -d `
  --name logstash `
  -p 5000:5000 `
  -p 5000:5000/udp `
  -v C:\logstash\config\logstash.conf:/usr/share/logstash/pipeline/logstash.conf `
  -e "LS_JAVA_OPTS=-Xmx256m -Xms256m" `
  docker.elastic.co/logstash/logstash:8.0.0
```

**Step 4: Start Zipkin**
```powershell
docker run -d `
  --name zipkin `
  -p 9411:9411 `
  -e "STORAGE_TYPE=elasticsearch" `
  -e "ES_HOSTS=http://host.docker.internal:9200" `
  openzipkin/zipkin:latest
```

---

### Option 2 Verification

**After setup, you should have:**
```
Dashboard Access:
├─ Zipkin: http://localhost:9411 ✅
├─ Kibana: http://localhost:5601 ✅
├─ Elasticsearch API: http://localhost:9200 ✅
└─ Logstash: Listening on port 5000 ✅

Services Running:
├─ elasticsearch (port 9200)
├─ kibana (port 5601)
├─ logstash (port 5000)
└─ zipkin (port 9411)
```

---

## ⚠️ OPTION 3: FULL STACK WITH KAFKA (PRODUCTION-ONLY)

### ⚠️ Important Note for Windows

```
Kafka on Windows is complex because:
├─ Kafka is designed for Linux
├─ Windows file paths are different
├─ Requires Java and Scala
├─ Performance is limited on Windows
└─ Better to use WSL2 or Docker

RECOMMENDATION:
For local development: Use Option 1 or 2
For production: Deploy on Linux/Kubernetes
For Windows: Use Docker for Kafka
```

### When You Need Kafka

```
Use Kafka when:
├─ Logs from 100+ instances
├─ Need to buffer logs (peak traffic)
├─ Want to process logs in real-time
├─ Scaling to enterprise level
└─ NOT for learning Phase 3

Skip for now!
```

### If You Really Want Kafka Setup

```powershell
# Using Docker Compose (Easiest approach for Windows)
# Add to docker-compose.yml:

zookeeper:
  image: confluentinc/cp-zookeeper:7.0.0
  environment:
    ZOOKEEPER_CLIENT_PORT: 2181

kafka:
  image: confluentinc/cp-kafka:7.0.0
  ports:
    - "9092:9092"
  environment:
    KAFKA_BROKER_ID: 1
    KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
    KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
    KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
```

**BUT:** This is production-level complexity. Skip for Phase 3 learning.

---

## 🎯 MY RECOMMENDED APPROACH FOR YOU

### Phase 3 Step-by-Step Setup

```
WEEK 1: Start Simple
├─ Monday: Option 1 - Zipkin Only
│  ├─ Docker setup: 5 minutes
│  ├─ Add Sleuth/Zipkin dependencies: 10 minutes
│  ├─ Configure services: 10 minutes
│  ├─ Test with 6 instances: 20 minutes
│  └─ Total: 45 minutes to full Phase 3 working!
│
├─ Tuesday-Thursday: Learn & Practice
│  ├─ Make requests, analyze traces
│  ├─ Understand request flows
│  ├─ Test failure scenarios
│  └─ Debug using Zipkin
│
└─ Friday: Optional Upgrade to Option 2

WEEK 2: Upgrade if Needed
├─ Add ELK Stack to existing Zipkin
├─ Test centralized logging
├─ Create Kibana dashboards
└─ Continue learning
```

---

## 🚀 QUICK START: Do This RIGHT NOW

### For Immediate Setup (5 minutes)

**Step 1: Check Docker**
```powershell
# Check if Docker is installed
docker --version
docker ps

# If error: Install Docker Desktop from https://www.docker.com/products/docker-desktop
```

**Step 2: Start Zipkin**
```powershell
# Run this single command
docker run -d -p 9411:9411 --name zipkin openzipkin/zipkin:latest
```

**Step 3: Verify**
```powershell
# Check if running
docker ps

# Open dashboard
Start-Process "http://localhost:9411"
```

**✅ You now have Zipkin running! Next: Add to services**

---

## 📊 Comparison Table: Which Option to Choose

| Need | Option 1 (Zipkin) | Option 2 (ELK+Zipkin) | Option 3 (Kafka) |
|------|-------------------|----------------------|------------------|
| **Learning Phase 3** | ✅ PERFECT | ✅ Overkill | ❌ Too complex |
| **Windows Setup** | ✅ Easy | ✅ Medium | ❌ Hard |
| **Time to Setup** | ✅ 5 min | ✅ 20 min | ❌ 60+ min |
| **Docker Needed** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Request Tracing** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Centralized Logs** | ❌ No | ✅ Yes | ✅ Yes |
| **Log Search** | ❌ Limited | ✅ Full-text | ✅ Full-text |
| **Production Ready** | ⚠️ Limited | ✅ Yes | ✅ Yes (on Linux) |

---

## 🔄 Migration Path

```
PHASE 3 JOURNEY:

Option 1 (Zipkin Only)
    ↓
"I understand distributed tracing"
    ↓
Option 2 (Add ELK Stack)
    ↓
"I need better log search capabilities"
    ↓
Option 3 (Production Kafka)
    ↓
"I'm deploying to production servers"
```

---

## ⚡ Resource Requirements

### Minimum System Requirements (Windows)

```
Option 1 - Zipkin Only:
├─ RAM needed: 512 MB
├─ Disk space: 500 MB
├─ Docker: Yes
├─ Other: Nothing else
└─ Total impact: Very light

Option 2 - Zipkin + ELK:
├─ RAM needed: 2-4 GB
├─ Disk space: 2 GB
├─ Docker: Yes
├─ Other: Docker Compose
└─ Total impact: Moderate

Option 3 - Full Stack:
├─ RAM needed: 8+ GB
├─ Disk space: 5 GB
├─ Docker: Yes
├─ Other: Complex networking
└─ Total impact: Heavy
```

### Your Current System:
```
Assuming typical developer laptop:
├─ RAM: 8-16 GB ✅
├─ Storage: Plenty ✅
└─ CPU: Multi-core ✅

You can run Option 2 comfortably!
Option 3 would be tight but possible
```

---

## 🛠️ Troubleshooting Common Issues

### Issue 1: Docker Not Installed
```powershell
# Solution: Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop
# Requires Windows 10/11 with WSL2 enabled
```

### Issue 2: Port Already in Use
```powershell
# Find process using port 9411
netstat -ano | findstr :9411

# Kill process
taskkill /PID <PID> /F

# Then retry docker run command
```

### Issue 3: Zipkin Logs Show Errors
```powershell
# View Docker logs
docker logs zipkin

# Restart Zipkin
docker restart zipkin

# If still fails, remove and recreate
docker rm -f zipkin
docker run -d -p 9411:9411 --name zipkin openzipkin/zipkin:latest
```

### Issue 4: Services Not Sending Traces to Zipkin
```
Common causes:
├─ Zipkin URL wrong in application.yml
├─ Sleuth dependency missing
├─ Sampling probability set to 0
└─ Trace propagation headers not sent

Check:
├─ spring.zipkin.base-url = http://localhost:9411
├─ spring.sleuth.sampler.probability = 1.0
├─ Dependencies added correctly
└─ Services restarted after config change
```

---

## 📝 Summary: Your Action Plan

### TODAY (Phase 3 Start):
```
1. Choose Option 1 (Zipkin Only) ✅
2. Run one Docker command (5 minutes)
3. Verify dashboard loads
4. Proceed to code changes (dependencies + config)
```

### THIS WEEK (Phase 3 Complete):
```
1. Add Sleuth/Zipkin to all 4 services
2. Configure application.yml
3. Restart services
4. Test with 6 instances
5. View traces in Zipkin dashboard
```

### NEXT WEEK (Optional Upgrade):
```
1. Docker-compose up for Option 2
2. Add Logstash config
3. Update services to send logs to Logstash
4. Explore Kibana dashboards
5. Learn advanced log queries
```

### PRODUCTION (Later):
```
1. Evaluate Option 3
2. Setup on Linux/Kubernetes
3. Configure Kafka topics
4. Scale to enterprise level
```

---

## ✨ Next Steps: Ready?

**Are you ready to:**
1. ✅ Start with Option 1 (Zipkin Only)?
2. ✅ Setup Docker and run Zipkin?
3. ✅ Proceed to Phase 3 code changes?

If yes, I'll provide:
- Step-by-step service configuration
- pom.xml changes for all 4 services
- application.yml updates
- Testing guide

**Shall we proceed?** 🚀

