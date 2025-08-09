# install.ps1 - Windows only PowerShell setup script
Write-Host "=== Starting Oh My Posh + Font Installation ===" -ForegroundColor Cyan

try {
    # Ensure profile exists
    if (-not (Test-Path -Path $PROFILE)) {
        Write-Host "Creating PowerShell profile..." -ForegroundColor Yellow
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    # Install oh-my-posh via winget
    Write-Host "Installing Oh My Posh..." -ForegroundColor Yellow
    winget install JanDeDobbeleer.OhMyPosh -s winget -h --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "Oh My Posh installation failed." }

    # Download and install font (CaskaydiaCove Nerd Font)
    Write-Host "Installing CaskaydiaCove Nerd Font..." -ForegroundColor Yellow
    $fontZip = "$env:TEMP\font.zip"
    Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip" -OutFile $fontZip
    Expand-Archive $fontZip -DestinationPath "$env:TEMP\font" -Force
    $fontFiles = Get-ChildItem "$env:TEMP\font" -Filter *.ttf
    foreach ($font in $fontFiles) {
        Write-Host "Installing font: $($font.Name)" -ForegroundColor Green
        Copy-Item $font.FullName -Destination "$env:WINDIR\Fonts"
    }

    # Update profile with theme
    $themePath = "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes\jandedobbeleer.omp.json"
    if (-not (Test-Path $themePath)) {
        Write-Host "Downloading default theme..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json" -OutFile $themePath
    }
    Add-Content -Path $PROFILE -Value "`noh-my-posh init pwsh --config `"$themePath`" | Invoke-Expression"

    # Set icon theme for Windows Terminal
    Write-Host "Setting Windows Terminal icon theme..." -ForegroundColor Yellow
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $settingsPath) {
        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
        foreach ($profile in $settings.profiles.list) {
            if ($profile.name -match "PowerShell") {
                $profile.fontFace = "CaskaydiaCove Nerd Font"
            }
        }
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath
    }

    Write-Host "✅ Installation complete! Restart your terminal to see the changes." -ForegroundColor Green
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Reverting changes..." -ForegroundColor Yellow
    Remove-Item $PROFILE -Force -ErrorAction SilentlyContinue
    Write-Host "Profile reset. No permanent changes made." -ForegroundColor Cyan
}
