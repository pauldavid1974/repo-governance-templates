# Reusable Repo Governance Templates

My personal drop-in kit that gives any new project clean governance from day one, built for
**Claude Code on Windows**: one always-on rule set, a branch-first / Conventional-Commits /
PR workflow, spec-before-code and prove-it-works habits, **fully automatic git** (Claude
branches, commits, pushes, and opens the PR on its own — no prompting), and **automatic
guardrails** that physically block the common mistakes.

Guiding principle: **written rules are only advice — an agent forgets them. The rules that
actually hold are the ones a machine enforces.** So this kit pairs short rules with hooks and
checks that do the right thing for you.

## What's in here

### Core (use in every project)

| File | Goes where (in the new repo) | Purpose |
|------|------------------------------|---------|
| `CLAUDE.template.md` | `CLAUDE.md` (repo root) | The always-on rules Claude reads every session. Single source of truth, including the automatic-git workflow. |
| `REPO_RULES.template.md` | `REPO_RULES.md` (repo root) | The full rationale: structure, secrets, branching, commits, PRs, guardrails, recovery. |
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
| `lefthook.template.yml` | `lefthook.yml` (repo root) | Runs checks before every commit — holds the secret scanner. |
| `gitleaks.template.toml` | `.gitleaks.toml` (repo root) | Config for the secret scanner (blocks commits containing keys/tokens/passwords). |

**How automatic git works:** Claude branches, commits (Conventional Commits), pushes, and
opens a PR with `gh pr create` — all without asking. The pipeline **stops at the open PR**;
merging into `main` stays a deliberate step. The branch guard and secret scan sit underneath,
so "automatic" never means committing on `main` or committing a secret.

### Optional (add when a project needs it)

See [`optional/README.md`](optional/README.md) — license guidance, `SECURITY.md`,
`CONTRIBUTING.md`, `CODEOWNERS`, `.editorconfig`, issue/PR templates, and a GitHub CI workflow.

## How to set up a new project

1. **Ignore first.** Copy `gitignore.template` → `.gitignore` and commit it before any code.
2. **Rules.** Copy `CLAUDE.template.md` → `CLAUDE.md`, `REPO_RULES.template.md` →
   `REPO_RULES.md`, and `WORKLOG.template.md` → `WORKLOG.md`. Fill in every `<PLACEHOLDER>`;
   delete what you don't need. Keep `CLAUDE.md` short.
3. **Hooks + permissions.** Copy `block-main-git.template.ps1`, `auto-commit.template.ps1`, and
   `protect-paths.template.ps1` → `.claude/hooks/`, then merge `claude-settings.snippet.json`
   into `.claude/settings.json`.
4. **Secret scan.** Copy `lefthook.template.yml` → `lefthook.yml` and `gitleaks.template.toml`
   → `.gitleaks.toml`. Install the tools (see comments in `lefthook.yml`) and run
   `lefthook install` once so the checks run on every commit.
5. **Optional extras.** Add anything from `optional/` that fits (almost always `.editorconfig`;
   a `LICENSE` if it'll ever be shared; the CI workflow if it's on GitHub).
6. **Or just ask me.** Tell me "set up this repo using my templates" in the new project and
   I'll do all of the above and tailor the placeholders to whatever we're building.

## Notes

- These are *templates*, not live config — editing them here never affects an existing repo.
  Each project gets its own filled-in copy.
- Keep `CLAUDE.md` lean. A bloated rules file gets ignored by the agent; if a rule can be
  enforced by a hook or check instead of prose, prefer that.
