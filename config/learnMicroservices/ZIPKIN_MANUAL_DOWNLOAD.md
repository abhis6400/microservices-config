# 📥 MANUAL ZIPKIN DOWNLOAD - Step by Step

**Date:** January 12, 2026  
**Status:** Network issues with automated download - using manual approach  
**Time:** 5 minutes

---

## 🎯 Download Manually (3 Easy Steps)

### Step 1: Create Directory (Already Done ✅)
```
C:\zipkin\  ← Directory created and ready
```

### Step 2: Download Zipkin JAR

**Option A: Direct Download (Recommended)**

1. **Open your browser** and go to:
   ```
   https://github.com/openzipkin/zipkin/releases/latest
   ```

2. **Look for the file**: `zipkin-X.XX.X-exec.jar`
   - Click on it to download
   - File size: ~60 MB

3. **Save to**: `C:\zipkin\`

4. **Rename to**: `zipkin.jar` (remove version numbers)

---

### Step 3: Verify Download

**In PowerShell:**
```powershell
cd C:\zipkin
Get-Item zipkin.jar
```

**Expected output:**
```
    Directory: C:\zipkin

Mode                 LastWriteTime         Length Name
----                 -----                ------ ----
-a---          1/12/2026   3:00 PM     60000000 zipkin.jar
```

---

## 📱 Direct Download Links (If Browser Downloads)

**Choose ONE of these direct links:**

```
Option 1 (Latest):
https://github.com/openzipkin/zipkin/releases/latest

Option 2 (Specific Version):
https://github.com/openzipkin/zipkin/releases/download/2.25.1/zipkin-2.25.1-exec.jar

Option 3 (Maven Central):
https://central.sonatype.dev/artifact/io.zipkin.java/zipkin-server
```

**Steps:**
1. Right-click the download link
2. Select "Save link as..."
3. Save to: `C:\zipkin\zipkin.jar`
4. Done!

---

## ✅ Once Downloaded

**After you save the JAR file, reply with:**
- "Downloaded!" or "Zipkin JAR ready"

**Then I'll help you:**
1. Start Zipkin
2. Update your services
3. Get Phase 3 working!

---

## 🆘 If Download Still Fails

**Alternative: Use portable Zipkin from cloud**

If your network is blocking downloads, you can:
1. Download on another machine
2. Transfer via USB
3. Copy to C:\zipkin\

Or use this approach:
```powershell
# Ask IT to allow download from github.com
# Corporate firewalls sometimes block it
```

---

## 📝 Next Step

**Once you have the JAR file:**

```powershell
cd C:\zipkin
java -jar zipkin.jar
```

Should see:
```
2026-01-12 15:30:00 Listening on 0.0.0.0:9411
```

Let me know once you've downloaded the JAR! 🚀

