# The server is shared ground — rules for putting anything on it

The mini PC (`minisforum`, reached as `gitserver.tail97bf76.ts.net`) runs several of
Paul's apps at the same time. Adding one is not a private act — every rule below exists
because breaking it took something else down.

1. **The bare address is the portal page. Never mount an app there.**
   Doing so silently replaces whatever was there, with no warning and no record of what
   it displaced. This has already happened once.
2. **One word after the slash per app**, matching its repo, its folder and its systemd
   service name: `/mealprep`, `/keycase`, `/git`, `/factory`. Not the machine's name,
   not a port number, not a capital letter.
3. **Port numbers are plumbing.** Paul never types one. Every app gets a word and the
   port stays invisible. Do not hand him `host:9100` as an address.
4. **Before changing `tailscale serve`: survey what is there, show Paul, and ask.**
   There is no way to remove a single mount. `tailscale serve <target> off` is not a
   thing in this version — passing it wipes the ENTIRE config and takes every other
   app down with it. To change one mount, rebuild them all together;
   `Fix-Server-Addresses.ps1` on Paul's Desktop does exactly that and verifies the
   result.
5. **An app must work under its mount.** Tailscale forwards the path WHOLE, prefix
   included — the app receives `/mealprep/api/list`, not `/api/list`. Test it mounted,
   not just at the root. PaulsMealPrep solves this with `unmount()` in `app.py` and an
   `APPBASE` script in each page; copy that approach rather than hardcoding a prefix.
6. **Adding an app means adding it to the portal page, in the same change.**
   An app nobody can find is not deployed.
7. **Nothing here goes on the public internet.** Private network only. That is a
   deliberate choice Paul made — never "helpfully" expose anything, and never propose
   a cloud bridge as a fix.

Current occupants: `/git` (Forgejo), `/mealprep`, `/keycase`, `/factory`,
`/neon-labrinth/`. Forgejo's `ROOT_URL` in `/etc/forgejo/app.ini` must match wherever
it is mounted, or every link it draws points somewhere else.
