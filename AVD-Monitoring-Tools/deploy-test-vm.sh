#!/bin/bash
# Quick Azure VM Deployment for Testing AVD Monitoring Script
# This creates a simple Windows VM with RDP enabled for testing

# Variables - CHANGE THESE
RESOURCE_GROUP="rg-avd-monitor-test"
LOCATION="westus2"
VM_NAME="vm-test-monitor"
VM_SIZE="Standard_B2s"  # Small, cheap VM
ADMIN_USERNAME="avdadmin"
ADMIN_PASSWORD="TestP@ssw0rd123!"  # Change this!

echo "Creating test environment for AVD monitoring script validation..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "VM Name: $VM_NAME"
echo ""

# Create resource group
echo "Creating resource group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Create VM with public IP and RDP enabled
echo "Creating Windows VM (this takes ~5 minutes)..."
az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --image Win2022Datacenter \
    --size $VM_SIZE \
    --admin-username $ADMIN_USERNAME \
    --admin-password $ADMIN_PASSWORD \
    --public-ip-sku Standard \
    --nsg-rule RDP

# Get the public IP and FQDN
echo ""
echo "Getting VM connection details..."
VM_PUBLIC_IP=$(az vm show -d \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --query publicIps -o tsv)

VM_FQDN=$(az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name "${VM_NAME}PublicIP" \
    --query dnsSettings.fqdn -o tsv)

echo ""
echo "=========================================="
echo "VM DEPLOYED SUCCESSFULLY!"
echo "=========================================="
echo "VM Name: $VM_NAME"
echo "Public IP: $VM_PUBLIC_IP"
echo "FQDN: $VM_FQDN"
echo "Username: $ADMIN_USERNAME"
echo "Password: $ADMIN_PASSWORD"
echo ""
echo "Test your monitoring script with:"
echo ".\Monitor-AVDConnection.ps1 -SessionHostFQDN \"$VM_FQDN\" -IntervalSeconds 10 -AlertOnFailure"
echo ""
echo "Or use the IP address:"
echo ".\Monitor-AVDConnection.ps1 -SessionHostFQDN \"$VM_PUBLIC_IP\" -IntervalSeconds 10 -AlertOnFailure"
echo ""
echo "=========================================="
echo "CLEANUP: When done testing, delete the resource group:"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo "=========================================="
