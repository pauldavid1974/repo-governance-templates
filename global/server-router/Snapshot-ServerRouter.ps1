# Requires PowerShell 5.1+
param(
    [string]$Server = 'minisforum',
    [string]$OutputRoot = $null,
    [switch]$ServerLocal
)

$ErrorActionPreference = 'Stop'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

if ($ServerLocal) {
    # Store directly in root-owned protected location on the server
    $remoteRoot = '/var/backups/server-router/snapshots'
    $remoteSnapshot = "$remoteRoot/$Stamp"
    Write-Host "Creating protected server-side snapshot in $remoteSnapshot on $Server..." -ForegroundColor Cyan

    ssh $Server @"
sudo install -d -o root -g root -m 0700 $remoteRoot
sudo install -d -o root -g root -m 0700 $remoteSnapshot
sudo install -d -o root -g root -m 0700 $remoteSnapshot/web

sudo tailscale serve status --json | sudo tee $remoteSnapshot/tailscale-serve-status.json >/dev/null
sudo cp /etc/forgejo/app.ini $remoteSnapshot/forgejo-app.ini
sudo chmod 0600 $remoteSnapshot/forgejo-app.ini

if sudo test -f /etc/caddy/Caddyfile; then
    sudo cp /etc/caddy/Caddyfile $remoteSnapshot/web/Caddyfile
    sudo chmod 0600 $remoteSnapshot/web/Caddyfile
else
    echo "ABSENT" | sudo tee $remoteSnapshot/web/Caddyfile.absent >/dev/null
fi

if sudo test -f /var/www/portal/index.html; then
    sudo cp /var/www/portal/index.html $remoteSnapshot/web/portal-index.html
    sudo chmod 0644 $remoteSnapshot/web/portal-index.html
else
    echo "ABSENT" | sudo tee $remoteSnapshot/web/portal-index.html.absent >/dev/null
fi

{
    systemctl is-enabled caddy 2>/dev/null || echo "not-found"
    systemctl is-active caddy 2>/dev/null || echo "inactive"
    systemctl is-enabled forgejo 2>/dev/null || echo "not-found"
    systemctl is-active forgejo 2>/dev/null || echo "inactive"
} | sudo tee $remoteSnapshot/prior-service-state.txt >/dev/null
sudo chmod 0600 $remoteSnapshot/prior-service-state.txt
"@
    if ($LASTEXITCODE -ne 0) { throw "Server-side snapshot failed on $Server." }
    Write-Host "Protected snapshot saved on $Server at $remoteSnapshot (mode 0700 root:root)." -ForegroundColor Green
    return
}

# Workstation-local snapshot outside Git
if (-not $OutputRoot) {
    $OutputRoot = Join-Path $HOME '.server-router-snapshots'
}
$snapshotDir = Join-Path $OutputRoot $Stamp
$webDir = Join-Path $snapshotDir 'web'

New-Item -ItemType Directory -Force -Path $snapshotDir | Out-Null
New-Item -ItemType Directory -Force -Path $webDir | Out-Null

Write-Host "Capturing rollback snapshot from $Server to $snapshotDir..." -ForegroundColor Cyan

# Workstation Tailscale status if available
try {
    tailscale status 2>$null | Out-File (Join-Path $snapshotDir 'workstation-tailscale-status.txt') -Encoding utf8
} catch {
    "UNAVAILABLE" | Out-File (Join-Path $snapshotDir 'workstation-tailscale-status.txt') -Encoding utf8
}

ssh $Server 'tailscale serve status --json' | Out-File (Join-Path $snapshotDir 'tailscale-serve-status.json') -Encoding utf8
ssh $Server 'sudo cat /etc/forgejo/app.ini' | Out-File (Join-Path $snapshotDir 'forgejo-app.ini') -Encoding utf8

# Check Caddyfile presence
$hasCaddy = ssh $Server "sudo test -f /etc/caddy/Caddyfile" 2>$null
if ($LASTEXITCODE -eq 0) {
    scp "$Server`:/etc/caddy/Caddyfile" (Join-Path $webDir 'Caddyfile') | Out-Null
} else {
    'ABSENT' | Out-File (Join-Path $webDir 'Caddyfile.absent') -Encoding ascii
}

# Check Portal presence
$hasPortal = ssh $Server "sudo test -f /var/www/portal/index.html" 2>$null
if ($LASTEXITCODE -eq 0) {
    scp "$Server`:/var/www/portal/index.html" (Join-Path $webDir 'portal-index.html') | Out-Null
} else {
    'ABSENT' | Out-File (Join-Path $webDir 'portal-index.html.absent') -Encoding ascii
}

ssh $Server 'systemctl is-enabled caddy 2>/dev/null || echo "not-found"; systemctl is-active caddy 2>/dev/null || echo "inactive"; systemctl is-enabled forgejo 2>/dev/null || echo "not-found"; systemctl is-active forgejo 2>/dev/null || echo "inactive"' | Out-File (Join-Path $snapshotDir 'prior-service-state.txt') -Encoding utf8

Write-Host "Snapshot captured successfully to $snapshotDir" -ForegroundColor Green
Write-Host "NOTE: This directory is outside Git and may contain machine credentials; do not commit it." -ForegroundColor Yellow
