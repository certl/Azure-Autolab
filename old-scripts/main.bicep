param location string = 'eastus'
//param vmName string = 'nasuniedge'
param windowsVMName string = 'windowsVM'
param adminUsername string = 'adminuser'
@secure()
param adminPassword string
param jsonString string
// param workspaceName string = 'myLogAnalyticsWorkspace'
param legalNoticeScriptUri string = 'https://nasuniscriptspublic.blob.core.windows.net/scripts/master.ps1'


resource myVnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: 'myVnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.6.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.6.0.0/24'
        }
      }
    ]
  }
}

resource edgeNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'edgeNSG'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Web_Access'
        properties: {
          priority: 120
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Admin'
        properties: {
          priority: 110
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8443'
        }
      }
    ]
  }
}

resource edgeNic 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: 'edgeNIC'
  location: location
  dependsOn: [
    myVnet
    edgeNsg
  ]
  properties: {
    networkSecurityGroup: {
      id: edgeNsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
		  privateIPAddress: '10.6.0.6'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'myVnet', 'default')
          }
        }
      }
    ]
  }
}

resource nasuniedge 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'nasuniedge'
  location: location
  plan: {
    name: 'nasuni-nea-99-prod'
    publisher: 'nasunicorporation'
    product: 'nasuni-nea-90-prod'
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    edgeNic
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D8s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'nasunicorporation'
        offer: 'nasuni-nea-90-prod'
        sku: 'nasuni-nea-99-prod'
        version: 'latest'
      }
      osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: 1024
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      ]
    }
    osProfile: {
      computerName: 'nasuniedge'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: edgeNic.id
        }
      ]
    }
  }
}

resource nmcNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nmcNsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Web_Access'
        properties: {
          priority: 120
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Admin'
        properties: {
          priority: 110
          protocol: 'TCP'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8443'
        }
      }
    ]
  }
}

resource nmcNic 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: 'nmcNic'
  location: location
  dependsOn: [
    myVnet
    nmcNsg
  ]
  properties: {
    networkSecurityGroup: {
      id: nmcNsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
		  privateIPAddress: '10.6.0.5'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'myVnet', 'default')
          }
        }
      }
    ]
  }
}

resource nmc 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'nmc'
  location: location
  plan: {
    name: 'nasuni-nmc-223-prod'
    publisher: 'nasunicorporation'
    product: 'nasuni-management-console'
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    nmcNic
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4s_v4'
    }
    storageProfile: {
      imageReference: {
        publisher: 'nasunicorporation'
        offer: 'nasuni-management-console'
        sku: 'nasuni-nmc-223-prod'
        version: 'latest'
      }
      osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
      }
    }
    osProfile: {
      computerName: 'nmc'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nmcNic.id
        }
      ]
    }
  }
}

resource windowsNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'windowsNsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource windowsPublicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'windowsVM-publicIP'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  sku: {
    name: 'Basic'
  }
}

resource windowsNic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'windowsNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
		  privateIPAddress: '10.6.0.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: myVnet.properties.subnets[0].id
          }
          // privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: windowsPublicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: windowsNsg.id
    }
  }
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: windowsVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: 'windowsVM'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: windowsNic.id
        }
      ]
    }
  }
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${windowsVM.name}/CustomScriptExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [legalNoticeScriptUri]
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File master.ps1 -Password "${adminPassword}" -jsonString "${jsonString}'
    }
  }
}

output windowsPublicIPId string = windowsPublicIP.id
