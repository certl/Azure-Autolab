param (
    [Parameter(Mandatory=$true)]
    [string]$Password,

    [Parameter(Mandatory=$true)]
    [string]$jsonString
)

# $jsonStringConverted = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($jsonstring))

# Write the escaped JSON string to the output file

Install-WindowsFeature -name AD-Domain-Services -IncludeManagementTools

$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

# Define the URL of the PowerShell script in the Azure container
$scriptUrl = "https://nasuniscriptspublic.blob.core.windows.net/scripts/adscript-v2.ps1"
$checkUserUrl = "https://nasuniscriptspublic.blob.core.windows.net/scripts/CheckUser.ps1"

$configureneaUrl = "https://nasuniscriptspublic.blob.core.windows.net/scripts/configurenea.ps1"
$configurenmcUrl = "https://nasuniscriptspublic.blob.core.windows.net/scripts/configurenmc.ps1"

# Define the local path to save the downloaded script
$localPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.15\Downloads\0\adscript-v2.ps1"
$checkUserPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.15\Downloads\0\CheckUser.ps1"

$configureneaPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.15\Downloads\0\configurenea.ps1"
$configurenmcPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.15\Downloads\0\configurenmc.ps1"

# Download the script
Invoke-WebRequest -Uri $scriptUrl -OutFile $localPath
Invoke-WebRequest -Uri $checkUserUrl -OutFile $checkUserPath

Invoke-WebRequest -Uri $configureneaUrl -OutFile $configureneaPath
Invoke-WebRequest -Uri $configurenmcUrl -OutFile $configurenmcPath

$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-File `"C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.15\Downloads\0\CheckUser.ps1`""
$Trigger = New-ScheduledTaskTrigger -AtLogon
$User= "adminuser"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd
$Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType ServiceAccount
Register-ScheduledTask -TaskName "MyTask" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal

<#
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-File `"C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.15\Downloads\0\CheckUser.ps1`""
$Trigger = New-ScheduledTaskTrigger -AtStartup
$User= "adminuser"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd
$Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType Password
$Password = $SecurePassword
Register-ScheduledTask -TaskName "MyTask" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -User $User -Password $Password
#>

# Execute the downloaded script with the password argument
. $localPath -Password $SecurePassword -jsonString $jsonString
