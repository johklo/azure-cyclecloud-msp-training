<#
.SYNOPSIS
    Deallocates or deletes the Azure CycleCloud MSP Training Lab environment.
.EXAMPLE
    .\destroy-lab.ps1 -Mode "Deallocate" # Stop VM to prevent compute costs
    .\destroy-lab.ps1 -Mode "Delete"     # Delete Resource Group completely
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("Deallocate", "Delete")]
    [string]$Mode = "Deallocate",

    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-cyclecloud-training"
)

$ErrorActionPreference = "Stop"

if ($Mode -eq "Deallocate") {
    Write-Host "Deallocating VM 'cc-server' in $ResourceGroupName to stop compute billing..." -ForegroundColor Yellow
    az vm deallocate -g $ResourceGroupName -n cc-server --output table
    Write-Host "Server VM deallocated successfully." -ForegroundColor Green
} elseif ($Mode -eq "Delete") {
    Write-Host "Deleting Resource Group '$ResourceGroupName' completely..." -ForegroundColor Red
    az group delete -n $ResourceGroupName --yes --no-wait
    Write-Host "Resource Group deletion initiated in background." -ForegroundColor Green
}
