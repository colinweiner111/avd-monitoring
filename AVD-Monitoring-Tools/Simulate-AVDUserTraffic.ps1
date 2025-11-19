# Simulate-AVDUserTraffic.ps1
# Simulates typical AVD user workload patterns to stress-test network monitoring
# Run this INSIDE an active AVD session

<#
.SYNOPSIS
    Simulates realistic user activity in an AVD session for network testing.

.DESCRIPTION
    This script generates typical user workload patterns including:
    - Web browsing (HTTP/HTTPS traffic)
    - File operations (disk I/O and network shares)
    - Office-like application activity
    - Video playback (bandwidth consumption)
    - Interactive UI operations (graphics rendering)

.PARAMETER Duration
    How long to run the simulation in minutes (default: 30)

.PARAMETER WorkloadType
    Type of workload: Light, Medium, Heavy, or Mixed (default)

.PARAMETER IncludeVideo
    Include video streaming simulation (high bandwidth)

.EXAMPLE
    .\Simulate-AVDUserTraffic.ps1 -Duration 15 -WorkloadType Mixed -IncludeVideo
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [int]$Duration = 30,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Light', 'Medium', 'Heavy', 'Mixed')]
    [string]$WorkloadType = 'Mixed',
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeVideo
)

$ErrorActionPreference = "SilentlyContinue"
$EndTime = (Get-Date).AddMinutes($Duration)

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         AVD User Traffic Simulation                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Workload Type: " -NoNewline -ForegroundColor Yellow
Write-Host $WorkloadType -ForegroundColor White
Write-Host "Duration:      " -NoNewline -ForegroundColor Yellow
Write-Host "$Duration minutes" -ForegroundColor White
Write-Host "End Time:      " -NoNewline -ForegroundColor Yellow
Write-Host $EndTime.ToString("HH:mm:ss") -ForegroundColor White
Write-Host ""
Write-Host "This script will simulate typical user activities..." -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop early" -ForegroundColor Gray
Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

# Function to simulate web browsing
function Invoke-WebBrowsing {
    param([int]$Count = 5)
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Simulating web browsing..." -ForegroundColor Cyan
    
    $Websites = @(
        'https://www.microsoft.com',
        'https://www.bing.com',
        'https://docs.microsoft.com',
        'https://azure.microsoft.com',
        'https://www.office.com'
    )
    
    for ($i = 0; $i -lt $Count; $i++) {
        $Site = $Websites | Get-Random
        try {
            Write-Host "  └─ Fetching: $Site" -ForegroundColor Gray
            $response = Invoke-WebRequest -Uri $Site -TimeoutSec 10 -UseBasicParsing
            Write-Host "     Response: $($response.StatusCode) - $($response.RawContentLength) bytes" -ForegroundColor Green
        }
        catch {
            Write-Host "     Failed to reach $Site" -ForegroundColor Yellow
        }
        Start-Sleep -Seconds 2
    }
}

# Function to simulate file operations
function Invoke-FileOperations {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Simulating file operations..." -ForegroundColor Cyan
    
    $TempPath = "$env:TEMP\AVDTest"
    New-Item -Path $TempPath -ItemType Directory -Force | Out-Null
    
    # Create test files
    for ($i = 1; $i -le 10; $i++) {
        $FilePath = "$TempPath\TestFile_$i.txt"
        $Content = "Test data " * 1000  # ~10KB per file
        Write-Host "  └─ Creating file $i of 10..." -ForegroundColor Gray
        $Content | Out-File $FilePath -Force
    }
    
    # Read files
    Write-Host "  └─ Reading files..." -ForegroundColor Gray
    Get-ChildItem $TempPath -File | ForEach-Object {
        Get-Content $_.FullName | Out-Null
    }
    
    # Copy files
    Write-Host "  └─ Copying files..." -ForegroundColor Gray
    $CopyPath = "$TempPath\Copy"
    New-Item -Path $CopyPath -ItemType Directory -Force | Out-Null
    Copy-Item "$TempPath\*.txt" $CopyPath -Force
    
    # Cleanup
    Write-Host "  └─ Cleaning up..." -ForegroundColor Gray
    Remove-Item $TempPath -Recurse -Force
    
    Write-Host "  ✓ File operations complete" -ForegroundColor Green
}

# Function to simulate CPU load (like Office apps)
function Invoke-CPULoad {
    param([int]$Seconds = 10)
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Simulating CPU load (Office-like)..." -ForegroundColor Cyan
    
    $EndTime = (Get-Date).AddSeconds($Seconds)
    $Jobs = @()
    
    # Spawn multiple background jobs to simulate multi-threaded app
    for ($i = 1; $i -le 4; $i++) {
        $Jobs += Start-Job -ScriptBlock {
            $end = (Get-Date).AddSeconds($using:Seconds)
            while ((Get-Date) -lt $end) {
                $result = 1..1000 | ForEach-Object { $_ * $_ }
            }
        }
    }
    
    Write-Host "  └─ Running CPU load for $Seconds seconds..." -ForegroundColor Gray
    
    while ((Get-Date) -lt $EndTime) {
        $Progress = [math]::Round((($Seconds - ($EndTime - (Get-Date)).TotalSeconds) / $Seconds) * 100)
        Write-Progress -Activity "CPU Load Simulation" -Status "$Progress% Complete" -PercentComplete $Progress
        Start-Sleep -Milliseconds 500
    }
    
    Write-Progress -Activity "CPU Load Simulation" -Completed
    $Jobs | Stop-Job
    $Jobs | Remove-Job -Force
    
    Write-Host "  ✓ CPU load complete" -ForegroundColor Green
}

# Function to simulate memory pressure
function Invoke-MemoryLoad {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Simulating memory usage..." -ForegroundColor Cyan
    
    # Allocate memory (simulates large document/spreadsheet)
    Write-Host "  └─ Allocating memory (100MB)..." -ForegroundColor Gray
    $MemoryArray = New-Object byte[] (100MB)
    for ($i = 0; $i -lt $MemoryArray.Length; $i += 1000) {
        $MemoryArray[$i] = [byte](Get-Random -Minimum 0 -Maximum 255)
    }
    
    Write-Host "  └─ Holding memory for 10 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 10
    
    Write-Host "  └─ Releasing memory..." -ForegroundColor Gray
    $MemoryArray = $null
    [System.GC]::Collect()
    
    Write-Host "  ✓ Memory test complete" -ForegroundColor Green
}

# Function to simulate video playback (high bandwidth)
function Invoke-VideoSimulation {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Simulating video streaming..." -ForegroundColor Cyan
    
    # Download a file to simulate video streaming bandwidth
    $VideoURL = "https://speed.cloudflare.com/__down?bytes=10000000"  # 10MB download
    
    try {
        Write-Host "  └─ Streaming video data (10MB download)..." -ForegroundColor Gray
        $StartTime = Get-Date
        Invoke-WebRequest -Uri $VideoURL -OutFile "$env:TEMP\videotest.tmp" -UseBasicParsing
        $Duration = ((Get-Date) - $StartTime).TotalSeconds
        $SpeedMbps = [math]::Round((10 / $Duration) * 8, 2)
        
        Write-Host "  └─ Download speed: $SpeedMbps Mbps" -ForegroundColor Green
        Remove-Item "$env:TEMP\videotest.tmp" -Force
    }
    catch {
        Write-Host "  └─ Video simulation failed (network issue?)" -ForegroundColor Yellow
    }
    
    Write-Host "  ✓ Video simulation complete" -ForegroundColor Green
}

# Function to simulate UI interactions (graphics rendering)
function Invoke-UIActivity {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Simulating UI activity..." -ForegroundColor Cyan
    
    # Open and close Notepad multiple times (simulates window operations)
    for ($i = 1; $i -le 3; $i++) {
        Write-Host "  └─ Opening application $i..." -ForegroundColor Gray
        $Process = Start-Process notepad.exe -PassThru
        Start-Sleep -Seconds 2
        Write-Host "  └─ Closing application $i..." -ForegroundColor Gray
        $Process | Stop-Process -Force
        Start-Sleep -Seconds 1
    }
    
    Write-Host "  ✓ UI simulation complete" -ForegroundColor Green
}

# Function to run mixed workload
function Invoke-MixedWorkload {
    $Activities = @(
        { Invoke-WebBrowsing -Count 3 },
        { Invoke-FileOperations },
        { Invoke-CPULoad -Seconds 15 },
        { Invoke-MemoryLoad }
    )
    
    if ($IncludeVideo) {
        $Activities += { Invoke-VideoSimulation }
    }
    
    # Run random activity
    $Activity = $Activities | Get-Random
    & $Activity
}

# Main simulation loop
Write-Host "Starting simulation at $(Get-Date -Format 'HH:mm:ss')..." -ForegroundColor Green
Write-Host ""

$Iteration = 0
while ((Get-Date) -lt $EndTime) {
    $Iteration++
    $TimeRemaining = ($EndTime - (Get-Date)).TotalMinutes
    
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "Iteration #$Iteration - Time remaining: $([math]::Round($TimeRemaining, 1)) minutes" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
    
    switch ($WorkloadType) {
        'Light' {
            Invoke-WebBrowsing -Count 2
            Start-Sleep -Seconds 30
        }
        'Medium' {
            Invoke-WebBrowsing -Count 3
            Invoke-FileOperations
            Start-Sleep -Seconds 20
        }
        'Heavy' {
            Invoke-WebBrowsing -Count 5
            Invoke-FileOperations
            Invoke-CPULoad -Seconds 20
            Invoke-MemoryLoad
            if ($IncludeVideo) { Invoke-VideoSimulation }
            Start-Sleep -Seconds 10
        }
        'Mixed' {
            Invoke-MixedWorkload
            Start-Sleep -Seconds (Get-Random -Minimum 15 -Maximum 45)
        }
    }
    
    Write-Host ""
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║            Simulation Complete                                ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Total iterations: $Iteration" -ForegroundColor White
Write-Host "Duration: $Duration minutes" -ForegroundColor White
Write-Host ""
Write-Host "Review your monitoring logs to analyze network behavior." -ForegroundColor Yellow
