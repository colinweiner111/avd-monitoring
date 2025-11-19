# Quick Azure VM Deployment for Testing AVD Monitoring Script
# This creates a simple Windows VM with RDP enabled for testing

# Variables - CHANGE THESE
$ResourceGroup = "rg-avd-monitor-test"
$Location = "westus2"
$VMName = "vm-test-monitor"
$VMSize = "Standard_B2s"  # Small, cheap VM (~$30/month if left running)
$AdminUsername = "avdadmin"
$AdminPassword = "TestP@ssw0rd123!"  # CHANGE THIS!

Write-Host "Creating test environment for AVD monitoring script validation..." -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host "Location: $Location" -ForegroundColor Yellow
Write-Host "VM Name: $VMName" -ForegroundColor Yellow
Write-Host ""

# Check if logged into Azure
try {
    $context = Get-AzContext -ErrorAction Stop
    Write-Host "✓ Already logged into Azure as: $($context.Account)" -ForegroundColor Green
}
catch {
    Write-Host "Not logged into Azure. Running Connect-AzAccount..." -ForegroundColor Yellow
    Connect-AzAccount
}

# Create resource group
Write-Host ""
Write-Host "Creating resource group..." -ForegroundColor Cyan
New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null

# Create VM credentials
$SecurePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($AdminUsername, $SecurePassword)

# Create VM with public IP and RDP enabled
Write-Host "Creating Windows VM (this takes ~5-8 minutes)..." -ForegroundColor Cyan
Write-Host "  - Installing Windows Server 2022" -ForegroundColor Gray
Write-Host "  - Opening RDP port 3389" -ForegroundColor Gray
Write-Host "  - Assigning public IP address" -ForegroundColor Gray

$VM = New-AzVM `
    -ResourceGroupName $ResourceGroup `
    -Location $Location `
    -Name $VMName `
    -Size $VMSize `
    -Image Win2022Datacenter `
    -Credential $Credential `
    -OpenPorts 3389 `
    -PublicIpAddressName "${VMName}-PublicIP" `
    -VirtualNetworkName "${VMName}-vnet" `
    -SubnetName "default" `
    -SecurityGroupName "${VMName}-nsg"

# Get connection details
Write-Host ""
Write-Host "Getting VM connection details..." -ForegroundColor Cyan
$PublicIP = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroup -Name "${VMName}-PublicIP"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "VM DEPLOYED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "VM Name:       " -NoNewline -ForegroundColor Yellow
Write-Host $VMName -ForegroundColor White
Write-Host "Public IP:     " -NoNewline -ForegroundColor Yellow
Write-Host $PublicIP.IpAddress -ForegroundColor White
Write-Host "Username:      " -NoNewline -ForegroundColor Yellow
Write-Host $AdminUsername -ForegroundColor White
Write-Host "Password:      " -NoNewline -ForegroundColor Yellow
Write-Host $AdminPassword -ForegroundColor White
Write-Host ""
Write-Host "Test your monitoring script with:" -ForegroundColor Cyan
Write-Host ".\Monitor-AVDConnection.ps1 -SessionHostFQDN ""$($PublicIP.IpAddress)"" -IntervalSeconds 10 -AlertOnFailure" -ForegroundColor White
Write-Host ""
Write-Host "Or test RDP connection first:" -ForegroundColor Cyan
Write-Host "mstsc /v:$($PublicIP.IpAddress)" -ForegroundColor White
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "ESTIMATED COST: ~$1/day if left running" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "When done testing, delete the resource group:" -ForegroundColor Red
Write-Host "Remove-AzResourceGroup -Name $ResourceGroup -Force" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Green
