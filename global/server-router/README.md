# Server Router — Canonical Governance & Deployment Source

Canonical management tools, configuration, and authoritative route manifest for Paul's private home server (`minisforum` / `gitserver.tail97bf76.ts.net`).

## Architecture

```
Tailscale Private HTTPS Ingress (443)
       ↓
Tailscale Serve root proxy (single background node-level proxy)
       ↓
Caddy Reverse Proxy & Static Server (127.0.0.1:8080, admin off)
       ↓
  /                → /var/www/portal/index.html (static home portal)
  /git/            → 127.0.0.1:3000 (Forgejo web UI; prefix stripped for backend)
  /mealprep/       → 127.0.0.1:9100 (Meal Prep AI; prefix preserved)
  /keycase/        → 127.0.0.1:8787 (Keycase service; prefix preserved)
  /factory         → 127.0.0.1:3187 (Paul's Software Factory; prefix preserved)
  /neon-labrinth/  → /var/www/neon-labrinth/dist (static app; disk prefix stripped)

Forgejo SSH remains separate and authoritative on port 22.
```

## Inventory

| File | Purpose |
|---|---|
| `routes.json` | **Single source of truth** for ingress target, Caddy parameters, and route definitions. |
| `Caddyfile` | Loopback Caddy configuration matching `routes.json`. |
| `portal/index.html` | Static HTML portal page linking to all active applications. |
| `Validate-ServerRouter.ps1` | Deterministic validator checking consistency between `routes.json`, `Caddyfile`, and portal. Fails closed. |
| `Deploy-ServerRouter.ps1` | Idempotent deployment script. Validates first, stages, installs, and reloads services. Dry-run by default. |
| `Verify-ServerRouter.ps1` | Comprehensive health check: ingress routes, Forgejo Git HTTP endpoint, loopback isolation, and systemd units. |
| `Snapshot-ServerRouter.ps1` | Captures pre-change snapshot to durable protected storage outside Git. |
| `Rollback-ServerRouter.ps1` | Repaired rollback script: safely restores Serve map, Forgejo config, and stops/disables Caddy if pre-migration. |

## Operational Procedures

### 1. Pre-Flight Validation
Run deterministic validation locally or against the server:
```powershell
powershell -NoProfile -File ".\Validate-ServerRouter.ps1" -Server minisforum
```
Fails closed if any route in `routes.json` is missing from `Caddyfile` or `portal/index.html`, if unmanifested routes exist, or if Caddy binary validation fails.

### 2. Routine Deployment
Always preview in dry-run mode first:
```powershell
powershell -NoProfile -File ".\Deploy-ServerRouter.ps1" -Server minisforum
```
Execute with explicit `-Apply` after approval:
```powershell
powershell -NoProfile -File ".\Deploy-ServerRouter.ps1" -Server minisforum -Apply
```

### 3. Health & Route Verification
Verify all routes and loopback isolation:
```powershell
powershell -NoProfile -File ".\Verify-ServerRouter.ps1" -Server minisforum
```

### 4. Taking a Pre-Change Snapshot
Before any consequential live server change, capture a protected snapshot:
```powershell
# Captures to /var/backups/server-router/snapshots/<timestamp> on the server (mode 0700 root:root):
powershell -NoProfile -File ".\Snapshot-ServerRouter.ps1" -Server minisforum -ServerLocal
```

### 5. Rollback Procedure
If recovery is required, verify the snapshot in dry-run mode:
```powershell
powershell -NoProfile -File ".\Rollback-ServerRouter.ps1" -Snapshot <path-to-snapshot>
```
To execute rollback:
```powershell
powershell -NoProfile -File ".\Rollback-ServerRouter.ps1" -Snapshot <path-to-snapshot> -Apply
```
**Rollback Scope:**
- **Restores:** Legacy Tailscale Serve map (using safe `tailscale serve reset` followed by handlers), Forgejo `app.ini` and `ROOT_URL`, portal `index.html`.
- **Caddy handling:** If Caddy was absent/inactive before migration, `caddy.service` is stopped and disabled, and `/etc/caddy/Caddyfile` is removed. It does NOT attempt to restart Caddy into failure.
- **Does not touch:** Repositories, databases, user credentials, system packages, or SSH host configuration.

## Safety Rules

1. **`routes.json` is the sole source of truth.** Never add an ad-hoc route to Caddyfile or portal without adding it to `routes.json`.
2. **Never run `tailscale serve <target> off`.** It wipes the entire node configuration.
3. **Loopback only.** Caddy must only listen on `127.0.0.1:8080`.
4. **No secrets in Git.** Machine snapshots contain full `app.ini` files and must remain in `/var/backups/server-router/snapshots/` or `$HOME/.server-router-snapshots/`.
