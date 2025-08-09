# PowerShell Install Script for Posh-Git, Oh My Posh, and Terminal-Icons
# Usage: Run in elevated PowerShell (Run as Administrator) or with:
# curl -L https://yourdomain.com/setup.ps1 | pwsh

Write-Host "=== PowerShell Environment Setup ===" -ForegroundColor Cyan

# Function to check if a module is installed
function Is-ModuleInstalled($moduleName) {
    return @(Get-Module -ListAvailable -Name $moduleName).Count -gt 0
}

# Install Posh-Git
if (-not (Is-ModuleInstalled "posh-git")) {
    Write-Host "Installing posh-git..." -ForegroundColor Yellow
    Install-Module posh-git -Scope CurrentUser -Force
} else {
    Write-Host "posh-git already installed. Skipping." -ForegroundColor Green
}

# Install Oh My Posh
if (-not (Is-ModuleInstalled "oh-my-posh")) {
    Write-Host "Installing oh-my-posh..." -ForegroundColor Yellow
    Install-Module oh-my-posh -Scope CurrentUser -Force
} else {
    Write-Host "oh-my-posh already installed. Skipping." -ForegroundColor Green
}

# Install Terminal-Icons
if (-not (Is-ModuleInstalled "Terminal-Icons")) {
    Write-Host "Installing Terminal-Icons..." -ForegroundColor Yellow
    Install-Module Terminal-Icons -Scope CurrentUser -Force
} else {
    Write-Host "Terminal-Icons already installed. Skipping." -ForegroundColor Green
}

# Update PowerShell Profile
$profileContent = @"
Import-Module posh-git
Import-Module oh-my-posh
Import-Module Terminal-Icons
Set-PoshPrompt -Theme paradox
"@

if (-not (Test-Path $PROFILE)) {
    New-Item -Type File -Path $PROFILE -Force | Out-Null
}

if (-not (Select-String -Path $PROFILE -Pattern "Import-Module posh-git" -Quiet)) {
    Add-Content -Path $PROFILE -Value $profileContent
    Write-Host "Profile updated with Posh-Git, Oh My Posh, and Terminal-Icons." -ForegroundColor Cyan
} else {
    Write-Host "Profile already configured. Skipping." -ForegroundColor Green
}

Write-Host "=== Setup Complete! Restart PowerShell to apply changes. ===" -ForegroundColor Magenta
