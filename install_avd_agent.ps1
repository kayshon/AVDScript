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

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $logFile = "C:\AVDInstallers\install_log.txt"
    $message | Out-File -Append -FilePath $logFile
    Write-Output $message
}

# Create directory if not exists
if (-not (Test-Path $installPath)) {
    New-Item -Path $installPath -ItemType Directory -ErrorAction Stop
    Log-Message "Created directory: $installPath"
}

# Download installers
try {
    Log-Message "Downloading AVD Agent..."
    Invoke-WebRequest -Uri $agentUrl -OutFile "$installPath\avdagent.msi" -ErrorAction Stop
    Log-Message "Downloading Bootloader..."
    Invoke-WebRequest -Uri $bootloaderUrl -OutFile "$installPath\avdbootloader.msi" -ErrorAction Stop
    Log-Message "Downloading RDP Properties..."
    Invoke-WebRequest -Uri $rdpPropertiesUrl -OutFile "$installPath\avdrdpinstaller.msi" -ErrorAction Stop
} catch {
    Log-Message "Failed to download one or more installers: $_"
    exit 1
}

# Install the AVD Agent, Bootloader, and RDP Properties
try {
    Log-Message "Installing AVD Agent..."
    Start-Process msiexec.exe -ArgumentList "/i $installPath\avdagent.msi /quiet /norestart" -Wait -ErrorAction Stop
    Log-Message "Installing Bootloader..."
    Start-Process msiexec.exe -ArgumentList "/i $installPath\avdbootloader.msi /quiet /norestart" -Wait -ErrorAction Stop
    Log-Message "Installing RDP Properties..."
    Start-Process msiexec.exe -ArgumentList "/i $installPath\avdrdpinstaller.msi /quiet /norestart" -Wait -ErrorAction Stop
} catch {
    Log-Message "Failed to install one or more components: $_"
    exit 1
}

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
try {
    Log-Message "Starting registration script..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $registrationScriptPath -registrationToken $registrationToken" -NoNewWindow -Wait
    Log-Message "Registration script execution completed."
} catch {
    Log-Message "Failed to execute the registration script: $_"
}
