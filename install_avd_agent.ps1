# Variables
$agentUrl = "https://aka.ms/avdagent"
$bootloaderUrl = "https://aka.ms/avdbootloader"
$rdpPropertiesUrl = "https://aka.ms/avdrdpinstaller"

# Path to save installers
$installPath = "C:\AVDInstallers"

# Create directory if not exists
if (-not (Test-Path $installPath)) {
    New-Item -Path $installPath -ItemType Directory
}

# Download installers
Invoke-WebRequest -Uri $agentUrl -OutFile "$installPath\avdagent.msi"
Invoke-WebRequest -Uri $bootloaderUrl -OutFile "$installPath\avdbootloader.msi"
Invoke-WebRequest -Uri $rdpPropertiesUrl -OutFile "$installPath\avdrdpinstaller.msi"

# Install the AVD Agent, Bootloader, and RDP Properties
Start-Process msiexec.exe -ArgumentList "/i $installPath\avdagent.msi /quiet /norestart" -Wait
Start-Process msiexec.exe -ArgumentList "/i $installPath\avdbootloader.msi /quiet /norestart" -Wait
Start-Process msiexec.exe -ArgumentList "/i $installPath\avdrdpinstaller.msi /quiet /norestart" -Wait

# Get the registration token from the argument passed to the script
param (
    [string]$registrationToken
)

# Register the VM to the AVD Host Pool
$registerCommand = "Add-RdsRegistrationInfo -RegistrationToken $registrationToken -RoleType RdsAgent"
Invoke-Expression $registerCommand
