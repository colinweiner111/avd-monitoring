<#
.SYNOPSIS
    Monitors Azure Virtual Desktop client-side network connectivity and logs issues.

.DESCRIPTION
    Continuously monitors network connectivity to AVD session hosts, tracking:
    - ICMP ping response times and packet loss
    - TCP/UDP port connectivity (RDP 3389 and Shortpath 3390)
    - Network adapter statistics and errors
    - WiFi signal strength (if applicable)
    - DNS resolution time
    - Detailed logging with timestamps for correlation with AVD disconnections

.PARAMETER SessionHostFQDN
    The FQDN of the AVD session host to monitor. Can be found in Log Analytics WVDConnections table.

.PARAMETER IntervalSeconds
    How often to run connectivity tests (default: 30 seconds)

.PARAMETER LogPath
    Path where the CSV log file will be saved (default: Desktop)

.PARAMETER AlertOnFailure
    If specified, will display prominent console alerts when connectivity issues are detected

.PARAMETER IncludeQualityScore
    If specified, calculates a 0-100 connection quality score based on latency, jitter, packet loss, and DNS performance

.EXAMPLE
    .\Monitor-AVDConnection.ps1 -SessionHostFQDN "CONCDSYS-72cb.ad4.sfgov.org" -IntervalSeconds 30 -AlertOnFailure

.EXAMPLE
    .\Monitor-AVDConnection.ps1 -SessionHostFQDN "CONCDSYS-72cb.ad4.sfgov.org" -IntervalSeconds 30 -IncludeQualityScore

.NOTES
    Author: Azure Customer Success Architecture
    Run this script on the client machine experiencing intermittent AVD connectivity issues.
    Let it run during normal work hours to capture patterns.
    Review the CSV log to correlate timestamps with user-reported disconnections.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="FQDN of AVD session host (e.g., CONCDSYS-72cb.ad4.sfgov.org)")]
    [string]$SessionHostFQDN,
    
    [Parameter(Mandatory=$false)]
    [int]$IntervalSeconds = 30,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:USERPROFILE\Desktop\AVD-Network-Monitor.csv",
    
    [Parameter(Mandatory=$false)]
    [switch]$AlertOnFailure,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeQualityScore
)

# Initialize
$ErrorActionPreference = "SilentlyContinue"
$script:baselineStats = $null
$script:issueCount = 0

# Create log file with headers if it doesn't exist
if (-not (Test-Path $LogPath)) {
    if ($IncludeQualityScore) {
        $headers = "Timestamp,PingStatus,AvgRTT_ms,MinRTT_ms,MaxRTT_ms,PacketLoss_%,TCP3389,DNSResolution_ms,NetworkAdapter,AdapterStatus,LinkSpeed,ReceivedErrors,SentErrors,TotalErrors,WiFiSignal,QualityScore,QualityRating,Notes"
    }
    else {
        $headers = "Timestamp,PingStatus,AvgRTT_ms,MinRTT_ms,MaxRTT_ms,PacketLoss_%,TCP3389,DNSResolution_ms,NetworkAdapter,AdapterStatus,LinkSpeed,ReceivedErrors,SentErrors,TotalErrors,WiFiSignal,Notes"
    }
    $headers | Out-File $LogPath -Encoding UTF8
    Write-Host "Created new log file: $LogPath" -ForegroundColor Green
}

# Function to test DNS resolution time
function Test-DNSResolution {
    param([string]$HostName)
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        [System.Net.Dns]::GetHostAddresses($HostName) | Out-Null
        $stopwatch.Stop()
        return [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 2)
    }
    catch {
        $stopwatch.Stop()
        return "Failed"
    }
}

# Function to get WiFi signal strength
function Get-WiFiSignalStrength {
    param([string]$AdapterName)
    
    try {
        $wifiInfo = netsh wlan show interfaces 2>$null | Select-String -Pattern "^\s*Signal"
        if ($wifiInfo -and $wifiInfo.ToString().Contains(':')) {
            $signalString = $wifiInfo.ToString().Split(':')[1].Trim()
            # Return only if it looks like a valid percentage
            if ($signalString -match '\d+%') {
                return $signalString
            }
        }
    }
    catch {
        # Silently fail - not critical
    }
    return "N/A"
}

# Function to calculate connection quality score (0-100)
function Get-ConnectionQualityScore {
    param(
        [double]$AvgLatency,
        [double]$Jitter,
        [double]$PacketLoss,
        [double]$DNSTime
    )
    
    $score = 100
    
    # Latency scoring (40 points max)
    # Excellent <30ms = 40pts, Good <100ms = 30pts, Fair <150ms = 20pts, Poor >150ms = 0-20pts
    if ($AvgLatency -eq "N/A" -or $AvgLatency -eq $null) {
        $latencyScore = 0
    }
    elseif ($AvgLatency -lt 30) {
        $latencyScore = 40
    }
    elseif ($AvgLatency -lt 100) {
        $latencyScore = 30 + ((100 - $AvgLatency) / 70 * 10)
    }
    elseif ($AvgLatency -lt 150) {
        $latencyScore = 20 + ((150 - $AvgLatency) / 50 * 10)
    }
    else {
        $latencyScore = [Math]::Max(0, 20 - (($AvgLatency - 150) / 10))
    }
    
    # Jitter scoring (20 points max)
    # Excellent <20ms = 20pts, Good <50ms = 15pts, Fair <100ms = 10pts, Poor >100ms = 0-10pts
    if ($Jitter -lt 20) {
        $jitterScore = 20
    }
    elseif ($Jitter -lt 50) {
        $jitterScore = 15 + ((50 - $Jitter) / 30 * 5)
    }
    elseif ($Jitter -lt 100) {
        $jitterScore = 10 + ((100 - $Jitter) / 50 * 5)
    }
    else {
        $jitterScore = [Math]::Max(0, 10 - (($Jitter - 100) / 20))
    }
    
    # Packet loss scoring (30 points max)
    # 0% loss = 30pts, each 1% loss = -6pts
    if ($PacketLoss -eq "N/A" -or $PacketLoss -eq $null) {
        $packetLossScore = 0
    }
    else {
        $packetLossScore = [Math]::Max(0, 30 - ($PacketLoss * 6))
    }
    
    # DNS time scoring (10 points max)
    # <50ms = 10pts, <200ms = 8pts, <500ms = 5pts, >500ms = 0-5pts
    if ($DNSTime -eq "N/A" -or $DNSTime -eq "Failed" -or $DNSTime -eq $null) {
        $dnsScore = 0
    }
    elseif ($DNSTime -lt 50) {
        $dnsScore = 10
    }
    elseif ($DNSTime -lt 200) {
        $dnsScore = 8 + ((200 - $DNSTime) / 150 * 2)
    }
    elseif ($DNSTime -lt 500) {
        $dnsScore = 5 + ((500 - $DNSTime) / 300 * 3)
    }
    else {
        $dnsScore = [Math]::Max(0, 5 - (($DNSTime - 500) / 200))
    }
    
    $totalScore = [Math]::Round($latencyScore + $jitterScore + $packetLossScore + $dnsScore, 0)
    $totalScore = [Math]::Min(100, [Math]::Max(0, $totalScore))
    
    return $totalScore
}

# Function to get quality rating from score
function Get-QualityRating {
    param([int]$Score)
    
    if ($Score -ge 90) { return "Excellent" }
    elseif ($Score -ge 75) { return "Good" }
    elseif ($Score -ge 60) { return "Fair" }
    elseif ($Score -ge 40) { return "Poor" }
    else { return "Critical" }
}

# Display startup information
Clear-Host
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Azure Virtual Desktop Network Connectivity Monitor        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target Session Host: " -NoNewline -ForegroundColor Yellow
Write-Host $SessionHostFQDN -ForegroundColor White
Write-Host "Monitoring Interval: " -NoNewline -ForegroundColor Yellow
Write-Host "$IntervalSeconds seconds" -ForegroundColor White
Write-Host "Log File Location:   " -NoNewline -ForegroundColor Yellow
Write-Host $LogPath -ForegroundColor White
Write-Host ""
Write-Host "Monitoring started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop monitoring..." -ForegroundColor Gray
Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

# Main monitoring loop
$iteration = 0
while ($true) {
    $iteration++
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $notes = @()
    $hasIssue = $false
    
    # Test DNS Resolution
    Write-Host "[$timestamp] Checking connectivity (Iteration #$iteration)..." -ForegroundColor Cyan
    $dnsTime = Test-DNSResolution -HostName $SessionHostFQDN
    
    if ($dnsTime -eq "Failed") {
        $notes += "DNS_RESOLUTION_FAILED"
        $hasIssue = $true
        Write-Host "  └─ DNS Resolution: FAILED" -ForegroundColor Red
    }
    else {
        Write-Host "  └─ DNS Resolution: $dnsTime ms" -ForegroundColor Green
        if ($dnsTime -gt 500) {
            $notes += "SLOW_DNS(${dnsTime}ms)"
        }
    }
    
    # Test ICMP Ping (4 packets for better statistics)
    $pingResults = Test-Connection -ComputerName $SessionHostFQDN -Count 4 -ErrorAction SilentlyContinue
    
    if ($pingResults) {
        $responseTimes = $pingResults | Select-Object -ExpandProperty ResponseTime
        $avgRTT = [math]::Round(($responseTimes | Measure-Object -Average).Average, 2)
        $minRTT = ($responseTimes | Measure-Object -Minimum).Minimum
        $maxRTT = ($responseTimes | Measure-Object -Maximum).Maximum
        $packetsReceived = $pingResults.Count
        $packetLoss = [math]::Round(((4 - $packetsReceived) / 4) * 100, 2)
        $pingStatus = "Success"
        
        $rttColor = if ($avgRTT -lt 50) { "Green" } elseif ($avgRTT -lt 150) { "Yellow" } else { "Red" }
        Write-Host "  └─ Ping: SUCCESS | Avg: $avgRTT ms | Min: $minRTT ms | Max: $maxRTT ms | Loss: $packetLoss%" -ForegroundColor $rttColor
        
        # Flag performance issues
        if ($avgRTT -gt 150) {
            $notes += "HIGH_LATENCY(${avgRTT}ms)"
            $hasIssue = $true
        }
        if ($packetLoss -gt 0) {
            $notes += "PACKET_LOSS(${packetLoss}%)"
            $hasIssue = $true
        }
        if (($maxRTT - $minRTT) -gt 100) {
            $notes += "HIGH_JITTER($($maxRTT - $minRTT)ms)"
            $hasIssue = $true
        }
    }
    else {
        $pingStatus = "Failed"
        $avgRTT = "N/A"
        $minRTT = "N/A"
        $maxRTT = "N/A"
        $packetLoss = 100
        $notes += "PING_FAILED"
        $hasIssue = $true
        Write-Host "  └─ Ping: FAILED (No response)" -ForegroundColor Red
    }
    
    # Test TCP port 3389 (standard RDP)
    $tcp3389Result = Test-NetConnection -ComputerName $SessionHostFQDN -Port 3389 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $tcp3389 = if ($tcp3389Result.TcpTestSucceeded) { "Open" } else { "Closed/Blocked" }
    $tcpColor = if ($tcp3389Result.TcpTestSucceeded) { "Green" } else { "Red" }
    Write-Host "  └─ TCP 3389 (RDP): $tcp3389" -ForegroundColor $tcpColor
    
    if (-not $tcp3389Result.TcpTestSucceeded) {
        $notes += "TCP_3389_BLOCKED"
        $hasIssue = $true
    }
    
    # Note: UDP 3390 (RDP Shortpath) cannot be reliably tested from client side
    # The ShortpathTransportNetworkDrop errors indicate UDP is negotiating but then dropping
    # We rely on ping jitter and packet loss as UDP health indicators instead
    Write-Host "  └─ UDP 3390 (Shortpath): Not testable from client" -ForegroundColor Gray
    
    # Get network adapter information
    $adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
    
    if ($adapter) {
        $adapterName = $adapter.Name
        $adapterStatus = $adapter.Status
        $linkSpeed = $adapter.LinkSpeed
        
        # Get adapter statistics
        $stats = Get-NetAdapterStatistics -Name $adapter.Name
        $receivedErrors = $stats.ReceivedPacketErrors
        $sentErrors = $stats.OutboundPacketErrors
        $totalErrors = $receivedErrors + $sentErrors
        
        # Check for new errors since last check
        if ($null -ne $script:baselineStats) {
            # Handle counter resets (adapter restart, etc.)
            if ($totalErrors -ge $script:baselineStats) {
                $newErrors = $totalErrors - $script:baselineStats
                if ($newErrors -gt 0) {
                    $notes += "NEW_PACKET_ERRORS(+$newErrors)"
                    $hasIssue = $true
                }
            }
            else {
                # Counter reset detected
                $notes += "ADAPTER_COUNTER_RESET"
            }
        }
        $script:baselineStats = $totalErrors
        
        $errorColor = if ($totalErrors -eq 0) { "Green" } else { "Yellow" }
        Write-Host "  └─ Adapter: $adapterName | Status: $adapterStatus | Speed: $linkSpeed" -ForegroundColor White
        Write-Host "  └─ Packet Errors: Received=$receivedErrors, Sent=$sentErrors, Total=$totalErrors" -ForegroundColor $errorColor
        
        # Get WiFi signal if applicable
        $wifiSignal = "N/A"
        if ($adapter.MediaType -match "802\.11|Wi-?Fi") {
            $wifiSignal = Get-WiFiSignalStrength -AdapterName $adapter.Name
            if ($wifiSignal -ne "N/A") {
                Write-Host "  └─ WiFi Signal: $wifiSignal" -ForegroundColor Cyan
                
                # Parse signal strength and flag weak signals
                if ($wifiSignal -match "(\d+)%") {
                    $signalPercent = [int]$Matches[1]
                    if ($signalPercent -lt 50) {
                        $notes += "WEAK_WIFI_SIGNAL(${signalPercent}%)"
                        $hasIssue = $true
                    }
                }
            }
        }
    }
    else {
        $adapterName = "None"
        $adapterStatus = "No active adapter"
        $linkSpeed = "N/A"
        $receivedErrors = 0
        $sentErrors = 0
        $totalErrors = 0
        $wifiSignal = "N/A"
        $notes += "NO_ACTIVE_ADAPTER"
        $hasIssue = $true
        Write-Host "  └─ WARNING: No active network adapter found!" -ForegroundColor Red
    }
    
    # Compile notes
    $notesString = if ($notes.Count -gt 0) { $notes -join ";" } else { "OK" }
    
    # Calculate quality score if enabled
    if ($IncludeQualityScore) {
        # Calculate jitter
        $jitter = if ($maxRTT -ne "N/A" -and $minRTT -ne "N/A") { 
            $maxRTT - $minRTT 
        } else { 
            0 
        }
        
        # Get numeric values
        $avgRTTNum = if ($avgRTT -eq "N/A") { 999 } else { [double]$avgRTT }
        $packetLossNum = if ($packetLoss -eq "N/A") { 100 } else { [double]$packetLoss }
        $dnsTimeNum = if ($dnsTime -eq "Failed" -or $dnsTime -eq "N/A") { 9999 } else { [double]$dnsTime }
        
        $qualityScore = Get-ConnectionQualityScore -AvgLatency $avgRTTNum -Jitter $jitter -PacketLoss $packetLossNum -DNSTime $dnsTimeNum
        $qualityRating = Get-QualityRating -Score $qualityScore
        
        # Color code the score display
        $scoreColor = switch ($qualityRating) {
            "Excellent" { "Green" }
            "Good" { "Green" }
            "Fair" { "Yellow" }
            "Poor" { "Red" }
            "Critical" { "Red" }
        }
        
        Write-Host "  └─ Connection Quality: $qualityScore/100 ($qualityRating)" -ForegroundColor $scoreColor
    }
    
    # Create CSV log entry
    if ($IncludeQualityScore) {
        $logEntry = @(
            $timestamp,
            $pingStatus,
            $avgRTT,
            $minRTT,
            $maxRTT,
            $packetLoss,
            $tcp3389,
            $dnsTime,
            $adapterName,
            $adapterStatus,
            $linkSpeed,
            $receivedErrors,
            $sentErrors,
            $totalErrors,
            $wifiSignal,
            $qualityScore,
            $qualityRating,
            $notesString
        ) -join ","
    }
    else {
        $logEntry = @(
            $timestamp,
            $pingStatus,
            $avgRTT,
            $minRTT,
            $maxRTT,
            $packetLoss,
            $tcp3389,
            $dnsTime,
            $adapterName,
            $adapterStatus,
            $linkSpeed,
            $receivedErrors,
            $sentErrors,
            $totalErrors,
            $wifiSignal,
            $notesString
        ) -join ","
    }
    
    # Write to log file
    $logEntry | Out-File $LogPath -Append -Encoding UTF8
    
    # Display issue alert if enabled
    if ($hasIssue) {
        $script:issueCount++
        if ($AlertOnFailure) {
            Write-Host ""
            Write-Host "  ⚠️  CONNECTIVITY ISSUE DETECTED (#$script:issueCount) ⚠️" -ForegroundColor Red -BackgroundColor Yellow
            Write-Host "  Issues: $notesString" -ForegroundColor Red
            Write-Host ""
        }
    }
    else {
        Write-Host "  ✓ All connectivity checks passed" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    # Wait for next interval
    Start-Sleep -Seconds $IntervalSeconds
}
