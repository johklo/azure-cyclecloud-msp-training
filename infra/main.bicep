// =====================================================================
//  Azure CycleCloud - Training environment (application server)
//  Deploys: VNet + NSG, public IP (with DNS), CycleCloud 8 server VM
//           (system-assigned + user-assigned managed identity),
//           storage account locker (private endpoint + private DNS),
//           role assignments, blob private endpoint.
//  Scope  : resourceGroup
//
//  NOTE: This subscription enforces Azure Policy that forces storage
//  accounts to publicNetworkAccess=Disabled and allowSharedKeyAccess=false.
//  CycleCloud therefore CANNOT use a shared-key locker over the public
//  endpoint. This template provisions:
//    * a user-assigned managed identity (UAMI) for the locker, attached
//      to the server VM and granted "Storage Blob Data Contributor",
//    * a blob private endpoint + private DNS zone so the server and
//      compute nodes reach the locker privately.
//  When creating the CycleCloud account, use LockerAuthMode=ManagedIdentity
//  and LockerIdentity=<lockerIdentityResourceId output>.
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
var lockerIdentityName = '${namePrefix}-locker-id'
var dnsLabel = '${namePrefix}-cyclecloud-${substring(suffix, 0, 6)}'
var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
// Built-in role definition IDs
var contributorRoleId = 'b24988ac-6180-42a0-af88-46d3c6c8b84a'
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var imagePlan = {
  name: 'cyclecloud8-gen2'
  publisher: 'azurecyclecloud'
  product: 'azure-cyclecloud'
}

// --- User-assigned identity used by the CycleCloud storage locker -----
// Attached to the server VM AND to every compute node so both can reach
// the blob locker with Entra auth (no account keys).
resource lockerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: lockerIdentityName
  location: location
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
    allowSharedKeyAccess: false
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
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
          privateEndpointNetworkPolicies: 'Disabled'
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

// --- Blob private endpoint + private DNS (locker over private network) -
resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: blobPrivateDnsZoneName
  location: 'global'
}

resource blobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: blobPrivateDnsZone
  name: '${namePrefix}-blob-dnslink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${namePrefix}-blob-pe'
  location: location
  properties: {
    subnet: {
      id: '${vnet.id}/subnets/cyclecloud'
    }
    privateLinkServiceConnections: [
      {
        name: '${namePrefix}-blob-conn'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [ 'blob' ]
        }
      }
    ]
  }
}

resource blobDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: blobPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: {
          privateDnsZoneId: blobPrivateDnsZone.id
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
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${lockerIdentity.id}': {}
    }
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

// --- Role assignments -------------------------------------------------
// Server system-assigned identity: Contributor on this resource group so
// CycleCloud can create compute VMs/disks/NICs here.
resource vmContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vm.id, contributorRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Locker UAMI: data-plane blob access to the storage locker.
resource lockerBlobRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, lockerIdentity.id, storageBlobDataContributorRoleId)
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: lockerIdentity.properties.principalId
    principalType: 'ServicePrincipal'
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
output lockerIdentityResourceId string = lockerIdentity.id
output lockerIdentityClientId string = lockerIdentity.properties.clientId
output lockerIdentityPrincipalId string = lockerIdentity.properties.principalId
