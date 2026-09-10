# Requires PowerShell 5.1+
param(
    [string]$Root = $PSScriptRoot,
    [string]$Server = $null
)

$ErrorActionPreference = 'Stop'

function Fail([string]$msg) {
    Write-Host "VALIDATION FAILED: $msg" -ForegroundColor Red
    throw $msg
}

Write-Host "Validating server router configuration in '$Root'..." -ForegroundColor Cyan

# 1. Authoritative routes.json validation
$routesPath = Join-Path $Root 'routes.json'
if (-not (Test-Path $routesPath)) { Fail "Missing authoritative route file: $routesPath" }

try {
    $manifest = Get-Content -Raw $routesPath -Encoding utf8 | ConvertFrom-Json
} catch {
    Fail "routes.json is not valid JSON: $_"
}

if (-not $manifest.host) { Fail "routes.json missing 'host'" }
if ($manifest.private_only -ne $true) { Fail "routes.json must declare 'private_only: true'" }
if (-not $manifest.tailscale_ingress -or -not $manifest.tailscale_ingress.target) {
    Fail "routes.json missing 'tailscale_ingress.target'"
}
if ($manifest.tailscale_ingress.target -ne 'http://127.0.0.1:8080') {
    Fail "tailscale_ingress target must be 'http://127.0.0.1:8080'"
}
if (-not $manifest.caddy -or $manifest.caddy.bind -ne '127.0.0.1' -or $manifest.caddy.port -ne 8080) {
    Fail "routes.json caddy settings must bind 127.0.0.1:8080"
}
if (-not $manifest.routes -or $manifest.routes.Count -eq 0) {
    Fail "routes.json contains no routes"
}

# 2. Caddyfile validation against routes.json
$caddyPath = Join-Path $Root 'Caddyfile'
if (-not (Test-Path $caddyPath)) { Fail "Missing Caddyfile: $caddyPath" }
$caddyContent = Get-Content -Raw $caddyPath -Encoding utf8

# Security & baseline checks
if ($caddyContent -notmatch '(?m)^\s*admin\s+off\b') {
    Fail "Caddyfile must explicitly disable admin API (admin off)"
}
if ($caddyContent -notmatch ':8080\s*\{' -or $caddyContent -notmatch 'bind\s+127\.0\.0\.1') {
    Fail "Caddyfile must listen on :8080 and bind strictly to 127.0.0.1"
}
$portalRoutes = @($manifest.routes | Where-Object { $_.path -eq '/' })
if ($portalRoutes.Count -ne 1 -or $portalRoutes[0].owner -ne 'portal') {
    Fail "Exactly one root route must be owned by the portal"
}
$defaultHandler = [regex]::Match($caddyContent, '(?s)\bhandle\s*\{([^{}]*)\}')
if (-not $defaultHandler.Success) { Fail "Missing default portal handler" }
if ($portalRoutes[0].kind -eq 'reverse_proxy' -and $portalRoutes[0].target -eq '127.0.0.1:8090') {
    if ($defaultHandler.Groups[1].Value -notmatch 'reverse_proxy\s+127\.0\.0\.1:8090\b') {
        Fail "Default handler must preserve the approved loopback dashboard"
    }
} elseif ($portalRoutes[0].kind -eq 'static' -and $portalRoutes[0].target -eq '/var/www/portal') {
    if ($defaultHandler.Groups[1].Value -notmatch 'root\s+\*\s+/var/www/portal\b' -or $defaultHandler.Groups[1].Value -notmatch 'file_server') {
        Fail "Default handler must serve the manifested static portal"
    }
} else { Fail "Unsupported root portal target; applications cannot take over the root" }

# Verify each manifested route is represented correctly in Caddyfile
$manifestedPaths = @{}
foreach ($route in $manifest.routes) {
    $rPath = [string]$route.path
    $normPath = '/' + $rPath.Trim('/')
    if ($rPath -eq '/') { continue }
    $manifestedPaths[$normPath] = $route

    # Check path matcher pattern
    $escapedNorm = [regex]::Escape($normPath)
    $matcherPattern = "@\w+\s+path\s+$escapedNorm\s+$escapedNorm/\*"
    if ($caddyContent -notmatch $matcherPattern) {
        Fail "Caddyfile missing path matcher for route: $rPath (expected matcher: @<name> path $normPath $normPath/*)"
    }

    # Check handler action
    if ($route.kind -eq 'reverse_proxy') {
        $escapedTarget = [regex]::Escape($route.target)
        if ($caddyContent -notmatch "reverse_proxy\s+$escapedTarget") {
            Fail "Caddyfile missing reverse_proxy target '$($route.target)' for route: $rPath"
        }
        if ($route.prefix_preserved -eq $false) {
            if ($caddyContent -notmatch "uri\s+strip_prefix\s+$escapedNorm") {
                Fail "Route $rPath has prefix_preserved=false; Caddyfile must include 'uri strip_prefix $normPath'"
            }
        }
    } elseif ($route.kind -eq 'static') {
        $escapedTarget = [regex]::Escape($route.target)
        if ($caddyContent -notmatch "root\s+\*\s+$escapedTarget") {
            Fail "Caddyfile missing static root '$($route.target)' for route: $rPath"
        }
        if ($caddyContent -notmatch "uri\s+strip_prefix\s+$escapedNorm") {
            Fail "Static route $rPath requires 'uri strip_prefix $normPath' for disk lookup"
        }
    } else {
        Fail "Unsupported route kind '$($route.kind)' for route: $rPath"
    }
}

# Bidirectional check: ensure no extraneous matchers exist in Caddyfile that are not in routes.json
$caddyMatchers = [regex]::Matches($caddyContent, '(?m)^\s*@(\w+)\s+path\s+(\S+)\s+(\S+)')
foreach ($match in $caddyMatchers) {
    $caddyPathArg = '/' + $match.Groups[2].Value.Trim('/')
    if (-not $manifestedPaths.ContainsKey($caddyPathArg)) {
        Fail "Caddyfile defines matcher '$($match.Groups[1].Value)' for '$caddyPathArg' which is not in routes.json"
    }
}

# 3. Portal index.html validation against routes.json
$portalPath = Join-Path $Root 'portal\index.html'
if (-not (Test-Path $portalPath)) { Fail "Missing portal file: $portalPath" }
$portalContent = Get-Content -Raw $portalPath -Encoding utf8

$portalLinks = [regex]::Matches($portalContent, 'href="([^"]+)"')
$foundHrefs = @{}
foreach ($link in $portalLinks) {
    $href = $link.Groups[1].Value
    $normHref = '/' + $href.Trim('/')
    $foundHrefs[$normHref] = $href
}

# Check that every manifested application route appears in portal
foreach ($normPath in $manifestedPaths.Keys) {
    if (-not $foundHrefs.ContainsKey($normPath)) {
        Fail "Portal ($portalPath) is missing an <a href> link for route: $normPath"
    }
}

# Check that no unmanifested links exist in portal navigation
foreach ($normHref in $foundHrefs.Keys) {
    if (-not $manifestedPaths.ContainsKey($normHref)) {
        Fail "Portal ($portalPath) contains orphan link '$normHref' not defined in routes.json"
    }
}

Write-Host "Authoritative manifest, Caddyfile, and portal are fully consistent." -ForegroundColor Green

# 4. Caddy binary syntax validation if requested or locally available
if ($Server) {
    Write-Host "Running remote syntax check with caddy binary on $Server..." -ForegroundColor Cyan
    $tmpDir = "/tmp/caddy-validate-" + (Get-Random)
    try {
        ssh $Server "mkdir -p $tmpDir"
        scp $caddyPath "$Server`:$tmpDir/Caddyfile" | Out-Null
        $valOutput = ssh $Server "sudo caddy validate --config $tmpDir/Caddyfile --adapter caddyfile 2>&1"
        if ($LASTEXITCODE -ne 0) {
            Fail "Remote caddy binary validation failed:`n$valOutput"
        }
        Write-Host "Remote caddy binary validated Caddyfile successfully." -ForegroundColor Green
    } finally {
        ssh $Server "rm -rf $tmpDir" 2>$null | Out-Null
    }
} elseif (Get-Command caddy -ErrorAction SilentlyContinue) {
    $valOutput = caddy validate --config $caddyPath --adapter caddyfile 2>&1
    if ($LASTEXITCODE -ne 0) {
        Fail "Local caddy binary validation failed:`n$valOutput"
    }
    Write-Host "Local caddy binary validated Caddyfile successfully." -ForegroundColor Green
}

Write-Host "All router artifact validations PASSED." -ForegroundColor Green
