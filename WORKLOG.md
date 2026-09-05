# Work log — repo-governance-templates

> Dated running log of what changed. Newest at the top. Keep entries short; link to the PR
> instead of re-explaining it.

## 2026-09-05 — Server routing Phase 2 deployment & Windows compatibility

- **Branch:** `fix/server-router-windows-compat` → PR #3
- **Changed:** During Phase 2 deployment, sanitized Windows PowerShell heredoc CRLF line endings
  (`-replace "`r", ""`) in `Deploy-ServerRouter.ps1`, `Rollback-ServerRouter.ps1`, and
  `Snapshot-ServerRouter.ps1` before passing over SSH to Linux bash. Updated Caddy reload to
  `systemctl restart caddy` in `Deploy-ServerRouter.ps1` because Caddy runs with `admin off`.
- **Live State:** Phase 2 fully executed: Forgejo HTTP backend bound to `127.0.0.1:3000`,
  stale UFW rule 3000/tcp removed, direct LAN access to port 3000 closed, protected snapshots
  captured in `/var/backups/server-router/snapshots/` (mode 0700 root:root).
- **Verified by:** `Verify-ServerRouter.ps1` (all 6 routes PASS, loopback isolation PASS,
  Git HTTP 401 challenge PASS, services active PASS), direct LAN port 3000 timeout PASS,
  `fj` CLI over Tailscale PASS, Git SSH PASS.

## 2026-09-05 — Server routing formalization & governance

- **Branch:** `fix/server-router-migration` → PR #2 (Merged by Paul)
- **Changed:** Formalized live server routing under `global/server-router/`. Canonical assets:
  `routes.json` (authoritative single source of truth), `Caddyfile`, `portal/index.html`.
  Tooling: `Validate-ServerRouter.ps1` (deterministic fail-closed validation of routes, Caddy,
  and portal), `Deploy-ServerRouter.ps1` (safe dry-run first deployment), `Verify-ServerRouter.ps1`
  (route probing, Git HTTP endpoint, loopback isolation, service health), `Snapshot-ServerRouter.ps1`
  (protected snapshot capture), and `Rollback-ServerRouter.ps1` (repaired rollback procedure
  resolving Caddy failure defect). Updated `global/server-rules.md` to reflect loopback Caddy architecture.
  Replaced disabled Desktop `Fix-Server-Addresses.ps1` with a thin canonical launcher. Scoped `.gitignore`.
- **Verified by:** Hermetic JSON validation, PowerShell AST parsing, deterministic cross-validation
  of routes.json/Caddyfile/portal, remote Caddy binary validation on `minisforum`, rollback dry-run
  regression check against historical snapshot 20260904-224841, and live read-only verification
  (all 6 routes PASS, loopback isolation PASS, service health PASS).

## 2026-09-05 — Governance V2


- **Branch:** `feat/governance-v2` → PR #1 (Forgejo, awaiting Paul's ratification)
- **Changed:** V2 of the kit. Autonomy after objective approval, one cohesive deliverable per
  branch, lean-engineering and subagent-economy rules native to `AGENTS.md`, one end-of-work
  independent reviewer (`.claude/agents/code-reviewer.md`, Sonnet 5 / high / read-only).
  Fixed two gates that never actually fired: the branch guard missed the first commit in a
  new repo, and the large-file gate never compared a size. Review receipt now tracks a digest
  of substantive files and is checked at merge as well as at PR creation. Lockfile blanket
  block replaced with a warning. New: `update-governance.ps1`, `sync-remotes.ps1`,
  `update-global-rules.ps1`, `governance-manifest.json`, `.governance-version`. WORKLOG CI
  toll booth removed.
- **Verified by:** `tests/acceptance.ps1` — 144 checks, 0 failures, all in disposable repos.
  Two independent reviews; both returned CHANGES REQUESTED and all findings were fixed
  (`docs/` exempting executables; receipt not re-checked at merge; the authority ceiling
  going blind when merging a PR by number from another branch).
- **Next:** Paul merges PR #1 on Forgejo, then `sync-remotes.ps1` converges GitHub's `main`.
- **Open decisions:** none. One documented limitation: on Forgejo the gate cannot verify that
  `fj pr merge <n>` refers to the checked-out branch, so "merge the branch you have checked
  out" is a rule there rather than an enforced gate.
