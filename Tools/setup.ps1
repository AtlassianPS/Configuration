[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
param()

# hide progress bars on linux/macOS
# as they mess with the CI's console
$originalProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

# If PowerShellGet is not available (PSv4 and PSv3), it must be installed
if ($PSVersionTable.PSVersion.Major -in @(3, 4)) {
    if (-not (Get-Module PowerShellGet -ListAvailable)) {
        Write-Host "Installing PowershellGet"
        Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList "/qn /quiet /i $(Join-Path $PSScriptRoot "PackageManagement_x64.msi")" -Wait
        $null = Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
    }
}

# Fail if PowerShellGet could not be found
Import-Module PowerShellGet -ErrorAction SilentlyContinue
if (-not (Get-Module PowerShellGet)) {
    throw "PowerShellGet still not available"
}

# PowerShell 5.1 and bellow need the PSGallery to be intialized
if (-not ($gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PackageProvider NuGet"
    $null = Install-PackageProvider -Name NuGet -Force -ErrorAction SilentlyContinue
}

# Make PSGallery trusted, to aviod a confirmation in the console
if (-not ($gallery.Trusted)) {
    Write-Host "Trusting PSGallery"
    # Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
}

$ismoProp = @{
    Scope = "CurrentUser"
    # ErrorAction = "Stop"
    Force = $true
}

$ConfigurationConditions = @{
    Minimum = "1.0"
    ForceBootstrap = $true
}
if ($PSVersionTable.PSVersion.Major -ge 5) {
    # PSv4 does not have the `-AllowClobber` parameter
    $ConfigurationConditions["SkipPublisherCheck"] = $true
}
Write-Host "Installing Configuration"
Install-Module "Configuration" @ismoProp @ConfigurationConditions

$pesterConditions = @{
    Minimum = "4.0"
}
if ($PSVersionTable.PSVersion.Major -ge 5) {
    # PSv4 does not have the `-SkipPublisherCheck` parameter
    $pesterConditions["SkipPublisherCheck"] = $true
}
Write-Host "Installing Pester"
Install-Module "Pester" @ismoProp @pesterConditions
