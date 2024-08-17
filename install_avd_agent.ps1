# Parameters
param (
    [string]$registrationToken
)

# Variables
$agentUrl = "https://aka.ms/avdagent"
$bootloaderUrl = "https://aka.ms/avdbootloader"
$rdpPropertiesUrl = "https://aka.ms/avdrdpinstaller"
$installPath = "C:\AVDInstallers"
$registrationScriptPath = "C:\AVDInstallers\Register-VM.ps1"

# Create directory if not exists
if (-not (Test-Path $installPath)) {
    New-Item -Path $installPath -ItemType Directory -ErrorAction Stop
    Write-Output "Created directory: $installPath"
}

# Download installers
Write-Output "Downloading AVD Agent..."
Invoke-WebRequest -Uri $agentUrl -OutFile "$installPath\avdagent.msi" -ErrorAction Stop
Write-Output "Downloading Bootloader..."
Invoke-WebRequest -Uri $bootloaderUrl -OutFile "$installPath\avdbootloader.msi" -ErrorAction Stop
Write-Output "Downloading RDP Properties..."
Invoke-WebRequest -Uri $rdpPropertiesUrl -OutFile "$installPath\avdrdpinstaller.msi" -ErrorAction Stop

# Install the AVD Agent, Bootloader, and RDP Properties
Write-Output "Installing AVD Agent..."
Start-Process msiexec.exe -ArgumentList "/i $installPath\avdagent.msi /quiet /norestart" -Wait -ErrorAction Stop
Write-Output "Installing Bootloader..."
Start-Process msiexec.exe -ArgumentList "/i $installPath\avdbootloader.msi /quiet /norestart" -Wait -ErrorAction Stop
Write-Output "Installing RDP Properties..."
Start-Process msiexec.exe -ArgumentList "/i $installPath\avdrdpinstaller.msi /quiet /norestart" -Wait -ErrorAction Stop

# Prepare registration script
$registrationScriptContent = @"
param (
    [string]`$registrationToken
)

# Ensure the required module is available and import it
if (-not (Get-Module -ListAvailable -Name RemoteDesktop)) {
    Write-Error "The RemoteDesktop module is not available. Please install it and try again."
    exit 1
}

Import-Module RemoteDesktop -ErrorAction Stop

# Register the VM to the AVD Host Pool
Write-Output "Registering the VM to the AVD Host Pool..."
Add-RdsRegistrationInfo -RegistrationToken `$registrationToken -RoleType RdsAgent -ErrorAction Stop
Write-Output "VM successfully registered to the AVD Host Pool."
"@

# Save the registration script to a file
$registrationScriptContent | Out-File -FilePath $registrationScriptPath -Encoding UTF8

# Execute the registration script
Write-Output "Starting registration script..."
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $registrationScriptPath -registrationToken $registrationToken" -NoNewWindow -Wait

Write-Output "Installation and registration process completed."
