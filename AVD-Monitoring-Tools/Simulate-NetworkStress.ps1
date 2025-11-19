# Simulate-NetworkStress.ps1
# Creates network stress conditions to test monitoring script's detection capabilities

<#
.SYNOPSIS
    Generates network stress to test AVD monitoring capabilities.

.DESCRIPTION
    This script creates various network stress conditions including:
    - High bandwidth consumption
    - Packet bursts
    - DNS queries
    - Concurrent connections
    - Large file transfers

.PARAMETER StressType
    Type of stress: Bandwidth, Latency, Burst, or All

.PARAMETER Duration
    How long to run stress test in minutes

.EXAMPLE
    .\Simulate-NetworkStress.ps1 -StressType Bandwidth -Duration 10
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Bandwidth', 'Connections', 'DNS', 'Burst', 'All')]
    [string]$StressType = 'All',
    
    [Parameter(Mandatory=$false)]
    [int]$Duration = 10
)

$EndTime = (Get-Date).AddMinutes($Duration)

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║         Network Stress Test                                   ║" -ForegroundColor Red
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "WARNING: This will generate significant network traffic!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Stress Type: $StressType" -ForegroundColor White
Write-Host "Duration: $Duration minutes" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop..." -ForegroundColor Gray
Start-Sleep -Seconds 3
Write-Host ""

# Bandwidth stress - download large files
function Invoke-BandwidthStress {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] BANDWIDTH STRESS - Downloading large files..." -ForegroundColor Red
    
    $DownloadURLs = @(
        'https://speed.cloudflare.com/__down?bytes=50000000',  # 50MB
        'https://speed.cloudflare.com/__down?bytes=50000000',
        'https://speed.cloudflare.com/__down?bytes=50000000'
    )
    
    $Jobs = @()
    foreach ($URL in $DownloadURLs) {
        $Jobs += Start-Job -ScriptBlock {
            param($url)
            try {
                Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\stress_$([guid]::NewGuid()).tmp" -UseBasicParsing
            } catch {}
        } -ArgumentList $URL
    }
    
    Write-Host "  └─ Running 3 concurrent 50MB downloads..." -ForegroundColor Yellow
    $Jobs | Wait-Job -Timeout 60 | Out-Null
    $Jobs | Remove-Job -Force
    
    # Cleanup
    Remove-Item "$env:TEMP\stress_*.tmp" -Force -ErrorAction SilentlyContinue
    
    Write-Host "  ✓ Bandwidth stress complete" -ForegroundColor Green
}

# Connection stress - many concurrent connections
function Invoke-ConnectionStress {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] CONNECTION STRESS - Opening many connections..." -ForegroundColor Red
    
    $Hosts = @(
        'www.microsoft.com',
        'www.google.com',
        'www.amazon.com',
        'www.facebook.com',
        'www.twitter.com',
        'www.linkedin.com',
        'www.github.com',
        'www.stackoverflow.com'
    )
    
    $Jobs = @()
    foreach ($Host in $Hosts) {
        $Jobs += Start-Job -ScriptBlock {
            param($hostname)
            try {
                for ($i = 0; $i -lt 5; $i++) {
                    Test-NetConnection -ComputerName $hostname -Port 443 -InformationLevel Quiet | Out-Null
                    Invoke-WebRequest -Uri "https://$hostname" -UseBasicParsing -TimeoutSec 5 | Out-Null
                }
            } catch {}
        } -ArgumentList $Host
    }
    
    Write-Host "  └─ Opening 40+ concurrent HTTPS connections..." -ForegroundColor Yellow
    $Jobs | Wait-Job -Timeout 30 | Out-Null
    $Jobs | Remove-Job -Force
    
    Write-Host "  ✓ Connection stress complete" -ForegroundColor Green
}

# DNS stress - rapid DNS queries
function Invoke-DNSStress {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] DNS STRESS - Rapid DNS queries..." -ForegroundColor Red
    
    $Domains = @(
        'www.microsoft.com', 'azure.microsoft.com', 'github.com',
        'stackoverflow.com', 'www.google.com', 'www.amazon.com',
        'www.cloudflare.com', 'www.reddit.com', 'www.wikipedia.org',
        'docs.microsoft.com', 'portal.azure.com', 'www.bing.com'
    )
    
    Write-Host "  └─ Performing 100 rapid DNS lookups..." -ForegroundColor Yellow
    
    for ($i = 0; $i -lt 100; $i++) {
        $Domain = $Domains | Get-Random
        [System.Net.Dns]::GetHostAddresses($Domain) | Out-Null
        
        if ($i % 20 -eq 0) {
            Write-Host "     Progress: $i/100 queries" -ForegroundColor Gray
        }
    }
    
    Write-Host "  ✓ DNS stress complete" -ForegroundColor Green
}

# Burst stress - sudden traffic spikes
function Invoke-BurstStress {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] BURST STRESS - Creating traffic spike..." -ForegroundColor Red
    
    Write-Host "  └─ Generating sudden traffic burst..." -ForegroundColor Yellow
    
    $Jobs = @()
    # Create 10 simultaneous connections
    for ($i = 0; $i -lt 10; $i++) {
        $Jobs += Start-Job -ScriptBlock {
            try {
                Invoke-WebRequest -Uri 'https://www.microsoft.com' -UseBasicParsing | Out-Null
                Invoke-WebRequest -Uri 'https://azure.microsoft.com' -UseBasicParsing | Out-Null
            } catch {}
        }
    }
    
    # Wait for burst to complete
    $Jobs | Wait-Job -Timeout 15 | Out-Null
    $Jobs | Remove-Job -Force
    
    Write-Host "  └─ Cooling down (30 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    Write-Host "  ✓ Burst stress complete" -ForegroundColor Green
}

# Main loop
$Iteration = 0
while ((Get-Date) -lt $EndTime) {
    $Iteration++
    $TimeRemaining = ($EndTime - (Get-Date)).TotalMinutes
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "Iteration #$Iteration - Time remaining: $([math]::Round($TimeRemaining, 1)) minutes" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
    
    switch ($StressType) {
        'Bandwidth' { Invoke-BandwidthStress }
        'Connections' { Invoke-ConnectionStress }
        'DNS' { Invoke-DNSStress }
        'Burst' { Invoke-BurstStress }
        'All' {
            $Tests = @(
                { Invoke-BandwidthStress },
                { Invoke-ConnectionStress },
                { Invoke-DNSStress },
                { Invoke-BurstStress }
            )
            $Test = $Tests | Get-Random
            & $Test
        }
    }
    
    Write-Host ""
    Write-Host "Waiting 30 seconds before next stress cycle..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║            Stress Test Complete                              ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Check your monitoring logs for detected issues." -ForegroundColor Yellow
