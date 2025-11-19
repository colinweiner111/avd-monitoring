# AVD Network Monitoring - Quick Start Guide

## Overview

This guide covers everything you need to get the AVD network monitoring scripts up and running quickly.

**Time to setup:** 5-10 minutes  
**Scripts included:** 
- Monitor-AVDConnection.ps1 (client-side monitoring)
- Simulate-AVDUserTraffic.ps1 (workload simulation)
- Test-MonitoringScript.ps1 (validation)

### Key Features

**Monitor-AVDConnection.ps1** tracks:
- Ping latency and packet loss
- DNS resolution time  
- TCP port connectivity
- Network adapter errors
- WiFi signal strength
- **NEW: Connection Quality Score** (optional 0-100 rating)

**To enable Quality Score, add `-IncludeQualityScore` parameter:**
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IncludeQualityScore
```

---

## Prerequisites Check

### System Requirements

| Requirement | Minimum | How to Check |
|-------------|---------|--------------|
| **Operating System** | Windows 10/11 or Windows Server 2016+ | `systeminfo \| findstr /B /C:"OS Name"` |
| **PowerShell Version** | 5.1 or higher | `$PSVersionTable.PSVersion` |
| **Network Connectivity** | Internet access | `Test-NetConnection 8.8.8.8` |
| **Disk Space** | 50 MB free | Check Desktop or C:\ drive |
| **Permissions** | Standard user (Admin recommended) | Run PowerShell normally |

### Quick Pre-Flight Check

Run this command to validate your environment:

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Output should show:
# Major  Minor  Build  Revision
# 5      1      xxxxx  xxxx     (or higher)
```

If version is 5.1+, you're good to go!

---

## Installation

### Step 1: Download the Scripts

Download all scripts to a local folder:

**Recommended location:** `C:\AVDMonitoring`

**Files needed:**
- Monitor-AVDConnection.ps1
- Simulate-AVDUserTraffic.ps1
- Test-MonitoringScript.ps1

### Step 2: Unblock the Scripts

PowerShell blocks downloaded scripts by default. Unblock them:

```powershell
# Navigate to your folder
cd C:\AVDMonitoring

# Unblock all PowerShell scripts
Get-ChildItem -Path . -Filter *.ps1 | Unblock-File

# Verify they're unblocked (should show no output)
Get-ChildItem -Path . -Filter *.ps1 | Get-Item -Stream Zone.Identifier
```

### Step 3: Set Execution Policy (If Needed)

If you get "running scripts is disabled" error:

```powershell
# Option A: For current session only (safest)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Option B: For current user (persists)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 4: Validate Setup

Run the validation script:

```powershell
.\Test-MonitoringScript.ps1
```

**Expected output:**
```
✓ PowerShell 5.1 - OK
✓ Test-Connection
✓ Test-NetConnection
✓ Get-NetAdapter
✓ Get-NetAdapterStatistics
✓ Network connectivity OK
✓ Can write to Desktop
✓ ALL CHECKS PASSED
```

If all checks pass, you're ready to go!

---

## Getting Your Session Host FQDN

Before running the monitor, you need your AVD session host FQDN.

### Option 1: From Azure Log Analytics (Recommended)

```kusto
WVDConnections
| where TimeGenerated > ago(7d)
| where UserName == "affected.user@domain.com"
| distinct SessionHostName
```

**Example output:** `host.domain.com`

### Option 2: From Azure Portal

1. Go to Azure Portal → Virtual Desktop
2. Select your Host Pool
3. Click "Session hosts"
4. Copy the Name (FQDN) of any session host

**Example output:** `host.domain.com`

---

## Running the Scripts

### Scenario 1: Monitor Real User (Production)

**Use case:** Troubleshoot active user experiencing disconnects

**Setup:**

**On user's laptop/client machine:**

**Basic monitoring:**
```powershell
cd C:\AVDMonitoring
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 30 -AlertOnFailure
```

**Recommended: With Connection Quality Score (easier trend analysis):**
```powershell
cd C:\AVDMonitoring
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 30 -AlertOnFailure -IncludeQualityScore
```

**What the `-IncludeQualityScore` does:**
- Adds a single 0-100 score combining latency, jitter, packet loss, and DNS time
- Makes trends easier to spot in Excel
- Adds two columns to CSV: `QualityScore` and `QualityRating`
- Shows quality in console: `Connection Quality: 88/100 (Good)`

**User continues working normally**

**When disconnect occurs:**
1. Note the exact time (e.g., 2:15 PM)
2. Press **Ctrl+C** to stop the script
3. Open the CSV file on Desktop: `AVD-Network-Monitor.csv`
4. Look for issues around 2:15 PM in the "Notes" column

**Duration:** Run as long as needed (typically 2-8 hours)

---

### Scenario 2: Controlled Testing (Both Scripts)

**Use case:** Reproduce issues in test environment or force problems to appear

**Setup requires 3 PowerShell windows:**

#### Window 1 - Monitor (on client/laptop)

```powershell
cd C:\AVDMonitoring

.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 15 -AlertOnFailure
```

**Leave this running - it will show real-time status**

#### Window 2 - Connect to AVD

1. Open your AVD client or web browser
2. Connect to your AVD session
3. Open PowerShell **inside the AVD session**

#### Window 3 - Traffic Simulation (inside AVD session)

```powershell
# Inside the AVD session, navigate to where you copied the scripts
cd C:\AVDMonitoring  # or wherever you put them

# Run the traffic simulation
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed -IncludeVideo
```

**Duration:** Typically 15-30 minutes

**What to watch:**
- Window 1 shows network metrics changing
- Red alerts appear when issues detected
- CSV logs everything automatically

**When complete:**
1. Stop the monitor (Ctrl+C in Window 1)
2. Open CSV file on Desktop
3. Analyze the results

---

### Scenario 3: Quick Validation Test

**Use case:** Verify scripts work before deploying to users

**On your laptop:**

```powershell
cd C:\AVDMonitoring

# Test against any reachable host (not AVD-specific)
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "microsoft.com" -IntervalSeconds 10
```

**Let it run for 2-3 minutes**

**Expected results:**
- Console shows connectivity checks
- CSV file created on Desktop
- Ping shows low latency
- TCP 3389 will show "Closed" (normal for microsoft.com)

**Stop with Ctrl+C**

If this works, your environment is ready for real testing.

---

## Common Scenarios

### WiFi vs Wired Comparison

**Test 1 - On WiFi:**
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 20 -LogPath "Desktop\wifi-test.csv" -AlertOnFailure
```
Run for 30 minutes with normal usage or traffic simulation

**Test 2 - On Wired (Ethernet):**
```powershell
# Disconnect WiFi, connect Ethernet cable
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 20 -LogPath "Desktop\wired-test.csv" -AlertOnFailure
```
Run for 30 minutes with same usage pattern

**Compare the two CSV files**

---

### VPN Testing

**Test 1 - With VPN:**
```powershell
# Connect VPN first
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 20 -LogPath "Desktop\vpn-test.csv" -AlertOnFailure
```

**Test 2 - Without VPN:**
```powershell
# Disconnect VPN
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 20 -LogPath "Desktop\direct-test.csv" -AlertOnFailure
```

**Compare results**

---

### Stress Testing

**Force maximum load to find breaking points:**

**Window 1 - Monitor with fast checks:**
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 10 -AlertOnFailure
```

**Window 2 - Heavy simulation inside AVD:**
```powershell
.\Simulate-AVDUserTraffic.ps1 -Duration 20 -WorkloadType Heavy -IncludeVideo
```

---

## Understanding the Output

### Monitor Console Output

```
[2025-11-18 14:30:15] Checking connectivity (Iteration #5)...
  └─ DNS Resolution: 23.4 ms
  └─ Ping: SUCCESS | Avg: 45 ms | Min: 42 ms | Max: 52 ms | Loss: 0%
  └─ TCP 3389 (RDP): Open
  └─ UDP 3390 (Shortpath): Not testable from client
  └─ Adapter: Wi-Fi | Status: Up | Speed: 866.7 Mbps
  └─ Packet Errors: Received=0, Sent=0, Total=0
  └─ WiFi Signal: 72%
  └─ Connection Quality: 88/100 (Good)
  ✓ All connectivity checks passed
```

**Note:** Connection Quality Score appears only if you use `-IncludeQualityScore` parameter.

**Key indicators:**

✅ **Green text** = Good  
⚠️ **Yellow text** = Warning  
❌ **Red text** = Problem

### Connection Quality Score (Optional Feature)

**To enable:** Add `-IncludeQualityScore` parameter when starting the script

**What it does:** Combines latency, packet loss, jitter, and DNS time into a single 0-100 score

#### Score Ranges

| Score | Rating | Color | Meaning |
|-------|--------|-------|---------|
| **90-100** | Excellent | Green | Optimal AVD performance |
| **75-89** | Good | Green | Acceptable for most work |
| **60-74** | Fair | Yellow | Noticeable slowness |
| **40-59** | Poor | Red | Significant lag/issues |
| **0-39** | Critical | Red | Unusable/about to disconnect |

#### How It's Calculated

The score is weighted based on importance to AVD performance:

| Component | Weight | Excellent | Good | Fair | Poor |
|-----------|--------|-----------|------|------|------|
| **Latency** | 40 points | <30ms | <100ms | <150ms | >150ms |
| **Packet Loss** | 30 points | 0% | 0% | >0% | >2% |
| **Jitter** | 20 points | <20ms | <50ms | <100ms | >100ms |
| **DNS Time** | 10 points | <50ms | <200ms | <500ms | >500ms |

#### Why Use It?

**Easier trend analysis:**
```
Without Quality Score (4 metrics to watch):
14:00 - Latency: 45ms, Loss: 0%, Jitter: 8ms, DNS: 25ms
14:15 - Latency: 120ms, Loss: 1%, Jitter: 65ms, DNS: 180ms  ← Is this bad?

With Quality Score (1 metric):
14:00 - Quality: 92 (Excellent)
14:15 - Quality: 58 (Poor)  ← Clearly degrading!
```

**Quick Excel charting:** Graph one column instead of four

**At-a-glance health:** See connection status immediately

#### Example Usage

```powershell
# Without quality score
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -AlertOnFailure

# With quality score (recommended)
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -AlertOnFailure -IncludeQualityScore
```

---

### CSV Log File

**Location:** `C:\Users\YourName\Desktop\AVD-Network-Monitor.csv`

**Open with:** Excel, Notepad, or any CSV viewer

**Key columns to watch:**

| Column | Good Value | Bad Value |
|--------|------------|-----------|
| **AvgRTT_ms** | < 50 | > 150 |
| **PacketLoss_%** | 0 | > 0 |
| **TotalErrors** | 0 (stable) | Increasing |
| **WiFiSignal** | > 70% | < 50% |
| **QualityScore*** | > 75 | < 60 |
| **QualityRating*** | Excellent/Good | Fair/Poor/Critical |
| **Notes** | OK | HIGH_LATENCY, PACKET_LOSS |

_*Only appears if using `-IncludeQualityScore` parameter_

### Traffic Simulation Output

```
╔════════════════════════════════════════════════════════════════╗
║         AVD User Traffic Simulation                          ║
╚════════════════════════════════════════════════════════════════╝

Workload Type: Mixed
Duration:      30 minutes

═══════════════════════════════════════════════════════════════
Iteration #1 - Time remaining: 29.5 minutes
═══════════════════════════════════════════════════════════════

[14:00:05] Simulating web browsing...
  └─ Fetching: https://www.microsoft.com
     Response: 200 - 156743 bytes
  ✓ Complete

[14:00:25] Simulating file operations...
  └─ Creating file 1 of 10...
  ✓ File operations complete
```

**This is normal** - just shows what activities are running

---

## Troubleshooting

### Problem: "Running scripts is disabled"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host"
```

---

### Problem: "Cannot resolve hostname"

**Check if FQDN is correct:**
```powershell
# Test DNS resolution
nslookup host.domain.com
```

**If DNS fails:**
- Verify the FQDN from Log Analytics
- Check if you need VPN connected
- Try using IP address instead

---

### Problem: Script starts but no CSV file

**Check permissions:**
```powershell
# Try writing to Desktop
"test" | Out-File "$env:USERPROFILE\Desktop\test.txt"
```

**If that fails, specify alternate location:**
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -LogPath "C:\Temp\avd.csv"
```

---

### Problem: TCP 3389 shows "Closed/Blocked"

**If testing against microsoft.com:**
- This is **normal** - microsoft.com doesn't have RDP open
- Use actual AVD session host FQDN instead

**If testing against actual AVD host:**
- Verify session host is running (check Azure Portal)
- Check NSG rules allow RDP from your IP
- Try from different network location
- May indicate firewall blocking

---

### Problem: High CPU/Memory from simulation

**Reduce workload intensity:**
```powershell
# Use Light workload instead
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Light

# Or increase check interval
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 60
```

---

### Problem: Script hangs on "Attempting TCP connect"

**This is normal** - Test-NetConnection has a timeout (about 20 seconds)

**Wait for it to complete** or reduce check frequency:
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 30
# Gives more time between checks
```

---

## Quick Reference Commands

### Basic Monitoring
```powershell
# Start monitoring
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com"

# With alerts
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -AlertOnFailure

# With connection quality score
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -IncludeQualityScore

# With both alerts and quality score
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -AlertOnFailure -IncludeQualityScore

# Custom interval (every 15 seconds)
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -IntervalSeconds 15

# Custom log location
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -LogPath "C:\Logs\test.csv"

# Stop monitoring
Press Ctrl+C
```

### Traffic Simulation (Inside AVD)
```powershell
# Light workload
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Light

# Medium workload
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Medium

# Heavy with video
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Heavy -IncludeVideo

# Mixed (default)
.\Simulate-AVDUserTraffic.ps1 -Duration 30

# Stop simulation
Press Ctrl+C
```

### Validation
```powershell
# Pre-flight check
.\Test-MonitoringScript.ps1

# Check PowerShell version
$PSVersionTable.PSVersion

# Test basic connectivity
Test-NetConnection -ComputerName your-host.domain.com -Port 3389
```

---

## Typical Test Workflow

### 1. Initial Setup (5 minutes)
```powershell
# Download scripts to C:\AVDMonitoring
cd C:\AVDMonitoring

# Unblock scripts
Get-ChildItem *.ps1 | Unblock-File

# Validate environment
.\Test-MonitoringScript.ps1
```

### 2. Get Session Host FQDN (2 minutes)
- Run Log Analytics query
- Copy the SessionHostName
- Example: `host.domain.com`

### 3. Quick Test (5 minutes)
```powershell
# Test against microsoft.com first
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "microsoft.com" -IntervalSeconds 10
# Let run 2-3 minutes
# Press Ctrl+C
# Verify CSV created on Desktop
```

### 4. Real Test - Monitoring Only (30+ minutes)
```powershell
# Start monitoring
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 30 -AlertOnFailure

# User works normally
# When issue occurs, note time and press Ctrl+C
# Review CSV file
```

### 5. Real Test - With Simulation (30 minutes)
```powershell
# Window 1 - On laptop
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 15 -AlertOnFailure

# Window 2 - Inside AVD session
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed -IncludeVideo

# Let both complete
# Review CSV file for correlation
```

---

## What to Look For in Results

### Healthy Connection
```csv
Timestamp,AvgRTT_ms,PacketLoss_%,TotalErrors,WiFiSignal,QualityScore,QualityRating,Notes
14:00:00,45,0,0,75%,92,Excellent,OK
14:00:30,48,0,0,74%,90,Excellent,OK
14:01:00,42,0,0,76%,94,Excellent,OK
```

### Problem Pattern - WiFi Degradation
```csv
14:10:00,52,0,0,68%,85,Good,OK
14:10:30,85,0,0,54%,68,Fair,OK
14:11:00,145,0,0,45%,42,Poor,HIGH_LATENCY(145ms),WEAK_WIFI_SIGNAL(45%)
14:11:30,198,2,0,42%,28,Critical,HIGH_LATENCY(198ms),PACKET_LOSS(2%),WEAK_WIFI_SIGNAL(42%)
14:12:00,N/A,100,0,N/A,0,Critical,PING_FAILED  ← DISCONNECT
```

**Notice:** Quality score drops from 85 (Good) to 28 (Critical) before disconnect

### Problem Pattern - Firewall Timeout
```csv
11:00:00,38,0,0,N/A,OK
11:30:00,40,0,0,N/A,OK
12:00:00,42,0,0,N/A,OK
12:30:00,38,0,0,N/A,TCP_3389_BLOCKED  ← Firewall dropped "idle" connection
12:31:00,40,0,0,N/A,OK  ← Reconnected
```

### Problem Pattern - Network Adapter Errors
```csv
09:00:00,45,0,0,N/A,OK
09:30:00,48,0,5,N/A,NEW_PACKET_ERRORS(+5)
10:00:00,52,0,18,N/A,NEW_PACKET_ERRORS(+13)
10:30:00,145,2,45,N/A,HIGH_LATENCY(145ms),PACKET_LOSS(2%),NEW_PACKET_ERRORS(+27)
```

---

## Next Steps After Testing

### If You Found Issues

1. **Document the pattern** from CSV
2. **Correlate with Azure Log Analytics** for same timeframe
3. **Apply appropriate fix:**
   - WiFi issues → Switch to wired or improve WiFi
   - Firewall timeout → Adjust UDP timeout settings
   - VPN issues → Exclude AVD traffic from VPN tunnel
   - Adapter errors → Update drivers, check hardware

### If No Issues Found

1. **Extend monitoring duration** (run for full workday)
2. **Test during problem hours** (if issues are time-specific)
3. **Increase simulation intensity** (use Heavy workload)
4. **Test different scenarios** (WiFi vs wired, VPN vs direct)

---

## Support Information

### Getting Help

If scripts don't work:
1. Run `.\Test-MonitoringScript.ps1` and share output
2. Check PowerShell version: `$PSVersionTable.PSVersion`
3. Verify cmdlets: `Get-Command Test-NetConnection`
4. Review error messages carefully

### File Locations

- **Scripts:** `C:\AVDMonitoring\*.ps1`
- **CSV Log:** `Desktop\AVD-Network-Monitor.csv`
- **Temp files:** `%TEMP%\AVDTest\` (created by traffic simulation)

### Additional Documentation

- **Complete guide:** AVD-Monitoring-Guide.md
- **Traffic simulation details:** Simulate-AVDUserTraffic-Guide.md
- **This file:** Quick-Start-Guide.md

---

## Checklist

Before you start, verify:

- [ ] Scripts downloaded to `C:\AVDMonitoring`
- [ ] Scripts unblocked: `Get-ChildItem *.ps1 | Unblock-File`
- [ ] Validation passed: `.\Test-MonitoringScript.ps1`
- [ ] Session host FQDN obtained from Log Analytics
- [ ] Execution policy set (if needed)
- [ ] PowerShell version 5.1 or higher

For monitoring only:
- [ ] Know the scenario: real user vs controlled test
- [ ] Know duration needed
- [ ] Have FQDN of session host

For both scripts:
- [ ] Monitor script ready on laptop
- [ ] Traffic script copied to AVD session
- [ ] Both unblocked in their respective locations

---

**You're ready to start monitoring!**

**Most common command to start:**
```powershell
# Basic monitoring
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 30 -AlertOnFailure

# Recommended: With quality score for easier trending
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 30 -AlertOnFailure -IncludeQualityScore
```

**Tip:** Use `-IncludeQualityScore` to get a single 0-100 metric that's easier to chart in Excel!

Good luck troubleshooting! 🚀
