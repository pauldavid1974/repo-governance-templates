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
2. **Rules.** Copy `AGENTS.template.md` → `AGENTS.md` (the real rules), then the per-agent
   pointers so every agent finds them: `CLAUDE.template.md` → `CLAUDE.md`,
   `GEMINI.template.md` → `GEMINI.md`, and `cursor-rules.template.mdc` →
   `.cursor/rules/agents.mdc`. (Codex reads `AGENTS.md` natively — no pointer needed.) Also
   copy `REPO_RULES.template.md` → `REPO_RULES.md` and `WORKLOG.template.md` → `WORKLOG.md`.
   Fill in every `<PLACEHOLDER>`; keep `AGENTS.md` short.
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
