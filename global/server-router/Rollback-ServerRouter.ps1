# Requires PowerShell 5.1+
param(
    [Parameter(Mandatory = $true)]
    [string]$Snapshot,
    [string]$Server = 'minisforum',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

Write-Host "Verifying rollback snapshot in '$Snapshot'..." -ForegroundColor Cyan

$isRemote = $Snapshot -match '^/'

# 1. Snapshot completeness validation
if ($isRemote) {
    Write-Host "Snapshot path is remote on $Server..." -ForegroundColor Cyan
    $dirCheck = ssh $Server "sudo test -d '$Snapshot'" 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Remote snapshot directory '$Snapshot' does not exist on $Server." }

    foreach ($name in 'tailscale-serve-status.json', 'forgejo-app.ini', 'prior-service-state.txt') {
        ssh $Server "sudo test -f '$Snapshot/$name'" 2>$null
        if ($LASTEXITCODE -ne 0) { throw "Remote snapshot is incomplete: missing '$name' on $Server at '$Snapshot/$name'" }
    }

    ssh $Server "sudo test -f '$Snapshot/web/Caddyfile'" 2>$null
    $caddyPresent = ($LASTEXITCODE -eq 0)
    ssh $Server "sudo test -f '$Snapshot/web/Caddyfile.absent'" 2>$null
    $caddyAbsent = ($LASTEXITCODE -eq 0)
    if (-not ($caddyPresent -or $caddyAbsent)) {
        throw "Remote snapshot is incomplete: missing either web/Caddyfile or web/Caddyfile.absent"
    }

    ssh $Server "sudo test -f '$Snapshot/web/portal-index.html'" 2>$null
    $portalPresent = ($LASTEXITCODE -eq 0)
    ssh $Server "sudo test -f '$Snapshot/web/portal-index.html.absent'" 2>$null
    $portalAbsent = ($LASTEXITCODE -eq 0)
    if (-not ($portalPresent -or $portalAbsent)) {
        throw "Remote snapshot is incomplete: missing either web/portal-index.html or web/portal-index.html.absent"
    }


    $priorState = (ssh $Server "sudo cat '$Snapshot/prior-service-state.txt'" | Out-String) -split "`r?`n"
    $serveJsonRaw = (ssh $Server "sudo cat '$Snapshot/tailscale-serve-status.json'" | Out-String)
} else {
    Write-Host "Snapshot path is local on workstation..." -ForegroundColor Cyan
    if (-not (Test-Path $Snapshot)) { throw "Local snapshot directory '$Snapshot' does not exist." }

    foreach ($name in 'tailscale-serve-status.json', 'forgejo-app.ini', 'prior-service-state.txt') {
        $itemPath = Join-Path $Snapshot $name
        if (-not (Test-Path $itemPath)) { throw "Snapshot is incomplete: missing required file '$name' at $itemPath" }
    }

    $caddyPresent = Test-Path (Join-Path $Snapshot 'web\Caddyfile')
    $caddyAbsent = Test-Path (Join-Path $Snapshot 'web\Caddyfile.absent')
    if (-not ($caddyPresent -or $caddyAbsent)) {
        throw "Snapshot is incomplete: missing either web\Caddyfile or web\Caddyfile.absent"
    }

    $portalPresent = Test-Path (Join-Path $Snapshot 'web\portal-index.html')
    $portalAbsent = Test-Path (Join-Path $Snapshot 'web\portal-index.html.absent')
    if (-not ($portalPresent -or $portalAbsent)) {
        throw "Snapshot is incomplete: missing either web\portal-index.html or web\portal-index.html.absent"
    }

    $priorState = Get-Content (Join-Path $Snapshot 'prior-service-state.txt')
    $serveJsonRaw = Get-Content -Raw (Join-Path $Snapshot 'tailscale-serve-status.json') -Encoding utf8
}

# 2. Parse prior service state
$caddyPriorEnabled = if ($priorState.Count -gt 0) { $priorState[0].Trim() } else { 'not-found' }
$caddyPriorActive = if ($priorState.Count -gt 1) { $priorState[1].Trim() } else { 'inactive' }
$forgejoPriorEnabled = if ($priorState.Count -gt 2) { $priorState[2].Trim() } else { 'enabled' }
$forgejoPriorActive = if ($priorState.Count -gt 3) { $priorState[3].Trim() } else { 'active' }

# 3. Parse and validate Tailscale Serve map from snapshot
$serveJson = $serveJsonRaw | ConvertFrom-Json
$webSection = $serveJson.Web.PSObject.Properties | Select-Object -First 1
if (-not $webSection) { throw "Snapshot contains no valid Web Serve map in tailscale-serve-status.json" }

Write-Host "Snapshot verified. Target server: $Server" -ForegroundColor Green
Write-Host "Prior Caddy state: enabled=$caddyPriorEnabled, active=$caddyPriorActive (Caddyfile present: $caddyPresent)"
Write-Host "Prior Forgejo state: enabled=$forgejoPriorEnabled, active=$forgejoPriorActive"

if (-not $Apply) {
    Write-Host ""
    Write-Host "DRY RUN ONLY. No changes made to $Server." -ForegroundColor Yellow
    Write-Host "To execute live rollback, rerun with -Apply."
    Write-Host "Actions that would be performed:"
    Write-Host "  1. Restore Forgejo configuration from snapshot and restart forgejo.service"
    if ($caddyPresent) {
        Write-Host "  2. Restore /etc/caddy/Caddyfile from snapshot"
        if ($caddyPriorActive -eq 'active') {
            Write-Host "  3. Restart caddy.service"
        } else {
            Write-Host "  3. Stop caddy.service (prior state was inactive)"
        }
    } else {
        Write-Host "  2. Stop and disable caddy.service, then remove /etc/caddy/Caddyfile"
        Write-Host "     (Caddy did not exist/was inactive prior to migration; DO NOT restart it into failure)"
    }
    if ($portalPresent) {
        Write-Host "  4. Restore /var/www/portal/index.html from snapshot"
    } else {
        Write-Host "  4. Remove /var/www/portal/index.html (was absent in snapshot)"
    }
    Write-Host "  5. Reset Tailscale Serve: 'sudo tailscale serve reset'"
    Write-Host "  6. Recreate legacy Tailscale Serve map:"
    foreach ($handler in $webSection.Value.Handlers.PSObject.Properties) {
        $path = $handler.Name
        $val = $handler.Value
        if ($val.Proxy) {
            $target = $val.Proxy -replace '^https?://127\.0\.0\.1:', ''
            if ($path -eq '/') { Write-Host "     - / -> $target (sudo tailscale serve --bg $target)" }
            else { Write-Host "     - $path -> $target (sudo tailscale serve --bg --set-path=$path $target)" }
        } elseif ($val.Path) {
            Write-Host "     - $path -> $($val.Path) (sudo tailscale serve --bg --set-path=$path $($val.Path))"
        }
    }
    Write-Host ""
    Write-Host "SCOPE NOTICE:" -ForegroundColor Cyan
    Write-Host "  - WHAT ROLLBACK RESTORES: Tailscale Serve handlers, Forgejo app.ini/ROOT_URL, Caddy configuration/service state, portal index.html."
    Write-Host "  - WHAT ROLLBACK DOES NOT TOUCH: Repository databases, Git history, user accounts, system packages, or SSH daemon configuration."
    exit 0
}

Write-Host "Executing rollback on $Server..." -ForegroundColor Yellow
$remoteStage = "/tmp/server-router-rollback-" + (Get-Random)

try {
    if (-not $isRemote) {
        ssh $Server "rm -rf $remoteStage; mkdir -p $remoteStage/web"
        scp (Join-Path $Snapshot 'forgejo-app.ini') "$Server`:$remoteStage/app.ini" | Out-Null
        scp (Join-Path $Snapshot 'tailscale-serve-status.json') "$Server`:$remoteStage/serve-status.json" | Out-Null
        if ($caddyPresent) {
            scp (Join-Path $Snapshot 'web\Caddyfile') "$Server`:$remoteStage/web/Caddyfile" | Out-Null
        }
        if ($portalPresent) {
            scp (Join-Path $Snapshot 'web\portal-index.html') "$Server`:$remoteStage/web/portal-index.html" | Out-Null
        }
        $srcDir = $remoteStage
        $srcForgejo = "$remoteStage/app.ini"
        $srcCaddy = "$remoteStage/web/Caddyfile"
        $srcPortal = "$remoteStage/web/portal-index.html"
    } else {
        $srcDir = $Snapshot
        $srcForgejo = "$Snapshot/forgejo-app.ini"
        $srcCaddy = "$Snapshot/web/Caddyfile"
        $srcPortal = "$Snapshot/web/portal-index.html"
    }

    # 1. Restore Forgejo configuration
    Write-Host "Restoring Forgejo app.ini and restarting forgejo.service..." -ForegroundColor Cyan
    ssh $Server "sudo cp '$srcForgejo' /etc/forgejo/app.ini; sudo systemctl restart forgejo"
    if ($LASTEXITCODE -ne 0) { throw "Failed to restore /etc/forgejo/app.ini or restart forgejo on $Server." }

    # 2. Handle Caddy state properly (Fixing Defect #6)
    if ($caddyPresent) {
        Write-Host "Restoring /etc/caddy/Caddyfile from snapshot..." -ForegroundColor Cyan
        ssh $Server "sudo install -o root -g root -m 0644 '$srcCaddy' /etc/caddy/Caddyfile"
        if ($caddyPriorActive -eq 'active') {
            Write-Host "Restarting caddy.service..." -ForegroundColor Cyan
            ssh $Server "sudo systemctl restart caddy"
        } else {
            Write-Host "Prior Caddy state was inactive; stopping caddy.service..." -ForegroundColor Cyan
            ssh $Server "sudo systemctl stop caddy"
        }
    } else {
        # Pre-Caddy state: Caddyfile was absent. Stop and disable Caddy; DO NOT restart it.
        Write-Host "Caddy was not present prior to migration. Stopping and disabling caddy.service..." -ForegroundColor Cyan
        $caddyStopCmd = @"
sudo systemctl stop caddy 2>/dev/null || true
sudo systemctl disable caddy 2>/dev/null || true
sudo rm -f /etc/caddy/Caddyfile
"@ -replace "`r", ""
        ssh $Server $caddyStopCmd
    }

    # 3. Handle Portal state
    if ($portalPresent) {
        Write-Host "Restoring /var/www/portal/index.html from snapshot..." -ForegroundColor Cyan
        ssh $Server "sudo install -d -o root -g root -m 0755 /var/www/portal; sudo install -o root -g root -m 0644 '$srcPortal' /var/www/portal/index.html"
    } else {
        Write-Host "Portal was absent in snapshot; removing /var/www/portal/index.html..." -ForegroundColor Cyan
        ssh $Server "sudo rm -f /var/www/portal/index.html"
    }

    # 4. Restore Tailscale Serve map safely
    Write-Host "Rebuilding legacy Tailscale Serve map on $Server..." -ForegroundColor Cyan
    ssh $Server "sudo tailscale serve reset"
    if ($LASTEXITCODE -ne 0) { throw "Failed to reset Tailscale Serve map on $Server." }

    foreach ($handler in $webSection.Value.Handlers.PSObject.Properties) {
        $path = $handler.Name
        $val = $handler.Value
        if ($val.Proxy) {
            $target = $val.Proxy -replace '^https?://127\.0\.0\.1:', ''
            if ($path -eq '/') {
                ssh $Server "sudo tailscale serve --bg $target"
            } else {
                ssh $Server "sudo tailscale serve --bg --set-path=$path $target"
            }
        } elseif ($val.Path) {
            ssh $Server "sudo tailscale serve --bg --set-path=$path $($val.Path)"
        }
        if ($LASTEXITCODE -ne 0) { throw "Failed to recreate Tailscale handler for '$path' on $Server." }
    }

    Write-Host "Rollback completed. Current Serve status on $Server :" -ForegroundColor Green
    ssh $Server "tailscale serve status"
} finally {
    if (-not $isRemote) {
        ssh $Server "rm -rf $remoteStage" 2>$null | Out-Null
    }
}
