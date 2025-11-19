# AVD Network Monitoring - Quick Start Guide

## Overview

This guide covers everything you need to get the AVD network monitoring scripts up and running quickly.

**Time to setup:** 5-10 minutes  
**Scripts included:** 
- Monitor-AVDConnection.ps1 (client-side monitoring)
- Simulate-AVDUserTraffic.ps1 (workload simulation)
- Test-MonitoringScript.ps1 (validation)

> ⚠️ **PowerShell requirement:**  
> These scripts are tested and supported on **PowerShell 7.0 or higher** (`pwsh`).  
> **Windows PowerShell 5.1 is not supported** and may throw parsing/encoding errors.  
>  
> 👉 **Download PowerShell 7 here:**  
> https://github.com/PowerShell/PowerShell/releases/latest

---

## Prerequisites Check

### System Requirements

| Requirement | Minimum | How to Check |
|-------------|---------|--------------|
| **Operating System** | Windows 10/11 or Windows Server 2016+ | `systeminfo \| findstr /B /C:"OS Name"` |
| **PowerShell Version** | **PowerShell 7.0 or higher** | `$PSVersionTable.PSVersion` |
| **Network Connectivity** | Internet access | `Test-NetConnection 8.8.8.8` |
| **Disk Space** | 50 MB free | Check Desktop or C:\ drive |
| **Permissions** | Standard user (Admin recommended) | Run PowerShell normally |

> 💡 On Windows, launch PowerShell 7 using:  
> ```powershell
> pwsh
> ```

### Quick Pre-Flight Check

Run this command to validate your environment:

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Expected:
# Major  Minor  Build  Revision
# 7      X      XXXXX  XXXX
```

If you see **Major = 5**, install PowerShell 7 from the link above.

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

```powershell
cd C:\AVDMonitoring
Get-ChildItem -Path . -Filter *.ps1 | Unblock-File
```

### Step 3: Set Execution Policy (If Needed)

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Step 4: Validate Setup

Run the validation script in **PowerShell 7**:

```powershell
.\Test-MonitoringScript.ps1
```

---

## Getting Your Session Host FQDN

### Option 1: From Azure Log Analytics

```kusto
WVDConnections
| where TimeGenerated > ago(7d)
| distinct SessionHostName
```

### Option 2: From Azure Portal

Virtual Desktop → Host Pool → Session Hosts

---

## Running the Scripts

### Scenario 1: Monitor Real User

```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 30 -AlertOnFailure -IncludeQualityScore
```

### Scenario 2: Controlled Testing

```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host" -IntervalSeconds 15 -AlertOnFailure
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed -IncludeVideo
```

### Scenario 3: Quick Validation Test

```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "microsoft.com" -IntervalSeconds 10
```

---

## Troubleshooting

### Script Fails on PowerShell 5.1

Errors such as:

- `Unexpected token '}'`
- `Missing closing ')'`
- `String terminator missing`

**Cause:** PowerShell 5.1 cannot parse modern UTF-8 scripts.  
**Fix:** Install PowerShell 7 → https://github.com/PowerShell/PowerShell/releases/latest

### Hostname Not Resolved

```powershell
nslookup host.domain.com
```

### No CSV Created

Try:

```powershell
"test" | Out-File "$env:USERPROFILE\Desktop\test.txt"
```

---

## Quick Reference

### Monitor

```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com"
```

### Simulation

```powershell
.\Simulate-AVDUserTraffic.ps1 -Duration 30
```

### Validate

```powershell
.\Test-MonitoringScript.ps1
```

---

## Checklist

- [ ] Running **PowerShell 7+**
- [ ] Scripts unblocked
- [ ] FQDN identified
- [ ] Execution policy set
- [ ] Monitoring scenario selected

---

## You're ready to start!

```powershell
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "host.domain.com" -IntervalSeconds 30 -AlertOnFailure -IncludeQualityScore
```

Good luck troubleshooting! 🚀
