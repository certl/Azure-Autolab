# Import the required module
Import-Module Az

# Set your storage account and container details
$storageAccountName = "pocrecords"
$containerName = "uploadedexcels"
# $jsonContainerName = "convertedjsons"

$destinationPath = "C:\DownloadedBlobs\"
$storageAccountKey = "fWB6bc0rUsdukNWPf6Hx+GzHu95qHqvLrghUnjkENSCGDwKTR2ivCJTOQPLg6W6du2AqN5d4g4Rm+AStGc9phg=="
$convertedPath = "C:\ConvertedJSON\"

# Create a storage context
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# Initialize last check time
$lastCheckTime = Get-Date

# Define the interval for checking new blobs (In seconds)
$interval = 60

# Enter an infinite loop
while($true) {
    try {
        # Get all blobs that were created after the last check
        $blobs = Get-AzStorageBlob -Container $containerName -Context $context | Where-Object { $_.LastModified -gt $lastCheckTime }

        # Download each new blob
        foreach($blob in $blobs) {
            Get-AzStorageBlobContent -Blob $blob.Name -Container $containerName -Destination $destinationPath -Context $context -Force

            # Check if the blob is an Excel file
            if($blob.Name -match "\.xlsx?$") {
                # Convert Excel file to JSON
                $filePath = Join-Path -Path $destinationPath -ChildPath $blob.Name
                $excelContent = Import-Excel -Path $filePath
                $jsonContent = $excelContent | ConvertTo-Json

                # Save the JSON file
                $jsonFilePath = Join-Path -Path $convertedPath -ChildPath ($blob.Name -replace "\.xlsx?$", ".json")
                $jsonContent | Set-Content -Path $jsonFilePath
				
				# Upload the JSON file to the Azure Blob Storage
                # Set-AzStorageBlobContent -File $jsonFilePath -Container $jsonContainerName -Blob ($blob.Name -replace "\.xlsx?$", ".json") -Context $context -Force
            }
        }
        # Update the last check time
        $lastCheckTime = Get-Date
		Start-Sleep -Seconds $interval

    }
    catch {
        Write-Error "Error downloading blob: $_"
    }
}