# Test-MonitoringScript.ps1
# Quick validation that the monitoring script can execute

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "AVD Monitoring Script - Pre-flight Check" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
Write-Host "Checking PowerShell version..." -ForegroundColor Yellow
$PSVersion = $PSVersionTable.PSVersion
if ($PSVersion.Major -ge 5) {
    Write-Host "  ✓ PowerShell $($PSVersion.Major).$($PSVersion.Minor) - OK" -ForegroundColor Green
} else {
    Write-Host "  ✗ PowerShell $($PSVersion.Major).$($PSVersion.Minor) - Too old (need 5.0+)" -ForegroundColor Red
    exit 1
}

# Check required cmdlets
Write-Host ""
Write-Host "Checking required cmdlets..." -ForegroundColor Yellow

$RequiredCmdlets = @(
    'Test-Connection',
    'Test-NetConnection',
    'Get-NetAdapter',
    'Get-NetAdapterStatistics'
)

$AllPresent = $true
foreach ($Cmdlet in $RequiredCmdlets) {
    $Found = Get-Command $Cmdlet -ErrorAction SilentlyContinue
    if ($Found) {
        Write-Host "  ✓ $Cmdlet" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $Cmdlet - NOT FOUND" -ForegroundColor Red
        $AllPresent = $false
    }
}

if (-not $AllPresent) {
    Write-Host ""
    Write-Host "ERROR: Missing required cmdlets. Update Windows or PowerShell." -ForegroundColor Red
    exit 1
}

# Check network connectivity
Write-Host ""
Write-Host "Testing basic network connectivity..." -ForegroundColor Yellow
$TestHost = "8.8.8.8"  # Google DNS
$PingResult = Test-Connection -ComputerName $TestHost -Count 2 -ErrorAction SilentlyContinue

if ($PingResult) {
    Write-Host "  ✓ Network connectivity OK" -ForegroundColor Green
} else {
    Write-Host "  ✗ Network connectivity FAILED" -ForegroundColor Red
    Write-Host "    Check your internet connection" -ForegroundColor Yellow
}

# Check network adapter
Write-Host ""
Write-Host "Checking network adapters..." -ForegroundColor Yellow
$Adapters = Get-NetAdapter | Where-Object Status -eq "Up"

if ($Adapters) {
    foreach ($Adapter in $Adapters) {
        Write-Host "  ✓ $($Adapter.Name) - $($Adapter.Status) - $($Adapter.LinkSpeed)" -ForegroundColor Green
    }
} else {
    Write-Host "  ✗ No active network adapters found" -ForegroundColor Red
}

# Test file creation permissions
Write-Host ""
Write-Host "Testing file write permissions..." -ForegroundColor Yellow
$TestLogPath = "$env:USERPROFILE\Desktop\test-avd-monitor.csv"
try {
    "test" | Out-File $TestLogPath -ErrorAction Stop
    Remove-Item $TestLogPath -ErrorAction SilentlyContinue
    Write-Host "  ✓ Can write to Desktop" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Cannot write to Desktop: $($_.Exception.Message)" -ForegroundColor Red
}

# Quick live test
Write-Host ""
Write-Host "Running quick live test (10 seconds)..." -ForegroundColor Yellow
Write-Host "  Testing against: microsoft.com" -ForegroundColor Gray

try {
    # DNS test
    $DNSStart = Get-Date
    [System.Net.Dns]::GetHostAddresses("microsoft.com") | Out-Null
    $DNSTime = ((Get-Date) - $DNSStart).TotalMilliseconds
    Write-Host "  ✓ DNS Resolution: $([math]::Round($DNSTime, 2)) ms" -ForegroundColor Green
    
    # Ping test
    $Ping = Test-Connection -ComputerName "microsoft.com" -Count 2 -ErrorAction SilentlyContinue
    if ($Ping) {
        $AvgRTT = ($Ping.ResponseTime | Measure-Object -Average).Average
        Write-Host "  ✓ Ping: $([math]::Round($AvgRTT, 2)) ms average" -ForegroundColor Green
    }
    
    # TCP test
    $TCPTest = Test-NetConnection -ComputerName "microsoft.com" -Port 443 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($TCPTest.TcpTestSucceeded) {
        Write-Host "  ✓ TCP Connectivity: OK" -ForegroundColor Green
    }
    
} catch {
    Write-Host "  ✗ Live test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Final verdict
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
if ($AllPresent -and $PingResult -and $Adapters) {
    Write-Host "✓ ALL CHECKS PASSED" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The monitoring script should work correctly." -ForegroundColor Green
    Write-Host ""
    Write-Host "To test with any reachable host:" -ForegroundColor Yellow
    Write-Host ".\Monitor-AVDConnection.ps1 -SessionHostFQDN ""microsoft.com"" -IntervalSeconds 10" -ForegroundColor White
    Write-Host ""
    Write-Host "To test with your AVD session host:" -ForegroundColor Yellow
    Write-Host ".\Monitor-AVDConnection.ps1 -SessionHostFQDN ""your-avd-host.domain.com"" -IntervalSeconds 10 -AlertOnFailure" -ForegroundColor White
} else {
    Write-Host "✗ SOME CHECKS FAILED" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Review the errors above before running the monitoring script." -ForegroundColor Yellow
}
Write-Host ""
