# Simulate-AVDUserTraffic.ps1 - User Guide

## Overview

**Purpose:** Simulates realistic Azure Virtual Desktop user workload patterns to test network monitoring and reproduce connectivity issues in a controlled environment.

**Use Case:** When you need to generate predictable, repeatable user activity patterns to:
- Test network monitoring capabilities
- Reproduce intermittent connectivity issues
- Validate AVD performance under load
- Create baseline metrics for comparison

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [What It Simulates](#what-it-simulates)
3. [Parameters](#parameters)
4. [Usage Examples](#usage-examples)
5. [Workload Types](#workload-types)
6. [Understanding the Output](#understanding-the-output)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Basic Usage

```powershell
# Run inside an active AVD session
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed
```

This will simulate 30 minutes of mixed user activity including web browsing, file operations, CPU load, and memory usage.

### Typical Testing Scenario

**Terminal 1 - On client machine (monitoring):**
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -IntervalSeconds 20 -AlertOnFailure
```

**Terminal 2 - Inside AVD session (traffic generation):**
```powershell
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed -IncludeVideo
```

---

## What It Simulates

### 1. Web Browsing
**What it does:**
- Fetches pages from major websites (Microsoft, Bing, Azure, Office)
- Generates HTTP/HTTPS traffic
- Simulates typical browser network patterns

**Network impact:**
- ~5-10 MB per iteration
- Multiple concurrent connections
- Mix of small and large responses

### 2. File Operations
**What it does:**
- Creates test files (~10KB each)
- Reads files into memory
- Copies files to new locations
- Deletes temporary files

**Disk/Network impact:**
- Generates I/O operations
- Tests file system performance
- Simulates document editing

### 3. CPU Load (Office-like Applications)
**What it does:**
- Spawns multiple background jobs
- Performs computational tasks
- Simulates multi-threaded applications

**System impact:**
- ~40-60% CPU usage during load
- Tests responsiveness under load
- Simulates Excel calculations, PowerPoint rendering

### 4. Memory Usage
**What it does:**
- Allocates 100MB of memory
- Fills with random data
- Holds for 10 seconds
- Releases and garbage collects

**System impact:**
- Tests memory pressure
- Simulates large documents/spreadsheets
- Validates memory management

### 5. Video Streaming (Optional)
**What it does:**
- Downloads large files (10MB+)
- Tests sustained bandwidth
- Measures download speed

**Network impact:**
- High bandwidth consumption
- Sustained traffic flow
- Tests UDP Shortpath under load

### 6. UI Activity
**What it does:**
- Opens and closes Notepad
- Simulates window operations
- Generates graphics rendering traffic

**System impact:**
- Tests RemoteFX/graphics subsystem
- Simulates typical user interactions
- Validates UI responsiveness

---

## Parameters

### -Duration

**Type:** Integer  
**Default:** 30  
**Range:** 1-unlimited (practical: 10-120 minutes)

**Description:** How long the simulation runs in minutes.

**Examples:**
```powershell
# Short test (10 minutes)
.\Simulate-AVDUserTraffic.ps1 -Duration 10

# Long test (2 hours)
.\Simulate-AVDUserTraffic.ps1 -Duration 120
```

### -WorkloadType

**Type:** String  
**Default:** Mixed  
**Options:** Light, Medium, Heavy, Mixed

**Description:** Intensity and type of simulated workload.

| Type | Activities | Frequency | Use Case |
|------|------------|-----------|----------|
| **Light** | Web browsing only | Every 30s | Baseline testing, low-impact validation |
| **Medium** | Web + files | Every 20s | Typical office worker simulation |
| **Heavy** | All activities | Every 10s | Power user, stress testing |
| **Mixed** | Random selection | 15-45s | Realistic varied usage patterns |

**Examples:**
```powershell
# Light user simulation
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Light

# Heavy user with all activities
.\Simulate-AVDUserTraffic.ps1 -Duration 20 -WorkloadType Heavy
```

### -IncludeVideo

**Type:** Switch  
**Default:** Not included  

**Description:** Adds video streaming simulation (10MB downloads).

**When to use:**
- Testing high bandwidth scenarios
- Validating video conferencing performance
- Stress testing UDP Shortpath

**Warning:** Generates significant bandwidth usage (~10MB per iteration).

**Examples:**
```powershell
# With video simulation
.\Simulate-AVDUserTraffic.ps1 -Duration 20 -WorkloadType Medium -IncludeVideo

# Without video (default)
.\Simulate-AVDUserTraffic.ps1 -Duration 20 -WorkloadType Medium
```

---

## Usage Examples

### Example 1: Quick Validation Test

**Objective:** Verify monitoring script detects activity

```powershell
.\Simulate-AVDUserTraffic.ps1 -Duration 10 -WorkloadType Light
```

**Expected duration:** 10 minutes  
**Activities:** Web browsing every 30 seconds  
**System impact:** Minimal  
**Use case:** Basic validation that traffic generation works

---

### Example 2: Typical Office Worker

**Objective:** Simulate realistic daily usage

```powershell
.\Simulate-AVDUserTraffic.ps1 -Duration 60 -WorkloadType Medium
```

**Expected duration:** 1 hour  
**Activities:** Web browsing + file operations  
**System impact:** Moderate  
**Use case:** Baseline performance testing

---

### Example 3: Power User with Video

**Objective:** High-load scenario with multimedia

```powershell
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Heavy -IncludeVideo
```

**Expected duration:** 30 minutes  
**Activities:** All activities including video streaming  
**System impact:** High CPU, memory, network, disk  
**Use case:** Stress testing, capacity planning

---

### Example 4: Reproduce Intermittent Issues

**Objective:** Run during problem hours to correlate

```powershell
# Start at 2 PM, run until 5 PM (when issues typically occur)
.\Simulate-AVDUserTraffic.ps1 -Duration 180 -WorkloadType Mixed -IncludeVideo
```

**Expected duration:** 3 hours  
**Activities:** Varied, unpredictable pattern  
**System impact:** Variable  
**Use case:** Long-term monitoring during peak hours

---

### Example 5: WiFi vs Wired Comparison

**Test 1 - On WiFi:**
```powershell
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Heavy -IncludeVideo
# Note results from monitoring
```

**Test 2 - On Wired:**
```powershell
# Disconnect WiFi, connect Ethernet
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Heavy -IncludeVideo
# Compare with WiFi results
```

---

## Workload Types

### Light Workload

**Profile:**
- Web browsing only (2-3 sites per cycle)
- 30-second pauses between activities
- Minimal system impact

**Simulates:**
- Occasional web research
- Reading documentation
- Light email checking

**Resource usage:**
- CPU: 5-10%
- Memory: Minimal
- Network: ~2-5 MB/minute
- Disk: None

**When to use:**
- Initial validation
- Baseline establishment
- Overnight monitoring

---

### Medium Workload

**Profile:**
- Web browsing (3-5 sites)
- File operations (create, read, copy)
- 20-second pauses

**Simulates:**
- Typical office worker
- Document editing
- Web-based applications
- File sharing

**Resource usage:**
- CPU: 15-30%
- Memory: Moderate
- Network: ~5-10 MB/minute
- Disk: Moderate I/O

**When to use:**
- Realistic testing
- Performance baselines
- Standard validation

---

### Heavy Workload

**Profile:**
- All activities concurrently
- Web browsing (5+ sites)
- File operations
- CPU load (15-20 seconds)
- Memory pressure
- Optional video streaming
- 10-second pauses

**Simulates:**
- Power users
- Developers
- Data analysts
- Multi-tasking users

**Resource usage:**
- CPU: 40-70%
- Memory: High (100MB+ allocations)
- Network: ~10-20 MB/minute (more with video)
- Disk: Heavy I/O

**When to use:**
- Stress testing
- Capacity planning
- Issue reproduction
- Maximum load scenarios

---

### Mixed Workload (Default)

**Profile:**
- Randomly selects activities
- Variable pauses (15-45 seconds)
- Unpredictable pattern

**Simulates:**
- Real-world varied usage
- Different tasks throughout day
- Natural user behavior

**Resource usage:**
- CPU: 10-50% (variable)
- Memory: Variable
- Network: 5-15 MB/minute (variable)
- Disk: Variable I/O

**When to use:**
- Most realistic testing
- Long-term monitoring
- Pattern analysis
- General validation

---

## Understanding the Output

### Console Output Example

```
╔════════════════════════════════════════════════════════════════╗
║         AVD User Traffic Simulation                          ║
╚════════════════════════════════════════════════════════════════╝

Workload Type: Mixed
Duration:      30 minutes
End Time:      14:30:00

This script will simulate typical user activities...
Press Ctrl+C to stop early

─────────────────────────────────────────────────────────────────

Starting simulation at 14:00:00...

═══════════════════════════════════════════════════════════════
Iteration #1 - Time remaining: 29.5 minutes
═══════════════════════════════════════════════════════════════

[14:00:05] Simulating web browsing...
  └─ Fetching: https://www.microsoft.com
     Response: 200 - 156743 bytes
  └─ Fetching: https://docs.microsoft.com
     Response: 200 - 89234 bytes
  └─ Fetching: https://azure.microsoft.com
     Response: 200 - 234561 bytes

[14:00:25] Simulating file operations...
  └─ Creating file 1 of 10...
  └─ Creating file 2 of 10...
  [...]
  └─ Reading files...
  └─ Copying files...
  └─ Cleaning up...
  ✓ File operations complete

[14:00:45] Simulating CPU load (Office-like)...
  └─ Running CPU load for 15 seconds...
  ✓ CPU load complete

═══════════════════════════════════════════════════════════════
Iteration #2 - Time remaining: 27.8 minutes
═══════════════════════════════════════════════════════════════
[...]
```

### Output Sections

**Header:**
- Confirms workload type and duration
- Shows expected end time
- Provides control instructions

**Iteration Block:**
- Shows current iteration number
- Displays remaining time
- Separates activities visually

**Activity Details:**
- Timestamp for each activity
- Specific actions being performed
- Success/failure indicators
- Completion confirmations

### Success Indicators

| Symbol | Meaning |
|--------|---------|
| ✓ | Activity completed successfully |
| └─ | Sub-activity or detail |
| Response: 200 | Successful HTTP request |
| [Timestamp] | When activity occurred |

### Warning Indicators

| Message | Meaning |
|---------|---------|
| "Failed to reach..." | Network connectivity issue |
| "Video simulation failed" | Bandwidth or network issue |
| Yellow text | Non-critical warning |

---

## Best Practices

### 1. Run Inside AVD Session

⚠️ **Important:** This script must run **inside** an active AVD session, not on the client machine.

**Correct:**
```
Client Machine → Connect to AVD → Open PowerShell in AVD → Run script
```

**Incorrect:**
```
Client Machine → Open local PowerShell → Run script ✗
```

### 2. Monitor Simultaneously

Always run the monitoring script on the client while traffic simulates in AVD:

**Client Machine:**
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host" -IntervalSeconds 20 -AlertOnFailure
```

**Inside AVD Session:**
```powershell
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed
```

### 3. Match Duration to Problem Window

If issues occur at specific times:

```powershell
# Problems happen 2-5 PM? Start at 1:45 PM:
.\Simulate-AVDUserTraffic.ps1 -Duration 195  # 3 hours 15 minutes
```

### 4. Start with Light, Increase Gradually

```powershell
# Day 1: Baseline
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Light

# Day 2: Normal load
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Medium

# Day 3: Stress test
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Heavy -IncludeVideo
```

### 5. Compare WiFi vs Wired

Always test both if WiFi is involved:

```powershell
# WiFi test - save results
.\Monitor-AVDConnection.ps1 -LogPath "Desktop\wifi-test.csv"
# Run traffic simulation

# Wired test - save to different file
.\Monitor-AVDConnection.ps1 -LogPath "Desktop\wired-test.csv"
# Run same traffic simulation
# Compare CSV files
```

### 6. Allow Warmup Time

Give the session 2-3 minutes to stabilize before starting:

```powershell
# Connect to AVD
# Wait 2-3 minutes
# Then start simulation
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed
```

### 7. Document Everything

Create a test log:

```
Test Date: 2025-11-18
Start Time: 14:00
Duration: 30 minutes
Workload: Heavy with Video
Network: WiFi (signal 68%)
Issues: Disconnected at 14:23
Monitoring CSV: avd-monitor-20251118.csv
Notes: High jitter observed before disconnect
```

### 8. Stop Cleanly

Use Ctrl+C to stop, don't close the window:

```powershell
# Press Ctrl+C
# Wait for cleanup to complete
# Review final statistics
```

---

## Troubleshooting

### Script Won't Start

**Error:** "Running scripts is disabled"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed
```

---

### Web Browsing Fails

**Symptom:** All web requests fail

**Possible causes:**
1. No internet connectivity in AVD session
2. Proxy settings required
3. Firewall blocking outbound HTTPS

**Solution:**
```powershell
# Test basic connectivity
Test-NetConnection -ComputerName www.microsoft.com -Port 443

# If proxy required, set:
$env:HTTPS_PROXY = "http://proxy.company.com:8080"
```

---

### High CPU/Memory Usage

**Symptom:** AVD session becomes slow or unresponsive

**Solution:**
```powershell
# Reduce workload intensity
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Light

# Or increase intervals by editing the script:
# Change "Start-Sleep -Seconds 10" to "Start-Sleep -Seconds 30"
```

---

### Notepad Windows Stay Open

**Symptom:** UI activity leaves Notepad windows open

**Solution:**
```powershell
# Manually close them or kill all Notepad processes:
Get-Process notepad -ErrorAction SilentlyContinue | Stop-Process -Force
```

---

### Script Stops Unexpectedly

**Symptom:** Script exits before duration completes

**Possible causes:**
1. AVD session disconnected
2. Network failure
3. PowerShell error

**Solution:**
- Check AVD session is still connected
- Review error messages
- Check monitoring CSV for disconnect time
- Restart with shorter duration to isolate issue

---

### Video Simulation Fails

**Error:** "Video simulation failed (network issue?)"

**Possible causes:**
1. Bandwidth limitations
2. Firewall blocking downloads
3. Cloudflare URL inaccessible

**Solution:**
```powershell
# Test URL manually:
Invoke-WebRequest -Uri "https://speed.cloudflare.com/__down?bytes=10000000" -OutFile "test.tmp"

# Or run without video:
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Heavy
# (Remove -IncludeVideo flag)
```

---

## Integration with Monitoring

### Correlation Workflow

1. **Start monitoring on client:**
   ```powershell
   .\Monitor-AVDConnection.ps1 -SessionHostFQDN "host" -IntervalSeconds 15 -AlertOnFailure
   ```

2. **Note start time** (e.g., 14:00:00)

3. **Start traffic in AVD session:**
   ```powershell
   .\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Heavy -IncludeVideo
   ```

4. **Watch for alerts** in monitoring window

5. **When simulation completes** or issues occur:
   - Note exact time
   - Stop monitoring (Ctrl+C)
   - Open CSV log

6. **Analyze correlation:**
   - Find simulation start time in CSV
   - Look for changes during heavy activities
   - Identify patterns leading to issues

### Expected Patterns

**Normal behavior:**
- Latency stable or slight increases during heavy load
- No packet loss
- Network adapter errors remain at 0
- WiFi signal stable (if wireless)

**Problem indicators:**
- Latency spikes during CPU/memory load
- Packet loss during video simulation
- WiFi signal drops during file operations
- New adapter errors during high bandwidth

---

## Advanced Usage

### Custom Workload Scripting

Modify the script to add custom activities:

```powershell
# Add your own function
function Invoke-CustomActivity {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Running custom activity..." -ForegroundColor Cyan
    # Your custom code here
    Write-Host "  ✓ Custom activity complete" -ForegroundColor Green
}

# Add to the Mixed workload activities array:
$Activities = @(
    { Invoke-WebBrowsing -Count 3 },
    { Invoke-FileOperations },
    { Invoke-CPULoad -Seconds 15 },
    { Invoke-MemoryLoad },
    { Invoke-CustomActivity }  # Your addition
)
```

### Scheduled Testing

Create a scheduled task to run daily:

```powershell
# Create wrapper script
$Script = @'
cd C:\AVDMonitoring
$Date = Get-Date -Format "yyyy-MM-dd-HHmm"
Start-Transcript -Path "C:\Logs\traffic-$Date.log"
.\Simulate-AVDUserTraffic.ps1 -Duration 60 -WorkloadType Medium -IncludeVideo
Stop-Transcript
'@

$Script | Out-File "C:\AVDMonitoring\Run-DailyTest.ps1"

# Schedule for 2 PM daily
$Trigger = New-ScheduledTaskTrigger -Daily -At 2PM
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\AVDMonitoring\Run-DailyTest.ps1"
Register-ScheduledTask -TaskName "AVD Traffic Test" -Trigger $Trigger -Action $Action
```

### Multiple Simultaneous Sessions

Test multiple users:

```powershell
# Session 1
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Light

# Session 2 (different AVD session)
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Heavy

# Session 3 (different AVD session)
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed -IncludeVideo
```

---

## Performance Impact

### Light Workload
- **CPU:** 5-10%
- **Memory:** ~50MB
- **Network:** 2-5 MB/minute
- **Disk:** Minimal
- **Impact:** Negligible, can run all day

### Medium Workload
- **CPU:** 15-30%
- **Memory:** ~150MB
- **Network:** 5-10 MB/minute
- **Disk:** Moderate (file operations)
- **Impact:** Noticeable but not disruptive

### Heavy Workload
- **CPU:** 40-70%
- **Memory:** ~200-300MB
- **Network:** 10-20 MB/minute
- **Disk:** Heavy (continuous operations)
- **Impact:** Significant, affects session responsiveness

### With Video
- **Additional Network:** +10-15 MB/minute
- **Total Bandwidth:** Can exceed 30 MB/minute
- **Impact:** May consume significant bandwidth, test carefully

---

## Use Cases Summary

| Scenario | Workload | Duration | Video | Purpose |
|----------|----------|----------|-------|---------|
| Quick validation | Light | 10 min | No | Verify scripts work |
| Baseline metrics | Medium | 30-60 min | No | Establish normal performance |
| Stress test | Heavy | 20-30 min | Yes | Find breaking points |
| Issue reproduction | Mixed | Hours | Maybe | Capture intermittent problems |
| WiFi comparison | Heavy | 30 min | Yes | Compare wireless vs wired |
| Daily monitoring | Mixed | 60-120 min | No | Ongoing validation |

---

## Command Quick Reference

```powershell
# Basic test
.\Simulate-AVDUserTraffic.ps1

# Quick validation (10 minutes, light)
.\Simulate-AVDUserTraffic.ps1 -Duration 10 -WorkloadType Light

# Typical user (30 minutes, medium)
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Medium

# Power user (30 minutes, heavy with video)
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Heavy -IncludeVideo

# Long-term test (2 hours, mixed)
.\Simulate-AVDUserTraffic.ps1 -Duration 120 -WorkloadType Mixed

# Stress test (15 minutes, everything)
.\Simulate-AVDUserTraffic.ps1 -Duration 15 -WorkloadType Heavy -IncludeVideo

# Stop at any time
Press Ctrl+C
```

---

## Summary

**Simulate-AVDUserTraffic.ps1** generates realistic user workload patterns inside AVD sessions to:
- Test network monitoring capabilities
- Reproduce intermittent issues in controlled conditions
- Establish performance baselines
- Validate capacity and performance

**Key points:**
- ✅ Run **inside** AVD session, not on client
- ✅ Monitor simultaneously from client machine
- ✅ Start with Light, increase to Heavy
- ✅ Match duration to your problem window
- ✅ Document everything for correlation

**Most common usage:**
```powershell
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed -IncludeVideo
```

For complete setup and troubleshooting workflows, see **AVD-Monitoring-Guide.md**.

---

**Version:** 1.0  
**Last Updated:** 2025-11-18  
**For use with:** Monitor-AVDConnection.ps1
