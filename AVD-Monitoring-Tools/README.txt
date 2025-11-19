AVD Network Monitoring Tools
=============================

Package Contents:
-----------------
1. Monitor-AVDConnection.ps1       - Main network monitoring script
2. Test-MonitoringScript.ps1       - Pre-flight validation script  
3. Simulate-AVDUserTraffic.ps1     - User traffic simulation
4. Simulate-NetworkStress.ps1      - Network stress testing
5. deploy-test-vm.ps1              - Azure VM deployment (PowerShell)
6. deploy-test-vm.sh               - Azure VM deployment (Bash)
7. AVD-Monitoring-Guide.md         - Complete usage guide
8. README-AVD-Monitor.md           - Quick reference guide

Quick Start:
------------
1. Extract all files to a folder (e.g., C:\AVDMonitoring)

2. Open PowerShell and navigate to the folder:
   cd C:\AVDMonitoring

3. Unblock the scripts:
   Get-ChildItem *.ps1 | Unblock-File

4. Run validation:
   .\Test-MonitoringScript.ps1

5. Start monitoring (replace with your session host):
   .\Monitor-AVDConnection.ps1 -SessionHostFQDN "your-host.domain.com" -IntervalSeconds 30 -AlertOnFailure

6. Check the CSV log on your Desktop when issues occur

For Complete Instructions:
--------------------------
Open "AVD-Monitoring-Guide.md" in any markdown viewer or text editor
(Recommended: Visual Studio Code, Notepad++, or view on GitHub)

Key Commands:
-------------
# Validate setup
.\Test-MonitoringScript.ps1

# Monitor production
.\Monitor-AVDConnection.ps1 -SessionHostFQDN "CONCDSYS-72cb.ad4.sfgov.org" -IntervalSeconds 30 -AlertOnFailure

# Simulate traffic (run inside AVD session)
.\Simulate-AVDUserTraffic.ps1 -Duration 30 -WorkloadType Mixed -IncludeVideo

# Stress test
.\Simulate-NetworkStress.ps1 -StressType All -Duration 10

Common Issues:
--------------
Q: Script won't run
A: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

Q: Can't find session host
A: Get FQDN from Azure Log Analytics WVDConnections table

Q: TCP 3389 shows "Closed/Blocked"
A: Normal when testing against non-RDP hosts like microsoft.com
   Use actual AVD session host FQDN instead

Support:
--------
Created: 2025-11-18
For Azure CSA use in diagnosing AVD connectivity issues
Focus: ShortpathTransportNetworkDrop (UDP) issues
