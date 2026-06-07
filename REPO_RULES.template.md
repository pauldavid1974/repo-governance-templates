# Repository Rules — <PROJECT_NAME>

> **How to use this template:** Copy it to your new repo's root as `REPO_RULES.md`.
> Replace every `<PLACEHOLDER>`. Delete sections that don't apply. Anything not in
> angle brackets is a sane default you can keep as-is.

These rules keep the repo clean, reproducible, and safe to share. They apply to every
commit, branch, and pull request. When in doubt, favor the simplest change that keeps
the project working.

---

## 1. Scope & structure

- Describe the intended shape of the project in one or two lines, so drift is obvious:
  <e.g. "a single CLI entry point under `src/`", "a Next.js app", "a Python package">.
- Keep the layout predictable. Sketch the top-level structure:

  ```
  <repo>/
  ├─ <main source location>
  ├─ <dependency manifest>   # e.g. requirements.txt / package.json / go.mod
  ├─ README.md               # what it is + how to run it
  ├─ REPO_RULES.md           # this file
  └─ .gitignore
  ```

- Don't restructure the project without updating this section first.

---

## 2. What MUST NEVER be committed

Generated, machine-local, private, or large files belong in `.gitignore`, never in history:

- **Secrets** — no `.env`, API keys, tokens, or credentials in code, config, or commit
  messages. Commit a `*.example` template instead when a reference is useful.
- **Dependencies / build output** — vendored deps, `node_modules/`, `.venv/`, `build/`, `dist/`.
- **Large binaries / data** — model files, datasets, media dumps, anything re-downloadable.
- **Local state** — log files, caches, user-specific config, scratch files.
- **Editor / OS cruft** — `.vscode/`, `.idea/`, `.DS_Store`, `Thumbs.db`, `desktop.ini`.

If one slips in by accident, see §7.

### Starter `.gitignore`

```gitignore
# Secrets
.env
.env.*
*.key

# Dependencies / build
node_modules/
.venv/ venv/ env/
build/ dist/
__pycache__/ *.py[cod]

# Local state
*.log
config.json
.cache/

# Large data (uncomment / adjust per project)
# models/ data/ *.wav *.mp3 *.zip

# Editor / OS
.vscode/ .idea/ .DS_Store Thumbs.db desktop.ini
```

---

## 3. Version control

### Setup
- Initialize once with `git init` and commit `.gitignore` **first**, before any code,
  so ignored files never enter history.
- `main` is the default branch and is always in a working state.

### Branching
- **Never commit directly to `main`.** Branch for every change.
- Branch naming: `<type>/<short-desc>` — `feat/`, `fix/`, `docs/`, `chore/`, `refactor/`.
  - `feat/add-export`, `fix/null-on-empty-input`, `docs/readme-setup`
- Delete branches after they merge.
- *(Optional but recommended)* enforce it with a hook that blocks `git commit`/`git push`
  on `main`. See `block-main-git.template.ps1` in this template set.

### Commits
- One logical change per commit. Small and reviewable.
- Imperative, present-tense subject, ≤ 72 chars, no trailing period.
  - ✅ `fix: restore focus after dialog closes`   ❌ `fixed some stuff`
- Use [Conventional Commits](https://www.conventionalcommits.org) prefixes:
  `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`.
- Commit body explains **why**, not just what.
- Never commit broken code to `main`. Never `git push --force` to `main`.
- Don't rewrite published history others may have pulled.

### Pull requests
- All changes reach `main` through a PR, even solo work — it's the review checkpoint.
- PR description states: what changed, why, and how it was tested.
- Keep PRs focused. A bug fix and a refactor are two PRs.
- A PR must build / run / pass tests before merge.

---

## 4. Dependencies

- Pin versions for reproducibility (`==`, lockfiles, etc.).
- Adding a dependency requires a one-line justification in the PR. Remove anything unused.
- State any hard constraints here: <e.g. "no cloud SDKs", "no telemetry", "local-only",
  "stdlib only", "no new outbound network calls">.

---

## 5. Code hygiene

- Match the existing style and comment density. Don't reformat untouched code in a feature PR.
- No dead code, no commented-out blocks, no debug-print spam left behind.
- Preserve the project's core invariants: <list the load-bearing guarantees your project
  must never break — e.g. "single source of truth for config", "no blocking calls on the UI thread">.

---

## 6. Secrets & privacy (hard line)

- No secret ever enters the repo — not in code, config, history, or a commit message.
- Before pushing, scan the diff for keys, tokens, paths with usernames, and device serials.
- State the network policy: <e.g. "local-only; any PR adding an outbound call is rejected
  unless this rule is changed first", or "external calls allowed to <approved hosts> only">.
- If a secret is ever committed, treat it as compromised: rotate it immediately, then scrub
  history (§7). Scrubbing alone is not enough — the key is burned.

---

## 7. When something bad gets committed

- **Large file** committed by mistake: remove it, add to `.gitignore`, and if already pushed,
  purge it from history with `git filter-repo` (preferred) or BFG, then force-update the
  remote *branch* (never `main`) and have collaborators re-clone.
- **Secret** committed: rotate the secret first (assume it's leaked), then scrub history as above.

---

## 8. Releases / tags (optional)

- Tag working milestones with semantic versions: `v0.1.0`, `v0.2.0`.
- A tagged commit must satisfy <your definition of "shippable">.

---

*These rules protect three things: a repo small enough to clone fast, a history clean of
secrets and binaries, and a project that still matches its intended shape. Change the rule
before you break it.*
