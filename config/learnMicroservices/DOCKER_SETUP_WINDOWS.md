# 🐳 DOCKER SETUP FOR WINDOWS - Complete Guide

**Date:** January 12, 2026  
**Platform:** Windows 10/11  
**Time:** 20 minutes  
**Goal:** Install Docker and run Zipkin

---

## ✅ What You Need

```
✅ Windows 10 Pro/Enterprise or Windows 11
✅ Administrator access
✅ 4+ GB RAM
✅ Virtualization enabled in BIOS (usually pre-enabled)
```

**Check your Windows version:**
```powershell
# Run this in PowerShell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion
```

Expected output:
```
WindowsProductName : Windows 11 Pro
WindowsVersion     : 23H2
```

---

## 🚀 STEP 1: Install Docker Desktop

### Download Docker Desktop

1. **Go to:** https://www.docker.com/products/docker-desktop

2. **Click:** "Download for Windows"

3. **File:** `Docker Desktop Installer.exe` (~500 MB)

4. **Run the installer:**
   - Double-click `Docker Desktop Installer.exe`
   - Click "OK" when prompted for admin permission
   - Follow the wizard (use default settings)
   - Click "Install"

5. **Wait for installation** (~5-10 minutes)

6. **Restart Windows** when prompted

---

## ✅ STEP 2: Verify Docker Installation

**After restart, open PowerShell and run:**

```powershell
# Check Docker version
docker --version

# Expected output:
# Docker version 26.1.3, build b604786
```

**If error:** "docker command not found"
```powershell
# Docker may still be starting
# Wait 30 seconds and try again

# Or restart PowerShell completely
```

---

## 🧪 STEP 3: Test Docker

**Run test container:**
```powershell
docker run hello-world
```

**Expected output:**
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

✅ **Docker is working!**

---

## 🎯 STEP 4: Start Zipkin with Docker

**Very simple - just one command:**

```powershell
# Start Zipkin
docker run -d -p 9411:9411 --name zipkin openzipkin/zipkin:latest

# Output:
# [Long container ID - this is normal]
```

**Wait 10 seconds for Zipkin to start**

---

## ✅ STEP 5: Verify Zipkin is Running

```powershell
# Check running containers
docker ps

# Expected output:
# CONTAINER ID   IMAGE                  STATUS              PORTS
# abc123def      openzipkin/zipkin      Up 5 seconds        0.0.0.0:9411->9411/tcp   zipkin
```

✅ **Zipkin is running!**

---

## 🌐 STEP 6: Open Zipkin Dashboard

```powershell
# Open in browser
Start-Process "http://localhost:9411"
```

**You should see:**
```
Zipkin Dashboard
├─ Search interface
├─ Service list (empty - normal)
├─ Trace visualization
└─ Dependencies graph
```

✅ **Zipkin is accessible!**

---

## 🛑 Useful Docker Commands

**Stop Zipkin:**
```powershell
docker stop zipkin
```

**Start Zipkin again:**
```powershell
docker start zipkin
```

**View Zipkin logs:**
```powershell
docker logs zipkin
```

**Remove Zipkin (clean):**
```powershell
docker rm -f zipkin
```

**List all containers:**
```powershell
docker ps -a
```

---

## ⚠️ Common Docker Issues

### Issue 1: "Docker daemon not running"

**Solution:**
```powershell
# Check if Docker Desktop is running
# Look for Docker icon in system tray (bottom right)

# If not running:
# 1. Search for "Docker Desktop" in Windows
# 2. Click to start
# 3. Wait 30 seconds
# 4. Try again
```

### Issue 2: Port 9411 Already in Use

```powershell
# Find process using port 9411
netstat -ano | findstr :9411

# Kill the process
taskkill /PID <PID> /F

# Then remove and restart Zipkin
docker rm -f zipkin
docker run -d -p 9411:9411 --name zipkin openzipkin/zipkin:latest
```

### Issue 3: "Cannot connect to Docker daemon"

**Solution:**
```powershell
# Restart Docker Desktop:
# 1. Right-click Docker icon in system tray
# 2. Click "Quit Docker Desktop"
# 3. Wait 5 seconds
# 4. Click "Docker Desktop" to restart
# 5. Wait 30 seconds
# 6. Try again
```

### Issue 4: Low Disk Space

```powershell
# Docker needs space
# Check disk space:
Get-Volume

# If low on space:
# Delete unused Docker images
docker image prune -a
```

---

## 📊 Docker vs Standalone JAR

| Aspect | Docker | Standalone JAR |
|--------|--------|-----------------|
| **Setup Time** | 20 min (first time) | 5 min |
| **Command** | 1 line | 1 line |
| **Space** | 400 MB | 60 MB |
| **Network Issues** | No (contained) | Yes (download) |
| **Reliability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **For Phase 3** | ✅ BEST | ⚠️ Network blocking |

---

## ✨ Once Zipkin is Running

You're ready for Phase 3!

**Next steps:**
1. ✅ Add Sleuth + Zipkin dependencies to services
2. ✅ Configure application.yml
3. ✅ Rebuild services
4. ✅ Start services
5. ✅ Make requests
6. ✅ View traces in Zipkin dashboard

---

## 🎯 Quick Reference

**Start Zipkin:**
```powershell
docker run -d -p 9411:9411 --name zipkin openzipkin/zipkin:latest
```

**Access Zipkin:**
```
http://localhost:9411
```

**Stop Zipkin:**
```powershell
docker stop zipkin
```

**Clean up:**
```powershell
docker rm -f zipkin
```

---

## 📞 Still Need Help?

If Docker installation fails:

**Troubleshooting steps:**
1. Check Windows version: `ver` (must be Windows 10/11)
2. Check virtualization: Search "Turn Windows features on or off" → Enable "Hyper-V"
3. Restart Windows
4. Try Docker Desktop installation again

**Alternative:** Use the Maven Central download method (Method A in previous section)

---

**Ready to proceed?** Let me know if Docker is installed! 🚀

