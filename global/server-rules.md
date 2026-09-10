# The server is shared ground — rules for putting anything on it

The mini PC (`minisforum`, reached as `gitserver.tail97bf76.ts.net`) runs several of
Paul's apps at the same time. Adding one is not a private act — every rule below exists
because breaking it took something else down.

1. **The bare address is the portal page. Never mount an app there.**
   The bare address (`/`) is owned by the static portal served by Caddy. Applications must
   never be mounted at `/`. Doing so displaces the portal.
2. **One word after the slash per app**, matching its repo, its folder and its systemd
   service name: `/mealprep`, `/keycase`, `/git`, `/factory`. Not the machine's name,
   not a port number, not a capital letter.
3. **Port numbers are plumbing.** Paul never types one. Every app gets a word and the
   port stays invisible. Do not hand him `host:9100` as an address. Backend services bind
   to loopback (`127.0.0.1`), never `0.0.0.0`.
4. **Tailscale provides one private ingress to loopback Caddy (`127.0.0.1:8080`).**
   Tailscale Serve runs a single root proxy forwarding `https://gitserver.tail97bf76.ts.net/`
   to Caddy on `http://127.0.0.1:8080`. Caddy owns internal path routing.
   The old architecture of separate direct per-app Tailscale Serve mounts is obsolete and
   must NOT be restored.
   Never run `tailscale serve <target> off`; on this Tailscale version it wipes the entire
   node configuration and takes every service down.
5. **`routes.json` is the single source of truth.**
   All routes must be declared in `global/server-router/routes.json` (installed live at
   `/etc/server-router/routes.json`). Caddy routing and the portal page must match
   `routes.json` deterministically. Always run `Validate-ServerRouter.ps1` before any change;
   drift between manifest, Caddyfile, and portal fails closed.
6. **Deploy and repair using canonical tooling.**
   The canonical deployment, verification, and rollback tooling lives in the governance kit
   under `global/server-router/`.
   `Fix-Server-Addresses.ps1` on Paul's Desktop is a thin launcher that invokes this
   canonical tooling; it does not contain a duplicate routing map.
7. **Forgejo web UI lives at `/git/`; SSH remains separate on port 22.**
   Forgejo's `ROOT_URL` in `/etc/forgejo/app.ini` is `https://gitserver.tail97bf76.ts.net/git/`.
   Caddy strips the public `/git` prefix before proxying to Forgejo's loopback port.
   Git SSH operations continue independently over port 22.
8. **An app must work under its mount.** Caddy preserves the full request path for dynamic
   applications that expect it (`/mealprep`, `/keycase`, `/factory`). Test apps mounted
   under their path, not just at the root.
9. **Adding an app means updating `routes.json`, Caddy, and the portal in the same change.**
   An app nobody can find is not deployed.
10. **Nothing here goes on the public internet.** Private network only. That is a
    deliberate choice Paul made — never "helpfully" expose ports to LAN or the public internet,
    and never propose a cloud bridge as a fix.

Current occupants: `/git/` (Forgejo), `/mealprep/`, `/keycase/`, `/factory`,
`/neon-labrinth/`.


## Owner-approved dashboard reconciliation — September 10, 2026
The owner authorized preserving the working dashboard and Astrocade, repairing configuration drift and privately publishing Cozy Tavern. The root remains owned by the Home Portal; its current implementation is dashboard.service behind Caddy at 127.0.0.1:8090, rather than the old static page. The static-only wording above is superseded for this specifically approved portal implementation. Other apps still cannot occupy root. The dashboard reads application cards from /etc/server-router/routes.json. Keep its backend bound to loopback. Current additional routes: /astrocade-specialist/ and /cozytavern/. The latter serves /var/www/cozytavern through Caddy. Private single-ingress rules are unchanged.
