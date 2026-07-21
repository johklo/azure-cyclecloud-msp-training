// =====================================================================
//  Azure CycleCloud - Training environment (application server)
//  Deploys: VNet + NSG, public IP (with DNS), CycleCloud 8 server VM
//           (system-assigned managed identity), storage account locker
//  Scope  : resourceGroup
// =====================================================================

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Short prefix used to name resources.')
@minLength(2)
@maxLength(8)
param namePrefix string = 'cc'

@description('Admin username for the CycleCloud server VM.')
param adminUsername string = 'azureadmin'

@description('SSH public key used for the admin account.')
@secure()
param adminSshPublicKey string

@description('VM size for the CycleCloud application server.')
param vmSize string = 'Standard_D4s_v5'

@description('Marketplace image version, e.g. "latest" or "8.9.120260630".')
param imageVersion string = 'latest'

@description('Source address/CIDR allowed to reach SSH (22). Use your public IP.')
param allowedSshCidr string = '*'

@description('Source address/CIDR allowed to reach the CycleCloud portal (443).')
param allowedHttpsCidr string = 'Internet'

@description('OS disk size in GB for the CycleCloud server.')
param osDiskSizeGb int = 128

// ---------------------------------------------------------------------
var suffix = toLower(uniqueString(resourceGroup().id))
var storageName = toLower('${namePrefix}lk${substring(suffix, 0, 10)}')
var vmName = '${namePrefix}-server'
var dnsLabel = '${namePrefix}-cyclecloud-${substring(suffix, 0, 6)}'
var imagePlan = {
  name: 'cyclecloud8-gen2'
  publisher: 'azurecyclecloud'
  product: 'azure-cyclecloud'
}

// --- Storage account (CycleCloud "locker" for projects/blobs) ---------
resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
}

resource lockerContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'cyclecloud'
  properties: {
    publicAccess: 'None'
  }
}

// --- Network security group ------------------------------------------
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: '${namePrefix}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedHttpsCidr
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedHttpsCidr
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
      {
        name: 'Allow-SSH'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: allowedSshCidr
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

// --- Virtual network + subnet ----------------------------------------
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${namePrefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.0.0.0/16' ]
    }
    subnets: [
      {
        name: 'cyclecloud'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'compute'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

// --- Public IP -------------------------------------------------------
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${namePrefix}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsLabel
    }
  }
}

// --- Network interface -----------------------------------------------
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${namePrefix}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/cyclecloud'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

// --- CycleCloud application server VM --------------------------------
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  plan: imagePlan
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'azurecyclecloud'
        offer: 'azure-cyclecloud'
        sku: 'cyclecloud8-gen2'
        version: imageVersion
      }
      osDisk: {
        createOption: 'FromImage'
        diskSizeGB: osDiskSizeGb
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// ---------------------------------------------------------------------
output vmName string = vm.name
output principalId string = vm.identity.principalId
output publicFqdn string = publicIp.properties.dnsSettings.fqdn
output publicIp string = publicIp.properties.ipAddress
output portalUrl string = 'https://${publicIp.properties.dnsSettings.fqdn}'
output storageAccountName string = storage.name
output adminUsername string = adminUsername
