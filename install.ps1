# Ensure running as admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    exit
}

Write-Host "Checking if Posh-Git is installed..."
if (-not (Get-Module -ListAvailable -Name Posh-Git)) {
    Install-Module Posh-Git -Scope CurrentUser -Force
    Write-Host "✅ Posh-Git installed."
} else {
    Write-Host "ℹ️ Posh-Git already installed. Skipping."
}

Write-Host "Checking if Oh My Posh is installed..."
if (-not (Get-Command oh-my-posh.exe -ErrorAction SilentlyContinue)) {
    winget install JanDeDobbeleer.OhMyPosh -s winget --silent
    Write-Host "✅ Oh My Posh installed."
} else {
    Write-Host "ℹ️ Oh My Posh already installed. Skipping."
}

# Import modules for current session
Import-Module Posh-Git
Write-Host "✅ Posh-Git imported."

# Configure Oh My Posh in profile
$profilePath = $PROFILE
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

if (-not (Select-String -Path $profilePath -Pattern "oh-my-posh init pwsh" -Quiet)) {
    Add-Content $profilePath 'oh-my-posh init pwsh | Invoke-Expression'
    Write-Host "✅ Oh My Posh startup command added to profile."
} else {
    Write-Host "ℹ️ Oh My Posh already configured in profile."
}

Write-Host "🎯 Done! Restart PowerShell to see the changes."
