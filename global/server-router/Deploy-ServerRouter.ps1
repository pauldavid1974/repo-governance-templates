# Requires PowerShell 5.1+
param(
    [string]$Server = 'minisforum',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot

# 1. Run deterministic pre-flight validation
Write-Host "Running pre-flight validation against canonical source..." -ForegroundColor Cyan
& (Join-Path $Root 'Validate-ServerRouter.ps1') -Root $Root -Server $Server
if ($LASTEXITCODE -ne 0) {
    throw "Pre-flight validation failed. Aborting deployment."
}

$routesPath = Join-Path $Root 'routes.json'
$manifest = Get-Content -Raw $routesPath -Encoding utf8 | ConvertFrom-Json
$ingressTarget = $manifest.tailscale_ingress.target

if (-not $Apply) {
    Write-Host ""
    Write-Host "DRY RUN ONLY. No changes made to $Server." -ForegroundColor Yellow
    Write-Host "To execute live deployment after PR approval, rerun with -Apply."
    Write-Host "Actions that would be performed:"
    Write-Host "  1. Stage Caddyfile, routes.json, and portal/index.html on $Server"
    Write-Host "  2. Validate staged Caddyfile using remote 'caddy validate'"
    Write-Host "  3. Install /etc/server-router/routes.json (0644 root:root)"
    Write-Host "  4. Install /var/www/portal/index.html (0644 root:root)"
    Write-Host "  5. Install /etc/caddy/Caddyfile (0644 root:root)"
    Write-Host "  6. Reload/restart caddy.service and verify it is active"
    Write-Host "  7. Verify or configure Tailscale root ingress: 'tailscale serve --bg $ingressTarget'"
    Write-Host "  8. Run post-deployment route verification"
    exit 0
}

Write-Host "Beginning deployment to $Server..." -ForegroundColor Cyan
$stageDir = "/tmp/server-router-deploy-" + (Get-Random)

try {
    ssh $Server "rm -rf $stageDir; mkdir -p $stageDir/portal"
    scp (Join-Path $Root 'Caddyfile') "$Server`:$stageDir/Caddyfile" | Out-Null
    scp (Join-Path $Root 'routes.json') "$Server`:$stageDir/routes.json" | Out-Null
    scp (Join-Path $Root 'portal\index.html') "$Server`:$stageDir/portal/index.html" | Out-Null

    Write-Host "Validating staged files on $Server..." -ForegroundColor Cyan
    ssh $Server "sudo caddy validate --config $stageDir/Caddyfile --adapter caddyfile"
    if ($LASTEXITCODE -ne 0) { throw "Remote Caddy validation of staged file failed." }

    ssh $Server "python3 -m json.tool $stageDir/routes.json >/dev/null; test -s $stageDir/portal/index.html"
    if ($LASTEXITCODE -ne 0) { throw "Staged routes.json or portal/index.html validation failed." }

    Write-Host "Installing canonical configuration files..." -ForegroundColor Cyan
    ssh $Server @"
sudo install -d -o root -g root -m 0755 /etc/server-router
sudo install -o root -g root -m 0644 $stageDir/routes.json /etc/server-router/routes.json
sudo install -d -o root -g root -m 0755 /var/www/portal
sudo install -o root -g root -m 0644 $stageDir/portal/index.html /var/www/portal/index.html
sudo install -o root -g root -m 0644 $stageDir/Caddyfile /etc/caddy/Caddyfile
"@
    if ($LASTEXITCODE -ne 0) { throw "Installation of files failed on $Server." }

    Write-Host "Reloading Caddy service..." -ForegroundColor Cyan
    ssh $Server "sudo systemctl reload-or-restart caddy"
    if ($LASTEXITCODE -ne 0) { throw "Failed to reload caddy.service on $Server." }

    $caddyState = (ssh $Server "systemctl is-active caddy" 2>$null | Out-String).Trim()
    if ($caddyState -ne 'active') { throw "caddy.service is not active on $Server (state: $caddyState)." }

    Write-Host "Verifying Tailscale Serve ingress..." -ForegroundColor Cyan
    $serveStatus = (ssh $Server "tailscale serve status 2>&1" | Out-String)
    if ($serveStatus -notmatch [regex]::Escape($ingressTarget)) {
        Write-Host "Tailscale Serve root proxy missing; applying from routes.json specification..." -ForegroundColor Yellow
        ssh $Server "sudo tailscale serve reset; sudo tailscale serve --bg $ingressTarget"
        if ($LASTEXITCODE -ne 0) { throw "Failed to configure Tailscale Serve root proxy on $Server." }
    }

    Write-Host "Deployment completed successfully. Running verification..." -ForegroundColor Green
    & (Join-Path $Root 'Verify-ServerRouter.ps1') -Server $Server
    if ($LASTEXITCODE -ne 0) {
        throw "Post-deployment verification failed on $Server."
    }
} finally {
    ssh $Server "rm -rf $stageDir" 2>$null | Out-Null
}

