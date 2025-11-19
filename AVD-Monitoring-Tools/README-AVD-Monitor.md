# AVD Network Connectivity Monitor - Usage Guide

## Purpose
This PowerShell script monitors client-side network connectivity to Azure Virtual Desktop session hosts to diagnose intermittent connection issues, particularly those causing `ShortpathTransportNetworkDrop` errors.

## Prerequisites

**Required:**
- Windows 10/11 or Windows Server
- PowerShell 5.1 or later (built into Windows)
- Administrator privileges recommended (but not required for basic functionality)

**Validated Cmdlets Used:**
- `Test-Connection` - Standard Windows cmdlet (available since PowerShell 3.0)
- `Test-NetConnection` - Available since PowerShell 4.0 (Windows 8.1/Server 2012 R2)
- `Get-NetAdapter` - Network cmdlet module (built-in)
- `Get-NetAdapterStatistics` - Network cmdlet module (built-in)

## Quick Start

### 1. Get Your Session Host FQDN
From your Log Analytics query results, grab the `SessionHostName` value:
```
Example: CONCDSYS-72cb.ad4.sfgov.org
```

### 2. Run the Script
Open PowerShell (doesn't need to be elevated) and run:

```powershell
# Navigate to where you saved the script
cd ~\Downloads

# Run with basic settings
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "CONCDSYS-72cb.ad4.sfgov.org"
```

### 3. Let It Run
- Leave the script running during normal work hours
- The user can continue working normally
- The PowerShell window will show real-time status
- All data is logged to CSV on the Desktop

### 4. Review Results
When a disconnection occurs:
1. Note the exact time
2. Stop the script (Ctrl+C)
3. Open the CSV file: `Desktop\AVD-Network-Monitor.csv`
4. Look for entries around the disconnection time
5. Check the "Notes" column for issues

## Command Line Options

### Basic Monitoring
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com"
```

### With Visual Alerts
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -AlertOnFailure
```

### Custom Check Interval (every 15 seconds)
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -IntervalSeconds 15
```

### Custom Log Location
```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -LogPath "C:\Logs\avd-monitor.csv"
```

### Full Example with All Options
```powershell
.\Monitor-AVDConnection.ps1 `
    -SessionHostFQDN "CONCDSYS-72cb.ad4.sfgov.org" `
    -IntervalSeconds 20 `
    -LogPath "C:\Temp\avd-network.csv" `
    -AlertOnFailure
```

## What the Script Monitors

| Metric | What It Tells You | Issue Indicator |
|--------|-------------------|-----------------|
| **Ping (ICMP)** | Basic connectivity & latency | Avg RTT >150ms, packet loss >0% |
| **Min/Max RTT** | Jitter (connection stability) | Difference >100ms indicates instability |
| **DNS Resolution** | DNS server responsiveness | >500ms is slow, "Failed" is critical |
| **TCP 3389** | Standard RDP port access | Must be "Open" for AVD to work |
| **Network Adapter** | Local NIC health | Packet errors indicate driver/hardware issues |
| **WiFi Signal** | Wireless strength (if applicable) | <50% signal is weak and problematic |

## Understanding the Results

### CSV Columns Explained

- **Timestamp**: When the check occurred
- **PingStatus**: Success/Failed
- **AvgRTT_ms**: Average round-trip time (lower is better)
- **MinRTT_ms/MaxRTT_ms**: Shows jitter when difference is large
- **PacketLoss_%**: Percentage of lost packets (should be 0%)
- **TCP3389**: RDP port status (must be "Open")
- **DNSResolution_ms**: Time to resolve hostname
- **NetworkAdapter**: Which NIC is active
- **AdapterStatus/LinkSpeed**: NIC health indicators
- **ReceivedErrors/SentErrors**: Cumulative packet errors
- **WiFiSignal**: Signal strength percentage (if on WiFi)
- **Notes**: Auto-flagged issues (KEY COLUMN!)

### Common Note Flags

| Flag | Meaning | Likely Cause |
|------|---------|--------------|
| `HIGH_LATENCY(XXXms)` | RTT >150ms | Network congestion, routing issues |
| `PACKET_LOSS(X%)` | Packets not reaching destination | Network instability, WiFi interference |
| `HIGH_JITTER(XXXms)` | Inconsistent latency | Network congestion, QoS issues |
| `NEW_PACKET_ERRORS(+X)` | NIC dropped packets | Driver issue, hardware problem |
| `WEAK_WIFI_SIGNAL(X%)` | Poor wireless signal | Distance from AP, interference |
| `DNS_RESOLUTION_FAILED` | Can't resolve hostname | DNS server down, network issue |
| `TCP_3389_BLOCKED` | RDP port not accessible | Firewall, routing, or host issue |
| `SLOW_DNS(XXXms)` | DNS taking too long | DNS server overload or network issue |

### Interpreting Patterns

**Pattern 1: Intermittent UDP Drops (Your Current Issue)**
```
Notes: HIGH_JITTER(120ms), PACKET_LOSS(2%), WEAK_WIFI_SIGNAL(45%)
```
**Analysis**: Network instability causing UDP (Shortpath) to fail. Likely WiFi-related.
**Action**: Test on wired connection, check WiFi channel/AP

**Pattern 2: Consistent High Latency**
```
AvgRTT_ms: 180-220, Notes: HIGH_LATENCY
```
**Analysis**: Routing or bandwidth issue, not intermittent
**Action**: Check ISP connection, run traceroute, verify QoS policies

**Pattern 3: Firewall Timeout**
```
Notes: OK, OK, OK, TCP_3389_BLOCKED, OK, OK
```
**Analysis**: Stateful firewall dropping "idle" connections
**Action**: Adjust firewall UDP/TCP timeout settings

**Pattern 4: Adapter Issues**
```
Notes: NEW_PACKET_ERRORS(+5), NEW_PACKET_ERRORS(+12)
```
**Analysis**: Network adapter dropping packets (driver/hardware)
**Action**: Update NIC drivers, check hardware, disable power management

## Correlating with AVD Disconnections

When a user reports a disconnection:

1. **Note the exact time** (e.g., "2025-11-13 14:23")
2. **Open the CSV in Excel**
3. **Filter/sort by Timestamp** to find that period
4. **Look at the 2-3 minutes before the disconnection**
5. **Check for warning signs:**
   - Increasing latency
   - Packet loss starting
   - New packet errors
   - WiFi signal dropping

Example:
```
14:20:15 - OK
14:21:30 - HIGH_LATENCY(165ms)
14:22:45 - HIGH_LATENCY(178ms), HIGH_JITTER(95ms)
14:23:10 - PACKET_LOSS(4%), HIGH_LATENCY(201ms)  ← Disconnection likely here
14:24:30 - OK  ← User reconnected
```

This pattern shows degrading network conditions leading to the drop.

## Troubleshooting the Script

### Script Won't Start
**Error**: "Execution policy"
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host"
```

### Can't Resolve Hostname
- Verify the FQDN is correct (check your Log Analytics results)
- Try using IP address instead if DNS is the problem
- Check if you're connected to the correct network

### No WiFi Signal Shown
- This is normal if on wired ethernet
- Script shows "N/A" when WiFi isn't detected

### Gaps in Logging
- Script only logs every X seconds (default 30)
- Very brief network blips might be missed
- Lower `IntervalSeconds` to 10-15 for finer granularity

## Known Limitations

1. **UDP Port 3390 Not Tested**: There's no reliable way to test UDP connectivity from PowerShell without sending actual UDP packets and waiting for responses. The script uses ping jitter and packet loss as proxy indicators for UDP health.

2. **Requires Active Session**: The script tests connectivity to the session host, but doesn't verify an active AVD session. It's for network-level troubleshooting.

3. **Windows Only**: This is a PowerShell script for Windows clients. Mac/Linux AVD clients would need different tools.

4. **No Root Cause**: The script identifies network issues but can't always determine the root cause (could be ISP, VPN, firewall, router, etc.)

## Next Steps After Monitoring

Once you've identified patterns in the logs:

### If WiFi-Related
- Test on wired ethernet
- Check WiFi channel congestion
- Move closer to access point
- Update WiFi drivers

### If Latency/Jitter
- Run traceroute to session host
- Check for VPN interference
- Verify QoS policies
- Test different times of day

### If Packet Errors
- Update network adapter drivers
- Check for hardware issues
- Disable adapter power management
- Try different NIC if available

### If Firewall-Related
- Check corporate firewall logs
- Review UDP timeout settings
- Verify port 3390 (UDP) is allowed
- Test from different network (home vs. office)

## Support

For issues with the script itself:
- Verify PowerShell version: `$PSVersionTable.PSVersion`
- Check cmdlet availability: `Get-Command Test-NetConnection`
- Run with `-Verbose` parameter for more details

For AVD connectivity issues:
- Review Azure Monitor AVD Insights
- Check session host health in Azure Portal
- Verify NSG rules allow ports 3389 (TCP) and 3390 (UDP)
- Review Application Event Logs on session host

## Example Success Case

```
Time: 09:15:30
Target: CONCDSYS-72cb.ad4.sfgov.org
  └─ DNS Resolution: 45.2 ms
  └─ Ping: SUCCESS | Avg: 32 ms | Min: 28 ms | Max: 41 ms | Loss: 0%
  └─ TCP 3389 (RDP): Open
  └─ Adapter: Ethernet | Status: Up | Speed: 1 Gbps
  └─ Packet Errors: Received=0, Sent=0, Total=0
  ✓ All connectivity checks passed
```

This is what you want to see - low latency, no packet loss, no errors.
