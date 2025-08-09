# Windows PowerShell Posh-Git, Oh My Posh, and Terminal-Icons Installer

# Ensure script is run in elevated mode
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    exit
}

# Set execution policy for current process
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Function to install a PowerShell module if not already installed
function Install-IfMissing {
    param (
        [string]$ModuleName
    )
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Write-Host "$ModuleName is already installed. Skipping..." -ForegroundColor Yellow
    } else {
        Write-Host "Installing $ModuleName..." -ForegroundColor Cyan
        Install-Module $ModuleName -Scope CurrentUser -Force
    }
}

# Install required modules
Install-IfMissing "posh-git"
Install-IfMissing "oh-my-posh"
Install-IfMissing "Terminal-Icons"

# Update PowerShell profile with module imports
$profilePath = $PROFILE
if (!(Test-Path -Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$profileContent = Get-Content $profilePath -ErrorAction SilentlyContinue
$linesToAdd = @(
    'Import-Module posh-git',
    'Import-Module oh-my-posh',
    'Import-Module Terminal-Icons',
    'Set-PoshPrompt -Theme Paradox'
)

foreach ($line in $linesToAdd) {
    if (-not ($profileContent -match [regex]::Escape($line))) {
        Add-Content -Path $profilePath -Value $line
        Write-Host "Added to profile: $line" -ForegroundColor Green
    }
}

Write-Host "`nSetup complete! Restart PowerShell to apply changes." -ForegroundColor Magenta
