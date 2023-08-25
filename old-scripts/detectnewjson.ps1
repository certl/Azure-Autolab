$azContext = "Solutions Architects"
$path = 'C:\ConvertedJSON\'
$bicepFilePath = 'C:\Users\christoph\Desktop\autolab\main.bicep'
$deploymentName = 'nasuni-deployment'
$tenantid = "93fd6cd2-9afa-4683-9e50-dd57622e829a"
$appId = "d687ac26-85fa-4c6d-9fb3-1ec3f2ddf041"
$certificatePath = "C:\\Users\\christoph\\tmpr6xcsuth.pem"
#$adminPassword = '$uper$secure123!'
$processedFiles = @()

function GeneratePassword {
    param (
        [Parameter(Mandatory = $true)]
        [int]$length
    )

    $alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    $password = ""
    for ($i = 0; $i -lt $length; $i++) {
        $password += $alphabet[(Get-Random -Maximum $alphabet.Length)]
    }
    Write-Host "Generated Password: $password"
    
    return $password
}

function ConvertTo-JsonAndSave {
    param(
        [Parameter(Mandatory=$true)][string]$string1,
        [Parameter(Mandatory=$true)][string]$string2,
        [Parameter(Mandatory=$true)][string]$string3,
        [Parameter(Mandatory=$true)][string]$filePath,
        [Parameter(Mandatory=$true)][string]$blobName
    )

    $jsonObject = @{
        "String1" = $string1
        "String2" = $string2
        "String3" = $string3
    } | ConvertTo-Json

    try {
        $jsonObject | Out-File -FilePath $filePath -Force
        Write-Host "JSON file saved successfully at $filePath"
        
        # Create an Azure Storage context
        $context = New-AzStorageContext -StorageAccountName "pocrecords" -StorageAccountKey "fWB6bc0rUsdukNWPf6Hx+GzHu95qHqvLrghUnjkENSCGDwKTR2ivCJTOQPLg6W6du2AqN5d4g4Rm+AStGc9phg=="

        # Upload the file to Azure Blob Storage
        Set-AzStorageBlobContent -File $filePath -Container "completedpocjsons" -Blob $blobName -Context $context -Force

        Write-Host "JSON file uploaded successfully to Azure Blob Storage at $containerName/$blobName"
    }
    catch {
        Write-Host "An error occurred: $_"
    }
}

Connect-AzAccount -ServicePrincipal -ApplicationId $appId -TenantId $tenantid -CertificatePath $certificatePath

while ($true) {
    Get-ChildItem -Path $path -File | ForEach-Object {
        if ($_.FullName -notin $processedFiles) {
            $name = $_.Name
            $timeStamp = Get-Date
            Write-Host "The file '$name' was uploaded at $timeStamp"
			
			$jsonFilePath = $path + $name
			$jsonFileRaw = Get-Content -Path $jsonFilePath -Raw
			$base64String = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($jsonFileRaw))	
						
            $resourceGroup = $name.Replace('.json', '')
            Write-Host "Checking availability of the resource group '$resourceGroup'..."

            do {
                $groupExists = (az group exists --name $resourceGroup)
                if (-Not ($groupExists -eq 'true')) {
                    Start-Sleep -Seconds 5
                }
            } until ($groupExists -eq 'true')
            
            Write-Host "Resource group '$resourceGroup' is available."
            try {
				$generatedPassword = GeneratePassword -length 24

                $parameterObject = @{
                    adminPassword = $generatedPassword
                    jsonString = $base64String
                }

                Write-Host "Created parameter object: $parameterObject "
                
                $deployment = New-AzResourceGroupDeployment  -ResourceGroupName $resourceGroup -name $deploymentName -TemplateFile $bicepFilePath -DeploymentDebugLogLevel all -Mode Complete -Force -TemplateParameterObject $parameterObject
                
                Write-Host "Deployment result: " + $deployment.OutputsString

                # az deployment group create `
                #     --resource-group $resourceGroup `
                #     --name $deploymentName `
                #     --template-file $bicepFilePath `
                #     --parameters adminPassword=$generatedPassword jsonString=$base64String
				
				# $deploymentOutput = az deployment group show `
				# 	--name $deploymentName `
				# 	--resource-group $resourceGroup `
				# 	--query "properties.outputs" `
				# 	| ConvertFrom-Json

				# $publicIPResourceId = $deploymentOutput.windowsPublicIPId.value

				# Get public IP address
				#$publicIPAddress = az network public-ip show --ids $publicIPResourceId --query "ipAddress" --output tsv

                $publicIPAddress = (Get-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name "windowsVM-publicIP").ipAddress

				Write-Host "PublicIP: $publicIPAddress"
				Write-Host "Password: $generatedPassword"
				
				ConvertTo-JsonAndSave -string1 $resourceGroup -string2 $publicIPAddress -string3 $generatedPassword -filePath "C:\CompletedRequests\$resourceGroup.json" -blobName "$resourceGroup.json"
				
            } catch {
                Write-Host "Failed to deploy the template. Error: $_"
            }
            # Add the processed file to the list
			
            $processedFiles += $_.FullName
        }
    }
    # Sleep for a bit before the next check
    Start-Sleep -Seconds 10
}


