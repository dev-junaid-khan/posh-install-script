<#
install.ps1
Windows-only. Installs posh-git, oh-my-posh, Terminal-Icons (if missing),
backups up profile, writes safe profile lines, and launches a new shell so user sees changes.

Run:
powershell -NoProfile -ExecutionPolicy Bypass -Command "iwr -useb https://raw.githubusercontent.com/dev-junaid-khan/posh-install-script/main/install.ps1 | iex"
or (if pwsh is available):
pwsh -NoProfile -Command "iwr -useb https://raw.githubusercontent.com/dev-junaid-khan/posh-install-script/main/install.ps1 | iex"
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Info($m){ Write-Host "[..] $m" -ForegroundColor Cyan }
function Write-Success($m){ Write-Host "[OK] $m" -ForegroundColor Green }
function Write-ErrorMsg($m){ Write-Host "[ERR] $m" -ForegroundColor Red }

if (-not $IsWindows) {
    Write-ErrorMsg "This script is Windows-only. Exiting."
    exit 1
}

Write-Host "=== Posh installer: posh-git, oh-my-posh, Terminal-Icons ===" -ForegroundColor Yellow

# Profile path & backup
$profilePath = $PROFILE
$profileFolder = Split-Path -Parent $profilePath

try {
    if (-not (Test-Path -Path $profileFolder)) {
        Write-Info "Creating profile folder: $profileFolder"
        New-Item -ItemType Directory -Path $profileFolder -Force | Out-Null
    }

    if (-not (Test-Path -Path $profilePath)) {
        Write-Info "Creating profile file: $profilePath"
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    $backupPath = "$profilePath.backup.$(Get-Date -Format yyyyMMdd_HHmmss).bak"
    Copy-Item -LiteralPath $profilePath -Destination $backupPath -Force
    Write-Info "Profile backed up to: $backupPath"
} catch {
    Write-ErrorMsg "Failed to prepare/backup profile: $($_.Exception.Message)"
    # continue - we'll still try to install modules
}

# Convenience: try to ensure PSGallery is available and NuGet provider installed
try {
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Info "Installing NuGet provider (current user)..."
        Install-PackageProvider -Name NuGet -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    }
    if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
        Write-Info "Registering PSGallery repository..."
        Register-PSRepository -Default -ErrorAction SilentlyContinue
    }
} catch {
    Write-Info "PSGallery/NuGet setup: non-fatal error: $($_.Exception.Message)"
}

$Failed = @()

function Install-ModuleIfMissing {
    param([string] $ModuleName)
    try {
        if (@(Get-Module -ListAvailable -Name $ModuleName).Count -gt 0) {
            Write-Success "$ModuleName already installed. Skipping."
            return $true
        }
        Write-Info "Installing module: $ModuleName (CurrentUser scope)"
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Write-Success "$ModuleName installed."
        return $true
    } catch {
        Write-ErrorMsg "Failed to install $ModuleName: $($_.Exception.Message)"
        $script:Failed += $ModuleName
        return $false
    }
}

# Install the modules (skips if already present)
Install-ModuleIfMissing "posh-git"
Install-ModuleIfMissing "oh-my-posh"
Install-ModuleIfMissing "Terminal-Icons"

# Download markbull theme (optional) — try but non-fatal
$themeDest = Join-Path $env:USERPROFILE 'markbull.omp.json'
try {
    if (-not (Test-Path $themeDest)) {
        Write-Info "Downloading markbull theme to $themeDest"
        Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/markbull.omp.json" -OutFile $themeDest -ErrorAction Stop
        Write-Success "Theme downloaded."
    } else {
        Write-Info "Theme already present at $themeDest"
    }
} catch {
    Write-Info "Could not download theme (non-fatal): $($_.Exception.Message)"
    # leave $themeDest path, profile will handle missing theme gracefully
}

# Build profile block to add (idempotent)
$profileBlock = @'
# >>> posh-installer: start (added by install.ps1) - do not edit below this line
Import-Module posh-git -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# oh-my-posh init: prefer 'oh-my-posh' executable, fallback to Set-PoshPrompt if available
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        $theme = "$env:USERPROFILE\markbull.omp.json"
        if (Test-Path $theme) {
            oh-my-posh init pwsh --config $theme | Invoke-Expression
        } else {
            oh-my-posh init pwsh | Invoke-Expression
        }
    } catch { }
} elseif (Get-Command Set-PoshPrompt -ErrorAction SilentlyContinue) {
    try { Set-PoshPrompt -Theme paradox } catch { }
}
# <<< posh-installer: end
'@

# Add the block if it's not already present
try {
    $current = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $current -or -not ($current -match 'posh-installer: start')) {
        Write-Info "Appending module imports and oh-my-posh init to profile."
        Add-Content -LiteralPath $profilePath -Value $profileBlock -Encoding UTF8
        Write-Success "Profile updated."
    } else {
        Write-Info "Profile already contains installer block. Skipping profile write."
    }
} catch {
    Write-ErrorMsg "Failed to update profile: $($_.Exception.Message)"
    $Failed += "profile-write"
}

# Try to import modules into current session (best-effort)
try {
    Import-Module posh-git -ErrorAction SilentlyContinue
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
    # Try init oh-my-posh now if available
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        if (Test-Path $themeDest) {
            oh-my-posh init pwsh --config $themeDest | Invoke-Expression
        } else {
            oh-my-posh init pwsh | Invoke-Expression
        }
    } elseif (Get-Command Set-PoshPrompt -ErrorAction SilentlyContinue) {
        Set-PoshPrompt -Theme paradox -ErrorAction SilentlyContinue
    }
} catch {
    Write-Info "Live import/init: non-fatal: $($_.Exception.Message)"
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Yellow
if ($Failed.Count -eq 0) {
    Write-Success "All requested steps completed (or were already present)."
} else {
    Write-ErrorMsg "Some steps failed or were skipped: $($Failed -join ', ')"
    Write-Host "You can re-run the script, or inspect the backup profile at: $backupPath" -ForegroundColor Yellow
}

# Open a new PowerShell window so user immediately sees the new prompt (best-effort)
try {
    $pwshCmd = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if ($pwshCmd) {
        Write-Info "Launching new pwsh window to show changes..."
        Start-Process -FilePath $pwshCmd -ArgumentList '-NoExit' -WindowStyle Normal
    } else {
        # fallback to Windows PowerShell
        $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        Write-Info "Launching new Windows PowerShell window to show changes..."
        Start-Process -FilePath $psExe -ArgumentList '-NoExit' -WindowStyle Normal
    }
} catch {
    Write-Info "Could not auto-launch new shell (non-fatal): $($_.Exception.Message)"
}

Write-Host "`nDone. Restart your terminal if things look off." -ForegroundColor Green
