<#
.SYNOPSIS
    Deploys the Azure CycleCloud MSP Training Lab environment on Azure.
.DESCRIPTION
    This script automates resource group creation, SSH key generation, Bicep template deployment,
    and RBAC role assignment for the CycleCloud server Managed Identity.
.EXAMPLE
    .\deploy-lab.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" -Location "koreacentral"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-cyclecloud-training",

    [Parameter(Mandatory=$false)]
    [string]$Location = "koreacentral",

    [Parameter(Mandatory=$false)]
    [string]$KeyPath = "..\keys\cyclecloud_rsa"
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Azure CycleCloud Training Lab Deployment Script" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# 1. Azure Login Check
Write-Host "`n[1/6] Checking Azure CLI authentication..." -ForegroundColor Yellow
$account = az account show --output json 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Azure CLI is not logged in. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

if ($SubscriptionId) {
    Write-Host "Setting subscription to: $SubscriptionId" -ForegroundColor Gray
    az account set --subscription $SubscriptionId
} else {
    Write-Host "Using active subscription: $($account.name) ($($account.id))" -ForegroundColor Gray
    $SubscriptionId = $account.id
}

# 2. Accept Marketplace Terms (First-time deployment)
Write-Host "`n[2/6] Accepting Azure CycleCloud Marketplace terms..." -ForegroundColor Yellow
try {
    az vm image terms accept --urn azurecyclecloud:azure-cyclecloud:cyclecloud8-gen2:latest --output none
    Write-Host "Marketplace terms accepted." -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not accept marketplace terms automatically or terms already accepted." -ForegroundColor Gray
}

# 3. Prepare SSH Key
Write-Host "`n[3/6] Ensuring SSH keypair exists..." -ForegroundColor Yellow
$keyDir = Split-Path -Path $KeyPath -Parent
if (-not (Test-Path $keyDir)) {
    New-Item -ItemType Directory -Path $keyDir -Force | Out-Null
}

if (-not (Test-Path $KeyPath)) {
    Write-Host "Generating SSH key at $KeyPath..." -ForegroundColor Gray
    ssh-keygen -t rsa -b 4096 -f $KeyPath -N '""' | Out-Null
}
$pubKey = (Get-Content "$KeyPath.pub" -Raw).Trim()

# 4. Get Current Client IP for NSG SSH Access
Write-Host "`n[4/6] Fetching current public IP..." -ForegroundColor Yellow
try {
    $myIp = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5).Trim()
    $allowedCidr = "$myIp/32"
    Write-Host "Allowed SSH Source IP set to: $allowedCidr" -ForegroundColor Gray
} catch {
    $allowedCidr = "*"
    Write-Host "Warning: Could not fetch public IP. Setting SSH CIDR to '*'" -ForegroundColor Yellow
}

# 5. Create Resource Group and Deploy Bicep
Write-Host "`n[5/6] Deploying infrastructure via Bicep template..." -ForegroundColor Yellow
Write-Host "Creating Resource Group: $ResourceGroupName in $Location..." -ForegroundColor Gray
az group create --name $ResourceGroupName --location $Location --output table

$scriptDir = $PSScriptRoot
$bicepFile = Join-Path $scriptDir "main.bicep"

Write-Host "Deploying main.bicep..." -ForegroundColor Gray
$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --name "cyclecloud-lab-deploy" `
    --template-file $bicepFile `
    --parameters adminSshPublicKey="$pubKey" allowedSshCidr="$allowedCidr" `
    --output json | ConvertFrom-Json

$outputs = $deployment.properties.outputs
$principalId = $outputs.principalId.value
$portalUrl = $outputs.portalUrl.value
$serverIp = $outputs.serverPublicIp.value

# 6. Assign Contributor Role to Managed Identity
Write-Host "`n[6/6] Assigning 'Contributor' role to CycleCloud Managed Identity..." -ForegroundColor Yellow
Write-Host "Principal ID: $principalId Scope: /subscriptions/$SubscriptionId" -ForegroundColor Gray

Start-Sleep -Seconds 5
az role assignment create `
    --assignee-object-id $principalId `
    --assignee-principal-type ServicePrincipal `
    --role "Contributor" `
    --scope "/subscriptions/$SubscriptionId" `
    --output table

Write-Host "`n=====================================================" -ForegroundColor Green
Write-Host " Lab Environment Deployment Completed Successfully!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green
Write-Host " CycleCloud Portal URL : $portalUrl" -ForegroundColor Cyan
Write-Host " Server Public IP     : $serverIp" -ForegroundColor Cyan
Write-Host " Resource Group       : $ResourceGroupName" -ForegroundColor Cyan
Write-Host " SSH Command          : ssh -i $KeyPath azureadmin@$serverIp" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Green
