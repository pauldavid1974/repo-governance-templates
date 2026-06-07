# Reusable Repo Governance Templates

My personal drop-in kit that gives any new project clean governance from day one. The rules
live in an **`AGENTS.md`** that any coding agent reads; the hooks and wiring are set up for
**Claude Code on Windows**. It provides: one always-on rule set, a branch-first /
Conventional-Commits / PR workflow, spec-before-code and prove-it-works habits, **fully
automatic git** (the agent branches, commits, pushes, and opens the PR on its own — no
prompting), and **automatic guardrails** that physically block the common mistakes.

Guiding principle: **written rules are only advice — an agent forgets them. The rules that
actually hold are the ones a machine enforces.** So this kit pairs short rules with hooks and
checks that do the right thing for you.

## What's in here

### Core (use in every project)

| File | Goes where (in the new repo) | Purpose |
|------|------------------------------|---------|
| `AGENTS.template.md` | `AGENTS.md` (repo root) | The always-on rules — **the single source of truth all agents follow** (including the automatic-git workflow). |
| `CLAUDE.template.md` | `CLAUDE.md` (repo root) | Claude Code's entry point. Imports `AGENTS.md`; adds the Claude-specific wiring. |
| `GEMINI.template.md` | `GEMINI.md` (repo root) | Antigravity's entry point. Points at `AGENTS.md`. |
| `cursor-rules.template.mdc` | `.cursor/rules/agents.mdc` | Cursor's always-apply pointer to `AGENTS.md`. |
| `REPO_RULES.template.md` | `REPO_RULES.md` (repo root) | The full rationale: structure, secrets, branching, commits, PRs, guardrails, recovery. |
| `PRD.template.md` | `PRD.md` (repo root) | Project brief — what we're building and why. Filled once at the start (the agent interviews you). |
| `SPEC.template.md` | `SPEC.md` (per feature) | A short plan to agree on **before** coding — outcome, scope, constraints, how it'll be verified. |
| `WORKLOG.template.md` | `WORKLOG.md` (repo root) | Dated running log — the project's memory between sessions. |
| `gitignore.template` | `.gitignore` (repo root) | Sensible defaults: secrets, deps, build output, local/editor files. Commit it **first**. |

### Automatic git + guardrails (enforcement)

| File | Goes where | Purpose |
|------|-----------|---------|
| `claude-settings.snippet.json` | merge into `.claude/settings.json` | Pre-allows the git/PR commands (so Claude is never prompted) and wires up all the hooks below. |
| `block-main-git.template.ps1` | `.claude/hooks/block-main-git.ps1` | Hook: denies `git commit`/`git push` while on `main`. |
| `auto-commit.template.ps1` | `.claude/hooks/auto-commit.ps1` | Stop hook: auto-commits and pushes any leftover work on the branch when a turn ends, so nothing is lost. |
| `protect-paths.template.ps1` | `.claude/hooks/protect-paths.ps1` | Hook: blocks edits to protected files (lockfiles, CI, the hooks themselves). |
| `lefthook.template.yml` | `lefthook.yml` (repo root) | Runs checks before every commit — branch guard + secret scanner. |
| `no-commit-on-main.template.sh` | `scripts/hooks/no-commit-on-main.sh` | The branch guard, as an LF-only POSIX sh script (lefthook runs `run:` via Git's bundled `sh`, not PowerShell). |
| `gitattributes.template` | `.gitattributes` (repo root) | Keeps `*.sh` LF-only so the hook script runs on Windows (defeats `core.autocrlf`). |
| `gitleaks.template.toml` | `.gitleaks.toml` (repo root) | Config for the secret scanner (blocks commits containing keys/tokens/passwords). |

**How automatic git works:** Claude branches, commits (Conventional Commits), pushes, and
opens a PR with `gh pr create` — all without asking. The pipeline **stops at the open PR**;
merging into `main` stays a deliberate step. The branch guard and secret scan sit underneath,
so "automatic" never means committing on `main` or committing a secret.

### Optional (add when a project needs it)

See [`optional/README.md`](optional/README.md) — license guidance, `SECURITY.md`,
`CONTRIBUTING.md`, `CODEOWNERS`, `.editorconfig`, issue/PR templates, and a GitHub CI workflow.

## Set up a new project (the easy way)

One command copies every template into the new folder under its real name and location,
inits git, and turns on the commit checks — no manual renaming:

```powershell
# from inside a new empty folder:
& "C:\pauls_apps\repo-governance-templates\new-governed-repo.ps1" -Name "My New App"

# or point it at a folder (created if missing):
& "C:\pauls_apps\repo-governance-templates\new-governed-repo.ps1" -Target C:\pauls_apps\my-new-app -Name "My New App"
```

Then open the folder in any agent (Claude Code, Codex, Cursor, Antigravity) and say:

> "Read AGENTS.md, then fill in the placeholders for &lt;what you're building&gt; and make the
> first commit."

The agent reads the rules, branches first, fills the remaining `<PLACEHOLDER>`s, and commits.

### Fully automatic (zero steps — recommended)

Install the global bootstrap once (see [`global/README.md`](global/README.md)) and you skip the
command entirely: open an empty folder in any agent, state your task, and the agent scaffolds
governance, interviews you to write `PRD.md`, fills the placeholders, and makes the first
commit — all before touching code. **Order:** governance first, then the PRD as the first
governed work (its answers fill the governance placeholders), then your task.

### Make it a one-word command (optional, one-time)

Add a `govern` shortcut to your PowerShell profile so you can run it from anywhere:

```powershell
Add-Content $PROFILE 'function Govern-Repo { & "C:\pauls_apps\repo-governance-templates\new-governed-repo.ps1" @args }'
Add-Content $PROFILE 'Set-Alias govern Govern-Repo'
. $PROFILE   # reload (or open a new terminal)
```

After that, from any new empty folder: `govern -Name "My New App"`.

Flags: `-WithOptional` also copies the `optional/` templates · `-Force` overwrites existing
files · `-NoGit` / `-NoLefthook` skip those steps.

### Manual setup (what the script does, if you'd rather do it by hand)

1. **Ignore first.** Copy `gitignore.template` → `.gitignore` and commit it before any code.
2. **Rules.** Copy `AGENTS.template.md` → `AGENTS.md` (the real rules), then the per-agent
   pointers: `CLAUDE.template.md` → `CLAUDE.md`, `GEMINI.template.md` → `GEMINI.md`, and
   `cursor-rules.template.mdc` → `.cursor/rules/agents.mdc`. (Codex reads `AGENTS.md` natively.)
   Also copy `REPO_RULES.template.md` → `REPO_RULES.md` and `WORKLOG.template.md` → `WORKLOG.md`.
3. **Hooks + permissions.** Copy `block-main-git.template.ps1`, `auto-commit.template.ps1`, and
   `protect-paths.template.ps1` → `.claude/hooks/`, then copy `claude-settings.snippet.json` →
   `.claude/settings.json` (or merge it into an existing one).
4. **Commit checks.** Install both tools first — `scoop install lefthook gitleaks` (the pipeline
   no-ops or fails if either is missing). Copy `lefthook.template.yml` → `lefthook.yml`,
   `gitleaks.template.toml` → `.gitleaks.toml`, `no-commit-on-main.template.sh` →
   `scripts/hooks/no-commit-on-main.sh`, and `gitattributes.template` → `.gitattributes`
   (the last keeps the sh hook LF-only on Windows). Then run `lefthook install`.
5. **Optional extras.** Add anything from `optional/` that fits.

## Notes

- **One rule set, many agents.** Codex, Cursor, Claude Code, and Antigravity each look for a
  different filename, so `AGENTS.md` holds the rules and the others (`CLAUDE.md`, `GEMINI.md`,
  `.cursor/rules/agents.mdc`) just point at it. Whichever agent opens the project reads the same
  rules before touching code. Change rules in `AGENTS.md` only. The git-level guardrails
  (branch guard + secret scan in `lefthook.yml`) apply to all of them; the `.claude/` hooks are
  a convenience layer for Claude Code specifically.
- These are *templates*, not live config — editing them here never affects an existing repo.
  Each project gets its own filled-in copy.
- Keep `AGENTS.md` lean. A bloated rules file gets ignored by the agent; if a rule can be
  enforced by a hook or check instead of prose, prefer that.
