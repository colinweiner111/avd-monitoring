CONCDSYS-72cb.ad4.sfgov.org# Azure Virtual Desktop Network Monitoring Guide

## Overview

This guide provides tools and procedures for diagnosing intermittent Azure Virtual Desktop (AVD) connectivity issues, particularly `ShortpathTransportNetworkDrop` errors that indicate UDP-based RDP Shortpath failures.

**Problem:** Users experiencing intermittent AVD disconnections with errors like:
- `ShortpathTransportNetworkDrop` (Code 68)
- `ReverseConnectDnsLookupFailed` (Code 39)
- `GraphicsSubsystemFailed` (Code 4399)

**Solution:** Client-side network monitoring to identify root causes.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Scripts Included](#scripts-included)
3. [Installation](#installation)
4. [Basic Usage](#basic-usage)
5. [Testing Scenarios](#testing-scenarios)
6. [Analyzing Results](#analyzing-results)
7. [Troubleshooting](#troubleshooting)
8. [Advanced Usage](#advanced-usage)
9. [FAQ](#faq)

---

## Quick Start

### 5-Minute Setup

1. **Download the scripts** to your client machine
2. **Find your AVD session host FQDN** from Azure Log Analytics (WVDConnections table)
3. **Run the monitor:**

```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 30 -AlertOnFailure
```

4. **Use AVD normally** or run traffic simulation
5. **Review the CSV log** when issues occur

---

## Scripts Included

### 1. Monitor-AVDConnection.ps1 (Primary Tool)

**Purpose:** Continuous network monitoring from the client side

**What it monitors:**
- ICMP ping latency and packet loss
- TCP port 3389 (RDP) connectivity
- DNS resolution time
- Network adapter statistics and errors
- WiFi signal strength (if wireless)
- Jitter detection (latency variance)

**Output:** Real-time console display + CSV log file

### 2. Test-MonitoringScript.ps1

**Purpose:** Pre-flight validation before running the monitor

**What it checks:**
- PowerShell version compatibility
- Required cmdlets availability
- Network adapter detection
- Basic connectivity
- File write permissions

**Use when:** Setting up for the first time

### 3. Simulate-AVDUserTraffic.ps1

**Purpose:** Generate realistic user workload patterns for testing

**What it simulates:**
- Web browsing (HTTP/HTTPS traffic)
- File operations (create, read, copy, delete)
- CPU load (Office-like applications)
- Memory usage (large documents)
- Video streaming (high bandwidth)
- UI activity (window operations)

**Use when:** Testing in controlled conditions

### 4. Simulate-NetworkStress.ps1

**Purpose:** Create network stress conditions to test detection

**What it generates:**
- High bandwidth consumption
- Connection bursts
- DNS query floods
- Concurrent connections

**Use when:** Forcing issues to validate monitoring

### 5. Deploy-Test-VM.ps1 / Deploy-Test-VM.sh

**Purpose:** Quick Azure VM deployment for testing RDP connectivity

**Use when:** Need a test target with RDP enabled

---

## Installation

### Prerequisites

- **Windows 10/11** or **Windows Server 2016+**
- **PowerShell 5.1+** (built into Windows)
- **Administrator privileges** (recommended, not required)
- **Network connectivity** to AVD session hosts

### Setup Steps

1. **Download all scripts** to a folder (e.g., `C:\AVDMonitoring`)

2. **Unblock the scripts** (if downloaded from the internet):
   ```powershell
   Get-ChildItem -Path C:\AVDMonitoring\*.ps1 | Unblock-File
   ```

3. **Set execution policy** (if needed):
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Validate setup:**
   ```powershell
   cd C:\AVDMonitoring
   .\Test-MonitoringScript.ps1
   ```

---

## Basic Usage

### Scenario 1: Monitor Production AVD Environment

**Objective:** Track network conditions during normal user activity

**Steps:**

1. **Get your session host FQDN** from Log Analytics:
   ```kusto
   WVDConnections
   | where TimeGenerated > ago(7d)
   | where UserName == "affected-user@domain.com"
   | project SessionHostName
   | distinct SessionHostName
   ```

2. **Start monitoring:**
   ```powershell
   .\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 30 -AlertOnFailure
   ```

3. **Let it run** during work hours (or all day)

4. **When disconnection occurs:**
   - Note the exact time
   - Stop the script (Ctrl+C)
   - Open the CSV log on your Desktop

5. **Analyze the log** around the disconnection timestamp

### Scenario 2: Quick Validation Test

**Objective:** Verify the script works before deploying

**Steps:**

1. **Run pre-flight check:**
   ```powershell
   .\Test-MonitoringScript.ps1
   ```

2. **Test against any reachable host:**
   ```powershell
   .\Monitor-AVDConnection.ps1 -SessionHostFQDN "microsoft.com" -IntervalSeconds 10
   ```

3. **Let it run for 2-3 minutes**

4. **Verify CSV log created** on Desktop with data

5. **Stop and review** (Ctrl+C)

### Scenario 3: Controlled Testing with Traffic Simulation

**Objective:** Reproduce issues in a controlled environment

**Steps:**

1. **Window 1 - Start monitoring:**
   ```powershell
   .\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -IntervalSeconds 15 -AlertOnFailure
   ```

2. **Window 2 - Connect to AVD session and run traffic simulation:**
   ```powershell
   # Inside AVD session
   .\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed -IncludeVideo
   ```

3. **Monitor both windows** for issues

4. **Review logs** after completion

---

## Testing Scenarios

### Light Testing (15-30 minutes)

**Purpose:** Basic validation and baseline establishment

```powershell
# Window 1: Monitor
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 30

# Window 2: Light traffic
.\Simulate-AVDUserTraffic.ps1 -Duration 15 -WorkloadType Light
```

**Expected results:**
- Low latency (<50ms)
- No packet loss
- No errors in CSV

### Medium Testing (30-60 minutes)

**Purpose:** Realistic workload simulation

```powershell
# Window 1: Monitor with alerts
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 20 -AlertOnFailure

# Window 2: Medium traffic with video
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Medium -IncludeVideo
```

**Expected results:**
- Moderate latency (50-100ms)
- Possible slight jitter
- Should remain stable

### Heavy Testing (15-30 minutes)

**Purpose:** Stress testing to expose weaknesses

```powershell
# Window 1: Monitor frequently
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 15 -AlertOnFailure

# Window 2: Heavy workload
.\Simulate-AVDUserTraffic.ps1 -Duration 15 -WorkloadType Heavy -IncludeVideo

# Window 3 (Optional): Add network stress
.\Simulate-NetworkStress.ps1 -StressType All -Duration 10
```

**Expected results:**
- Higher latency (100-150ms)
- Possible packet loss under WiFi
- May expose UDP issues

### WiFi vs Wired Comparison

**Purpose:** Isolate WiFi as root cause

```powershell
# Test 1: On WiFi
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 20 -LogPath "Desktop\avd-wifi.csv" -AlertOnFailure
# Run for 30 minutes with normal usage

# Test 2: On Ethernet (switch connection)
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 20 -LogPath "Desktop\avd-wired.csv" -AlertOnFailure
# Run for 30 minutes with same usage patterns

# Compare the two CSV files
```

### VPN Testing

**Purpose:** Determine if VPN causes issues

```powershell
# Test 1: With VPN connected
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 20 -LogPath "Desktop\avd-vpn.csv" -AlertOnFailure

# Test 2: Without VPN (direct internet)
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 20 -LogPath "Desktop\avd-direct.csv" -AlertOnFailure

# Compare results
```

---

## Analyzing Results

### Understanding the CSV Log

**File location:** `C:\Users\YourName\Desktop\AVD-Network-Monitor.csv`

**Key columns:**

| Column | What It Means | Good Value | Bad Value |
|--------|---------------|------------|-----------|
| **AvgRTT_ms** | Average latency | <50ms | >150ms |
| **PacketLoss_%** | Lost packets | 0% | >0% |
| **TCP3389** | RDP port status | Open | Closed/Blocked |
| **TotalErrors** | NIC packet errors | 0 or stable | Increasing |
| **WiFiSignal** | Signal strength | >70% | <50% |
| **Notes** | Auto-detected issues | OK | Any flag |

### Common Issue Patterns

#### Pattern 1: High Latency Before Disconnect

```
13:45:00 - AvgRTT: 45ms, Notes: OK
13:46:30 - AvgRTT: 125ms, Notes: HIGH_LATENCY(125ms)
13:48:00 - AvgRTT: 187ms, Notes: HIGH_LATENCY(187ms), HIGH_JITTER(95ms)
13:49:15 - AvgRTT: 215ms, PacketLoss: 3%, Notes: HIGH_LATENCY(215ms), PACKET_LOSS(3%)
13:50:30 - [USER REPORTS DISCONNECT]
```

**Diagnosis:** Network congestion or bandwidth issue
**Action:** Check for competing traffic, ISP issues, or QoS policies

#### Pattern 2: WiFi Signal Degradation

```
10:15:00 - WiFiSignal: 85%, Notes: OK
10:30:00 - WiFiSignal: 72%, Notes: OK
10:45:00 - WiFiSignal: 48%, Notes: WEAK_WIFI_SIGNAL(48%)
11:00:00 - WiFiSignal: 42%, PacketLoss: 2%, Notes: WEAK_WIFI_SIGNAL(42%), PACKET_LOSS(2%)
11:15:00 - [USER REPORTS DISCONNECT]
```

**Diagnosis:** WiFi roaming, distance from AP, or interference
**Action:** Move closer to AP, switch to 5GHz band, or use wired connection

#### Pattern 3: Packet Errors Accumulating

```
09:00:00 - TotalErrors: 0, Notes: OK
09:30:00 - TotalErrors: 0, Notes: OK
10:00:00 - TotalErrors: 5, Notes: NEW_PACKET_ERRORS(+5)
10:30:00 - TotalErrors: 18, Notes: NEW_PACKET_ERRORS(+13)
11:00:00 - TotalErrors: 45, Notes: NEW_PACKET_ERRORS(+27)
```

**Diagnosis:** Network adapter driver or hardware issue
**Action:** Update NIC drivers, check hardware, disable power management

#### Pattern 4: DNS Resolution Failures

```
14:20:00 - DNSResolution_ms: 25, Notes: OK
14:21:30 - DNSResolution_ms: 450, Notes: SLOW_DNS(450ms)
14:23:00 - DNSResolution_ms: Failed, Notes: DNS_RESOLUTION_FAILED
14:24:30 - DNSResolution_ms: Failed, Notes: DNS_RESOLUTION_FAILED
```

**Diagnosis:** DNS server issue or network path problem
**Action:** Change DNS servers, check firewall rules, verify network connectivity

#### Pattern 5: Intermittent Spikes (Firewall Timeout)

```
11:00:00 - AvgRTT: 35ms, Notes: OK
11:30:00 - AvgRTT: 38ms, Notes: OK
12:00:00 - TCP3389: Closed/Blocked, Notes: TCP_3389_BLOCKED
12:01:30 - TCP3389: Open, Notes: OK
12:30:00 - AvgRTT: 42ms, Notes: OK
13:00:00 - TCP3389: Closed/Blocked, Notes: TCP_3389_BLOCKED
```

**Diagnosis:** Stateful firewall dropping "idle" UDP sessions
**Action:** Adjust firewall UDP timeout settings (increase to 300+ seconds)

### Correlation with Azure Logs

1. **Export Log Analytics data** for the same time period:
   ```kusto
   WVDConnections
   | where TimeGenerated between (datetime('2025-11-18 13:00') .. datetime('2025-11-18 14:00'))
   | where UserName == "affected.user@domain.com"
   | project TimeGenerated, State, Errors
   ```

2. **Compare timestamps** between CSV and Azure logs

3. **Look for matching patterns:**
   - Azure shows `ShortpathTransportNetworkDrop`
   - CSV shows high jitter or packet loss at same time
   - **Confirms:** Network instability causing UDP drops

### Using Excel for Analysis

1. **Open CSV in Excel**

2. **Create PivotTable** or charts:
   - Time series of AvgRTT_ms
   - Packet loss percentage over time
   - WiFi signal trends

3. **Filter by Notes column** to find issues:
   - Filter for "HIGH_LATENCY"
   - Filter for "PACKET_LOSS"
   - Filter for "WEAK_WIFI_SIGNAL"

4. **Identify patterns:**
   - Time of day correlations
   - Gradual degradation vs sudden failures
   - Cyclic issues (every 30 min = firewall timeout)

---

## Troubleshooting

### Script Won't Start

**Error:** "Cannot be loaded because running scripts is disabled"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host"
```

### Can't Resolve Session Host

**Error:** DNS resolution shows "Failed"

**Solutions:**
1. Verify FQDN is correct from Log Analytics
2. Try using IP address instead:
   ```powershell
   .\Monitor-AVDConnection.ps1 -SessionHostFQDN "10.20.30.40"
   ```
3. Check if connected to correct network (VPN if required)
4. Verify DNS server settings

### No CSV File Created

**Problem:** Script runs but no log file appears

**Solutions:**
1. Check Desktop permissions
2. Specify alternate location:
   ```powershell
   .\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -LogPath "C:\Temp\avd.csv"
   ```
3. Run PowerShell as Administrator

### TCP 3389 Always Shows "Closed/Blocked"

**If testing against non-RDP host (like microsoft.com):**
- This is **expected** - use actual AVD session host instead

**If testing against actual AVD host:**
- Check NSG rules allow RDP from your IP
- Verify session host is running
- Try from different network location
- May indicate firewall blocking

### Script Shows High Latency But AVD Seems Fine

**Possible causes:**
1. Testing against wrong host (verify FQDN)
2. Network path to test host differs from AVD path
3. ICMP (ping) being deprioritized by network
4. Background processes causing momentary spikes

**Validation:**
- Test from multiple client machines
- Compare with Azure Monitor metrics
- Run traceroute to identify hop with latency

### Memory/CPU Usage Too High

**If simulation scripts consume too much:**

**Adjust workload:**
```powershell
# Reduce intensity
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Light

# Increase intervals
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 60
```

---

## Advanced Usage

### Custom Monitoring Intervals

**Faster checks (every 10 seconds) for detailed capture:**
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 10
```

**Slower checks (every 60 seconds) for long-term trends:**
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 60
```

### Multiple Session Hosts

**Monitor multiple hosts simultaneously:**

```powershell
# Window 1
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host1.domain.com" -LogPath "Desktop\host1.csv"

# Window 2
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host2.domain.com" -LogPath "Desktop\host2.csv"

# Window 3
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host3.domain.com" -LogPath "Desktop\host3.csv"
```

### Automated Daily Monitoring

**Create scheduled task to run monitoring during business hours:**

```powershell
# Create script wrapper
$ScriptBlock = @'
cd C:\AVDMonitoring
$Date = Get-Date -Format "yyyy-MM-dd"
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -LogPath "C:\Logs\avd-$Date.csv" -IntervalSeconds 30
'@

$ScriptBlock | Out-File "C:\AVDMonitoring\Start-Monitoring.ps1"

# Create scheduled task (run as user, 8 AM - 5 PM daily)
$Trigger = New-ScheduledTaskTrigger -Daily -At 8AM
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\AVDMonitoring\Start-Monitoring.ps1"
Register-ScheduledTask -TaskName "AVD Network Monitoring" -Trigger $Trigger -Action $Action -User $env:USERNAME
```

### Integration with Azure Monitor

**Upload logs to Log Analytics for centralized analysis:**

```powershell
# After collecting CSV logs
$WorkspaceId = "your-workspace-id"
$SharedKey = "your-workspace-key"
$LogType = "AVDClientMonitoring"

# Parse CSV and upload (requires additional scripting)
# See Azure Monitor HTTP Data Collector API documentation
```

### Email Alerts on Issues

**Add email notification when problems detected:**

```powershell
# Modify Monitor-AVDConnection.ps1 to include:
if ($hasIssue) {
    Send-MailMessage -To "admin@company.com" `
        -From "avd-monitor@company.com" `
        -Subject "AVD Connectivity Issue Detected" `
        -Body "Issue detected at $timestamp: $notesString" `
        -SmtpServer "smtp.company.com"
}
```

---

## FAQ

### Q: Can this script fix connectivity issues?

**A:** No, this is a **diagnostic tool** only. It identifies when and what type of issues occur, but doesn't fix them. Use the data to identify root causes and apply appropriate fixes.

### Q: Does this require administrator privileges?

**A:** Not required for basic functionality, but recommended for full network adapter statistics and some diagnostic capabilities.

### Q: Will this impact AVD session performance?

**A:** Minimal impact. The monitor runs on the **client machine** (not in AVD session) and uses lightweight network tests (ping, DNS lookups). It should not affect session performance.

### Q: How long should I run the monitoring?

**A:** 
- **Minimum:** 30 minutes during typical work
- **Recommended:** Full workday (8+ hours)
- **Ideal:** Multiple days to capture patterns

### Q: Can I run this on Mac or Linux?

**A:** No, these are PowerShell scripts for Windows clients. Mac/Linux users would need different tools (ping, traceroute, tcpdump, etc.)

### Q: What if UDP port 3390 is blocked by our firewall?

**A:** This is likely causing your `ShortpathTransportNetworkDrop` errors. Work with network team to:
1. Allow UDP port 3390 outbound
2. Set firewall UDP timeout to 300+ seconds
3. Ensure stateful firewalls don't drop "idle" UDP sessions

### Q: The script says "UDP 3390: Not testable from client" - why?

**A:** UDP port testing requires sending actual UDP packets and waiting for responses, which isn't reliably possible with standard PowerShell cmdlets. The script uses ping jitter and packet loss as proxy indicators for UDP health.

### Q: Can this detect if my VPN is causing issues?

**A:** Yes, run the monitor with VPN connected and disconnected, then compare the CSV logs. Look for differences in latency, packet loss, and connection stability.

### Q: What's a "good" latency for AVD?

**A:**
- **Excellent:** <30ms
- **Good:** 30-100ms
- **Acceptable:** 100-150ms
- **Poor:** 150-200ms
- **Unusable:** >200ms

### Q: How do I stop the monitoring script?

**A:** Press **Ctrl+C** in the PowerShell window. The CSV log will be saved with all data collected up to that point.

### Q: Can I modify the scripts?

**A:** Yes, they're open source. Common modifications:
- Add custom tests
- Change alert thresholds
- Integrate with monitoring systems
- Add email notifications

### Q: What causes ShortpathTransportNetworkDrop errors?

**A:** Common causes:
1. **Firewall UDP timeout** (most common) - firewall drops UDP after 30-120s
2. **WiFi issues** - signal degradation, roaming, interference
3. **VPN blocking UDP** - VPN clients often block or poorly handle UDP
4. **ISP CGNAT** - Carrier-grade NAT with aggressive UDP timeouts
5. **Network congestion** - High packet loss affecting UDP more than TCP

### Q: Should I disable RDP Shortpath?

**A:** Only as a **temporary workaround**. Shortpath (UDP) provides better performance than TCP fallback. Better to fix the underlying network issue. To disable:

```powershell
# On client machine
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services\Client" /v fClientDisableUDP /t REG_DWORD /d 1 /f
```

### Q: How much data does the monitoring generate?

**A:** Very minimal:
- CSV file: ~1KB per hour (~8KB per day)
- Network traffic: ~1MB per hour (mostly ping packets)

### Q: Can I run this 24/7?

**A:** Yes, but typically not needed. Focus on:
- Business hours when users are active
- Times when issues are reported
- Comparison testing (WiFi vs wired, VPN vs direct)

---

## Command Reference

### Monitor-AVDConnection.ps1

```powershell
.\Monitor-AVDConnection.ps1 
    -SessionHostFQDN <string>      # Required: FQDN or IP of AVD session host
    -IntervalSeconds <int>         # Optional: Check frequency (default: 30)
    -LogPath <string>              # Optional: CSV log location (default: Desktop)
    -AlertOnFailure                # Optional: Show prominent alerts on issues
```

**Examples:**

```powershell
# Basic usage
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com"

# With alerts and frequent checks
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 15 -AlertOnFailure

# Custom log location
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -LogPath "C:\Logs\avd-monitor.csv"
```

### Test-MonitoringScript.ps1

```powershell
.\Test-MonitoringScript.ps1
```

No parameters needed. Validates environment and shows pre-flight check results.

### Simulate-AVDUserTraffic.ps1

```powershell
.\Simulate-AVDUserTraffic.ps1 
    -Duration <int>               # Optional: Run time in minutes (default: 30)
    -WorkloadType <string>        # Optional: Light|Medium|Heavy|Mixed (default: Mixed)
    -IncludeVideo                 # Optional: Add video streaming simulation
```

**Examples:**

```powershell
# Light workload for 15 minutes
.\Simulate-AVDUserTraffic.ps1 -Duration 15 -WorkloadType Light

# Heavy workload with video
.\Simulate-AVDUserTraffic.ps1 -Duration 20 -WorkloadType Heavy -IncludeVideo

# Mixed workload (default)
.\Simulate-AVDUserTraffic.ps1 -Duration 30
```

### Simulate-NetworkStress.ps1

```powershell
.\Simulate-NetworkStress.ps1 
    -StressType <string>          # Optional: Bandwidth|Connections|DNS|Burst|All (default: All)
    -Duration <int>               # Optional: Run time in minutes (default: 10)
```

**Examples:**

```powershell
# All stress types
.\Simulate-NetworkStress.ps1 -StressType All -Duration 10

# Bandwidth stress only
.\Simulate-NetworkStress.ps1 -StressType Bandwidth -Duration 15
```

---

## Additional Resources

### Microsoft Documentation

- [RDP Shortpath Overview](https://learn.microsoft.com/azure/virtual-desktop/rdp-shortpath)
- [AVD Network Connectivity](https://learn.microsoft.com/azure/virtual-desktop/network-connectivity)
- [Troubleshooting AVD Connections](https://learn.microsoft.com/azure/virtual-desktop/troubleshoot-client-connection)

### Log Analytics Queries

**Find ShortpathTransportNetworkDrop errors:**
```kusto
WVDConnections
| where TimeGenerated > ago(7d)
| where Errors contains "ShortpathTransportNetworkDrop"
| project TimeGenerated, UserName, SessionHostName, ClientIPAddress, Errors
| order by TimeGenerated desc
```

**Connection success rate by user:**
```kusto
WVDConnections
| where TimeGenerated > ago(7d)
| summarize Total=count(), Failed=countif(State=="Failed") by UserName
| extend SuccessRate = round((Total-Failed)*100.0/Total, 2)
| order by SuccessRate asc
```

### Network Requirements

**Ports required for AVD:**
- TCP 443 (HTTPS) - Control plane
- TCP 3389 (RDP) - Fallback data plane
- UDP 3390 (RDP Shortpath) - Preferred data plane

**Bandwidth recommendations:**
- Light usage: 1.5 Mbps
- Office productivity: 3-4 Mbps
- Power users / video: 5-10 Mbps

---

## Support and Contributing

### Getting Help

If you encounter issues with these scripts:

1. Run `Test-MonitoringScript.ps1` to validate environment
2. Check PowerShell version: `$PSVersionTable.PSVersion`
3. Verify cmdlet availability: `Get-Command Test-NetConnection`
4. Review error messages carefully
5. Check execution policy: `Get-ExecutionPolicy`

### Feedback

For script improvements or issues:
- Document the specific error or unexpected behavior
- Include PowerShell version and Windows version
- Provide sample output or error messages
- Describe expected vs actual behavior

---

## Version History

**v1.0** (2025-11-18)
- Initial release
- Basic network monitoring
- Traffic simulation
- Stress testing tools
- Pre-flight validation

---

## License

These scripts are provided as-is for diagnostic purposes. Use at your own risk. Always test in non-production environments first.

---

## Quick Reference Card

### Common Commands

```powershell
# Validate setup
.\Test-MonitoringScript.ps1

# Start monitoring
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host" -IntervalSeconds 30 -AlertOnFailure

# Simulate user traffic (in AVD session)
.\Simulate-AVDUserTraffic.ps1 -Duration 20 -WorkloadType Mixed -IncludeVideo

# Stress test network
.\Simulate-NetworkStress.ps1 -StressType All -Duration 10

# Stop monitoring
Press Ctrl+C
```

### Key Files

- **Monitor CSV:** `Desktop\AVD-Network-Monitor.csv`
- **Scripts:** `C:\AVDMonitoring\*.ps1`

### Key Metrics

- **RTT:** <50ms good, >150ms poor
- **Packet Loss:** 0% only
- **WiFi Signal:** >70% good, <50% poor
- **Jitter:** <50ms good, >100ms poor

---

**End of Guide**
